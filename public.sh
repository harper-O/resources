#!/bin/bash

# Set the AWS profile
export AWS_PROFILE=aws219

# Retrieve all RDS instances
rds_instances=$(aws rds describe-db-instances --query 'DBInstances[*].DBInstanceIdentifier' --output text)

# Iterate over each RDS instance
for instance in $rds_instances; do
  # Retrieve the public accessibility status of the RDS instance
  public_access=$(aws rds describe-db-instances --db-instance-identifier $instance --query 'DBInstances[0].PubliclyAccessible' --output text)
  
  # Check if the RDS instance has public access
  if [ "$public_access" == "true" ]; then
    echo "RDS instance '$instance' has public access enabled."
  else
    echo "RDS instance '$instance' does not have public access enabled."
  fi
done

#!/bin/bash

# Set the AWS profile
export AWS_PROFILE=aws219

# Output file
output_file="rds.csv"

# Write header to the output file
echo "RDS Instance,Engine,Version,Instance Class,Storage,Public Access" > "$output_file"

# Retrieve all RDS instances
rds_instances=$(aws rds describe-db-instances --query 'DBInstances[*].DBInstanceIdentifier' --output text)

# Iterate over each RDS instance
for instance in $rds_instances; do
  # Retrieve the details of the RDS instance
  instance_details=$(aws rds describe-db-instances --db-instance-identifier $instance --query 'DBInstances[0]')
  
  # Extract relevant details from the instance details
  engine=$(echo "$instance_details" | jq -r '.Engine')
  version=$(echo "$instance_details" | jq -r '.EngineVersion')
  instance_class=$(echo "$instance_details" | jq -r '.DBInstanceClass')
  storage=$(echo "$instance_details" | jq -r '.AllocatedStorage')
  public_access=$(echo "$instance_details" | jq -r '.PubliclyAccessible')
  
  # Write the instance details to the output file
  echo "$instance,$engine,$version,$instance_class,$storage,$public_access" >> "$output_file"
done

echo "RDS instance details have been exported to $output_file"
