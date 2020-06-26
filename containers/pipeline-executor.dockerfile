# Tooling configuration files
FROM scratch AS context

ADD sources/sdk/pacman/package.json \
    sources/sdk/pacman/yarn.lock \
    sources/sdk/pacman/.eslintrc
    /workspace/

# Source code
FROM scratch AS sources

ADD sources/sdk/pacman/src /workspace/src

# Unit tests
FROM scratch AS tests

ADD tests/sdk/pacman/ /workspace/tests

# Install dependencies
FROM node:alpine AS dependencies

COPY --from=context /workspace/package.json /workspace/package.json
COPY --from=context /workspace/yarn.lock /workspace/yarn.lock
WORKDIR /workspace

RUN yarn install --network-timeout 300000 --production

# Install dev dependencies
FROM node:alpine AS dev-dependencies

COPY --from=dependencies /workspace /workspace
WORKDIR /workspace

RUN yarn install --network-timeout 300000

# Lint
FROM node:alpine AS linter

COPY --from=context /workspace /workspace
COPY --from=dev-dependencies /workspace/node_modules /workspace/node_modules
COPY --from=sources /workspace/src /workspace/src
WORKDIR /workspace

RUN yarn run lint

# Build application
FROM node:alpine AS builder

COPY --from=context /workspace /workspace
COPY --from=dev-dependencies /workspace/node_modules /workspace/node_modules
COPY --from=sources /workspace/src /workspace/src
WORKDIR /workspace

RUN yarn run build

# Run test suite
FROM node:alpine AS test

COPY --from=context /workspace /workspace
COPY --from=dev-dependencies /workspace/node_modules /workspace/node_modules
COPY --from=builder /workspace/dist /workspace/dist
COPY --from=tests /workspace/tests /workspace/tests
WORKDIR /workspace

RUN yarn run test

# Final artifact
FROM node:alpine AS runner

COPY --from=context /workspace/package.json /workspace/package.json
COPY --from=dependencies /workspace/node_modules /workspace/node_modules
COPY --from=builder /workspace/dist /workspace/dist
WORKDIR /workspace

ENV PACMAN_MANIFEST_PATH ".datapio/index.js"
ENV PACMAN_WORKSPACE_PVC "workspace-pvc"

ENV VAULT_ADDR "http://127.0.0.1:8200"
ENV VAULT_ROLE "default"
ENV VAULT_K8S_MOUNT_POINT ""
ENV K8S_JWT ""

CMD [ "yarn", "start" ]
