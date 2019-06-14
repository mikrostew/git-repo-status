# shared testing code
# probably move this back into the file, but whatever for now

# create test repos in tmp directories
tmpdirname="$TMPDIR/tmp$RANDOM"

# for every test, initialize an empty repo, and cleanup after
setup() {
    mkdir "$tmpdirname"
    cd "$tmpdirname"
    git init
}
teardown() {
    cd ..
    rm -rf "$tmpdirname"
}

# the same string used by the main repo_status function
test_status() {
  git status --porcelain --untracked-files=normal --branch 2>/dev/null
}

# Compare the input strings and return the result. If strings differ, difference will be shown.
# arguments:
#  $1 - the expected string
#  $2 - the actual string
compare_status() {
    # these lines will only be shown if the test fails
    echo "Expected: '$1'" >&2
    echo "  Actual: '$2'" >&2
    echo "$(cmp -bl <(echo "$1") <(echo "$2") )" >&2
    # compare the strings and return the result
    [ "$1" = "$2" ]
    return
}

# Remove all but the remote status from the output line, and compare to expected
# arguments:
#  $1 - the expected status line
compare_remote_status() {
    local expected="$1"
    local actual="$(echo "${lines[0]}" | sed -e 's|[^ ]* ||' -e 's| /.*$||')"
    $(compare_status "$expected" "$actual")
    return
}


# functions for testing, because these things use `printf -v` instead of returning text on stdout

test_parse_branch_line() {
  gs_parse_branch_line branch_info "$(test_status)" && echo "$branch_info"
}

# return all 3 things, enclosed in single quotes, to simplify testing
test_git_head_origin() {
  gs_parse_branch_line git_branch_info "$(test_status)"
  # testing the 'git_head' output of this function:
  gs_git_head_origin git_head git_head_nocolor git_origin "$git_branch_info"
  echo "'$git_head' '$git_head_nocolor' '$git_origin'"
}

test_git_local_status() {
  git_dir=$(git rev-parse --git-dir)
  # testing the output of this function:
  rs_git_local_status git_local_status "$git_dir" "$(test_status)"
  echo "$git_local_status"
}

test_remote_status() {
  gs_parse_branch_line git_branch_info "$(test_status)"
  # testing the 'git_head' output of this function:
  gs_git_head_origin git_head git_head_nocolor git_origin "$git_branch_info"
  gs_git_remote_status git_remote_status "$git_head_nocolor" "$git_origin"
  echo "$git_remote_status"
}

