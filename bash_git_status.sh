#!/usr/bin/env bash

# colors used in the prompt
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[1;34m'
COLOR_ORANGE='\033[38;5;95;38;5;208m'
COLOR_RESET='\033[0m'
# show info about what kind of repo we're in
# some code and ideas from:
# - http://zanshin.net/2012/03/09/wordy-nerdy-zsh-prompt/
# - https://github.com/sjl/oh-my-zsh/commit/3d22ee248c6bce357c018a93d31f8d292d2cb4cd
# - https://github.com/magicmonty/bash-git-prompt
function repo_status() {
    git_status_porcelain=$(git status --porcelain --untracked-files=all --branch 2>/dev/null)
    if [ "$?" -eq 0 ]; then
        git_dir=$(git rev-parse --git-dir)
        # count occurrences of each case
        git_num_conflict=0
        git_num_modified=0
        git_num_untracked=0
        git_num_staged=0
        while IFS='' read -r line; do
            XY=${line:0:2}
            case "$XY" in
                \#\#) git_branch_line="${line:3}" ;;
                U?)     ((git_num_conflict++)) ;;  # unmerged
                ?U)     ((git_num_conflict++)) ;;  # unmerged
                DD)     ((git_num_conflict++)) ;;  # unmerged (both deleted)
                AA)     ((git_num_conflict++)) ;;  # unmerged (both added)
                ?[MDT]) ((git_num_modified++)) ;;  # modified/deleted/typechange in working tree
                \?\?)   ((git_num_untracked++)) ;; # untracked in index and working tree
            esac
            case "$XY" in
                [MARCD]?) ((git_num_staged++)) ;; # modified/added/renamed/copied/deleted in index
            esac
        done <<< "$git_status_porcelain"

        # figure out local and remote branch, and ahead/behind/diverged
        if [[ "$git_branch_line" =~ Initial\ commit\ on\ (.+) ]]; then
            # "Initial commit on master"
            git_branch="|${COLOR_BLUE}${BASH_REMATCH[1]}${COLOR_RESET}"
            git_remote_status="${COLOR_BLUE}-${COLOR_RESET}"
        elif [[ "$git_branch_line" =~ no\ branch ]]; then
            # "HEAD (no branch)"
            git_tag=$(git describe --exact-match 2>/dev/null)
            if [ -n "$git_tag" ]; then
                git_branch="▹${COLOR_BLUE}$git_tag${COLOR_RESET}"
                # TODO: how to tell if tag has been pushed
            else
                git_commit_hash=$(git rev-parse --short HEAD)
                git_branch=":${COLOR_BLUE}$git_commit_hash${COLOR_RESET}"
            fi
            git_remote_status="${COLOR_BLUE}-${COLOR_RESET}"
        else
            # "master...origin/master [ahead 8]"
            # "master...origin/master [behind 12]"
            # "master...origin/master [ahead 1, behind 7]"
            git_branch_arr=(${git_branch_line//.../ })
            git_branch="|${COLOR_BLUE}${git_branch_arr[0]}${COLOR_RESET}"
            git_branch_arr=("${git_branch_arr[@]:1}") # remove the branch from the array
            # remote tracking branch
            if [[ ${git_branch_arr[0]} ]]; then
                git_origin=${git_branch_arr[0]}
                git_upstream=${git_origin/origin/upstream}
                git_branch_arr=("${git_branch_arr[@]:1}") # remove the remote branch from the array
                git_ahead_behind="${git_branch_arr[*]}" # combine array elements
                if [[ "$git_ahead_behind" =~ ahead\ ([0-9]+) ]]; then
                    git_ahead="${COLOR_BLUE}${BASH_REMATCH[1]}${COLOR_RESET}⇧"
                fi
                if [[ "$git_ahead_behind" =~ behind\ ([0-9]+) ]]; then
                    git_behind="${COLOR_BLUE}${BASH_REMATCH[1]}${COLOR_RESET}⇩"
                fi
                # difference between origin and upstream for forked repos
                if [[ ! $(ps) =~ git\ remote\ update ]]; then
                    nohup git remote update >/dev/null 2>&1 &
                fi
                git_rev_list=$(git rev-list --count --left-right ${git_origin}..${git_upstream} 2>/dev/null)
                if [ "$?" -eq 0 ]; then
                    git_fork_arr=($git_rev_list) # will split into array because it's 2 numbers separated by spaces
                    if [ "${git_fork_arr[0]}" -gt 0 ]; then
                        git_fork_ahead="${COLOR_BLUE}${git_fork_arr[0]}${COLOR_RESET}"
                    fi
                    if [ "${git_fork_arr[1]}" -gt 0 ]; then
                        git_fork_behind="${COLOR_BLUE}${git_fork_arr[1]}${COLOR_RESET}"
                    fi
                    if [ "$git_fork_ahead" ] || [ "$git_fork_behind" ]; then
                        git_fork_status="${git_fork_ahead}⑂${git_fork_behind}"
                    fi
                fi
                if [ "$git_behind" ] || [ "$git_ahead" ] || [ "$git_fork_status" ]; then
                    git_remote_stat_arr=($git_behind $git_ahead $git_fork_status)
                    local IFS=' '
                    git_remote_status="${git_remote_stat_arr[*]}"
                else
                    # all sync-ed up
                    git_remote_status="${COLOR_BLUE}✓${COLOR_RESET}"
                fi
            else
                # local branch with no remote tracking
                git_remote_branches=$(git branch -r)
                if [ "$git_remote_branches" ]; then
                    git_remotes_arr=($git_remote_branches)
                    git_excludes_arr=()
                    for r in "${git_remotes_arr[@]}"; do
                        if [[ "$r" != "->" ]]; then
                            git_excludes_arr+=("^$r")
                        fi
                    done
                    git_excludes=$(IFS=' ' ; echo "${git_excludes_arr[*]}")
                fi
                # figure out how many commits exist on this branch that are not in the remotes
                git_local_commits=$(git rev-list --count HEAD ${git_excludes} 2>/dev/null)
                if [ "$?" -eq 0 ] && [ "$git_local_commits" -gt 0 ]; then
                    git_remote_status="${COLOR_BLUE}$git_local_commits${COLOR_RESET}⇪"
                else
                    git_remote_status="${COLOR_BLUE}-${COLOR_RESET}"
                fi

            fi
        fi

        git_stash_list=$(git stash list)

        if [ "$git_num_staged" -gt 0 ]; then
            git_staged="${COLOR_GREEN}$git_num_staged${COLOR_RESET}⊕"
        fi
        if [ "$git_num_modified" -gt 0 ]; then
            git_modified="${COLOR_ORANGE}$git_num_modified${COLOR_RESET}⊛"
        fi
        if [ "$git_num_untracked" -gt 0 ]; then
            git_untracked="${COLOR_YELLOW}$git_num_untracked${COLOR_RESET}⍰"
        fi
        if [ "$git_num_conflict" -gt 0 ]; then
            git_conflict="${COLOR_RED}$git_num_conflict${COLOR_RESET}⚠"
        fi
        if [ "$git_stash_list" ]; then
            git_num_stashed=0
            while IFS='' read -r line; do
                ((git_num_stashed++))
            done <<< "$git_stash_list"
            # TODO: icon for stashed
            git_stashed="${COLOR_YELLOW}$git_num_stashed${COLOR_RESET}<stashed>"
        fi
        if [ -d "$git_dir/rebase-apply" ] || [ -d "$git_dir/rebase-merge" ]; then
            if [ -f "$git_dir/rebase-apply/head-name" ]; then
                git_rebase_head="$(cat "$git_dir/rebase-apply/head-name")"
            elif [ -f "$git_dir/rebase-merge/head-name" ]; then
                git_rebase_head="$(cat "$git_dir/rebase-merge/head-name")"
            else
                git_rebase_head="!!"
            fi
            # TODO: strip out everything in front of the branch name
            # TODO: icon for rebase
            git_rebase="${COLOR_RED}$git_rebase_head${COLOR_RESET}<rebase>"
        fi
        if [ -f "$git_dir/MERGE_HEAD" ]; then
            git_merge_head="$(cat "$git_dir/MERGE_HEAD")"
            git_merge_branch="$(git branch --no-color --contains "$git_merge_head")"
            if [ "$git_merge_branch" ]; then
                git_merge_name="${git_merge_branch/\*/ }"
            else
                git_merge_name="${git_merge_head:0:8}"
            fi
            # TODO: icon for merge
            git_merge="${COLOR_RED}$git_merge_name${COLOR_RESET}<merge>"
        fi
        if [ "$git_staged" ] || [ "$git_modified" ] || [ "$git_untracked" ] || [ "$git_conflict" ] || [ "$git_stashed" ] || [ "$git_rebase" ] || [ "$git_merge" ]; then
            git_stat_arr=($git_staged $git_modified $git_untracked $git_conflict $git_stashed $git_rebase $git_merge)
            local IFS=' '
            git_local_status="${git_stat_arr[*]}"
        else
            git_local_status="${COLOR_GREEN}✓${COLOR_RESET}"
        fi

        echo -e "  ${COLOR_BLUE}git${COLOR_RESET}$git_branch $git_remote_status / $git_local_status"
    elif [ -d .svn ]; then
        svn_info=$(svn info 2>/dev/null)
        svn_path=$( ( [[ "$svn_info" =~ URL:\ ([^$'\n']+) ]] && echo ${BASH_REMATCH[1]} ) || echo '?' )
        svn_protocol=$(expr "$svn_path" : '\([a-z]\+://\)') # remove the svn:// or https:// from the start of the repo
        svn_revision=$( [[ "$svn_info" =~ Revision:\ ([0-9]+) ]] && echo ${BASH_REMATCH[1]} )
        svn_stat=$(svn status 2>/dev/null)
        svn_dirty=$( ( [[ "$svn_stat" =~ [?!AM]([[:space:]]+[^$'\n']+) ]] && echo 'dirty' ) || echo "${COLOR_GREEN}✓${COLOR_RESET}" )
        echo -e "  ${COLOR_BLUE}svn${COLOR_RESET}|${COLOR_BLUE}${svn_path#$svn_protocol}${COLOR_RESET}@${COLOR_BLUE}$svn_revision${COLOR_RESET} $svn_dirty"
    else
        echo ''
    fi
}

