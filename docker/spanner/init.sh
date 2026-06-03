#!/bin/bash
set -e

sleep 5

gcloud config set auth/disable_credentials true
gcloud config set project bc
gcloud config set api_endpoint_overrides/spanner http://spanner:9020/

gcloud spanner instances create sandbox \
  --config=emulator-config \
  --description="Local Instance" \
  --nodes=1 || true

gcloud spanner databases create local \
  --instance=sandbox || true

echo "Setup complete!"