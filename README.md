# GeneticRiskIndex

This repository contains reproducible infrastructure and application scripts for calculating extinction 
risk index based on spatial separation of species, dispersal capacity, and landscape resistance processed 
with Circuitscape.jl. It is written for species in Victoria, Australia using the ALA occurrence datasets.

Terraform is used to build the required AWS infrastructure to process hundreds/thousands of
species. AWS containers are provisioned with R/Julia using Ansible playbooks.
