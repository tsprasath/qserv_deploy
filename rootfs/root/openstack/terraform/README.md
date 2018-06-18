Provision Qserv using Terraform
======

This procedure provision a cluster in OpenStack for Qserv

Pre-requisites
------

* [Install terraform](https://www.terraform.io/downloads.html)
* Download your [OpenStack RC file](http://docs.openstack.org/user-guide/common/cli_set_environment_variables_using_openstack_rc.html)
* Then, in the `terraform` directory run:
```bash
$ . ./<your-rc-file>.sh
$ . ./terraform-setup.sh
$ cp terraform.tfvars.example terraform.tfvars
```

* Edit the `terraform.tfvars` file with your cluster parameters then run `$ terraform init`

For the next terraform commands, **remember to source your RC file and `terraform-setup.sh`** before running the commands.

Setting up the cluster
-----
To set up the cluster or to apply changes to the configuration, run `$ terraform apply`, check the plan and answer yes to the question.

Deleting the cluster
-------
To delete the resources you created use `$ terraform delete`

Others commands
-------
You can use all commands available in terraform, see [the Doc](https://www.terraform.io/docs/commands/index.html) for a complete list.
