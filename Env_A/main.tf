module "Env_A" {
  source = "../modules/Core"

  environment = {
    name = "EnvA"
    network_prefix = "10.1"
    tags = "Env_A"
  }

  asg_min = 0
  asg_max = 0

}
