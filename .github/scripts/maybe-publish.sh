#!/bin/sh

package=$1
local_version=$(cat package.json | jq -r .version)
upstream_versions=$(yarn info $package --json | jq -r '.data.versions | values[] as $v | $v')
echo $upstream_version | grep $local_version
not_upstream=$?
if [ $not_upstream -eq 1 ]
then
  yarn publish
fi