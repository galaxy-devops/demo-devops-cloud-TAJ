## Regarding to this Repository

---

### Overview

Aside my another [demo repository](https://github.com/galaxy-devops/demo-springboot-service), This lightweight repository’s target is to demonstrate the continue delivery application with Jenkins pipeline to AWS platform. Devops CD  on the Cloud with Terraform, Ansible, and Jenkins



### Branch

#### v1-Terraform

This branch demonstrate the use of Terraform to create resource objects on AWS.

- AWS VPC
  - Subnet
  - Route
  - IGW
- AWS EC2
  - Keypair
  - Security Group
- Running APP

> For more use case of Terraform, please refer to my [repository](https://github.com/galaxy-IaC/terraform)

#### v2-Ansible

In this branch, will achieve the purpose of deploying app using Ansible within terraform resource manifests

#### v3-CD-with-Jenkins

Using terraform to achieve Continuous Deployment in Jenkins pipeline.