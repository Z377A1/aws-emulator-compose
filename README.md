# AWS Emulator via Docker Compose

Compose setup for [Getting started with Docker](https://docs.aws.amazon.com/emulator/latest/userguide/getting-started-docker.html).

## Setup

1. Optional: `cp .env.example .env` and edit (Arm CPU → `EMULATOR_ARCH=aarch64`; Linux → set `UID`/`GID` from `id -u`/`id -g`).
2. Create the shared directory (required on Linux, or Docker makes it root-owned):
   - macOS/Linux: `mkdir -p ~/.aws/emulator`
   - PowerShell: `New-Item -ItemType Directory -Force "$env:USERPROFILE\.aws\emulator"`
3. `docker compose up --build` (add `-d` to run in the background).

Stop with Ctrl+C or `docker compose down`. Emulated resources live in memory and are lost on stop.

## Shell into the container

While the emulator is running, open another terminal and run:

```sh
docker compose exec aws-emulator /bin/sh
```

Exit the shell with `exit`.

## AWS CLI in the container

The image includes [AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), already set up to use the emulator (see `environment` in `compose.yaml`). You don't need to install or configure anything on the host:

```sh
docker compose exec aws-emulator aws sts get-caller-identity   # account 000000000000
docker compose exec aws-emulator aws s3 mb s3://my-bucket
```

Or run `aws` from a shell inside the container.

## Point your SDK at it

PowerShell (replace 9297 if you changed `EMULATOR_PORT`):

```powershell
$env:AWS_ENDPOINT_URL = "https://127.0.0.1:9297"
$env:AWS_SHARED_CREDENTIALS_FILE = "$env:USERPROFILE\.aws\emulator\9297\emulator_credentials"
$env:AWS_CONFIG_FILE = "$env:USERPROFILE\.aws\emulator\9297\config"
$env:AWS_CA_BUNDLE = "$env:USERPROFILE\.aws\emulator\9297\ca.pem"
$env:AWS_EC2_METADATA_DISABLED = "true"
$env:AWS_DISABLE_HOST_PREFIX_INJECTION = "true"
$env:AWS_REGION = "us-east-1"
$env:AWS_DEFAULT_REGION = "us-east-1"
Remove-Item Env:AWS_ACCESS_KEY_ID, Env:AWS_SECRET_ACCESS_KEY, Env:AWS_SESSION_TOKEN, Env:AWS_PROFILE -ErrorAction SilentlyContinue
```

macOS/Linux:

```sh
export AWS_ENDPOINT_URL=https://127.0.0.1:9297
export AWS_SHARED_CREDENTIALS_FILE=~/.aws/emulator/9297/emulator_credentials
export AWS_CONFIG_FILE=~/.aws/emulator/9297/config
export AWS_CA_BUNDLE=~/.aws/emulator/9297/ca.pem
export AWS_EC2_METADATA_DISABLED=true
export AWS_DISABLE_HOST_PREFIX_INJECTION=true
export AWS_REGION=us-east-1 AWS_DEFAULT_REGION=us-east-1
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE
```

Check: `curl --cacert ~/.aws/emulator/9297/ca.pem https://127.0.0.1:9297/__admin/health` → `ok`, and `aws sts get-caller-identity` should show account `000000000000`.

Node.js needs `NODE_EXTRA_CA_CERTS`, Rust/.NET need `SSL_CERT_FILE` (both → `ca.pem`); Java uses `truststore.p12`.

## Notes

- The port is bound to `127.0.0.1` only. Keep host and container ports equal (`EMULATOR_PORT`); never use port 0.
- To run several emulators, use separate project names and ports, e.g. `EMULATOR_PORT=9300 docker compose -p emu9300 up`.
- Telemetry data lives in the named volume `telemetry`, not the bind mount. Its SQLite `-shm` file crashes the emulator (exit 135) on Docker Desktop bind mounts after the first run. Set `EMULATOR_TELEMETRY=off` to opt out.
- Remove: `docker compose down --rmi all -v`, and optionally delete `~/.aws/emulator`.
