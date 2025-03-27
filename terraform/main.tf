provider "aws" {
  region = var.region
}

resource "random_pet" "id" {
  length = 2
}