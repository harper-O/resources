#!/bin/bash

# Output file
OUTPUT_FILE="output-keys-due.csv"

# CSV header
echo "AccountId,Username,AccessKeyId,KeyAgeInDays,LastUsedInDays" > $OUTPUT_FILE

# Get current date in seconds since epoch
CURRENT_DATE=$(date +%s)

# Function to calculate days difference
days_difference() {
    local date_string="$1"
    local date_seconds=$(date -d "$date_string" +%s)
    echo $(( ($CURRENT_DATE - $date_seconds) / 86400 ))
}

# Function to assume role and set AWS environment variables
assume_role() {
    local account_id="$1"
    local role_name="YourRoleName"  # Replace with your actual role name
    local session_name="KeyAuditSession"

    local creds=$(aws sts assume-role --role-arn "arn:aws:iam::${account_id}:role/${role_name}" \
                                      --role-session-name "${session_name}" \
                                      --profile YourProfileName)  # Replace with your profile name

    export AWS_ACCESS_KEY_ID=$(echo $creds | jq -r .Credentials.AccessKeyId)
    export AWS_SECRET_ACCESS_KEY=$(echo $creds | jq -r .Credentials.SecretAccessKey)
    export AWS_SESSION_TOKEN=$(echo $creds | jq -r .Credentials.SessionToken)
}

# Get list of all account IDs in the organization
account_ids=$(aws organizations list-accounts --query 'Accounts[*].Id' --output text --profile YourProfileName)  # Replace with your profile name

for account_id in $account_ids; do
    echo "Processing account: $account_id"
    
    # Assume role in the account
    assume_role $account_id

    # Fetch all users
    users=$(aws iam list-users --query 'Users[*].UserName' --output text)

    for user in $users; do
        # Fetch access keys for each user
        keys=$(aws iam list-access-keys --user-name "$user" --query 'AccessKeyMetadata[*].[AccessKeyId,CreateDate,Status]' --output text)
        
        while read -r key_id create_date status; do
            # Check if key is active
            if [ "$status" == "Active" ]; then
                # Calculate key age
                key_age=$(days_difference "$create_date")
                
                # Check if key is older than 170 days
                if [ $key_age -gt 170 ]; then
                    # Check for the specific tag
                    tag_value=$(aws iam list-access-key-tags --access-key-id "$key_id" --user-name "$user" --query "Tags[?Key=='uflip-enabled'].Value" --output text)
                    
                    # If tag is not present or not 'true', process this key
                    if [ "$tag_value" != "true" ]; then
                        # Get last used date
                        last_used=$(aws iam get-access-key-last-used --access-key-id "$key_id" --query 'AccessKeyLastUsed.LastUsedDate' --output text)
                        
                        # Calculate days since last use
                        if [ "$last_used" != "None" ]; then
                            last_used_days=$(days_difference "$last_used")
                        else
                            last_used_days="Never"
                        fi
                        
                        # Append to CSV
                        echo "$account_id,$user,$key_id,$key_age,$last_used_days" >> $OUTPUT_FILE
                    fi
                fi
            fi
        done <<< "$keys"
    done

    # Clear AWS session environment variables
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
done

echo "Results written to $OUTPUT_FILE"
