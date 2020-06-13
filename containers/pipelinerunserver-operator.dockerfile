FROM quay.io/operator-framework/ansible-operator:v0.17.1

COPY sources/operators/pipelinerunserver/requirements.yml ${HOME}/requirements.yml
COPY sources/operators/pipelinerunserver/python-deps.txt ${HOME}/python-deps.txt

RUN ansible-galaxy collection install -r ${HOME}/requirements.yml && \
    pip3 install -r ${HOME}/python-deps.txt && \
    chmod -R ug+rwx ${HOME}/.ansible

COPY sources/operators/pipelinerunserver/watches.yaml ${HOME}/watches.yaml

COPY sources/operators/pipelinerunserver/roles/ ${HOME}/roles/
