# AWS-Terraform-3Tier-Architecture
This project provides a complete Terraform-based infrastructure as code (IAC) solution for creating a scalable and resilient 3-tier architecture on Amazon Web Services (AWS). 

## Terraform
Terraform is a tool for provisioning, managing, and deploying infrastructure resources. It is an open-source tool written in Golang and created by the HashiCorp company. With Terraform, you can manage infrastructure for your applications across multiple cloud providers - AWS, Azure, GCP, etc. - using a single tool.

![Terraform](/0.png)

## Prerequisites for Deploying the AWS-Terraform-3Tier-Architecture

**AWS Account:** You need an active AWS account to create and manage the resources in Amazon Web Services.

**AWS CLI Installed:** Install the AWS Command Line Interface (CLI) on your local machine. You can download and install it from the official AWS CLI documentation.

**AWS CLI Configuration:** Configure your AWS CLI with access and secret keys. You can use the aws configure command to set up your AWS credentials. Ensure that the configured user has the necessary permissions to create and manage AWS resources.

**Terraform Installed:** Install Terraform on your local machine. You can download Terraform from the official Terraform website and follow the installation instructions for your operating system.

**Git Installed (Optional):** If you want to clone the project from a Git repository, you should have Git installed on your machine. You can download Git from the official Git website.

**Text Editor or IDE:** Use a text editor or integrated development environment (IDE) of your choice for editing Terraform configuration files. Popular options include Visual Studio Code, Sublime Text, or Notepad++.

**SSH Key Pair:** If you plan to connect to the EC2 instances created by Terraform, you should have an SSH key pair (.pem) file. You'll need this key to SSH into the instances.

**Basic Terraform Knowledge:** Familiarize yourself with the basics of Terraform, including how to write Terraform configuration files (HCL), initialize Terraform projects, and run Terraform commands.

**Database Credentials:** Prepare the username and password for the database you intend to create. Replace placeholders like "your_username" and "your_password" in the Terraform configuration files with your actual database credentials.

**Step 1:** Create a **vpc.tf** file (Creating the VPC): In vpc.tf, you are defining the configuration for an Amazon Virtual Private Cloud (VPC). It specifies the VPC's IP address range (CIDR block) and its tenancy settings.
    
    # Creating VPC
    resource "aws_vpc" "demovpc" {
      cidr_block       = "${var.vpc_cidr}"
      instance_tenancy = "default"
    
      tags = {
        Name = "Demo VPC"
      }
    }

**Step 2:** Create a **subnet.tf** file (Creating Subnets): In subnet.tf, you create various subnets within the VPC. There are web subnets (public-subnet-1 and public-subnet-2) configured for web servers, application subnets (application-subnet-1 and application-subnet-2) for application servers, and private database subnets (database-subnet-1 and database-subnet-2) for database servers. Each subnet has its own CIDR block, and some are configured for public IP assignment while others are not.

        # Creating 1st web subnet
        resource "aws_subnet" "public-subnet-1" {
          vpc_id                  = aws_vpc.demovpc.id
          cidr_block             = "${var.subnet_cidr}"
          map_public_ip_on_launch = true
          availability_zone       = "us-east-1a"
        
          tags = {
            Name = "Web Subnet 1"
          }
        }
        
        # Creating 2nd web subnet
        resource "aws_subnet" "public-subnet-2" {
          vpc_id                  = aws_vpc.demovpc.id
          cidr_block             = "${var.subnet1_cidr}"
          map_public_ip_on_launch = true
          availability_zone       = "us-east-1b"
        
          tags = {
            Name = "Web Subnet 2"
          }
        }
        
        # Creating 1st application subnet
        resource "aws_subnet" "application-subnet-1" {
          vpc_id                  = aws_vpc.demovpc.id
          cidr_block             = "${var.subnet2_cidr}"
          map_public_ip_on_launch = false
          availability_zone       = "us-east-1a"
        
          tags = {
            Name = "Application Subnet 1"
          }
        }
        
        # Creating 2nd application subnet
        resource "aws_subnet" "application-subnet-2" {
          vpc_id                  = aws_vpc.demovpc.id
          cidr_block             = "${var.subnet3_cidr}"
          map_public_ip_on_launch = false
          availability_zone       = "us-east-1b"
        
          tags = {
            Name = "Application Subnet 2"
          }
        }
        
        # Create Database Private Subnet
        resource "aws_subnet" "database-subnet-1" {
          vpc_id            = aws_vpc.demovpc.id
          cidr_block        = "${var.subnet4_cidr}"
          availability_zone = "us-east-1a"
        
          tags = {
            Name = "Database Subnet 1"
          }
        }
        
        # Create Database Private Subnet
        resource "aws_subnet" "database-subnet-2" {
          vpc_id            = aws_vpc.demovpc.id
          cidr_block        = "${var.subnet5_cidr}"
          availability_zone = "us-east-1b"
        
          tags = {
            Name = "Database Subnet 2"
          }
        }


**Step 3:** Create an **igw.tf** file (Creating the Internet Gateway): In igw.tf, you define an Amazon Internet Gateway, which provides a way for resources within your VPC to access the internet and vice versa.
    
        # Creating Internet Gateway
        resource "aws_internet_gateway" "demogateway" {
          vpc_id = aws_vpc.demovpc.id
        }


**Step 4:** Create a **route_table_public.tf** file (Creating the Route Table and Associations): route_table_public.tf creates a route table (aws_route_table.route) and associates it with the VPC (aws_vpc.demovpc). It also sets up routes to direct internet-bound traffic (0.0.0.0/0) to the internet gateway (aws_internet_gateway.demogateway). Route table associations (aws_route_table_association) are established for both web subnets (public-subnet-1 and public-subnet-2).

    # Creating Route Table
    resource "aws_route_table" "route" {
      vpc_id = aws_vpc.demovpc.id
    
      route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.demogateway.id
      }
    
      tags = {
        Name = "Route to internet"
      }
    }
    
    # Associating Route Table
    resource "aws_route_table_association" "rt1" {
      subnet_id      = aws_subnet.public-subnet-1.id
      route_table_id = aws_route_table.route.id
    }
    
    # Associating Route Table
    resource "aws_route_table_association" "rt2" {
      subnet_id      = aws_subnet.public-subnet-2.id
      route_table_id = aws_route_table.route.id
    }


**Step 5:** Create an **ec2.tf** file (Creating EC2 Instances): In ec2.tf, you define Amazon Elastic Compute Cloud (EC2) instances. Two instances (demoinstance and demoinstance1) are created, both using the specified Amazon Machine Image (AMI). These instances are placed in the web subnets (public-subnet-1 and public-subnet-2) and configured with security groups and public IP addresses. They also run user data scripts from the "data.sh" file(see step-12).

        # Creating 1st EC2 instance in Public Subnet
        resource "aws_instance" "demoinstance1" {
          ami                         = "ami-087c17d1fe0178315"
          instance_type               = "t2.micro"
          count                       = 2
          key_name                    = "tests"
          vpc_security_group_ids      = [aws_security_group.demosg.id]
          subnet_id                   = aws_subnet.public-subnet-1.id
          associate_public_ip_address = true
          user_data                   = "${file("data.sh")}"
        
          tags = {
            Name = "My Public Instance 1"
          }
        }


**Step 6:** Create a **web_sg.tf** file (Creating Security Group for the FrontEnd tier): web_sg.tf defines a security group (aws_security_group.demosg) for the web tier. It allows inbound traffic on ports 80 (HTTP), 443 (HTTPS), and 22 (SSH) from anywhere.

        # Creating Security Group
    resource "aws_security_group" "demosg" {
      vpc_id = aws_vpc.demovpc.id
    
      # Inbound Rules
      # HTTP access from anywhere
      ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    
      # HTTPS access from anywhere
      ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    
      # SSH access from anywhere
      ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    
      # Outbound Rules
      # Internet access to anywhere
      egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    
      tags = {
        Name = "Web SG"
      }
    }


**Step 7:** Create a **database_sg.tf** file (Creating Security Group for the Database tier): In database_sg.tf, you configure a security group (aws_security_group.database-sg) for the database tier. It allows inbound traffic on port 3306 (MySQL) from the security group associated with the web tier.

        # Create Database Security Group
        resource "aws_security_group" "database-sg" {
          name        = "Database SG"
          description = "Allow inbound traffic from application layer"
          vpc_id      = aws_vpc.demovpc.id
        
          ingress {
            description     = "Allow traffic from application layer"
            from_port       = 3306
            to_port         = 3306
            protocol        = "tcp"
            security_groups = [aws_security_group.demosg.id]
          }
        
          egress {
            from_port   = 32768
            to_port     = 65535
            protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
          }
        
          tags = {
            Name = "Database SG"
          }
        }

**Step 8:** Create an **alb.tf** file (Creating the Application Load Balancer): alb.tf defines an Application Load Balancer (aws_lb.external-alb) that serves as a front-end for your application. It's placed in public subnets (public-subnet-1 and public-subnet-2) and associated with a security group (aws_security_group.demosg).
   
        # Creating External LoadBalancer
        resource "aws_lb" "external-alb" {
          name               = "External-LB"
          internal           = false
          load_balancer_type = "application"
          security_groups    = [aws_security_group.demosg.id]
          subnets            = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]
        }
        
        resource "aws_lb_target_group" "target-elb" {
          name     = "ALB-TG"
          port     = 80
          protocol = "HTTP"
          vpc_id   = aws_vpc.demovpc.id
        }
        
        resource "aws_lb_listener" "external-elb" {
          load_balancer_arn = aws_lb.external-alb.arn
          port              = "80"
          protocol          = "HTTP"
        
          default_action {
            type             = "forward"
            target_group_arn = aws_lb_target_group.target-elb.arn
          }
        }


**Step 9:** Create a **rds.tf** file (Creating the RDS instance): In rds.tf, you set up an Amazon RDS database instance (aws_db_instance.default). The database is configured with specified settings, including allocated storage, engine type (MySQL), version, instance class, and multi-AZ deployment. You should replace "your_username" and "your_password" with actual database credentials.
        
        # Creating RDS Instance
        resource "aws_db_subnet_group" "default" {
          name       = "main"
          subnet_ids = [aws_subnet.database-subnet-1.id, aws_subnet.database-subnet-2.id]
        
          tags = {
            Name = "My DB subnet group"
          }
        }
        
        resource "aws_db_instance" "default" {
          allocated_storage      = 10
          db_subnet_group_name   = aws_db_subnet_group.default.id
          engine                 = "mysql"
          engine_version         = "8.0.33"
          instance_class         = "db.t2.micro"
          multi_az               = true
          identifier             = "mydb-new"
          username               = "rahulvikhe"
          password               = "Rahul2345678"
          skip_final_snapshot    = true
          vpc_security_group_ids = [aws_security_group.database-sg.id]
        }


**Step 10:** Create an **outputs.tf** file (Creating Outputs): outputs.tf defines an output variable (lb_dns_name) that provides the DNS name of the load balancer (aws_lb.external-alb). This allows you to easily access your application via the load balancer.

        # Getting the DNS of load balancer
        output "lb_dns_name" {
          description = "The DNS name of the load balancer"
          value       = aws_lb.external-alb.dns_name
        }

**Step 11:** Create a **vars.tf** file (Defining Variables): In vars.tf, you define variables that allow you to customize settings like VPC CIDR blocks and subnet CIDR blocks. These variables provide flexibility when deploying your infrastructure.

        # Defining CIDR Block for VPC
        variable "vpc_cidr" {
          default = "10.0.0.0/16"
        }
        
        # Defining CIDR Block for 1st Subnet
        variable "subnet_cidr" {
          default = "10.0.1.0/24"
        }
        
        # Defining CIDR Block for 2nd Subnet
        variable "subnet1_cidr" {
          default = "10.0.2.0/24"
        }
        
        # Defining CIDR Block for 3rd Subnet
        variable "subnet2_cidr" {
          default = "10.0.3.0/24"
        }
        
        # Defining CIDR Block for 4th Subnet
        variable "subnet3_cidr" {
          default = "10.0.4.0/24"
        }
        
        # Defining CIDR Block for 5th Subnet
        variable "subnet4_cidr" {
          default = "10.0.5.0/24"
        }
        
        # Defining CIDR Block for 6th Subnet
        variable "subnet5_cidr" {
          default = "10.0.6.0/24"
        }


**Step 12:** Create the **data.sh** File. This script will be used as the user data for your EC2 instances in the Terraform configuration to set up the Apache web server and display the "Hello World" message.

        #!/bin/bash
        yum update -y
        yum install -y httpd.x86_64
        systemctl start httpd.service
        systemctl enable httpd.service
        echo "Hello World from $(hostname -f)" > /var/www/html/index.html
        
These files collectively define your AWS infrastructure using Terraform, enabling you to provision and manage resources systematically.

## Deployment

To deploy the AWS infrastructure stack using Terraform, follow these steps:

Step 1: Prepare Your Environment

Ensure you have the following prerequisites set up on your local machine:

Terraform: Install Terraform on your machine. You can download it from the official Terraform website (https://www.terraform.io/downloads.html).

AWS CLI: Configure the AWS Command Line Interface (CLI) with your AWS credentials. You can do this by running aws configure and providing your AWS Access Key ID, Secret Access Key, default region, and output format.

AWS IAM Role: Make sure you have an AWS IAM user or role with the necessary permissions to create and manage resources like VPCs, subnets, EC2 instances, RDS databases, and security groups.

Step 2: Clone the GitHub Repository. If you haven't already, clone your GitHub repository that contains your Terraform configuration files:

    git clone <repository-url>
    cd <repository-directory>

Step 3: Initialize Terraform in your project directory to download the necessary provider plugins:

    terraform init

Step 4: Plan the Deployment. Run terraform plan to see what resources Terraform will create, modify, or destroy. Review the plan to ensure it matches your expectations:

    terraform plan

Step 5: Deploy the Infrastructure. Once you're satisfied with the plan, apply it to create the infrastructure:

    terraform apply

Step 6: Wait for Deployment and Verify

Terraform will provision the resources based on your configurations. This process may take some time, especially if you're creating multiple instances or a database. Be patient and let Terraform complete the deployment. After Terraform completes the deployment, it will display a summary of the created resources. You can log in to the AWS Management Console or use the AWS CLI to verify that your resources are up and running as expected.

Step 7: Access Outputs (Optional) If you defined any output variables in your Terraform configurations (in outputs.tf), you can access them using the terraform output command. For example:

    terraform output lb_dns_name

Step 10: Destroy the Stack (Optional) When you're done with your resources, you can use Terraform to destroy the entire stack:

    terraform destroy
