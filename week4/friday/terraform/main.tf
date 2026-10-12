# One reusable module, called once per server with for_each.
module "app_server" {
  source   = "./modules/app_server"
  for_each = var.servers

  name          = "kijaniosk-${each.key}"
  role          = each.value.role
  app_port      = each.value.app_port
  ami_id        = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  subnet_id     = sort(data.aws_subnets.default.ids)[0]
  vpc_id        = data.aws_vpc.default.id
  vpc_cidr      = data.aws_vpc.default.cidr_block
  ssh_cidr      = var.admin_cidr

  tags = {
    Role = each.value.role
  }
}
