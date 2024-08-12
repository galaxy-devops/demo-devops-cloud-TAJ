terraform {
  cloud {
    organization = "demo-devops-cloud-TAJ"
    workspaces {
      name = "terransible"
    }
  }
}