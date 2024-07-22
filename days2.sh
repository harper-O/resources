#!/bin/bash

output_file="aws_old_keys_report.csv"

# Function to calculate days between two dates
days_between() {
    local start_date=$1
    local end_date=$2
    local seconds=$(($(date -d "$end_date" +%s) - $(date -d "$start_date" +%s)))
    echo $((seconds / 86400))
}

# Function to check user and their access keys
check_user() {
    local profile=$1
    local user=$2
    
    # Get access keys for the user
    keys=$(aws iam list-access-keys --user-name "$user" --profile "$profile" --query 'AccessKeyMetadata[?Status==`Active`].[AccessKeyId,CreateDate]' --output text)
    
    while read -r key create_date; do
        if [ -n "$key" ] && [ -n "$create_date" ]; then
            # Calculate the age of the key in days
            age=$(days_between "$create_date" "$(date +%Y-%m-%d)")
            
            if [ $age -gt 170 ]; then
                # Get last used date
                last_used=$(aws iam get-access-key-last-used --access-key-id "$key" --profile "$profile" --query 'AccessKeyLastUsed.LastUsedDate' --output text)
                
                # Calculate days since last used
                if [ "$last_used" == "N/A" ]; then
                    days_since_last_used="Never"
                else
                    days_since_last_used=$(days_between "$last_used" "$(date +%Y-%m-%d)")
                fi
                
                echo "$profile,$user,$key,$age,$create_date,$days_since_last_used" >> "$output_file"
            fi
        fi
    done <<< "$keys"
}

# Clear the output file if it exists and add header
echo "Profile,User,Key,Age (days),Create Date,Days Since Last Used" > "$output_file"

# Get all profiles from AWS credentials file
profiles=$(grep '^\[' ~/.aws/credentials | sed 's/\[//g' | sed 's/\]//g')

# Iterate through all profiles
for profile in $profiles; do
    echo "Checking profile: $profile"
    # List all users for the current profile
    users=$(aws iam list-users --profile "$profile" --query 'Users[*].UserName' --output text)
    
    # Check each user
    for user in $users; do
        check_user "$profile" "$user"
    done
done

echo "Results have been saved to $output_file"
