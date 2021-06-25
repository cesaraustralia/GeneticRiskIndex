# Base image https://hub.docker.com/u/rocker/
FROM rocker/r-base

# RUN commands are executed inside the containers
# system libraries of general use
## install debian packages
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
    # dependency
    git \
    libssh2-1-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libgit2-dev \
    libgdal-dev \
    libgeos-dev \
    libgeotiff-dev \
    libjpeg-dev \
    libicu-dev \
    libproj-dev \ 
    libudunits2-dev

# libcurl4-gnutls-dev

## update system libraries
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean

# install R packages
RUN Rscript -e 'install.packages(c("tidyverse","lubridate","galah","fpc"))'
RUN Rscript -e 'install.packages(c("rgdal","rgeos","sf","terra","tmap"))'

RUN git clone https://github.com/cesaraustralia/GeneticRiskIndex /project/GeneticRiskIndex

WORKDIR /project/GeneticRiskIndex/R
CMD ["/bin/bash"]
