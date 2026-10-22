# terraform

Root module. It only wires the modules in `modules/` together; resources live
in the modules and per-environment values live in `environments/<env>/`.

```bash
make init ENV=dev      # needs environments/dev/backend.hcl
```

Run `make bootstrap-plan` first if the state bucket does not exist yet. See the
top-level README for the full deployment steps.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11, < 2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.70 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.70.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_kms"></a> [kms](#module\_kms) | ./modules/kms | n/a |
| <a name="module_network"></a> [network](#module\_network) | ./modules/network | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment. Selects the settings profile in environments/<env>/. | `string` | n/a | yes |
| <a name="input_flow_log_retention_days"></a> [flow\_log\_retention\_days](#input\_flow\_log\_retention\_days) | Days to keep VPC flow logs. | `number` | n/a | yes |
| <a name="input_nat_gateway_mode"></a> [nat\_gateway\_mode](#input\_nat\_gateway\_mode) | single shares one NAT gateway across zones (cheaper). per\_az gives each zone its own, so one zone failing does not cut egress for the others. | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner tag applied to every resource. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region to deploy into, for example us-east-1. | `string` | n/a | yes |
| <a name="input_allowed_account_ids"></a> [allowed\_account\_ids](#input\_allowed\_account\_ids) | AWS account IDs Terraform may run against. Leave empty to disable the guard. | `list(string)` | `[]` | no |
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | Number of availability zones to spread subnets across (2 or 3). | `number` | `2` | no |
| <a name="input_kms_deletion_window_in_days"></a> [kms\_deletion\_window\_in\_days](#input\_kms\_deletion\_window\_in\_days) | Days a KMS key stays recoverable after deletion is scheduled (7-30). | `number` | `30` | no |
| <a name="input_project"></a> [project](#input\_project) | Short project name used as the prefix of every resource name. | `string` | `"info-api"` | no |
| <a name="input_vpc_cidr_block"></a> [vpc\_cidr\_block](#input\_vpc\_cidr\_block) | IPv4 CIDR of the VPC. Subnets are /24 blocks carved from it, so use /16 or larger. | `string` | `"10.20.0.0/16"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | AWS account this configuration is applied to. Check it before approving a plan. |
| <a name="output_nat_public_ips"></a> [nat\_public\_ips](#output\_nat\_public\_ips) | Public IPs of the NAT gateways. Allow-list these at any service the Lambda calls over the internet. |
| <a name="output_region"></a> [region](#output\_region) | AWS region this configuration is applied to. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC. |
<!-- END_TF_DOCS -->
