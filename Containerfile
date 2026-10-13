# Toolchain image for dialectic-playground/objc: Objective-C (container-first; see tools/dp-run).
#
# Objective-C with Foundation (GNUstep Base; Apple Foundation on macOS); build and package tool: GNUstep Make.
# Official base image pinned by multi-architecture index digest, plus make and python3 (for the
# curriculum's black-box runner). Dependabot (docker) refreshes the digest; moving to a new
# release line is a deliberate change (keep `make toolchain` and the native CI in step).
FROM docker.io/library/debian:trixie-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f

RUN apt-get update \
    && apt-get install -y --no-install-recommends gobjc gnustep-make libgnustep-base-dev make python3 \
    && rm -rf /var/lib/apt/lists/*

ENV DP_IN_CONTAINER=1
