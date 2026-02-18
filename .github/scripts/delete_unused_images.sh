#!/usr/bin/env bash

DRY_RUN=false
DELETE_PR=false
DELETE_CI=false
DELETE_UNTAGGED=false

while [[ $# -gt 0 ]]; do
	case "$1" in
		--dry-run|-n)
			DRY_RUN=true
			shift
			;;
		--delete-pr)
			DELETE_PR=true
			shift
			;;
		--delete-ci)
			DELETE_CI=true
			shift
			;;
		--delete-untagged)
			DELETE_UNTAGGED=true
			shift
			;;
		--help|-h)
			echo "Usage: $0 [--dry-run] [--delete-pr] [--delete-ci] [--delete-untagged]"
			exit 0
			;;
		*)
			echo "Unknown option: $1" >&2
			echo "Usage: $0 [--dry-run] [--delete-pr] [--delete-ci] [--delete-untagged]" >&2
			exit 1
			;;
	esac
done

if [[ "${DELETE_PR}" == "false" && "${DELETE_CI}" == "false" ]]; then
	DELETE_PR=true
fi

get_container_package_name() {
	local container_name=$1

	if [[ -z "${container_name}" ]]; then
		echo "Container name is required" >&2
		return 1
	fi

	# URL-encode the package path (eps-devcontainers/${container_name}) for the GH API
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

delete_pr_images() {
	local container_name=$1
	local package_name
	local versions_json
	local tags

	if [[ -z "${container_name}" ]]; then
		echo "Container name is required" >&2
		return 1
	fi

	package_name=$(get_container_package_name "${container_name}")
	versions_json=$(get_container_versions_json "${container_name}")
	tags=$(jq -r '[.[].metadata.container.tags[]?] | unique | .[]' <<<"${versions_json}")

	if [[ -z "${tags}" ]]; then
		echo "No tags found for container ${container_name}, skipping."
		return 0
	fi

	while IFS= read -r tag; do
		local pull_request
		if [[ "${tag}" =~ ^pr-([0-9]+)(-.+)?$ ]]; then
			pull_request=${BASH_REMATCH[1]}
		elif [[ "${tag}" =~ ^githubactions-pr-([0-9]+)(-.+)?$ ]]; then
			pull_request=${BASH_REMATCH[1]}
		else
			echo "Tag ${tag} does not match expected PR tag format for container ${container_name}, skipping."
			continue
		fi

			local pr_json
			local pr_state

			if ! pr_json=$(gh api \
				-H "Accept: application/vnd.github+json" \
				"/repos/NHSDigital/eps-devcontainers/pulls/${pull_request}"); then
				continue
			fi
            echo "Checking PR #${pull_request} for tag ${tag} in container ${container_name}..."
			pr_state=$(jq -r '.state // empty' <<<"${pr_json}")
			if [[ "${pr_state}" != "closed" ]]; then
                echo "State is not closed - not deleting images"
				continue
			fi

			jq -r --arg tag "${tag}" '.[] | select(.metadata.container.tags[]? == $tag) | .id' \
				<<<"${versions_json}" \
				| while IFS= read -r version_id; do
					if [[ -n "${version_id}" ]]; then
						if [[ "${DRY_RUN}" == "true" ]]; then
							echo "[DRY RUN] Would delete image with tag ${tag} (version ID: ${version_id}) from container ${container_name}."
						else
							echo "Deleting image with tag ${tag} (version ID: ${version_id}) from container ${container_name}..."
							gh api \
						 		-H "Accept: application/vnd.github+json" \
						 		-X DELETE \
						 		"/orgs/nhsdigital/packages/container/${package_name}/versions/${version_id}"
						fi
					fi
				done
	done <<<"${tags}"
}

delete_ci_images() {
	local container_name=$1
	local package_name
	local versions_json
	local tags

	if [[ -z "${container_name}" ]]; then
		echo "Container name is required" >&2
		return 1
	fi

	package_name=$(get_container_package_name "${container_name}")
	versions_json=$(get_container_versions_json "${container_name}")
	tags=$(jq -r '[.[].metadata.container.tags[]?] | unique | .[]' <<<"${versions_json}")

	if [[ -z "${tags}" ]]; then
		echo "No tags found for container ${container_name}, skipping."
		return 0
	fi

	while IFS= read -r tag; do
		if [[ ! "${tag}" =~ ^ci-[0-9a-fA-F]{8}.*$ ]] && [[ ! "${tag}" =~ ^githubactions-ci-[0-9a-fA-F]{8}.*$ ]]; then
			echo "Tag ${tag} does not match expected CI tag format for container ${container_name}, skipping."
			continue
		fi

		jq -r --arg tag "${tag}" '.[] | select(.metadata.container.tags[]? == $tag) | .id' \
			<<<"${versions_json}" \
			| while IFS= read -r version_id; do
				if [[ -n "${version_id}" ]]; then
					if [[ "${DRY_RUN}" == "true" ]]; then
						echo "[DRY RUN] Would delete CI image with tag ${tag} (version ID: ${version_id}) from container ${container_name}."
					else
						echo "Deleting CI image with tag ${tag} (version ID: ${version_id}) from container ${container_name}..."
						gh api \
					 		-H "Accept: application/vnd.github+json" \
					 		-X DELETE \
					 		"/orgs/nhsdigital/packages/container/${package_name}/versions/${version_id}"
					fi
				fi
			done
	done <<<"${tags}"
}

delete_untagged_images() {
	local container_name=$1
	local package_name
	local versions_json

	if [[ -z "${container_name}" ]]; then
		echo "Container name is required" >&2
		return 1
	fi

	package_name=$(get_container_package_name "${container_name}")
	versions_json=$(get_container_versions_json "${container_name}")

	jq -r '.[] | select(((.metadata.container.tags // []) | length) == 0) | .id' \
		<<<"${versions_json}" \
		| while IFS= read -r version_id; do
			if [[ -n "${version_id}" ]]; then
				if [[ "${DRY_RUN}" == "true" ]]; then
					echo "[DRY RUN] Would delete untagged image version ID ${version_id} from container ${container_name}."
				else
					echo "Deleting untagged image version ID ${version_id} from container ${container_name}..."
					gh api \
					 	-H "Accept: application/vnd.github+json" \
					 	-X DELETE \
					 	"/orgs/nhsdigital/packages/container/${package_name}/versions/${version_id}"
				fi
			fi
		done
}

base_node_folders=$(find src/base_node -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | jq -R -s -c 'split("\n")[:-1]')
language_folders=$(find src/languages -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | jq -R -s -c 'split("\n")[:-1]')
project_folders=$(find src/projects -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | jq -R -s -c 'split("\n")[:-1]')

for container_name in $(jq -r '.[]' <<<"${project_folders}"); do
	if [[ "${DELETE_PR}" == "true" ]]; then
		delete_pr_images "${container_name}"
	fi
	if [[ "${DELETE_CI}" == "true" ]]; then
		delete_ci_images "${container_name}"
	fi
	if [[ "${DELETE_UNTAGGED}" == "true" ]]; then
		delete_untagged_images "${container_name}"
	fi
done

for container_name in $(jq -r '.[]' <<<"${base_node_folders}"); do
	if [[ "${DELETE_PR}" == "true" ]]; then
		delete_pr_images "${container_name}"
	fi
	if [[ "${DELETE_CI}" == "true" ]]; then
		delete_ci_images "${container_name}"
	fi
	if [[ "${DELETE_UNTAGGED}" == "true" ]]; then
		delete_untagged_images "${container_name}"
	fi
done

for container_name in $(jq -r '.[]' <<<"${language_folders}"); do
	if [[ "${DELETE_PR}" == "true" ]]; then
		delete_pr_images "${container_name}"
	fi
	if [[ "${DELETE_CI}" == "true" ]]; then
		delete_ci_images "${container_name}"
	fi
	if [[ "${DELETE_UNTAGGED}" == "true" ]]; then
		delete_untagged_images "${container_name}"
	fi
done

if [[ "${DELETE_PR}" == "true" ]]; then
	delete_pr_images "base"
fi
if [[ "${DELETE_CI}" == "true" ]]; then
	delete_ci_images "base"
fi
if [[ "${DELETE_UNTAGGED}" == "true" ]]; then
	delete_untagged_images "base"
fi
