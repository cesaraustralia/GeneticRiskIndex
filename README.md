# GeneticRiskIndex

This repository contains reproducible infrastructure and application scripts for calculating extinction 
risk index based on spatial separation of species, dispersal capacity, and landscape resistance processed 
with Circuitscape.jl. It is written for species in Victoria, Australia using the ALA occurrence datasets.

Terraform is used to build the required AWS infrastructure to process hundreds/thousands of
species. AWS containers are provisioned with R/Julia using Ansible playbooks.


## Setup

Software needed to run these scripts locally:
- [terraform](https://www.terraform.io/)
- [ansible](https://www.ansible.com/)

On linux and mac these can be installed with most package managers (e.g. brew,
apt, pacman) and run from the command line.

On windows ansible will need [cygwin](https://www.cygwin.com/), while terraform
has a [windows installer](https://www.terraform.io/downloads.html).

It is recomended these scripts are run from linux, either a local machine, a vm
or a server.

Once terraform and ansible are installed, clone or download this repository to
start.


## R and Julia server images

These scripts generate images for ubutu servers using ansible playbooks. One
contains R binaries and required packages, the other Julia binaries and
pre-installed packages for this project.

These servers can be generated locally in a virtual machine, for manual use of
scripts, using [Vagrant](https://www.vagrantup.com/).

To generate the virtual machine, go to the `ansible/julia` or `ansible/R`
folders and run:

```bash
vagrant up
```

To ssh into them, run:

```bash
vagrant ssh
```

You will be logged into a fully functioning system with all software and scripts
needed for this project already installed.


## Running Tasks with Terraform

The tasks in this project are run in on Amazon Web Services (AWS) using
terraform. This needs an AWS account, details of which need to be filled out in
a `terraform.tfvars` file placed in the `terraform` folder. This can be copied
from the `terraform.tfvars.example` and filled in with your AWS credentials.

The terraform run is broken into 3 steps. 

1. Run an R server to download and prefilter taxon data, and prepare list of
species that need habitat resistance modelling using Ciscuitscape in Julia.
Simultaneously prepare an aws AMI to run Julia and Circuitscape, with this
project pre-installed and instantiated.

2. Start [AWS Fargate](https://aws.amazon.com/fargate) tasks (using the
predefined julia AMI) for each taxon that requires a habitat resistance
simulation. This is by far the largest use of server resources, spinning up
hundreds of containers.

3. Run another R instance to finalise risk calculations from data returned by
Circuitscape tasks.


**⚠  WARNING terraform can start hundreds of AWS containers ** 

Be careful with the contents of your terraform.tfvars file, and the size of the
csv returned from step 1 and passed to step 2. The number of taxon rows is the
number of Fargate containers that will be created.

These variables also have direct effect of the cost of AWS servers. 
Larger numbers are more expensive:

```
r_instance_type = "t2.micro"
julia_cpus = 4
julia_instance_memory = 4096
```

To simulate running the tasks, from the command line run:

```
terraform plan
```

To run them, run:

```
terraform apply
```

To finally destroy the R instance, run:
```
terraform destroy
```

The Fargate Julia/Circuitscape tasks will close themselves on completion.
