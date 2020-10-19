FROM rocker/r-base:latest

# Install external dependencies
RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends --allow-downgrades \
 libcurl4-openssl-dev \
 libssl-dev \
 libsqlite3-dev \
 libxml2-dev \
 qpdf \
 vim \
 libgsl-dev \
 && apt-get clean \

# Install some required libraries
RUN Rscript -e 'install.packages("BiocManager", dependencies=TRUE)'
RUN Rscript -e 'BiocManager::install("GenomicRanges", dependencies=TRUE)'

# Install python and required packages
RUN apt-get update
RUN apt-get install -y python3.4 python3-dev libpq-dev python3-pip

COPY requirements.txt /bin/
RUN pip install --no-cache-dir -r /bin/requirements.txt
COPY . /bin/
RUN chmod -R +x /bin/


CMD ["/bin/bash"]