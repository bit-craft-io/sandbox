#!/bin/sh

/google/spanner/bin/spanner databases create local --deployment-endpoint=spanner-omni:15000 || true

echo "Setup complete!"