FROM quay.io/operator-framework/ansible-operator:v0.17.1

COPY sources/operators/pipelinerunserver/requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible

COPY sources/operators/pipelinerunserver/watches.yaml ${HOME}/watches.yaml

COPY sources/operators/pipelinerunserver/roles/ ${HOME}/roles/
