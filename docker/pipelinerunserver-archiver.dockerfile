# Tooling configuration files
FROM scratch AS context

ADD sources/operators/pipelinerunserver/apps/archiver/package.json \
    sources/operators/pipelinerunserver/apps/archiver/yarn.lock \
    sources/operators/pipelinerunserver/apps/archiver/.eslintrc
    /workspace/

# Source code
FROM scratch AS sources

ADD sources/operators/pipelinerunserver/apps/archiver/src /workspace/src

# Unit tests
FROM scratch AS tests

ADD tests/operators/pipelinerunserver/apps/archiver/ /workspace/tests

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

# Run test suite
FROM node:alpine AS test

COPY --from=context /workspace /workspace
COPY --from=dev-dependencies /workspace/node_modules /workspace/node_modules
COPY --from=sources /workspace/src /workspace/src
COPY --from=tests /workspace/tests /workspace/tests
WORKDIR /workspace

RUN yarn run test

# Final artifact
FROM node:alpine AS runner

COPY --from=context /workspace/package.json /workspace/package.json
COPY --from=dependencies /workspace/node_modules /workspace/node_modules
COPY --from=sources /workspace/src /workspace/src
WORKDIR /workspace

ENV RABBITMQ_URL "amqp://localhost:5672"
ENV RABBITMQ_HISTORY_QUEUE "history"
ENV ARCHIVER_HISTORY_SIZE "10"

CMD [ "yarn", "start" ]
