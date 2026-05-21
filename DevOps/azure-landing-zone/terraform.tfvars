landing_zones = {

  dev = {
    location      = "eastus"
    address_space = ["10.10.0.0/16"]

    subnets = {
      web = ["10.10.1.0/24"]
      app = ["10.10.2.0/24"]
      db  = ["10.10.3.0/24"]
    }

    tags = {
      environment = "dev"
      owner       = "devops"
    }
  }

  uat = {
    location      = "westus"
    address_space = ["10.20.0.0/16"]

    subnets = {
      web = ["10.20.1.0/24"]
      app = ["10.20.2.0/24"]
      db  = ["10.20.3.0/24"]
    }

    tags = {
      environment = "uat"
      owner       = "devops"
    }
  }

  prod = {
    location      = "westus"
    address_space = ["10.30.0.0/16"]

    subnets = {
      web = ["10.30.1.0/24"]
      app = ["10.30.2.0/24"]
      db  = ["10.30.3.0/24"]
    }

    tags = {
      environment = "prod"
      owner       = "platform"
    }
  }
}

devops_group_id = "YOUR_AZURE_AD_GROUP_OBJECT_ID"

tenant_id = "139a10da-0e8f-4b9a-afda-6985517e8411"