provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}

resource "aws_instance" "ansible_control_plane_server" {
  ami                         = "ami-0ae8f15ae66fe8cda"    # Amazon Linux 2 AMI ID for us-east-1
  instance_type               = "t2.small"                 # Preferred instance type
  key_name                    = "Khurram-key"              # Add your key pair name
  vpc_security_group_ids      = ["sg-025028548d0e7a3d0"]   # Add your security group ID
  subnet_id                   = "subnet-08d90b90e9b121c7e" # Add your subnet ID
  availability_zone           = "us-east-1a"               # Add your availability zone
  associate_public_ip_address = true                       # Assign a public IP address
  disable_api_termination     = true                       # Prevent accidental termination
  monitoring                  = true                       # Enable detailed monitoring
  ebs_optimized               = false                      # Disable EBS optimization
  count                       = 1                          # Create a single instance

  tags = {
    Name = "Ansible-Control-Plane-Server"                  # Instance name
  }

  root_block_device {
    volume_size = 50                                       # Root volume size in GB
    volume_type = "gp2"                                    # General Purpose SSD
    encrypted   = false                                    # Unencrypt the root volume
  }

  connection {
    type        = "ssh"                                    # Use SSH to connect to the instance
    user        = "ec2-user"                               # Default user for Amazon Linux 2
    private_key = file("/home/ubuntu/Khurram-key.pem")     # Path to your local PEM key
    host        = self.public_ip                           # Public IP address of the instance
  }

  provisioner "file" {
    source      = "/home/ubuntu/Khurram-key.pem"           # Path to your local PEM key
    destination = "/home/ec2-user/Khurram-key.pem"         # Destination path on the remote instance
  }

  provisioner "file" {
    source      = "${path.module}/inventory.ini"
    destination = "/home/ec2-user/inventory.ini"
  }

  provisioner "file" {
    source      = "${path.module}/test_connectivity.yml"
    destination = "/home/ec2-user/test_connectivity.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",                                           # Update the instance
      "sudo yum install -y git python3 python3-pip",                  # Install Git, Python3, and Pip3
      "python3 -m pip install --user ansible-core",                   # Install Ansible Core
      "python3 -m pip install --user ansible",                        # Install Ansible
      "sudo pip3 install boto boto3 awscli",                          # Install Boto, Boto3, and AWS CLI
      "sudo chown ec2-user:ec2-user /home/ec2-user/Khurram-key.pem",  # Change ownership of the PEM key
      "sudo chmod 400 /home/ec2-user/Khurram-key.pem",                # Change permissions of the PEM key
      "ssh-keygen -t rsa -N '' -f /home/ec2-user/.ssh/id_rsa",        # Generate SSH key pair
      "cat /home/ec2-user/.ssh/id_rsa.pub >> /home/ec2-user/.ssh/authorized_keys", # Add public key to authorized_keys
      "chmod 600 /home/ec2-user/.ssh/authorized_keys",                             # Change permissions of authorized_keys
      "chmod 700 /home/ec2-user/.ssh",                                              # Change permissions of .ssh directory
      "sudo hostnamectl set-hostname Ansible-Control-Plane-Server",                 # Set the hostname temporarily
      "echo 'Ansible-Control-Plane-Server' | sudo tee /etc/hostname",               # Set the hostname permanently
      "sudo sed -i 's/127.0.0.1.*/127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 Ansible-Control-Plane-Server/' /etc/hosts",
      "sudo sed -i 's/::1.*/::1         localhost localhost.localdomain localhost6 localhost6.localdomain6 Ansible-Control-Plane-Server/' /etc/hosts",
      "ansible-playbook -i /home/ec2-user/inventory.ini /home/ec2-user/test_connectivity.yml"  # Run the playbook
    ]
  }
}

resource "aws_instance" "ansible_server" {
  count                       = 3                          # Create three instances
  ami                         = "ami-0ae8f15ae66fe8cda"    # Amazon Linux 2 AMI ID for us-east-1
  instance_type               = "t2.micro"                 # Preferred instance type
  key_name                    = "Khurram-key"              # Add your key pair name
  vpc_security_group_ids      = ["sg-025028548d0e7a3d0"]   # Add your security group ID
  subnet_id                   = "subnet-08d90b90e9b121c7e" # Add your subnet ID
  availability_zone           = "us-east-1a"               # Add your availability zone
  associate_public_ip_address = true                       # Assign a public IP address
  disable_api_termination     = true                       # Prevent accidental termination
  monitoring                  = true                       # Enable detailed monitoring
  ebs_optimized               = false                      # Disable EBS optimization

  tags = {
    Name = "AnsibleServer-${count.index + 1}"              # Instance name with index
  }

  root_block_device {
    volume_size = 20                                       # Root volume size in GB
    volume_type = "gp2"                                    # General Purpose SSD
    encrypted   = false                                    # Unencrypt the root volume
  }

  connection {
    type        = "ssh"                                    # Use SSH to connect to the instance
    user        = "ec2-user"                               # Default user for Amazon Linux 2
    private_key = file("/home/ubuntu/Khurram-key.pem")     # Path to your local PEM key
    host        = self.public_ip                           # Public IP address of the instance
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",                                # Update the instance
      "sudo yum install -y git python3 python3-pip",       # Install Git, Python3, and Pip3
      "python3 -m pip install --user ansible-core",        # Install Ansible Core
      "python3 -m pip install --user ansible",             # Install Ansible
      "sudo pip3 install boto boto3 awscli",               # Install Boto, Boto3, and AWS CLI
      "ssh-keygen -t rsa -N '' -f /home/ec2-user/.ssh/id_rsa",        # Generate SSH key pair
      "cat /home/ec2-user/.ssh/id_rsa.pub >> /home/ec2-user/.ssh/authorized_keys", # Add public key to authorized_keys
      "chmod 600 /home/ec2-user/.ssh/authorized_keys",                             # Change permissions of authorized_keys
      "chmod 700 /home/ec2-user/.ssh",                                              # Change permissions of .ssh directory
      "sudo hostnamectl set-hostname AnsibleServer-${count.index + 1}",  # Set the hostname temporarily
      "echo 'AnsibleServer-${count.index + 1}' | sudo tee /etc/hostname", # Set the hostname permanently
      "sudo sed -i 's/127.0.0.1.*/127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4 AnsibleServer-${count.index + 1}/' /etc/hosts",
      "sudo sed -i 's/::1.*/::1         localhost localhost.localdomain localhost6 localhost6.localdomain6 AnsibleServer-${count.index + 1}/' /etc/hosts"
    ]
  }
}

resource "local_file" "inventory_ini" {
  content = <<EOF
[control-plane]
control-plane ansible_host=${aws_instance.ansible_control_plane_server[0].public_ip} ansible_user=ec2-user

[worker-nodes]
%{ for i, instance in aws_instance.ansible_server }
worker-node${i + 1} ansible_host=${instance.public_ip} ansible_user=ec2-user
%{ endfor }
EOF

  filename = "${path.module}/inventory.ini"
}

resource "local_file" "test_connectivity_yml" {
  content = <<EOF
---
- name: Test connectivity between control plane and worker nodes
  hosts: all
  gather_facts: no
  tasks:
    - name: Ping all servers
      ping:
EOF

  filename = "${path.module}/test_connectivity.yml"
}

resource "null_resource" "upload_inventory" {
  depends_on = [local_file.inventory_ini, local_file.test_connectivity_yml]

  provisioner "file" {
    source      = "${path.module}/inventory.ini"
    destination = "/home/ec2-user/inventory.ini"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/home/ubuntu/Khurram-key.pem")
      host        = aws_instance.ansible_control_plane_server[0].public_ip
    }
  }

  provisioner "file" {
    source      = "${path.module}/test_connectivity.yml"
    destination = "/home/ec2-user/test_connectivity.yml"

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/home/ubuntu/Khurram-key.pem")
      host        = aws_instance.ansible_control_plane_server[0].public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "ansible-playbook -i /home/ec2-user/inventory.ini /home/ec2-user/test_connectivity.yml"  # Run the playbook
    ]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/home/ubuntu/Khurram-key.pem")
      host        = aws_instance.ansible_control_plane_server[0].public_ip
    }
  }
}

resource "null_resource" "update_hosts" {
  count = 4  # Total number of instances (1 control plane + 3 servers)

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("/home/ubuntu/Khurram-key.pem")
      host        = element(concat([aws_instance.ansible_control_plane_server[0].public_ip], aws_instance.ansible_server[*].public_ip), count.index)
    }

    inline = [
      "echo '${aws_instance.ansible_control_plane_server[0].private_ip} ansible-control-plane-server' | sudo tee -a /etc/hosts",
      "for i in ${join(" ", aws_instance.ansible_server[*].private_ip)}; do echo \"$i ansible-server-${count.index + 1}\" | sudo tee -a /etc/hosts; done"
    ]
  }
}

output "ansible_control_plane_server_ip" {
  value = aws_instance.ansible_control_plane_server[0].public_ip  # Output the public IP address of the instance
}

output "ansible_server_ips" {
  value = aws_instance.ansible_server[*].public_ip                # Output the public IP addresses of the instances
}
