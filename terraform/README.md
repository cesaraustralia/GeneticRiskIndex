Terraform manages cloud resources, in this case on AWS.

We break terraform resource management into three steps: setup, prefiltering, and
resistance.

- **setup**: everything shared between instances is defined. This MUST be applied first and
  destroyed last.
- **prefiltering**: Run once setup has run. Uses an R instance to download and
  prefilter species data.
- **circuitscape**: Runs circuitscape for species with habitat limited
  dispersal. Run once prefiltering has run. This needs the habitat.csv file
  output by prefiltering to be able to run.
