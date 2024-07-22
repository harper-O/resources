#!/bin/bash

# Function to check user and their access keys
check_user() {
    local profile=$1
    local user=$2
    
    # Get access keys for the user
    keys=$(aws iam list-access-keys --user-name "$user" --profile "$profile" --query 'AccessKeyMetadata[?Status==`Active`].[AccessKeyId,CreateDate]' --output text)
    
    while read -r key create_date; do
        if [ -n "$key" ] && [ -n "$create_date" ]; then
            # Calculate the age of the key in days
            age=$(( ($(date +%s) - $(date -d "$create_date" +%s)) / 86400 ))
            
            if [ $age -gt 170 ]; then
                echo "Profile: $profile, User: $user, Key: $key, Age: $age days"
            fi
        fi
    done <<< "$keys"
}

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
