resource "aws_instance" "instance" {
  count = 1

  ami                    = "ami-0574da719dca65348" # ubuntu 22 us-east
  instance_type          = "t2.micro"
  key_name               = "kp"
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.allow_grafana.id, aws_security_group.allow_ssh.id]
  subnet_id              = aws_default_subnet.default[count.index].id

  associate_public_ip_address = true

  user_data = <<EOF
#!/bin/bash -x
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
sudo apt install -y docker-ce
sudo usermod -aG docker ubuntu

sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

sudo apt install -y git
git clone https://github.com/andregri/docker-compose-grafana.git
docker-compose -f docker-compose-grafana/app/docker-compose.yaml up -d
docker-compose -f docker-compose-grafana/grafana/docker-compose.yaml up -d
EOF

  tags = {
    name      = "instance-${count.index}"
    Terraform = "true"
    Project   = "demo"
    Type      = "machine"
  }
}
