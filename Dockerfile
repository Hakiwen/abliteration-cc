FROM debian:stable-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
      curl ca-certificates git ripgrep less jq procps iproute2 \
    && rm -rf /var/lib/apt/lists/*
# Install Claude Code via the official native installer
RUN curl -fsSL https://claude.ai/install.sh | bash || true
# Installer drops the binary under ~/.local/bin; make sure it's on PATH
ENV PATH="/root/.local/bin:/root/.claude/local:${PATH}"
WORKDIR /work
CMD ["bash"]
