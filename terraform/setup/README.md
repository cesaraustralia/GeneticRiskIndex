These scripts must be run first. They:

- Define security groups.
- Define a shared local network.
- Create a shared efs drive for instances.
- Build amis for julia and r instances, with all project dependencies
  preinstalled and the shared efs drive pre-mounted.

They can be run with:

```
terraform init
terraform apply
```
