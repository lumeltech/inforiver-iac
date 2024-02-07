# Instructions
1. Clone this repo.
2. Ensure CLI credentials are set for Terraform to connect to AWS. 
3. CD into the **inforiver-iac/aws/terraform** directory and create **value.tfvars** file with required input values. Use the **input-values.tfvars.template** as reference.
4. Execute the following commands:
   ```
   terraform init
   terraform plan -var-file="values.tfvars"  # to view the resources values before provison
   terraform apply -var-file="values.tfvars" # to provison the resources
   ```
5. Once the deployment is completed, Ensure the worker node ARN is granted permissions to access the S3 bucket.
