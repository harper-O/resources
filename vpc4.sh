#!/bin/bash

# Check if region and profile are provided as arguments
if [ $# -ne 2 ]; then
    echo "Please provide the AWS region and profile as arguments."
    echo "Usage: $0 <aws-region> <aws-profile>"
    exit 1
fi

# Set the AWS region and profile
AWS_REGION=$1
AWS_PROFILE=$2

# Set the S3 bucket for flow logs (dynamic based on profile)
S3_BUCKET="${AWS_PROFILE}-cloudtrail-bucket"

# Read VPC IDs from file
VPC_FILE="vpc.txt"
if [ ! -f "$VPC_FILE" ]; then
    echo "VPC file $VPC_FILE not found!"
    exit 1
fi

# Define custom log format
LOG_FORMAT='${version} ${account-id} ${az-id} ${flow-direction} ${instance-id} ${interface-id} ${srcaddr} ${dstaddr} ${srcport} ${dstport} ${protocol} ${packets} ${bytes} ${start} ${end} ${action} ${log-status} ${pkt-dst-aws-service} ${pkt-dstaddr} ${pkt-src-aws-service} ${pkt-srcaddr} ${region} ${sublocation-id} ${sublocation-type} ${subnet-id} ${tcp-flags} ${traffic-path} ${type} ${type} ${version} ${vpc-id}'

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


# ./create_vpc_flow_logs.sh us-east-1 aws210
