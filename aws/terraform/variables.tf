variable "region" {
  description = "The region which all the services to be deployed."
  type        = string
  default     = "us-east-2"
}

variable "vpc_cidr" {
  description = "The CIDR/IP range for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "publicsb_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
  default     = "10.0.0.0/24"
}

variable "applicationsb_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
  default     = "10.0.1.0/24"
}

variable "databasesb_cidr" {
  description = "The CIDR block for the VPC. Default value is a valid CIDR, but not acceptable by AWS and should be overridden"
  type        = string
  default     = "10.0.2.0/24"
}

variable "project" {
  description = "Name to be used on all the resources as identifier.Application name"
  type = string
}

variable "instance_type" {
  description = "K8's worker node instance type"
  type = string
  default = "t3.medium"
}

variable "disk_size" {
  description = "K8's worker node disk size"
  type = number
  default = 20
 
}

variable "db_identifiername" {
  description = "RDS mssql database identifier name"
  type        = string
}

variable "db_storage_allocation" {
  description = "Allocated storage for RDS Mssql database"
  type        = string
  default     = 20
}

variable "db_instance_class" {
  description = "Specifying DB instance size"
  type        = string   
}

variable "db_admin_username" {
  description = "Specifying DB instance Admin name"
  type        = string
}

variable "db_admin_password" {
  description = "Specifying DB instance Admin password"
  type        = string
}

variable "cache_instance_class" {
  description = "Redis cache node instance class type"
  type        = string  
}

variable "redis_auth_token" {
  description = "Elastic cache Redis authentication token"
  type        = string  
}

variable "imagetag" {
  description = "Tag version of the image"
  type        = string  
}

variable "AdminPortalURL" {
  description = " Certification URL to host website i.e., https://inforiver.com/. This will be your admin portal."
  type        = string  
}

variable "AppHost" {
  description = " App host domain"
  type        = string  
}

variable "S3BucketName" {
  description = " Bucket name to be accessed by Inforiver."
  type        = string  
}

variable "WorkspaceName" {
  description = " Workspacename i.e., inforiver"
  type        = string  
}

variable "WorkspaceAdministratorEmail" {
  description = " Specifying workspace admin email address"
  type        = string  
}

variable "WorkspaceDomain" {
  description = " Office 365 primary Workspace domain eg.,lumel.com "
  type        = string  
}

variable "WorkspaceLicenseKey" {
  description = " License key provided by deployment support team. If it is not provided, please request for the same. "
  type        = string  
}

variable "Dockerpwd" {
  description = " Docker registry password.Docker password provided by deployment support team. If it is not provided, please request for the same."
  type        = string  
}

variable "Appclientid" {
  description = " App client ID"
  type        = string  
}

variable "Appsecretid" {
  description = " App Secret ID"
  type        = string  
}

variable "Apptenantid" {
  description = " App Tenant ID"
  type        = string  
}

variable "SMTPAPIKey" {
  description = " Api key for SMTP"
  type        = string  
}

variable "SMTPHost" {
  description = " SMTP host name"
  type        = string  
}

variable "SMTPservice" {
  description = " SMTP service name"
  type        = string  
}

variable "SMTPUsername" {
  description = " SMTP user name"
  type        = string  
}

variable "SSL_ARN" {
  description = " SSL certificate Arn for your loadbalancer"
  type        = string  
}

variable "WebHookKey" {
  description = "Web hook authorization key"
  type        = string
}