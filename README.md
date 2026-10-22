# abliteration-cc

Run **Claude Code** against [abliteration.ai](https://docs.abliteration.ai/integrations/claude-code)'s
refusal-ablated model inside a **network-isolated throwaway container**, without touching your normal
Claude Code install/subscription on the host.

The point of this util is the containment, not the model: the abliterated backend is a public service,
and this wraps it so a no-guardrails agent can't reach anything it shouldn't.

## Isolation guarantees (verified empirically)

The container runs on a dedicated Docker network (`ablnet`, `172.29.0.0/24`) that can reach **only the
public internet**. Blocked: cloud metadata/IMDS (`169.254.0.0/16`), the whole Tailscale range
(`100.64.0.0/10`, including the host's own tailnet IP), `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`.
No host secrets are mounted; only the one abliteration API key is injected as an env var. The launcher
re-asserts the firewall rules on every run, so isolation survives host reboots.

## Setup

1. Put your abliteration API key at `~/.secrets/abliteration_api_key` (file contents = the `ak_...` key).
2. `docker build -t abliteration-cc:latest .`
3. Install the launcher: `install -m755 abliteration-cc ~/bin/abliteration-cc` (ensure `~/bin` is on PATH).

The launcher creates the `ablnet` network and firewall rules itself (needs passwordless `sudo iptables`).

## Usage

```bash
abliteration-cc                      # interactive CC on the abliterated model, scratch dir ~/abliteration-work
ABL_WORK=/path/to/dir abliteration-cc   # mount a specific dir at /work
ABL_RO=1 ABL_WORK=/path abliteration-cc # mount it read-only
abliteration-cc                      # runs with --dangerously-skip-permissions (safe here: isolated, no creds)
abliteration-cc -p "summarize README.md"         # headless
```

Runs with `--dangerously-skip-permissions` by default (CC's root check is satisfied via `IS_SANDBOX=1`); this is intentional because the container is isolated and holds no credentials.

Model: `abliterated-model-large-v2[1m]` (Claude Code prints a cosmetic `unrecognized_model` warning;
the request still succeeds). Config comes from `ANTHROPIC_BASE_URL=https://api.abliteration.ai` plus the
injected `ANTHROPIC_AUTH_TOKEN`.

## Notes / caveats

- **Mounting a sensitive dir re-introduces risk.** Network isolation holds, but the agent has open
  internet egress, so anything you mount (source, uncommitted secrets) is readable/exfiltratable by a
  model with no refusals. Prefer a clean checkout; strip plaintext secrets first.
- Git does not work *inside* the container when you mount a git **worktree** (its gitdir lives outside
  the mount). Edit in the container, review/commit from the host. A standalone clone works in-container.

## Teardown

```bash
docker rmi abliteration-cc:latest
docker network rm ablnet
docker volume rm ablclaude
rm ~/bin/abliteration-cc
sudo iptables -S DOCKER-USER | grep 172.29.0.0/24   # then -D each rule; same for INPUT
```
