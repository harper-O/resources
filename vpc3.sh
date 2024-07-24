#!/bin/bash

# Check if region is provided as an argument
if [ $# -eq 0 ]; then
    echo "Please provide the AWS region as an argument."
    echo "Usage: $0 <aws-region>"
    exit 1
fi

# Set the AWS profile and region
AWS_PROFILE="aws210"
AWS_REGION=$1

# Set the S3 bucket for flow logs
S3_BUCKET="cloudtrail-000"

# Read VPC IDs from file
VPC_FILE="vpc.txt"
if [ ! -f "$VPC_FILE" ]; then
    echo "VPC file $VPC_FILE not found!"
    exit 1
fi

# Define custom log format
LOG_FORMAT='${version} ${account-id} ${interface-id} ${srcaddr} ${dstaddr} ${srcport} ${dstport} ${protocol} ${packets} ${bytes} ${start} ${end} ${action} ${log-status}'

# Loop through each VPC ID in the file and create a flow log
while IFS= read -r vpc_id
do
    echo "Creating VPC Flow Log for VPC: $vpc_id"
    
    aws ec2 create-flow-logs \
        --profile $AWS_PROFILE \
        --region $AWS_REGION \
        --resource-type VPC \
        --resource-ids $vpc_id \
        --traffic-type ALL \
        --log-destination-type s3 \
        --log-destination "arn:aws:s3:::$S3_BUCKET" \
        --log-format "$LOG_FORMAT" \
        --destination-options 'FileFormat=plain-text,HiveCompatiblePartitions=false,PerHourPartition=true' \
        --max-aggregation-interval 3600

    if [ $? -eq 0 ]; then
        echo "Successfully created VPC Flow Log for VPC: $vpc_id"
    else
        echo "Failed to create VPC Flow Log for VPC: $vpc_id"
    fi
    
    echo "----------------------------------------"
done < "$VPC_FILE"

echo "VPC Flow Log creation process completed."
