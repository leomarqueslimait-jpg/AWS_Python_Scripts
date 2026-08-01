data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Prod instances: no Schedule tag, so the scheduler Lambdas' tag filter
# (tag:Schedule = office-hours) skips these entirely. They keep running.
resource "aws_instance" "prod" {
  count                  = 3
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.prod.id
  vpc_security_group_ids = [aws_security_group.instances.id]

  tags = {
    Name        = "prod-instance-${count.index + 1}"
    Environment = "prod"
  }
}

# Dev instances: tagged Environment=dev + Schedule=office-hours, so the
# scheduler Lambdas pick these up and stop/start them on the cron schedule.
resource "aws_instance" "dev" {
  count                  = 3
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.dev.id
  vpc_security_group_ids = [aws_security_group.instances.id]

  tags = {
    Name        = "dev-instance-${count.index + 1}"
    Environment = "dev"
    Schedule    = "office-hours"
  }
}
