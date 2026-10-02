required_providers - parameter "~> 6.0" tells terraform to use any version within 6th major version (6.x.x).  
Purpose is not to break system after next major update.  
Update this parameter and run "terraform init -upgrade" if necessary. 

The .terraform.lock.hcl file should be committed to version control for others to have similar providers as you.   
