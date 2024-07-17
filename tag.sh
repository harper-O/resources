#!/bin/bash

# Output file
output_file="iam_users.csv"

# Write header to the output file
echo "AWS Profile,Username,Email,Uflip Notify Emails" > "$output_file"

# Iterate through all AWS profiles in the credentials file
for profile in $(grep '\[.*\]' ~/.aws/credentials | tr -d '[]'); do
  # Retrieve IAM users with .sv in their username for the current profile
  users=$(aws iam list-users --profile "$profile" --output text --query 'Users[?contains(UserName, `.sv`)].UserName')
  
  # Iterate through each user and retrieve their email and uflip-notify-emails tags
  for user in $users; do
    email=$(aws iam list-user-tags --user-name "$user" --profile "$profile" --output text --query 'Tags[?Key==`email`].Value' --no-paginate)
    uflip_notify_emails=$(aws iam list-user-tags --user-name "$user" --profile "$profile" --output text --query 'Tags[?Key==`uflip-notify-emails`].Value' --no-paginate)
    
    # Write the user information to the output file
    echo "$profile,$user,$email,$uflip_notify_emails" >> "$output_file"
  done
done

echo "IAM user information has been exported to $output_file"
