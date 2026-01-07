#!/usr/bin/env bash

# Get the current directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANGUAGE_VERSIONS_DIR="${SCRIPT_DIR}/../src/base/.devcontainer/language_versions"

# Define repositories to fetch .tool-versions from
REPOS=(
  "NHSDigital/electronic-prescription-service-clinical-prescription-tracker"
  "NHSDigital/prescriptionsforpatients"
  "NHSDigital/prescriptions-for-patients"
  "NHSDigital/electronic-prescription-service-api"
  "NHSDigital/electronic-prescription-service-release-notes"
  "NHSDigital/electronic-prescription-service-account-resources"
  "NHSDigital/eps-prescription-status-update-api"
  "NHSDigital/eps-FHIR-validator-lambda"
  "NHSDigital/eps-load-test"
  "NHSDigital/eps-prescription-tracker-ui"
  "NHSDigital/eps-aws-dashboards"
  "NHSDigital/eps-cdk-utils"
  "NHSDigital/eps-vpc-resources"
  "NHSDigital/eps-assist-me"
  "NHSDigital/validation-service-fhir-r4"
  "NHSDigital/electronic-prescription-service-get-secrets"
  "NHSDigital/nhs-fhir-middy-error-handler"
  "NHSDigital/nhs-eps-spine-client"
  "NHSDigital/electronic-prescription-service-api-regression-tests"
  "NHSDigital/eps-action-sbom"
  "NHSDigital/eps-action-cfn-lint"
  "NHSDigital/eps-common-workflows"
  "NHSDigital/eps-storage-terraform"
  "NHSDigital/eps-spine-shared"
)


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
