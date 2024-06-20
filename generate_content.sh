#!/bin/bash

GIST_LIST="gists.txt"

REPOSITORY_LIST=$1
MODE=${2:-table}

# User input, or will be automated detected via CI
GITHUB_OWNER=$3

if [[ -z $REPOSITORY_LIST || -z $MODE || -z $GITHUB_OWNER ]]; then
    echo "ERROR: epository list is empty!"
    echo "Usage: $0 <repository_list_path> <mode> <github_owner>"
    exit 1
fi

# Function to generate table rows
generate_repo_list() {
    local index="$1"
    local repo_name="$2"
    local description="$3"

    # Only get base repo name, execlude the username
    repo_base_name=$(basename $repo_name)

    local repo_hyperlink="<a href=\"https://github.com/$repo_name\">$repo_name</a>"

    echo "## $index. $repo_base_name" >>README.md
    echo "- URL: $repo_hyperlink" >>README.md
    echo "- Description: $description" >>README.md
}

# Function to generate table rows for Gists
generate_gist_table() {
    local index="$1"
    local gist_id="$2"
    local description="$3"

    local gist_hyperlink="<a href=\"https://gist.github.com/$gist_id\">$gist_id</a>"

    # Add header in the first run
    if [[ "$index" == "1" ]]; then
        echo "" >> README.md
        echo "| ID  | Gist URL      | Description                                              |" >> README.md
        echo "| :-- | :--------------- | :---------------------------------------------  |" >> README.md
    fi

    echo "| $index | $gist_hyperlink | $description  |" >> README.md
}




# Function to generate table rows
generate_repo_table() {
    local index="$1"
    local repo_name="$2"
    local description="$3"

    # Only get base repo name, execlude the username
    repo_base_name=$(basename $repo_name)

    local repo_hyperlink="<a href=\"https://github.com/$repo_name\">$repo_base_name</a>"
    local stars="<a href=\"https://github.com/$repo_name/stargazers\"><img alt=\"GitHub Repo stars\" src=\"https://img.shields.io/github/stars/$repo_name?style=flat\" height=\"20\"/></a>"

    # At header in the first run
    if [[ "$index" == "1" ]]; then
        echo "" >> README.md
        echo "| ID  | URL          | Description                                              |" >> README.md
        echo "| :-- | :--------------- | :---------------------------------------------  |" >> README.md
    fi

    echo "| $index | $repo_hyperlink | $description  |" >> README.md
}

# Start README file with header
echo "<h1 align=\"center\">Repositories and Gists Landscape 💎</h1>" >README.md
echo "<p align=\"center\">Welcome to my repositories and gists landscape 👋</p>" >>README.md
echo "" >>README.md

# Repositories Table Header
echo "| ID  | Type | URL          | Description                                              |" >> README.md
echo "| :-- | :--- | :--------------- | :---------------------------------------------  |" >> README.md

# Start with index 1 for first item
index=1

# Process Repositories
while IFS= read -r repo_name; do
    echo "Working on repo: $repo_name, with index: $index"

    # Make the API request to get repository information
    response=$(curl -s "https://api.github.com/repos/$repo_name")
    description=$(echo "$response" | jq -r '.description')
    repo_hyperlink="<a href=\"https://github.com/$repo_name\">$repo_name</a>"

    # Add to table
    echo "| $index | Repo | $repo_hyperlink | $description  |" >> README.md

    ((index++))
done <"$REPOSITORY_LIST"

# Process Gists
while IFS= read -r gist_id; do
    echo "Working on gist: $gist_id, with index: $index"

    # Make the API request to get gist information and store it in temp.json
    curl -s "https://api.github.com/gists/$gist_id" > temp.json
    
    # Extract description
    description=$(jq -r '.description' temp.json)
    
    # Extract filenames and create a list of hyperlinks
    filenames=$(jq -r '.files | to_entries[] | .key' temp.json)
    file_links=""
    for filename in $filenames; do
        file_links+="<a href=\"https://gist.github.com/$gist_id#file-$(echo $filename | sed 's/ /-/g')\">$filename</a>, "
    done
    # Remove the trailing comma and space
    file_links=${file_links%, }

    # Delete temp.json
    rm temp.json
    
    gist_hyperlink="<a href=\"https://gist.github.com/$gist_id\">$gist_id</a>"

    # Add to table with filenames
    echo "| $index | Gist | $gist_hyperlink | $description | $file_links |" >> README.md

    ((index++))
done <"$GIST_LIST"

echo "" >>README.md
echo "For full list of repositories and gists, click [**here**](https://github.com/${GITHUB_OWNER}?tab=repositories&q=&type=&language=&sort=stargazers)." >>README.md
