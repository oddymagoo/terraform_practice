module "Env_A" {
  source = "../modules/Core"

  environment = {
    name = "Env_A"
    network_prefix = "10.1"
  }


  tags = {
    Name = "Env_A"
  }

}
