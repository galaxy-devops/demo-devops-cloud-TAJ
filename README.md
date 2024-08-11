### Using Ansible within Terraform

#### Overview

We could implement to deploy our APP(grafana as example) in previous branch before. In this branch, we will achieve to deploy it using ansible within the terraform manifests. 

#### Prepare Ansible

> install ansible

```bash
$ sudo apt update
$ sudo apt install software-properties-common
$ sudo add-apt-repository --yes --update ppa:ansible/ansible
$ sudo apt install -y ansible
```

#### Playbook and template file

##### Change Group Name

> modify file: aws_hosts

FROM

- [servers]

TO

- [main]

##### Playbook file

Create the directory `playbooks` and the underlying file `main-playbook.yml` 

```yaml
---
- name: Bootstrap Main Node
  hosts: main
  become: yes
  vars:
    listen_address: 0.0.0.0
    listen_port: 9090

  tasks:
  - name: "Download apt key"
    ansible.builtin.apt_key:
      url: "https://packages.grafana.com/gpg.key"
      state: present
  - name: "Add Grafana repo to sources.list"
    ansible.builtin.apt_repository:
      repo: "deb https://packages.grafana.com/oss/deb stable main"
      filename: grafana
      state: present
  - name: "Update apt cache and install Grafana"
    ansible.builtin.apt:
      name: grafana
      update_cache: yes
  - name: "Ensure Grafana is started and enabled"
    ansible.builtin.systemd:
      name: "grafana-server"
      enabled: yes
      state: started
  - name: "Download Prometheus"
    ansible.builtin.get_url:
      url: "https://github.com/prometheus/prometheus/releases/download/v2.30.3/prometheus-2.30.3.linux-amd64.tar.gz"
      dest: "/home/ubuntu"
  - name: "Set up Prometheus"
    ansible.builtin.unarchive:
      src: "/home/ubuntu/prometheus-2.30.3.linux-amd64.tar.gz"
      dest: "/home/ubuntu/"
      remote_src: yes
  - name: "Create Prometheus group"
    ansible.builtin.group:
      name: prometheus
      state: present
  - name: "Create Prometheus user"
    ansible.builtin.user:
      name: prometheus
      group: prometheus
      shell: /sbin/nologin
  - name: "Create Prometheus directories"
    ansible.builtin.file:
      path: "{{ item }}"
      state: directory
      recurse: yes
      owner: prometheus
      group: prometheus
      mode: '0755'
    loop:
      - /etc/prometheus
      - /etc/prometheus/rules
      - /etc/prometheus/rules.d
      - /etc/prometheus/files_sd
      - /var/lib/prometheus
  - name: "Copy Prometheus binary files"
    ansible.builtin.copy:
      src: "{{ item }}"
      dest: /usr/local/bin
      remote_src: yes
      mode: '0755'
      owner: prometheus
      group: prometheus
    loop:
      - /home/ubuntu/prometheus-2.30.3.linux-amd64/prometheus
      - /home/ubuntu/prometheus-2.30.3.linux-amd64/promtool
  - name: "Copy console relevant files"
    ansible.builtin.copy:
      src: "{{ item }}"
      dest: /etc/prometheus
      remote_src: yes
    loop:
      - /home/ubuntu/prometheus-2.30.3.linux-amd64/consoles
      - /home/ubuntu/prometheus-2.30.3.linux-amd64/console_libraries  
  - name: "Create prometheus configure file"
    ansible.builtin.template:
      src: prometheus.yml.j2
      dest: /etc/prometheus/prometheus.yml
  - name: "Create prometheus systemd file"
    ansible.builtin.template:
      src: prometheus.service.j2
      dest: /etc/systemd/system/prometheus.service
  - name: "Ensure Prometheus service is started"
    ansible.builtin.systemd:
      state: started
      enabled: yes
      name: prometheus
```

##### Template file

> file: prometheus.service.j2

```jinja2
[Unit]
Description=Prometheus systemd service unit
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=prometheus
Group=prometheus
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/local/bin/prometheus \
--config.file=/etc/prometheus/prometheus.yml \
--storage.tsdb.path=/var/lib/prometheus \
--web.console.templates=/etc/prometheus/consoles \
--web.console.libraries=/etc/prometheus/console_libraries \
--web.listen-address={{ listen_address }}:{{ listen_port }}

SyslogIdentifier=prometheus
Restart=always

[Install]
WantedBy=multi-user.target
```

> file: prometheus.yml.j2

```jinja2
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['{{ listen_address }}:{{ listen_port }}']
```

#### Referencing Ansible

##### Edit file

> file: compute.tf

As we don't need install APP with `user data` . Remove the line in the file.

```plain
user_data = templatefile("./main-userdata.tpl", { new_hostname = "galaxy_demo-main-${random_id.galaxy_demo_node_id[count.index].dec}" })
```

Then remove the file: `main-userdata.tpl` 



Old line:

- `command = "printf '\n${self.public_ip}' >> aws_hosts"`

New line:

- ``command = "printf '\n${self.public_ip}' >> aws_hosts && aws ec2 wait instance-status-ok --instance-ids ${self.id} --region ${var.aws_region}"`` 

##### Add resource

> file: compute.tf

Add  `null_resource`  resource

```plain
resource "null_resource" "app_install" {
  depends_on = [ aws_instance.mtc_main ]
  provisioner "local-exec" {
    command = "ansible-playbook -i aws_hosts --key-file /home/ubuntu/.ssh/demo-devops-cloud-TAJ playbooks/main-playbook.yml"
  }
}
```

> Note:  Prepare the key file ahead of time by command.
>
> $ ssh-keygen -t rsa -q -N ""  -f /home/ubuntu/.ssh/demo-devops-cloud-TAJ

#### Execute Terraform Commands

```bash
$ terraform init
$ terraform plan
$ terraform apply -auto-approve
```

