#!/bin/bash

# Output file
output_file="vpc_info.csv"

# Write header to the output file
echo "AWS Profile,Region,VPC Name,VPC ID" > "$output_file"

# Iterate through all AWS profiles in the credentials file
for profile in $(grep '\[.*\]' ~/.aws/credentials | tr -d '[]'); do
    # Iterate through all available regions
    for region in $(aws ec2 describe-regions --profile "$profile" --query 'Regions[].RegionName' --output text); do
        # Retrieve VPC information for the current profile and region
        vpc_info=$(aws ec2 describe-vpcs --profile "$profile" --region "$region" --query 'Vpcs[].[Tags[?Key==`Name`].Value | [0], VpcId]' --output text)
        
        # Iterate through each VPC and append the information to the output file
        while IFS=$'\t' read -r vpc_name vpc_id; do
            echo "$profile,$region,$vpc_name,$vpc_id" >> "$output_file"
        done <<< "$vpc_info"
    done
done

echo "VPC information has been exported to $output_file"
