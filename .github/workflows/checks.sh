#!/bin/bash

# verify CHANGELOG.md exists
echo "---> Checking for CHANGELOG.md"
if [[ ! -f "CHANGELOG.md"  ]]
then
    echo "::error::CHANGELOG file NOT FOUND"
    exit 1
fi

# verify CHANGELOG.md has a version that has been updated
echo "---> Checking for update to version in CHANGELOG.md"
if [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
    version_line=$( git diff refs/remotes/origin/master.. -- CHANGELOG.md | grep '^+# ' | head -1 )
elif [ "$GITHUB_EVENT_NAME" = "push" ] && [ "$GITHUB_REF" = "refs/heads/master" ]; then
    version_line=$( git diff  HEAD~1 -- CHANGELOG.md | grep '^+# ' | head -1 )
fi
if [[ -z "${version_line}"  ]]; then
    echo "::error::CHANGELOG.md must have an updated version number. Git diff didn't show changes"
    echo "::dump::Event name: $GITHUB_EVENT_NAME, and Ref: $GITHUB_REF"
    exit 1
fi

version_line_old=$(cat CHANGELOG.md | grep -Eo -m 2 "# [0-9].*[0-9]*.[0-9]*" | awk 'FNR == 2 {print $2}')
if [[ -z "${version_line_old}"  ]]; then
    echo "::error::There is no old version number in CHANGELOG.md, weird."
    exit 1
fi

# check that the version number provided is properly formatted
echo "---> Checking for properly formatted version in CHANGELOG.md"
version_num=$(echo ${version_line} | grep -Eo [0-9].*[0-9]*.[0-9]*)
if [[ -z "${version_num}"  ]]; then
    echo "::error::There is no old version number in CHANGELOG.md, weird."
    exit 1
fi

# check that the version number was actually increased
echo "---> Checking that the version number was incremented"

# split new version into an array
IFS='.' eval 'new_version_split=($version_num)'

# split old version into an array
old_version_num=$(echo ${version_line_old} | grep -Eo [0-9].*[0-9]*.[0-9]*)
IFS='.' eval 'old_version_split=($old_version_num)'

# check major
if [[ ${new_version_split[0]} -eq ${old_version_split[0]} ]];then
  # check minor
  if [[ ${new_version_split[1]} -eq ${old_version_split[1]} ]];then
    # check patch
    if [[ ${new_version_split[2]} -eq ${old_version_split[2]} ]];then
      echo "::error::CHANGELOG.md version must be incremented. master version: $old_version_num, $GITHUB_REF version: $version_num"
      exit 1
    elif [[ ${new_version_split[2]} -lt ${old_version_split[2]} ]];then
      echo "::error::CHANGELOG.md version must be incremented. master version: $old_version_num, $GITHUB_REF version: $version_num"
      exit 1
    fi
  elif [[ ${new_version_split[1]} -lt ${old_version_split[1]} ]];then
    echo "::error::CHANGELOG.md version must be incremented. master version: $old_version_num, $GITHUB_REF version: $version_num"
    exit 1
  fi
  # output version
  echo "::set-output name=new_version::$version_num"
  echo "::notice::Version: $version_num"
elif [[ ${new_version_split[0]} -lt ${old_version_split[0]} ]];then
  echo "::error::CHANGELOG.md version must be incremented. master version: $old_version_num, $GITHUB_REF version: $version_num"
  exit 1
fi

# Check that there's a Jira ticket-number in some message in the commit log
# Look only in the changelog for the PR branch - ignore commits from master
jira_ticket=`git log master.. --oneline --no-merges | grep -oP '[A-Z0-9]+-\d+' | head --lines=1`

if [[ -z "${jira_ticket}"  ]]
then
    echo -e "\nCommit-log is missing a Jira ticket number.\n"
    exit 1
else
    echo -e "\nJira ticket from commit-log is <${jira_ticket}>\n"
fi

echo -e "\nPull-Request files are excellent.\n"