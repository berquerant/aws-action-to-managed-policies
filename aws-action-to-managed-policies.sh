#!/bin/bash

AWS_CLI="${AWS_CLI:-aws}"
JQ="${JQ:-jq}"

AWS_A2P_CACHED="${AWS_A2P_CACHED:-.aws-action-to-managed-policies}"
AWS_A2P_CACHE_LIST_POLICIES="${AWS_A2P_CACHED}/list.json"
AWS_A2P_CACHE_POLICYD="${AWS_A2P_CACHED}/policies"
AWS_A2P_GET_POLICY_INTERVAL="${AWS_A2P_GET_POLICY_INTERVAL:-0.1}"

__aws() {
    "$AWS_CLI" "$@"
}

__jq() {
    "$JQ" "$@"
}

list_policies() {
    __aws iam list-policies --scope AWS | __jq -c
}

cached_list_policies() {
    if [ -f "$AWS_A2P_CACHE_LIST_POLICIES" ] ; then
        cat "$AWS_A2P_CACHE_LIST_POLICIES"
    else
        mkdir -p "$AWS_A2P_CACHED"
        list_policies | tee "$AWS_A2P_CACHE_LIST_POLICIES"
    fi
}

remove_list_policies_cache() {
    echo rm -f "$AWS_A2P_CACHE_LIST_POLICIES"
}

get_policy() {
    sleep "$AWS_A2P_GET_POLICY_INTERVAL"
    __aws iam get-policy-version --policy-arn "$1" --version-id "$2" | __jq -c
}

batch_get_policies() {
    mkdir -p "$AWS_A2P_CACHE_POLICYD"
    __jq -c '.Policies[]' "$AWS_A2P_CACHE_LIST_POLICIES" |\
        while read policy ; do
            name="$(echo "$policy"|__jq -r '.PolicyName')"
            arn="$(echo "$policy"|__jq -r '.Arn')"
            version="$(echo "$policy"|__jq -r '.DefaultVersionId')"

            dest="${AWS_A2P_CACHE_POLICYD}/${name}.${version}.json"
            if [ -f "$dest" ] ; then
                echo "EXIST ${name} | ${arn} - ${version}" >&2
            else
                echo "GET ${name} | ${arn} - ${version}" >&2
                get_policy "$arn" "$version" > "$dest"
            fi
        done
}

remove_policies_cache() {
    echo rm -rf "$AWS_A2P_CACHE_POLICYD"
}

search_policy() {
    jq_query_action='.PolicyVersion.Document.Statement[].Action|if(type=="array") then . else [.] end|.[]'
    grep --files-with-matches -r "$@" "$AWS_A2P_CACHE_POLICYD" |\
        while read policy ; do
            if __jq -r "$jq_query_action" "$policy" | grep -q "$@" ; then
                echo "$policy"
            fi
        done
}

search_policy_dump() {
    search_policy "$@" |\
        while read policy ; do
            __jq --arg f "$policy" '{policy:.,file:$f}' "$policy"
        done
}

search_policy_detail() {
    search_policy "$@" |\
        while read policy ; do
            echo "$policy"
            __jq . "$policy" | grep "$@"
        done
}

usage() {
    cat - <<EOS
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
EOS
}

main() {
    set -eo pipefail

    if [ -z "$1" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        usage
        return
    fi

    clear_list_cache=0
    clear_policies_cache=0
    download_policies=0
    search_detail=0
    search_dump=0
    if [ "$1" = "--prune-list" ] ; then
        clear_list_cache=1
        shift
    fi
    if [ "$1" = "--prune-policies" ] ; then
        clear_policies_cache=1
        shift
    fi
    if [ "$1" = "--prune" ] ; then
        clear_list_cache=1
        clear_policies_cache=1
        shift
    fi
    if [ "$1" = "--fetch" ] ; then
        download_policies=1
        shift
    fi
    if [ "$1" = "--detail" ] ; then
        search_detail=1
        shift
    fi
    if [ "$1" = "--dump" ] ; then
        search_dump=1
        shift
    fi

    if [ "$clear_list_cache" = 1 ] ; then
        remove_list_policies_cache
    fi
    if [ "$clear_policies_cache" = 1 ] ; then
        remove_policies_cache
    fi
    if [ ! -d "$AWS_A2P_CACHED" ] || [ "$download_policies" = 1 ] ; then
        echo "it may take a while, ok? (y/N) >" >&2
        read  yn
        if [ "$yn" = "y" ] ; then
            batch_get_policies
        else
            exit 1
        fi
    fi
    if [ "$search_detail" = 1 ] ; then
        search_policy_detail "$@"
    elif [ "$search_dump" = 1 ] ; then
        search_policy_dump "$@"
    else
        search_policy "$@"
    fi
}

main "$@"
