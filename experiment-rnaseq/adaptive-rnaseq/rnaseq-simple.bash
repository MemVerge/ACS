#!/bin/bash

exec > $FLOAT_LOG_PATH/run.log 2>&1

# a simple RNAseq QC pipeline based on https://github.com/nextflow-io/rnaseq-nf


binpath="/opt/conda/bin"
# Initialize variables
read1=""
read2=""
transcriptome=""
multiqc=""

# Function to display usage information
usage() {
    echo "Usage: $0 [--read1 <read1_file>] [--read2 <read2_file>] [--transcriptome <transcriptome_file>] [--multiqc <multiqc_dir>] [--threads 2]"
    exit 1
}

# Parse command-line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        --read1|-1)
            shift
            read1="$1"
            ;;
        --read2|-2)
            shift
            read2="$1"
            ;;
        --transcriptome|-r)
            shift
            transcriptome="$1"
            ;;
        --multiqc|-m)
            shift
            multiqc="$1"
            ;;
        --threads|-t)
            shift
            threads="$1"
            ;;
        *)
            usage
            ;;
    esac
    shift
done

# Check the existence of the files and directory
if [ ! -f "${read1}" ]; then
    echo "Error: 1st Reads file: ${read1} not found."
    usage
fi

if [ ! -f "${read2}" ]; then
    echo "Error: 2nd Reads file: ${read2} not found."
    usage
fi

if [ ! -f "$transcriptome" ]; then
    echo "Error: Transcriptome file not found."
    usage
fi

if [ ! -d "$multiqc" ]; then
    echo "Error: MultiQC directory not found."
    usage
fi

if [[ $threads -lt 2 ]]; then
    threads=2
fi

filename=${read1##*/}  # remove the path, keep only the file name
sample_id=${filename%_1*}
#workdir="$PWD/${sample_id}"
workdir="/mnt/jfs/nextflow"
mkdir -p $workdir
cd $workdir

outdir="${workdir}/results"


# index
###
echo $(date) "[Task] start salmon index"
start=`date +%s`

$binpath/salmon index --threads $threads -t $transcriptome -i index

end=`date +%s`
echo $(date) "[Task End] time used: " $((end-start)) "sec"


# quant
###
echo $(date) "[Task] start salmon quant"
start=`date +%s`

$binpath/salmon quant --threads $threads --libType=U -i index -1 ${read1} -2 ${read2} -o pair_id

end=`date +%s`
echo $(date) "[Task End] time used: " $((end-start)) "sec"

/opt/memverge/bin/float migrate --sync -f -t c5a.large -j ${FLOAT_JOB_ID}

# fastqc
###
echo $(date) "[Task] start fastqc"
start=`date +%s`

mkdir fastqc_${sample_id}_logs
$binpath/fastqc -o fastqc_${sample_id}_logs -f fastq -q ${read1}
$binpath/fastqc -o fastqc_${sample_id}_logs -f fastq -q ${read2}

end=`date +%s`
echo $(date) "[Task End] time used: " $((end-start)) "sec"


# multiqc
###
echo $(date) "[Task] start multiqc"
start=`date +%s`

cp $multiqc/* .
echo "custom_logo: \$PWD/logo.png" >> multiqc_config.yaml
$binpath/multiqc .

end=`date +%s`
echo $(date) "[Task End] time used: " $((end-start)) "sec"
