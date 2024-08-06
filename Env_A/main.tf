#main
module "Env_A" {
  source = "../modules/Core"

  tags = {
    Name = "ExampleAppServerInstance"
  }

}
