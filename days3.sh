#!/bin/bash

# Output CSV file
output_file="access_keys_report.csv"

# Write CSV header
echo "Account,Username,AccessKeyId,Status,CreationDate,AgeInDays" > "$output_file"

# Get list of all profiles
profiles=$(aws configure list-profiles)

for profile in $profiles
do
    echo "Processing profile: $profile"
    
    # Get account ID
    account_id=$(aws sts get-caller-identity --profile "$profile" --query Account --output text)
    
    # List all users
    users=$(aws iam list-users --profile "$profile" --query 'Users[*].UserName' --output text)
    
    for user in $users
    do
        # Get access keys for each user
        keys=$(aws iam list-access-keys --profile "$profile" --user-name "$user" --query 'AccessKeyMetadata[*].[AccessKeyId,Status,CreateDate]' --output text)
        
        while read -r key_id status creation_date
        do
            # Calculate age in days
            age_days=$(( ($(date +%s) - $(date -d "$creation_date" +%s)) / 86400 ))
            
            # Append to CSV
            echo "$account_id,$user,$key_id,$status,$creation_date,$age_days" >> "$output_file"
        done <<< "$keys"
    done
done

echo "Report generated: $output_file"
