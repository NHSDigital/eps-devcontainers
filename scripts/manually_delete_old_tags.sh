#!/usr/bin/env bash
set -euo pipefail

# Script to interactively review and delete old container package versions from GitHub Packages.
# By default, it will review all container packages based on the folder structure in src/.
# You can specify a single container to review with --container <name>.
# Use --dry-run to see what would be deleted without actually performing deletions.
# To use it, you must have authenticated with github using this command
# gh auth login --scopes read:packages,delete:packages
#

DRY_RUN=false
TARGET_CONTAINER=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--dry-run|-n)
			DRY_RUN=true
			shift
			;;
		--container)
			if [[ $# -lt 2 || -z "$2" ]]; then
				echo "--container requires a value" >&2
				echo "Usage: $0 [--dry-run] [--container <name>]" >&2
				exit 1
			fi
			TARGET_CONTAINER="$2"
			shift 2
			;;
		--help|-h)
			echo "Usage: $0 [--dry-run] [--container <name>]"
			echo "Interactively review every container package version and delete selected versions."
			exit 0
			;;
		*)
			echo "Unknown option: $1" >&2
			echo "Usage: $0 [--dry-run] [--container <name>]" >&2
			exit 1
			;;
	esac
done

if ! command -v gh >/dev/null 2>&1; then
	echo "gh CLI is required" >&2
	exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
	echo "jq is required" >&2
	exit 1
fi

get_container_package_name() {
	local container_name=$1

	if [[ -z "${container_name}" ]]; then
		echo "Container name is required" >&2
		return 1
	fi

	printf 'eps-devcontainers/%s' "${container_name}" | jq -sRr @uri
}

get_container_versions_json() {
	local container_name=$1
	local package_name

	package_name=$(get_container_package_name "${container_name}")

	gh api \
		-H "Accept: application/vnd.github+json" \
		"/orgs/nhsdigital/packages/container/${package_name}/versions" \
		--paginate
}

confirm_delete() {
	local prompt=$1
	local reply

	if [[ -r /dev/tty ]]; then
		read -r -p "${prompt} [y/N]: " reply < /dev/tty
	else
		echo "No interactive terminal available; defaulting to 'No'."
		return 1
	fi
	[[ "${reply}" == "y" || "${reply}" == "Y" ]]
}

review_and_delete_container_versions() {
	local container_name=$1
	local package_name
	local versions_json
	local version_count

	package_name=$(get_container_package_name "${container_name}")
	versions_json=$(get_container_versions_json "${container_name}")
	version_count=$(jq 'length' <<<"${versions_json}")

	echo ""
	echo "=== Container: ${container_name} (${version_count} versions) ==="

	if [[ "${version_count}" -eq 0 ]]; then
		echo "No versions found, skipping."
		return 0
	fi

	while IFS= read -r version; do
		local version_id
		local created_at
		local updated_at
		local tags
		local is_untagged
		local has_sha256_tag
		local keep_without_prompt

		version_id=$(jq -r '.id' <<<"${version}")
		created_at=$(jq -r '.created_at // "unknown"' <<<"${version}")
		updated_at=$(jq -r '.updated_at // "unknown"' <<<"${version}")
		tags=$(jq -r '(.metadata.container.tags // []) | if length == 0 then "<untagged>" else join(", ") end' <<<"${version}")
		is_untagged=$(jq -r '((.metadata.container.tags // []) | length) == 0' <<<"${version}")
		has_sha256_tag=$(jq -r 'any((.metadata.container.tags // [])[]?; test("^sha256-.+"))' <<<"${version}")
		keep_without_prompt=$(jq -r '
			any((.metadata.container.tags // [])[]?;
				test("^githubactions-ci-.+") or
				test("^ci-.+") or
				test("^githubactions-latest$") or
				test("^latest$") or
				test("^githubactions-v.+") or
				test("^v.+")
			)
		' <<<"${version}")

		echo ""
		echo "Container:  ${container_name}"
		echo "Version ID: ${version_id}"
		echo "Created:    ${created_at}"
		echo "Updated:    ${updated_at}"
		echo "Tags:       ${tags}"

		if [[ "${is_untagged}" == "true" ]]; then
			if [[ "${DRY_RUN}" == "true" ]]; then
				echo "[DRY RUN] Would auto-delete untagged version ID ${version_id} from ${container_name}."
			else
				echo "Auto-deleting untagged version ID ${version_id} from ${container_name}..."
				gh api \
					-H "Accept: application/vnd.github+json" \
					-X DELETE \
					"/orgs/nhsdigital/packages/container/${package_name}/versions/${version_id}"
			fi
		elif [[ "${has_sha256_tag}" == "true" ]]; then
			if [[ "${DRY_RUN}" == "true" ]]; then
				echo "[DRY RUN] Would auto-delete sha256-tagged version ID ${version_id} from ${container_name}."
			else
				echo "Auto-deleting sha256-tagged version ID ${version_id} from ${container_name}..."
				gh api \
					-H "Accept: application/vnd.github+json" \
					-X DELETE \
					"/orgs/nhsdigital/packages/container/${package_name}/versions/${version_id}"
			fi
		elif [[ "${keep_without_prompt}" == "true" ]]; then
			echo "Keeping protected version ID ${version_id} (matching keep-tag rule)."
		elif confirm_delete "Delete this version?"; then
			if [[ "${DRY_RUN}" == "true" ]]; then
				echo "[DRY RUN] Would delete version ID ${version_id} from ${container_name}."
			else
				echo "Deleting version ID ${version_id} from ${container_name}..."
				gh api \
					-H "Accept: application/vnd.github+json" \
					-X DELETE \
					"/orgs/nhsdigital/packages/container/${package_name}/versions/${version_id}"
			fi
		else
			echo "Skipping version ID ${version_id}."
		fi
	done < <(jq -c '.[]' <<<"${versions_json}")
}

base_node_folders=$(find src/base_node -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | jq -R -s -c 'split("\n")[:-1]')
language_folders=$(find src/languages -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | jq -R -s -c 'split("\n")[:-1]')
project_folders=$(find src/projects -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | jq -R -s -c 'split("\n")[:-1]')

if [[ -n "${TARGET_CONTAINER}" ]]; then
	review_and_delete_container_versions "${TARGET_CONTAINER}"
	exit 0
fi

for container_name in $(jq -r '.[]' <<<"${project_folders}"); do
	review_and_delete_container_versions "${container_name}"
done

for container_name in $(jq -r '.[]' <<<"${base_node_folders}"); do
	review_and_delete_container_versions "${container_name}"
done

for container_name in $(jq -r '.[]' <<<"${language_folders}"); do
	review_and_delete_container_versions "${container_name}"
done

review_and_delete_container_versions "base"
