import requests

# GitHub API endpoint for listing repositories in an organization
api_url = "https://api.github.com/orgs/{org}/repos"

# GitHub personal access token
access_token = "YOUR_PERSONAL_ACCESS_TOKEN"

# Headers for authentication and API version
headers = {
    "Authorization": f"Bearer {access_token}",
    "Accept": "application/vnd.github+json"
}

# Organization name
org_name = "YOUR_ORGANIZATION_NAME"

# Send a GET request to the GitHub API to list repositories
response = requests.get(api_url.format(org=org_name), headers=headers)

# Check if the request was successful
if response.status_code == 200:
    # Parse the JSON response
    repos = response.json()

    # Iterate over each repository
    for repo in repos:
        repo_name = repo["name"]
        secrets_url = f"https://api.github.com/repos/{org_name}/{repo_name}/actions/secrets"

        # Send a GET request to check if the repository has secrets
        secrets_response = requests.get(secrets_url, headers=headers)

        if secrets_response.status_code == 200:
            secrets = secrets_response.json()
            if secrets["total_count"] > 0:
                print(f"{repo_name} is using GitHub Secrets.")
        else:
            print(f"Failed to retrieve secrets for {repo_name}. Status code: {secrets_response.status_code}")
else:
    print(f"Failed to retrieve repositories. Status code: {response.status_code}")
