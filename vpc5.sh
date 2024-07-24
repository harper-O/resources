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

# Check if credentials are available
if ! aws sts get-caller-identity --profile $AWS_PROFILE --region $AWS_REGION &> /dev/null; then
    echo "Error: Unable to locate credentials for profile $AWS_PROFILE"
    echo "Please check your AWS credentials configuration."
    exit 1
fi

# Check if region and profile are provided as arguments
if [ $# -ne 2 ]; then
    echo "Please provide the AWS region and profile as arguments."
    echo "Usage: $0 <aws-region> <aws-profile>"
    exit 1
fi

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
    
    flow_log_id=$(aws ec2 create-flow-logs \
        --profile $AWS_PROFILE \
        --region $AWS_REGION \
        --resource-type VPC \
        --resource-ids $vpc_id \
        --traffic-type ALL \
        --log-destination-type s3 \
        --log-destination "arn:aws:s3:::$S3_BUCKET" \
        --log-format "$LOG_FORMAT" \
        --destination-options 'FileFormat=plain-text,HiveCompatiblePartitions=false,PerHourPartition=true' \
        --max-aggregation-interval 3600 \
        --query 'FlowLogIds[0]' \
        --output text)

    if [ $? -eq 0 ] && [ -n "$flow_log_id" ]; then
        echo "Successfully created VPC Flow Log for VPC: $vpc_id"
        echo "Flow Log ID: $flow_log_id"
        
        # Add Name tag to the Flow Log
        aws ec2 create-tags \
            --profile $AWS_PROFILE \
            --region $AWS_REGION \
            --resources $flow_log_id \
            --tags Key=Name,Value="FlowLog-$vpc_id"
        
        if [ $? -eq 0 ]; then
            echo "Successfully added Name tag to Flow Log"
        else
            echo "Failed to add Name tag to Flow Log"
        fi
    else
        echo "Failed to create VPC Flow Log for VPC: $vpc_id"
    fi
    
    echo "----------------------------------------"
done < "$VPC_FILE"

echo "VPC Flow Log creation process completed."
