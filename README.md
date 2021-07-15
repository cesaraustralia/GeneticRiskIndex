# GeneticRiskIndex

This repository contains reproducible infrastructure and application scripts for
calculating extinction risk index based on spatial separation of species,
dispersal capacity, and landscape resistance processed with
[Circuitscape.jl](https://github.com/Circuitscape/Circuitscape.jl). It is
written primarily for species in Victoria, Australia using the ALA occurrence
datasets.

Terraform is used to build the required Amazon Web Services (AWS) Batch
infrastructure to process hundreds/thousands of species. AWS containers are
provisioned with R and Julia using
[Docker](https://www.docker.com/resources/what-container).


# Installation

Software needed to run these scripts locally:
- [terraform](https://www.terraform.io/)
- [docker](https://docs.docker.com/get-docker/)
- [aws cli](https://aws.amazon.com/cli/)

On linux and mac these can be installed with most package managers (e.g. brew,
apt, pacman) and run from the command line. It is recommended these scripts are
run from linux, either in a local machine, a virtual machine or on a server.

Once terraform and aws-cli are installed, clone or download this repository to
get started.

# Overview

The process of running these scripts is broken into a number of steps:

1. Define an AWS IAM user with admin permissions

1. Define an AWS S3 bucket for data storage throughout the project.

2. Set up all AWS other infrastructure with terraform.

3. Run prefiltering, circuitscape and postprocessing iteratively until all tasks
are working and outputs make sense.

4. Back up all data to the S3 bucket. This can also happen during step 2.

5. Destroy all AWS infrastructure using terraform, besides the S3 bucket.


# Local Instructions

All scripts can be run locally, as well as in the cloud. However they need
the same data available. This must be in a `data` folder in your home directory.

It must include:

- habitat.tif
- fire_severity.tif
- batch_taxa.csv
- config.toml (modified from config.toml.example in this repo)

First run the R script with:

```
cd GeneticRiskIndex/R
Rscript prefilter.R
```

The julia script can then be run with:

```
cd GeneticRiskIndex/julia
julia --project=. circuitscape.jl
```

To run a specific item, here the 5th taxon, use:

```
AWS_BATCH_JOB_ARRAY_INDEX=5 julia --project=. circuitscape.jl
```

The jobs are listed in data/batch_jobs.txt, which is output by prefilter.R.

# Cloud Instructions

First set up an IAM user for the project, or multiple IAM users if multiple people
need access.

## Set up AWS

`aws cli` handles storing your aws credentials in your system.
Terraform will use these to create instances in your account, and we 
will use `aws cli` from the command line.

Run:

```
aws configure
```

and follow the prompt.


## Set up an AWS bucket for long-term cloud file storage

Go to https://s3.console.aws.amazon.com and click "create bucket", and define
a bucket called "genetic-risk-index-s3". Other names are possible but will
need a variable place in a terraform.tfvars file in the terraform directory, 
for example:


## Set up all other infrastructure

```
project = "genetic-risk-index"
project_repo = "https://github.com/cesaraustralia/GeneticRiskIndex"
s3_bucket = "genetic-risk-index-s3"
aws_credentials = "/home/username/.aws/credentials"
aws_region = "ap-southeast-2"
aws_availability_zone = "ap-southeast-2a"
```


To simulate setting up infrastructure, from the command line run:

```
cd terraform
terraform init
terraform plan
```

To actually run them, run:

```
terraform apply
```

And answer 'yes'. This should build all the required infrastructure.


## Prefiltering

We first need to upload the our config file and the required `habitat.tif` and
`fire_severity.tif` layers:

```
aws s3 cp habitat.tif s3://genetic-risk-index-s3/habitat.tif
aws s3 cp fire_severity.tif s3://genetic-risk-index-s3/fire_severity.tif
```

These only need to be uploaded once, unless you need to change them. 

Then copy your `config.toml file`, modified from `config.toml.example` in this repository:

```
aws s3 cp config.toml s3://genetic-risk-index-s3/config.toml
```

Then we can upload the csv containing the taxa we want to process in this batch:

```
aws s3 cp batch_taxa.csv s3://genetic-risk-index-s3/batch_taxa.csv
```

This will likely be repeatedly uploaded to run lists of taxa, as it is unlikely
the whole list will run successfully immediately.

Then, navigate to the terraform folder and trigger the R prefilter job. We can
get the ids of our jobs and job queue from terraform, so we don't have to track
any of that manually:

```
cd GeneticRiskIndex/terraform
aws batch submit-job --job-name prefilter --job-queue $(terraform output -raw queue) --job-definition $(terraform output -raw prefilter)
```

The name can be anything you like. To back-up data from the run to the amazon s3 bucket:

```
aws datasync start-task-execution --task-arn $(terraform output -raw backup-arn)
```

We can check that it worked:

```
aws s3 ls s3://genetic-risk-index-s3/data
```

Or visit the s3 console page in a web browser:

https://s3.console.aws.amazon.com/s3/buckets/genetic-risk-index-s3


We can also download all the data to a local directory:

```
aws s3 sync s3://genetic-risk-index-s3/data output_data
```

Or just the precluster/orphan plots:

```
aws s3 sync s3://genetic-risk-index-s3/data/plots output_plots
```


## Run Circuitscape jobs

Copy the job list into your terraform folder:

```
aws s3 cp s3://genetic-risk-index-s3/data/batch_jobs.txt batch_jobs.txt
```

The file will be a list of taxa to run in circuitscape, you can check it to see if it makes sense.

```
less batch_jobs.txt
```

**⚠  WARNING aws-cli commands can start thousands of containers** 

Be careful to check the contents of your batch_jobs.txt file are what you expect them to be.


To run the first taxon in the list only as a test, or a list of length 1:

```
aws batch submit-job --job-name circuitscape --job-queue $(terraform output -raw queue) --job-definition $(terraform output -raw circuitscape)
```

For an array of taxa (must be 2 or more jobs, thats just how AWS Batch arrays work)

```
aws batch submit-job --array-properties size=$(wc -l < batch_jobs.txt) --job-name circuitscape --job-queue $(terraform output -raw queue) --job-definition $(terraform output -raw circuitscape)
```


Backup again:

```
aws datasync start-task-execution --task-arn $(terraform output -raw backup-arn)
```

## Run post-processing

```
aws batch submit-job --job-name postprocessing --job-queue $(terraform output -raw queue) --job-definition $(terraform output -raw postprocessing)
```

You can check the batch tasks in the console:
https://ap-southeast-2.console.aws.amazon.com/batch/v2/home

Make sure also to check the s3 bucket in the web interface to be sure the data
is available before you destroy any infrastructure.


## Destroy infrastructure

To finally destroy all infrastructure besides the s3 bucket, run:

```
terraform destroy
```
