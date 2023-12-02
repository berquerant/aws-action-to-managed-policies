# aws-action-to-managed-policies

```
❯ aws-action-to-managed-policies.sh -h
Name
  aws-action-to-managed-policies.sh - search aws managed policies by action

SYNOPSIS
  aws-action-to-managed-policies.sh [--prune-list] [--prune-policies] [--prune] [--fetch] [--detail] [--verbose] [GREP_OPTIONS] WORD

  --prune-list
    remove cached managed policy list

  --prune-policies
    remove cached managed policies

  --prune
    --prune-list and --prune-policies

  --fetch
    download policy list and policies

  --detail
    display matched actions

  --dump
    display matched policy documents in the following format:

    {
      "policy": {
         "PolicyVersion": ...
      },
      "file": "AWS_A2P_CACHED/policies/POLICY_NAME.VERSION.json"
    }

ENVIRONMENT VARIABLES
  AWS_A2P_CACHED
    directory for caching policies

  AWS_CLI
    aws command

  JQ
    jq command
```
