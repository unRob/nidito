# Configuration for nidito

Every `.yaml` file here contains configuration for different aspects of my home. Secrets are stored in 1password, and are marked with the `!!secret` yaml tag. Local manipulation is available with `milpa nidito config` commands. Home services also have access via op-connect and a vault plugin that reads from op-connect.

## How it works:

- one 1password (op) item per config file
- `password` field contains md5sum of source file
- one text field per value (secret or not)
- uses dot notation for keys, so these should only contain `[a-Z0-9_-]`
- arrays stored as `.index.`, i.e. `.0.`
- non-string scalar types (bool, int, float, and null) stored as under the `~annotations` section with the same key name

`milpa nidito config` contains commands to manipulate the config.
