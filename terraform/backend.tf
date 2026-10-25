terraform {
  backend "s3" {
    bucket       = "anac-flights-tfstate"
    key          = "terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
