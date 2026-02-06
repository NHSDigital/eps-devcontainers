#!/usr/bin/env bash
set -e

# Get the current directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANGUAGE_VERSIONS_DIR="${SCRIPT_DIR}/../src/base/.devcontainer/language_versions"

# Check if the user is logged in with GitHub CLI
if ! gh auth status > /dev/null 2>&1; then
  echo "You are not logged in to GitHub CLI. Initiating login..."
  gh auth login
fi

# Fetch the repos.json file from the eps-repo-status repository using GitHub CLI
REPOS_JSON_PATH="repos/NHSDigital/eps-repo-status/contents/packages/get_repo_status/app/repos.json"
TEMP_REPOS_JSON="/tmp/repos.json"

# Download the repos.json file
if ! gh api -H 'Accept: application/vnd.github.v3.raw' "$REPOS_JSON_PATH" > "$TEMP_REPOS_JSON"; then
  echo "Failed to fetch repos.json using GitHub CLI. Exiting."
  exit 1
fi

# Parse the repoUrl values from the JSON file
mapfile -t REPOS < <(jq -r '.[].repoUrl' "$TEMP_REPOS_JSON")

# Define output files
mkdir -p "${LANGUAGE_VERSIONS_DIR}"
NODEJS_FILE="${LANGUAGE_VERSIONS_DIR}/nodejs-versions.txt"
PYTHON_FILE="${LANGUAGE_VERSIONS_DIR}/python-versions.txt"
JAVA_FILE="${LANGUAGE_VERSIONS_DIR}/java-versions.txt"
TERRAFORM_FILE="${LANGUAGE_VERSIONS_DIR}/terraform-versions.txt"
GOLANG_FILE="${LANGUAGE_VERSIONS_DIR}/golang-versions.txt"
ALL_LANGUAGES_FILE="${LANGUAGE_VERSIONS_DIR}/language-versions.txt"
# Clear existing files
true > "$NODEJS_FILE"
true > "$PYTHON_FILE"
true > "$JAVA_FILE"
true > "$TERRAFORM_FILE"
true > "$GOLANG_FILE"
true > "$ALL_LANGUAGES_FILE"

# Loop through repositories and fetch .tool-versions
for repo in "${REPOS[@]}"; do
  TEMP_FILE="/tmp/.tool-versions"

  # Fetch .tool-versions from the repository
  gh api -H 'Accept: application/vnd.github.v3.raw' "repos/${repo}/contents/.tool-versions" > "$TEMP_FILE"

  # Extract versions and append to respective files
  if [ -f "$TEMP_FILE" ]; then
    echo "" >> ${TEMP_FILE}
    while IFS= read -r line; do
      tool=$(echo "$line" | awk '{print $1}')
      version=$(echo "$line" | awk '{print $2}')

      case $tool in
        nodejs)
          echo "$version" >> "$NODEJS_FILE"
          echo "nodejs $version : ${repo}" >> "$ALL_LANGUAGES_FILE"
          ;;
        python)
          echo "$version" >> "$PYTHON_FILE"
          echo "python $version : ${repo}" >> "$ALL_LANGUAGES_FILE"
          ;;
        java)
          echo "$version" >> "$JAVA_FILE"
          echo "java $version : ${repo}" >> "$ALL_LANGUAGES_FILE"
          ;;
        terraform)
          echo "$version" >> "$TERRAFORM_FILE"
          echo "terraform $version : ${repo}" >> "$ALL_LANGUAGES_FILE"
          ;;
        golang)
          echo "$version" >> "$GOLANG_FILE"
          echo "golang $version : ${repo}" >> "$ALL_LANGUAGES_FILE"
          ;;
        poetry)
          echo "poetry $version : ${repo}" >> "$ALL_LANGUAGES_FILE"
          ;;
      esac
    done < "$TEMP_FILE"
  fi

  # Remove temporary file
  rm -f "$TEMP_FILE"
done

# Remove duplicate entries from the files
sort -u "$NODEJS_FILE" -o "$NODEJS_FILE"
sort -u "$PYTHON_FILE" -o "$PYTHON_FILE"
sort -u "$JAVA_FILE" -o "$JAVA_FILE"
sort -u "$TERRAFORM_FILE" -o "$TERRAFORM_FILE"
sort -u "$GOLANG_FILE" -o "$GOLANG_FILE"
sort -u "$ALL_LANGUAGES_FILE" -o "$ALL_LANGUAGES_FILE"

echo "Version files generated successfully."
cat "$ALL_LANGUAGES_FILE"
