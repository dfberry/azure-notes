#!/bin/bash

# Get the current date and time
current_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Get the date and time 24 hours ago
one_day_ago=$(date -u -d "24 hours ago" +"%Y-%m-%dT%H:%M:%SZ")

# Get the list of resource groups
resource_groups=$(az group list --query "[?tags.createdTime >= '$one_day_ago' && tags.createdTime <= '$current_date']")

# Loop through the resource groups
for resource_group in $(echo "${resource_groups}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${resource_group} | base64 --decode | jq -r ${1}
    }

    # Get the resource group name
    resource_group_name=$(_jq '.name')

    # Get the creator's identity
    creator_identity=$(_jq '.tags.createdBy')

    # Add the tag with the creator's identity
    az group update --name $resource_group_name --set tags.Creator=$creator_identity
done

