FROM julia:1.6
RUN apt-get -y update
RUN apt-get -y install git

RUN useradd docker \
	&& mkdir /home/docker \
	&& chown docker:docker /home/docker \
	&& addgroup docker staff

RUN git clone https://github.com/cesaraustralia/GeneticRiskIndex /project/GeneticRiskIndex
RUN chown -R docker /project/GeneticRiskIndex
RUN su docker -c 'julia --project=/project/GeneticRiskIndex/julia -e "using Pkg; Pkg.instantiate()"'
RUN mkdir -p /home/docker/data
RUN chown -R docker /home/docker/data

USER docker
WORKDIR /project/GeneticRiskIndex/julia
CMD ["/bin/bash"]
