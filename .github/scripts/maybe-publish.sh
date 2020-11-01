#!/bin/sh

package=$(cat package.json | jq -r .name)
local_version=$(cat package.json | jq -r .version)
yarn info $package --json | jq -r '.data.versions | values[] as $v | $v' | grep -E "^${local_version}$"
not_upstream=$?

if [ $not_upstream -eq 1 ]
then
  yarn publish
fi
