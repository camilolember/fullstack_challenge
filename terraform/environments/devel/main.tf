# In this file put all the logic to crete the proper infraestructure
terraform {
    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.7.0"
        }
    }
    #backend
}
provider "aws" {
    region = "us-east-1"
}

#module_block
module "deploy_resources" {
    source = "../../modules/app/"
    environment = "devel"
}