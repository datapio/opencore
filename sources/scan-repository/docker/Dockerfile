FROM lachlanevenson/k8s-kubectl:latest

ARG YQ_VERSION="2.4.1"

RUN apk add --no-cache jq git wget
RUN wget -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"

ADD scripts/read-datapio.sh /usr/local/bin/read-datapio

ENV RESOURCE_NAME="git-source"

ENTRYPOINT [ "/bin/sh" ]
CMD [ "/usr/local/bin/read-datapio" ]
