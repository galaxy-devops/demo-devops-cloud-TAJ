### Devops with Jenkins

#### Overview

In this branch, we will demonstrate to call the Jenkins pipeline which will use terraform to automate the deployment of the APP after doing submit the code to GitHub

> For more use case of Jenkins CI/CD pipeline, please refer to my another [repository](https://github.com/galaxy-devops/demo-springboot-service)

#### Install Jenkins

##### Default inventory

Open the default inventory file

```bash
$ sudo vim /etc/ansible/hosts
```

Add the setting as below

```plain
[hosts]
localhost
[hosts:vars]
ansible_connection=local
ansible_python_interpreter=/usr/bin/python3
```

##### Installation

> The playbook file under `playbooks` directory
>
> File name: jenkins.yml

```yaml
---
- name: "Install Jenkins"
  hosts: localhost
  become: yes

  tasks:
  - name: "download apt key"
    ansible.builtin.get_url:
      dest: /usr/share/keyrings/jenkins-keyring.asc
      url: https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
  - name: "Add jenkins repo to sources.list"
    ansible.builtin.apt_repository:
      repo: "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/"
      state: present
      filename: jenkins
  - name: "Install requisite package"
    ansible.builtin.apt:
      name: "{{ item }}"
      state: latest
    loop:
      - fontconfig
      - openjdk-17-jre
  - name: "Update all packages to their latest version"
    ansible.builtin.apt:
      name: "*"
      state: latest    
  - name: "Update apt cache and install jenkins"
    ansible.builtin.apt:
      name: jenkins
      update_cache: yes
  - name: "Ensure jenkins is started and enabled"
    ansible.builtin.systemd:
      name: jenkins
      enabled: yes
      state: started
```

Run ansible command

```bash
$ ansible-playbook playbooks/jenkins.yml
```

##### Plugin

It's necessary to install these plugins during configuration Jenkins

- ansible
- pipeline-aws

#### GitHub Configuration

##### Register GitHub APP

We should register the GitHub app ahead of Jenkins pipeline. Click `Settings` in the organization page.

 <img src="https://camo.githubusercontent.com/f1953539f05314877c35aaece8d869a8b027f493f20fbd1cec0e737b40a70488/68747470733a2f2f67697465652e636f6d2f62696e676f343933332f626c6f67696d6167652f7261772f6d61737465722f696d672f64656d6f2d54414a2f76332d6465706c6f796d656e742d7573696e672d4a656e6b696e732f73657474696e67732e706e67" style="zoom:67%;" />

Then, Click `GitHub Apps` under the `Developer settings` entry. Click `New GitHub App` button

 <img src="https://camo.githubusercontent.com/c9f617747e9b773464fe59e30d5f627fc06e4352a7b02bd56636c4aa9664a1ee/68747470733a2f2f67697465652e636f6d2f62696e676f343933332f626c6f67696d6167652f7261772f6d61737465722f696d672f64656d6f2d54414a2f76332d6465706c6f796d656e742d7573696e672d4a656e6b696e732f676974687562617070732e706e67" style="zoom:60%;" />

In the `Register new GitHub App` page

- GitHub App name: `demo-devops-cloud-TAJ`

- Homepage URL: `https://github.com/galaxy-devops`
   <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/v3-Devops-with-Jenkins/registerGitHubApp-1.png" style="zoom:50%;" />

- Identifying and authorizing users

  - Callback URL: keep it blank
  - Expire user authorization tokens: uncheck

- Webhook

  - Webhook URL: `http://galaxy-jenkins.hicam.net:8080/github-webhook`

    > This `galaxy-jenkins.hicam.net` is a dynamic DNS domain name which resolve to my Cloud9 host IP address

     <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/v3-Devops-with-Jenkins/registerGitHubApp-2.png" style="zoom:60%;" />

- Permissions

  - Repository permissions
    - Commit statuses: `Access: Read and write`
    - Contents: `Access: Read-only`
    - Metadata: `Access: Read-only`
    - Pull requests: `Access: Read-only`
    - other items: keep it default
  - Subscribe to events
    - check all the items
  - Where can this GitHub App be installed: `Only on this account`

- Click `Create GitHub App`

Then, please take note the `App ID` in the `General`

 <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/v3-Devops-with-Jenkins/general-appID.png" style="zoom:50%;" />

let's go ahead enter to the `Install App` item and click `Install`

 <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/v3-Devops-with-Jenkins/installAPP-1.png" style="zoom:50%;" />

Click `Only select repositories`  and select  `demo-devops-cloud-TAJ` repository in the subsequent page.

Click `Install` button

 <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/v3-Devops-with-Jenkins/installAPP-2.png" style="zoom:50%;" />

##### Convert private key format

Click `Generate a private key` button in above `General` menu.

 <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/v3-Devops-with-Jenkins/private-key-1.png" style="zoom:50%;" />

It will automatically download private key in your compute. Then let's convert its format using this command

```bash
$ openssl pkcs8 -topk8 -inform PEM \
-outform PEM \
-in demo-devops-cloud-taj.2024-08-11.private-key.pem \
-out converted-github-app.pem \
-nocrypt
```

#### Add credentials

> Enter into the credentials item from Security in the Jenkins dashboard

##### GitHub App

- Kind: `GitHub App`
- ID: `demo-devops-cloud-taj`
- App ID: `967359`
- Key:  open the converted key file, copy and paste the content in here
- Click `Test Connection` button for validation
  <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/v3-Devops-with-Jenkins/jenkinsCredentials-1.png" style="zoom:40%;" />



##### Terraform

- Kind: `Secret file`
- File: click `choose file` button, select the file which generated by `terraform init` command
- ID: `tf-creds`
  <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/v3-Devops-with-Jenkins/jenkinsCredentials-2.png" style="zoom:50%;" />

##### Ansible

- Kind: `SSH Username with private key`

- ID: `ec2-ssh-key`

- Description: `Key for bootstrapping ec2 instances`

- Username: `ubuntu`

- Private key:

  - Check: `Enter directly`

  - Click `Add`  button

  - Open private key file of **`SSH`** protocol and paste the content in here

     <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/v3-Devops-with-Jenkins/jenkinsCredentials-3.png" style="zoom:50%;" />

#### Jenkins pipeline

##### Add webhook

Click `Settings` in the repository. Then click `Webhooks` and `Add webhook` button under the `General` section

 <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/v3-Devops-with-Jenkins/jenkins-webhooks-1.png" style="zoom:50%;" />

Add these options as below

- Payload URL: `http://galaxy-jenkins.hicam.net:8080/github-webhook/`
- Content type: `application/json`
- Secret: keep it blank
- SSL verification: `Disable (not recommended)`
- Which events would you like to trigger this webhook?
  - select: `Let me select individual events`
  - check:
    - `Pushes`
    - `Pull requests`
- tick:`Active`
- Click: `Add webhook` 

##### Pipeline

> Create a pipeline project in Jenkins

- name: `demo-devops-cloud-TAJ`
- type: `Multibranch pipeline`
- Click: `OK` 

Enter into this pipeline project

- General label page
  - Branch Sources: click `Add source` then choose `GitHub` 
  - Credentials: `demo-devops-cloud-taj`
    - Repository HTTPS URL: `https://github.com/galaxy-devops/demo-devops-cloud-TAJ`
    - Click`Validate`  button to test access connection
      <img src="https://gitee.com/bingo4933/blogimage/raw/master/img/demo-devops-cloud-TAJ/v3-Devops-with-Jenkins/repositoryBranchSource-1.png" style="zoom:45%;" />
  - Orphaned Item Strategy:
    - Max # of old items to keep: `5`
- All of others: keep it default
- Click: `Save`

##### Jenkinsfile

Add `shared_credentials_files` argument in the file `provider.tf`

```plain
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.aws_region
  shared_credentials_files = ["/home/ubuntu/.aws/credentials"]
}
```

Create file `Jenkinsfile`

```plain
pipeline{
    agent any
    environment {
        TF_IN_AUTOMATION='true'
        TF_CLI_CONFIG_FILE=credentials('tf-creds')
        AWS_SHARED_CREDENTIALS_FILE = '/home/ubuntu/.aws/credentials'
    }
    stages {
        stage ('Init') {
            steps {
                sh 'terraform init -no-color'
            }
        }
        stage('Plan') {
            steps{
                sh 'echo "TERRAFORM PLAN"'
                sh 'terraform plan -no-color -var-file="$BRANCH_NAME.tfvars"'
            }
        }

        stage('Validate Apply') {
            when {
                beforeInput true
                branch "dev"
            }
            input {
                message "Do you want to apply this plan?"
                ok "Apply this plan"
            }
            steps {
                echo 'Apply Accepted'
            }
        }

        stage('Apply'){
            steps{
                sh 'echo "This is APPLY stage"'
                sh 'terraform apply -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
            }
        }

        stage('Inventory') {
            steps {
                sh '''printf \\
                    "\\n$(terraform output -json instance_ips | jq -r '.[]')" \\
                    >> aws_hosts'''
            }
        }

        stage('EC2 Wait') {
            steps{
                sh 'echo "EC2 Waiting"'
                sh '''aws ec2 wait instance-status-ok \\
                    --instance-id $(terraform output -json instance_ids | jq -r \'.[]\') \\
                    --region ap-northeast-1'''
            }
        }

        stage('Validate Ansible') {
            when {
                beforeInput true
                branch "dev"
            }
            input {
                message "Do you want to run Ansible?"
                ok "Run Ansible!."
            }
            steps {
                echo 'Ansible Accepted'
            }
        }

        stage('Ansible') {
            steps {
                ansiblePlaybook(credentialsId: 'ec2-ssh-key', inventory: 'aws_hosts', playbook: 'playbooks/main-playbook.yml')
            }
        }

        stage('Validate Destroy') {
            input {
                message "Do you want to destroy all the things?"
                ok "Destroy!."
            }
            steps {
                echo 'Destroy Accepted'
            }
        }

        stage('Destroy') {
            steps{
                sh 'echo "This is DESTROY stage"'
                sh 'terraform destroy -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
            }
        }
    }
    post {
        success {
            echo 'Success!'
        }
        failure {
            sh 'terraform destroy -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
        }
        aborted {
            sh 'terraform destroy -auto-approve -no-color -var-file="$BRANCH_NAME.tfvars"'
        }        
    }
}
```

##### Use Jenkinsfile

###### dev branch

According to business process,  need firstly develop and deploy our application in the `dev` branch

```bash
$ git checkout -b dev
```

To accommodate changes in business needs, let's split the `terraform.tfvars` file into two independent files.

- dev.tfvars
- main.tfvars

> dev.tfvars

```plain
aws_region      = "ap-northeast-1"
vpc_cidr        = "10.123.0.0/16"
key_name        = "galaxy-demo-TAJ"
public_key_path = "/home/ubuntu/.ssh/demo-devops-cloud-taj.pub"
```

> main.tfvars

```plain
aws_region      = "ap-northeast-1"
vpc_cidr        = "10.124.0.0/16"
key_name        = "galaxy-demo-TAJ"
public_key_path = "/home/ubuntu/.ssh/demo-devops-cloud-taj.pub"
```

Commit code within `dev` branch

```bash
$ git add .
$ git commit -m "Created dev branch"
$ git push -u origin dev
```

Then, Jenkins will be triggered by webhook to build pipeline after doing commit operation.

###### Add validation

Create file `node-test.yml` in the `playbooks` directory to achieve automate validation of APP

```yaml
---
- name: "Test for Grafana and Prometheus access"
  hosts: main
  gather_facts: no
  vars:
    apps:
      prometheus:
        port: 9090
        status_code: [302]
      grafana:
        port: 3000
        status_code: [302]
  tasks:
  - name: "test app"
    ansible.builtin.uri:
      url: http://{{ inventory_hostname }}:{{ item.value.port }}
      follow_redirects: none
      status_code: "{{ item.value.status_code }}"
    loop: "{{ lookup('dict', apps) }}"
```

Then, add a stage in the jenkinsfile

```plain
stage('Test grafana and Prometheus') {
    steps {
        ansiblePlaybook(credentialsId: 'ec2-ssh-key', inventory: 'aws_hosts', playbook: 'playbooks/node-test.yml')
    }
}
```

Commit code again within `dev` branch

```bash
$ git add .
$ git commit -m "add ansible testing"
$ git push origin dev
```

Jenkins will build the pipeline again

###### Merge branch

We could merge branch into `main` in case testing was completely in `dev` branch

```bash
$ git checkout main
$ git merge dev
```

Then, let's approve the merge request on GitHub
