# GeneticRiskIndex

This repository contains reproducible infrastructure and application scripts for
calculating extinction risk index based on spatial separation of species,
dispersal capacity, and landscape resistance processed with Circuitscape.jl. It
is written for species in Victoria, Australia using the ALA occurrence datasets.

Terraform is used to build the required Amazon Web Services (AWS) infrastructure
to process hundreds/thousands of species. AWS containers are provisioned with R
and Julia using [Ansible playbooks](https://docs.ansible.com/ansible/latest/user_guide/playbooks_intro.html).


## Setup

Software needed to run these scripts locally:
- [terraform](https://www.terraform.io/)
- [aws cli](https://aws.amazon.com/cli/)

On linux and mac these can be installed with most package managers (e.g. brew,
apt, pacman) and run from the command line. On windows ansible will need
[cygwin](https://www.cygwin.com/), while terraform has a [windows
installer](https://www.terraform.io/downloads.html). It is recommended these
scripts are run from linux, either a local machine, a vm or a server.

Once terraform and aws-cli are installed, clone or download this repository to
get started.

## Running Tasks with Terraform

The tasks in this project are run in on Amazon Web Services (AWS) using
terraform. This needs an AWS account, details of which need to be filled out in
a `terraform.tfvars` file placed in the `terraform` folder. This can be copied
from the `terraform.tfvars.example` and filled in with your AWS credentials.

The terraform run is broken into 3 steps. 

1. Set up aws infrastructure for the project.

2. Run an R container to download and prefilter taxon data.

3. Start AWS Batch tasks (using julia docker container) for each taxon that
requires a habitat resistance simulation. This is by far the largest use of
server resources, and may be hundreds of containers.

4. Run another task in an R container to finalise risk calculations from data
returned by Circuitscape tasks.

**⚠  WARNING terraform can start hundreds of AWS containers** 

Be careful with the contents of your terraform.tfvars file, and the size of the
csv returned from step 1 and passed to step 2. The number of taxon rows is the number of Fargate containers that will be created.

These variables also have direct effect of the cost of AWS servers. 
Larger numbers are more expensive:


# Instructions

## Set AWS credentials

`aws cli` handles storing your aws credentials in your system. 
Terraform will use these to create instances in your account, and we 
will use `aws cli` from the command line

Run:

```
aws configure
```

and follow the prompt.


# Set up infrastructure

To simulate running the tasks, from the command line run:

```
cd terraform/setup
terraform plan
```

To run them, run:

```
terraform apply
```

And answer 'yes' to run. This should build all the required infrastructure.

Then we can run the R task

```
aws submit-job --job-name '$(terraform output prefilter)` --job-queue '$(terraform output queue)` --job-definition $(terraform output prefilter)
```

To back-up data from the run to the amazon s3 bucket:

```
aws datasync start-task-execution --task-arn '$(terraform output efs-data-backup-arn)`
```

Then we can run the Circuitscape batch jobs returned by the prefilter task

```
aws submit-job --job-name '$(terraform output circuitscape)` --job-queue '$(terraform output queue)` --job-definition $(terraform output circuitscape)
```

Backup again:

```
aws datasync start-task-execution --task-arn '$(terraform output efs-data-backup-arn)`
```

Check the s3 bucket in the web interface to be sure the data is available.


To finally destroy the R instance, run:

```
terraform destroy
```
