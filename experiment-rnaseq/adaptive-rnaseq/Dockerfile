FROM mambaorg/micromamba:alpine
MAINTAINER Paolo Di Tommaso <paolo.ditommaso@gmail.com>

USER root

RUN \
   micromamba install -y -n base -c defaults -c bioconda -c conda-forge \
     typing-extensions \
      python=3.11.6 \
      salmon=1.10.2 \
      fastqc=0.12.1 \
      multiqc=1.15 \
   && micromamba clean -a -y

ENV PATH="$PATH:/opt/conda/bin"
COPY rnaseq-simple.bash ./
ENTRYPOINT ["./rnaseq-simple.bash" ]
