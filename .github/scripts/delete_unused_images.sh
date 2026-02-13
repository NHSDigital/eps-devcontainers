#!/usr/bin/env bash

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
		return 0
	fi

	while IFS= read -r tag; do
		if [[ "${tag}" =~ ^pr-[0-9]+- ]]; then
			local pull_request
			local pr_json
			local pr_state

			pull_request=${tag#pr-}
			pull_request=${pull_request%%-*}

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
                        echo "Deleting image with tag ${tag} (version ID: ${version_id}) from container ${container_name}..."
						gh api \
						 	-H "Accept: application/vnd.github+json" \
						 	-X DELETE \
						 	"/orgs/nhsdigital/packages/container/${package_name}/versions/${version_id}"
					fi
				done
		fi
	done <<<"${tags}"
}


language_folders=$(find src/languages -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | jq -R -s -c 'split("\n")[:-1]')
project_folders=$(find src/projects -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | jq -R -s -c 'split("\n")[:-1]')

for container_name in $(jq -r '.[]' <<<"${project_folders}"); do
	delete_pr_images "${container_name}"
done

for container_name in $(jq -r '.[]' <<<"${language_folders}"); do
	delete_pr_images "${container_name}"
done

delete_pr_images "base"
