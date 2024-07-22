#!/bin/bash

# Output file
output_file="iam_users.csv"

# Write header to the output file
echo "AWS Account,IAM User,Access Key ID,Access Key Age (Days)" > "$output_file"

# Iterate through all AWS profiles in the credentials file
for profile in $(grep '\[.*\]' ~/.aws/credentials | tr -d '[]'); do
  echo "Processing account: $profile"
  
  # Retrieve IAM users without the tag key "uflip-enabled"
  users=$(aws iam list-users --profile "$profile" --query 'Users[?!Tags[?Key==`uflip-enabled`]]' --output text | awk '{print $NF}')
  
  echo "Found users: $users"
  
  # Iterate through each user
  for user in $users; do
    echo "Checking user: $user"
    
    # Retrieve access keys for the user
    access_keys=$(aws iam list-access-keys --user-name "$user" --profile "$profile" --output json)
    
    echo "Access keys: $access_keys"
    
    # Check each access key
    for access_key in $(echo "$access_keys" | jq -r '.AccessKeyMetadata[].AccessKeyId'); do
      echo "Checking access key: $access_key"
      
      # Get the access key details
      access_key_details=$(aws iam get-access-key-last-used --access-key-id "$access_key" --profile "$profile")
      
      echo "Access key details: $access_key_details"
      
      # Check if the access key is active and older than 170 days
      last_used_date=$(echo "$access_key_details" | jq -r '.AccessKeyLastUsed.LastUsedDate')
      if [[ -n "$last_used_date" ]]; then
        current_date=$(date +%Y-%m-%d)
        key_age=$(( ($(date -d "$current_date" +%s) - $(date -d "$last_used_date" +%s)) / 86400 ))
        echo "Access key age: $key_age days"
        if [[ $key_age -gt 170 ]]; then
          echo "Adding user to output: $profile,$user,$access_key,$key_age"
          echo "$profile,$user,$access_key,$key_age" >> "$output_file"
        fi
      fi
    done
  done
done

echo "IAM user information has been exported to $output_file"
