#!/bin/bash

# Output file
output_file="iam_users.csv"

# Write header to the output file
echo "AWS Account,IAM User,Access Key ID,Access Key Age (Days)" > "$output_file"

# Iterate through all AWS profiles in the credentials file
for profile in $(grep '\[.*\]' ~/.aws/credentials | tr -d '[]'); do
  echo "Processing account: $profile"

  # Retrieve all IAM users
  users=$(aws iam list-users --profile "$profile" --output text | awk '{print $NF}')

  # Iterate through each user
  for user in $users; do
    echo "Checking user: $user"

    # Check if the user has the "uflip-enabled" tag
    user_tags=$(aws iam list-user-tags --user-name "$user" --profile "$profile" --output json)
    uflip_enabled_tag=$(echo "$user_tags" | jq -r '.Tags[] | select(.Key == "uflip-enabled")')

    if [[ -z "$uflip_enabled_tag" ]]; then
      echo "User $user does not have the uflip-enabled tag"

      # Retrieve access keys for the user
      access_keys=$(aws iam list-access-keys --user-name "$user" --profile "$profile" --output json)

      # Check each access key
      for access_key in $(echo "$access_keys" | jq -r '.AccessKeyMetadata[].AccessKeyId'); do
        echo "Checking access key: $access_key"

        # Get the access key last used information
        access_key_last_used=$(aws iam get-access-key-last-used --access-key-id "$access_key" --profile "$profile" --output json)
        last_used_date=$(echo "$access_key_last_used" | jq -r '.AccessKeyLastUsed.LastUsedDate')

        if [[ -n "$last_used_date" ]]; then
          current_date=$(date +%Y-%m-%d)
          key_age=$(( ($(date -d "$current_date" +%s) - $(date -d "$last_used_date" +%s)) / 86400 ))
          echo "Access key age: $key_age days"

          if [[ $key_age -gt 170 ]]; then
            echo "Adding user to output: $profile,$user,$access_key,$key_age"
            echo "$profile,$user,$access_key,$key_age" >> "$output_file"
          fi
        else
          echo "Access key has never been used"
        fi
      done
    else
      echo "User $user has the uflip-enabled tag"
    fi
  done
done

echo "IAM user information has been exported to $output_file"
