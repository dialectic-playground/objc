# Toolchain image for dialectic-playground/objc: Objective-C (container-first; see tools/dp-run).
#
# Objective-C with Foundation (GNUstep Base; Apple Foundation on macOS); build and package tool:
# GNUstep Make; formatter: clang-format. Official base image pinned by multi-architecture index
# digest, plus make, python3 (for the curriculum's black-box runner), and clang-format (make lint /
# make format; Debian trixie ships 19.1.7, the release line pinned natively). Dependabot (docker)
# refreshes the digest; moving to a new release line is a deliberate change (keep
# `make toolchain` and the native CI in step).
FROM docker.io/library/debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

# Debian keeps only the current version of each package, so apt versions cannot be pinned
# reproducibly; the base image is pinned by digest instead.
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends gobjc gnustep-make libgnustep-base-dev make python3 clang-format \
    && rm -rf /var/lib/apt/lists/*

ENV DP_IN_CONTAINER=1
