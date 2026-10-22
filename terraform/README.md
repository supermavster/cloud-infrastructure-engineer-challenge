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

## Resources

| Name | Type |
| ---- | ---- |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment. Selects the settings profile in environments/<env>/. | `string` | n/a | yes |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner tag applied to every resource. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region to deploy into, for example us-east-1. | `string` | n/a | yes |
| <a name="input_allowed_account_ids"></a> [allowed\_account\_ids](#input\_allowed\_account\_ids) | AWS account IDs Terraform may run against. Leave empty to disable the guard. | `list(string)` | `[]` | no |
| <a name="input_kms_deletion_window_in_days"></a> [kms\_deletion\_window\_in\_days](#input\_kms\_deletion\_window\_in\_days) | Days a KMS key stays recoverable after deletion is scheduled (7-30). | `number` | `30` | no |
| <a name="input_project"></a> [project](#input\_project) | Short project name used as the prefix of every resource name. | `string` | `"info-api"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_account_id"></a> [account\_id](#output\_account\_id) | AWS account this configuration is applied to. Check it before approving a plan. |
| <a name="output_region"></a> [region](#output\_region) | AWS region this configuration is applied to. |
<!-- END_TF_DOCS -->
