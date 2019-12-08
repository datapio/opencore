#!/bin/sh

query() {
    db=$1
    shift

    case $db in
        git)
            git $@
            ;;

        datapio)
            yq r -j datapio.yml | jq $@
            ;;

        *)
            exit 1
            ;;
    esac
}

main() {
    source=$(query git rev-parse --abbrev-ref HEAD)
    envs=$(query datapio -r ".environments|keys[]" | xargs)
    match=""

    for env in $envs
    do
        target=$(query datapio -r ".environments.$env.branch")
        if [ $source == $target ]
        then
            match="$env"
            break
        fi
    done

    if [ "x$match" != "x" ]
    then
        artifacts=$(query datapio ".artifacts" | yq r - | sed 's/^/    /')
        version=$(query git rev-parse HEAD)

        cat > release.yml <<EOF
---
apiVersion: datap.io/v1
kind: Release
metadata:
  name: release-${version}
spec:
  version: ${version}
  resource: ${RESOURCE_NAME}
  environment: ${match}
  artifacts:
${artifacts}
EOF

        kubectl apply -f release.yml
    fi
}

main
