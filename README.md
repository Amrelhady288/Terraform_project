# Multi-Tier AWS Infrastructure with Terraform

This project provisions a complete multi-tier cloud architecture on **Amazon Web Services (AWS)** using **Terraform**.
The setup includes **VPC networking**, **EC2 application server**, **RDS MariaDB**, **Amazon MQ (RabbitMQ)**, and **ElastiCache Redis**.

---

## 🏗️ Architecture Diagram

```
                         ┌──────────────────────────┐
                         │        Internet          │
                         └──────────────▲───────────┘
                                        │
                               Public IP / HTTP
                                        │
                           ┌────────────┴────────────┐
                           │        VPC (CIDR)        │
                           └────────────┬────────────┘
                                        │
                          ┌─────────────┴───────────────┐
                          │       Public Subnets         │
                          └─────────────┬───────────────┘
                                        │
                         ┌──────────────┼──────────────┐
                         │              │              │
              ┌──────────▼───┐   ┌─────▼────────┐   ┌─▼────────────────┐
              │   EC2 App    │   │  RDS MariaDB  │   │ ElastiCache Redis│
              │ Ubuntu +     │   │  Managed DB   │   │   Managed Cache  │
              │   Nginx      │   │ Public Access │   │  Cluster Mode    │
              └──────────────┘   └───────────────┘   └──────────────────┘
                         │
                         │
                   ┌─────▼────────────┐
                   │  Amazon MQ        │
                   │ RabbitMQ Broker   │
                   │ Public Access     │
                   └───────────────────┘
```

---

## 📌 Architecture Overview

The deployed infrastructure includes:

* **VPC** with **two public subnets**
* **Internet Gateway** + **Route Table**
* **Security Group** allowing full inbound/outbound *(for demo/testing purposes)*
* **EC2 Instance (Ubuntu)** running **Nginx**
* **RDS MariaDB instance**
* **Amazon MQ (RabbitMQ)** broker
* **ElastiCache Redis cluster**

All resources are deployed in **eu-north-1**.

---

## 🚀 Features

* Fully automated provisioning using Terraform
* Custom VPC and networking layers
* High-availability multi-subnet design
* Automatic Nginx installation via EC2 user data
* Managed database, message queue, and caching services
* Modular, clean, and production-friendly structure

---

## 📁 File Structure

```
project/
├── main.tf           # Main Terraform configuration
├── variables.tf      # (optional) Input variables
├── outputs.tf        # (optional) Output definitions
└── README.md
```

---

## 🧩 Requirements

* **Terraform ≥ 1.0**
* **AWS account** with required IAM permissions
* **AWS CLI configured** or AWS access keys exported

---

## ⚙️ Deployment Steps

### Initialize Terraform

```bash
terraform init
```

### Validate configuration

```bash
terraform validate
```

### Preview changes

```bash
terraform plan
```

### Apply & deploy

```bash
terraform apply
```

Confirm with **yes**.

---

## 📤 Outputs (Examples)

```
app_server_ip     = 13.53.xx.xx
mariadb_endpoint  = app-mariadb.xxxxxx.eu-north-1.rds.amazonaws.com
redis_endpoint    = app-redis.xxxxxx.clustercfg.euw1.cache.amazonaws.com
mq_broker_url     = b-xxxx.mq.eu-north-1.amazonaws.com
```

---

## 🛑 Cleanup

To destroy all created resources:

```bash
terraform destroy
```

---

## 🔐 Security Notes

⚠️ **Important for production:**

* Security group allows **0.0.0.0/0** (insecure)
* RDS, MQ are **publicly accessible**
* Database credentials are **hardcoded**

**Use instead:**

* Private subnets
* AWS Secrets Manager
* Restricted IP inbound rules

---

## 🙌 Credits

Created as part of a **DevOps learning journey** using **Terraform & AWS**.
