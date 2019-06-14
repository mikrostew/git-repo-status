#!/usr/bin/env bats
# Test the functions

# need to make the functions available
source git-repo-status

load test-helper


# full status

@test "full status | empty repo" {
  run repo_status --no-color
  [ "$status" -eq 0 ]
  compare_status "master - / ✓" "${lines[0]}"
}

@test "full status | 1 commit no remote" {
  touch "newfile.txt"
  git add  "newfile.txt"
  git commit -m "Test commit"

  run repo_status --no-color
  [ "$status" -eq 0 ]
  compare_status "master 1⇪ / ✓" "${lines[0]}"
}

# parse branch line

@test "parse branch line | empty repo" {
  run test_parse_branch_line
  [ "$status" -eq 0 ]
  compare_status "No commits yet on master" "${lines[0]}"
}

@test "parse branch line | one commit" {
  touch "newfile.txt"
  git add  "newfile.txt"
  git commit -m "First commit"

  run test_parse_branch_line
  [ "$status" -eq 0 ]
  compare_status "master" "${lines[0]}"
}

@test "parse branch line | checkout hash" {
  touch "newfile.txt"
  git add  "newfile.txt"
  git commit -m "First commit"
  touch "newfile2.txt"
  git add  "newfile2.txt"
  git commit -m "Second commit"
  git checkout HEAD~1

  run test_parse_branch_line
  [ "$status" -eq 0 ]
  compare_status "HEAD (no branch)" "${lines[0]}"
}

@test "parse branch line | checkout tag" {
  touch "newfile.txt"
  git add  "newfile.txt"
  git commit -m "First commit"
  git tag "v1.0"
  touch "newfile2.txt"
  git add  "newfile2.txt"
  git commit -m "Second commit"
  git checkout "v1.0"

  run test_parse_branch_line
  [ "$status" -eq 0 ]
  compare_status "HEAD (no branch)" "${lines[0]}"
}

# parse head and origin

@test "parse head and origin | empty repo" {
  no_color=true run test_git_head_origin
  [ "$status" -eq 0 ]
  compare_status "'master' 'master' ''" "${lines[0]}"
}

@test "parse head and origin | empty repo, with remote" {
  # delete the initialized repo from setup
  rm -rf .git/
  git clone git@github.com:mikrostew/empty-repo-for-testing.git ./

  no_color=true run test_git_head_origin
  [ "$status" -eq 0 ]
  compare_status "'master' 'master' 'origin/master'" "${lines[0]}"
}

@test "parse head and origin | checkout hash" {
  touch "newfile.txt"
  git add  "newfile.txt"
  git commit -m "First commit"
  touch "newfile2.txt"
  git add  "newfile2.txt"
  git commit -m "Second commit"
  git checkout HEAD~1

  expected_hash="$(git rev-parse --short HEAD)"

  no_color=true run test_git_head_origin
  [ "$status" -eq 0 ]
  compare_status "'#$expected_hash' '' ''" "${lines[0]}"
}

@test "parse head and origin | checkout tag" {
  touch "newfile.txt"
  git add  "newfile.txt"
  git commit -m "First commit"
  git tag "v1.0"
  touch "newfile2.txt"
  git add  "newfile2.txt"
  git commit -m "Second commit"
  git checkout "v1.0"

  no_color=true run test_git_head_origin
  [ "$status" -eq 0 ]
  compare_status "'»v1.0' '' ''" "${lines[0]}"
}

# local status

@test "local status | untracked file" {
  touch "newfile.txt"

  no_color=true run test_git_local_status
  [ "$status" -eq 0 ]
  compare_status "1?" "${lines[0]}"
}

@test "local status | staged file" {
  touch "newfile.txt"
  git add "newfile.txt"

  no_color=true run test_git_local_status
  [ "$status" -eq 0 ]
  compare_status "1+" "${lines[0]}"
}

@test "local status | modified file" {
  touch "newfile.txt"
  git add -N "newfile.txt"

  no_color=true run test_git_local_status
  [ "$status" -eq 0 ]
  compare_status "1*" "${lines[0]}"
}

# remote status

@test "remote status | empty repo" {
  no_color=true run test_remote_status
  [ "$status" -eq 0 ]
  compare_status "-" "${lines[0]}"
}

@test "remote status | 1 commit, no remote" {
  touch "newfile.txt"
  git add  "newfile.txt"
  git commit -m "Test commit"

  no_color=true run test_remote_status
  [ "$status" -eq 0 ]
  compare_status "1⇪" "${lines[0]}"
}
