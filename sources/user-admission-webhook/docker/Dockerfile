# Tooling configuration files
FROM scratch AS context

ADD package.json yarn.lock .eslintrc /workspace/

# Source code
FROM scratch AS sources

ADD src /workspace/src

# Unit tests
FROM scratch AS tests

ADD tests /workspace/tests

# Install dependencies
FROM node:alpine AS dependencies

COPY --from=context /workspace/package.json /workspace/package.json
COPY --from=context /workspace/yarn.lock /workspace/yarn.lock
WORKDIR /workspace

RUN yarn install --production

# Install dev dependencies
FROM node:alpine AS dev-dependencies

COPY --from=dependencies /workspace /workspace
WORKDIR /workspace

RUN yarn install

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

EXPOSE 8000
CMD [ "yarn", "run", "server" ]
