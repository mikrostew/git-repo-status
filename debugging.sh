#!/usr/bin/env bash

#################### Debugging & Profiling ####################

# trace the calls that are made to git
debug_repo_status_call_trace() {
    ( set -x; repo_status 2>&1 | grep " git " )
}

# figure out how long the individual functions take to run
debug_repo_status_function_time() {
    somevar="doesn't matter"
    somevar1="doesn't matter"
    somevar2="doesn't matter"
    git_status_porcelain=$(git status --porcelain --untracked-files=normal --branch 2>/dev/null)
    git_dir="$(git rev-parse --git-dir)"
    gs_parse_branch_line git_branch_info "$git_status_porcelain"
    gs_git_head_origin git_head git_head_nocolor git_origin "$git_branch_info"

    # for sed here, only print the "real   0m0.001s" line
    sed_args=( '-n' '/real/ p' )

    # formatting so things line up nicely
    report_format="%-40s %s\n"

    # can refactor this stuff to a loop, but whatever
    printf "$report_format" \
      "repo_status()" \
      "$( ( time repo_status ) 2>&1 | sed "${sed_args[@]}" )"

    printf "$report_format" \
      "git status --porcelain --unormal" \
      "$( ( time git status --porcelain --untracked-files=normal --branch 2>/dev/null) 2>&1 | sed "${sed_args[@]}" )"

    printf "$report_format" \
      "git status --porcelain --uno" \
      "$( ( time git status --porcelain --untracked-files=no --branch 2>/dev/null) 2>&1 | sed "${sed_args[@]}" )"

    printf "$report_format" \
      "gs_parse_branch_line()" \
      "$( ( time gs_parse_branch_line somevar $git_status_porcelain ) 2>&1 | sed "${sed_args[@]}" )"

    printf "$report_format" \
      "rs_git_stash()" \
      "$( ( time rs_git_stash somevar $git_dir ) 2>&1 | sed "${sed_args[@]}" )"

    printf "$report_format" \
      "rs_git_backup_refs()" \
      "$( ( time rs_git_backup_refs somevar $git_dir ) 2>&1 | sed "${sed_args[@]}" )"

    printf "$report_format" \
      "rs_git_rebase()" \
      "$( ( time rs_git_rebase somevar $git_dir ) 2>&1 | sed "${sed_args[@]}" )"

    printf "$report_format" \
      "rs_git_merge()" \
      "$( ( time rs_git_merge somevar $git_dir ) 2>&1 | sed "${sed_args[@]}" )"

    printf "$report_format" \
      "rs_git_bisect()" \
      "$( ( time rs_git_bisect somevar $git_dir ) 2>&1 | sed "${sed_args[@]}" )"

    printf "$report_format" \
      "rs_git_local_status()" \
      "$( ( time rs_git_local_status somevar $git_dir "$git_status_porcelain" ) 2>&1 | sed "${sed_args[@]}" )"

    printf "$report_format" \
      "gs_git_head_origin()" \
      "$( ( time gs_git_head_origin somevar somevar1 somevar2 "$git_branch_info" ) 2>&1 | sed "${sed_args[@]}" )"

    printf "$report_format" \
      "rs_git_reviewid()" \
      "$( ( time rs_git_reviewid somevar "$git_head_nocolor" ) 2>&1 | sed "${sed_args[@]}" )"

    printf "$report_format" \
      "gs_git_remote_status()" \
      "$( ( time gs_git_remote_status somevar "$git_head_nocolor" "$git_origin" ) 2>&1 | sed "${sed_args[@]}" )"
}
