# aws-action-to-managed-policies

```
❯ aws-action-to-managed-policies.sh -h
Name
  aws-action-to-managed-policies.sh - search aws managed policies by action

SYNOPSIS
  aws-action-to-managed-policies.sh [-hlspfvd] [-- GREP_OPTIONS] WORD

  -l
    remove cached managed policy list

  -s
    remove cached managed policies

  -p
    --prune-list and --prune-policies

  -f
    download policy list and policies

  -v
    display matched actions

  -d
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
