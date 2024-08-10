### Demo using terraform

#### Overview

In this branch, we're going to demonstrate a simple use case of using terraform to create resource on AWS. These below manifests were completely implemented and passed within [AWS Cloud9](https://aws.amazon.com/cloud9/)

#### Prerequisite

We utilize `HCP Terraform` as the backend of `terraform state` . So, please prepare an organization and workspace on it.

##### Organization

Login to the [HCP terraform platform](https://app.terraform.io/session)

 ![](https://camo.githubusercontent.com/f68d6758bbfa343a9a3e4b157f2f0598d068420d926b628235300e30254d0d0a/68747470733a2f2f67697465652e636f6d2f62696e676f343933332f626c6f67696d6167652f7261772f6d61737465722f696d672f64656d6f2d54414a2f76312d7465727261666f726d2f4843502532307465727261666f726d2e706e67)

 Then, click `Create organization` button in the `Organizations`

- Organization name, input: `demo-devops-cloud-TAJ`
- Email address, input your email

 <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/create-organization-1.png" style="zoom:75%;" />

##### Workspace

- Choose your workflow
  - choose`CLI Driven Workflow`
    <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/create-workspace-1.png" style="zoom:50%;" />

- Configure Settings
  - Workspace Name，input：`terransible` 
  - Project，keep the default
  - Create
     <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/create-workspace-2.png" style="zoom:50%;" />

##### Configure workspace

click `Remote` in the `Execution mode` 

 <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/changeMode.png" style="zoom:75%;" />

Then click `Local(custom)`

 <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/executionMode.png" style="zoom:75%;" />

##### Token

Click drop-down arrow aside of avatar profile then `Account settings`

 <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/token-1.png" style="zoom:70%;" />

Click `Create an API token` button in the tokens

 <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/token-2.png" style="zoom:70%;" />

##### Validation

Let's try to create AWS resource  using this manifests as below

> file：providers.tf

```plain
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}
```

> file：backend.tf

```plain
terraform {
  cloud {
    organization = "demo-devops-cloud-TAJ"
    workspaces {
      name = "terransible"
    }
  }
}
```

> file: vpc.tf

```plain
resource "aws_vpc" "demo_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" = "demo_vpc"
  }
}
```

Let's go to run these commands

```plain
$ terraform login
$ terraform init
$ terraform apply
```

Show the state

```bash
$ terraform state list
aws_vpc.demo_vpc
```

Get the state in the remote workspace

 <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/checkState.png" style="zoom:70%;" />

#### Implement Resource

Create AWS resource object

```bash
$ terraform init
$ terraform apply -auto-approve

```

