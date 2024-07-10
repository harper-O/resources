#!/bin/bash

# GitHub API endpoint for listing repositories in an organization
api_url="https://api.github.com/orgs/${org_name}/repos"

# GitHub personal access token
access_token="YOUR_PERSONAL_ACCESS_TOKEN"

# Headers for authentication and API version
headers=("Authorization: Bearer ${access_token}" "Accept: application/vnd.github+json")

# Organization name
org_name="YOUR_ORGANIZATION_NAME"

# Output file
output_file="output.csv"

# Send a GET request to the GitHub API to list repositories
response=$(curl -s -H "${headers[0]}" -H "${headers[1]}" "${api_url}")

# Check if the request was successful
if [[ $(echo "$response" | jq 'length') -gt 0 ]]; then
    # Extract repository names from the response
    repo_names=($(echo "$response" | jq -r '.[].name'))

    # Write CSV header to the output file
    echo "Repository,Using GitHub Secrets" > "$output_file"

    # Iterate over each repository
    for repo_name in "${repo_names[@]}"; do
        secrets_url="https://api.github.com/repos/${org_name}/${repo_name}/actions/secrets"

        # Send a GET request to check if the repository has secrets
        secrets_response=$(curl -s -H "${headers[0]}" -H "${headers[1]}" "${secrets_url}")

        if [[ $(echo "$secrets_response" | jq 'has("total_count")') == "true" ]]; then
            secrets_count=$(echo "$secrets_response" | jq '.total_count')
            if [[ $secrets_count -gt 0 ]]; then
                echo "${repo_name},Yes" >> "$output_file"
            else
                echo "${repo_name},No" >> "$output_file"
            fi
        else
            echo "${repo_name},Error" >> "$output_file"
        fi
    done
else
    echo "Failed to retrieve repositories. Response: $response"
fi
