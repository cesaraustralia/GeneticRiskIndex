FROM julia:1.6
RUN apt-get -y update
RUN apt-get -y install git
RUN git clone https://github.com/cesaraustralia/GeneticRiskIndex
RUN julia --project=GeneticRiskIndex/julia -e "using Pkg; Pkg.instantiate()"
WORKDIR GeneticRiskIndex/julia
CMD ["/bin/bash"]
