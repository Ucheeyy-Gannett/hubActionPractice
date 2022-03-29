#!/bin/bash

# Checks whether a repository has CHANGELOG.md.
# Checks that each commit to the repository is updated in the CHANGELOG.md.
# The CHANGELOG version number is updated in the format # 1.0.2, # 12.3.10, # 1.10.1
#Checks that there is jira ticket number associated with the commit.

#Checking if CHANGELOG.md exists
#echo "Checking for CHANGELOG.md"

if [ ! -f "CHANGELOG.md" ]
then
    echo "::error::CHANGELOG file NOT FOUND"
    exit 1
else
    echo "CHANGELOG.md  found"
fi

## Checks if there is version number.
## The version here could be any number of digits provided defined in the following order:
## 1.0.0, # 20.5.1, # 1.203.4

version=$(egrep -o "# [0-9]{1,}\.[0-9]{1,}\.[0-9]{1,}" CHANGELOG.md)

if [[ -z "${version}" ]];
then
    echo -e "\CHANGELOG.md must have a version number.\n"
    exit
    else
    echo -e "\Available Version numbers listed below.\n"
    echo "$version"
fi

## Check if jira ticket number is documented.
## This will identify the most recent jira ticket.
 jira_ticket=$(git log main.. --oneline --no-merges | egrep -o [A-Z]*-[0-9]* CHANGELOG.md)

    if [[ -z "${jira_ticket}"  ]]
    then
        echo -e "\nCommit-log is missing a Jira ticket number.\n"
        exit 1
    else
        echo -e "\nJira ticket from commit-log is <${jira_ticket}>\n"
    fi

#echo -e "\nPull-Request files are excellent.\n"

#################################################

#
 if [[ -z "${version_line}"  ]]; then
      echo "::error::CHANGELOG.md must have an updated version number. Git diff didn't show changes"
      else
      echo "version is updated"
      exit 1
  fi

version_line_old=$(head -20 CHANGELOG.md | grep -Eo -m 2 "# [0-9].*[0-9]*.[0-9]*" | awk 'FNR == 2 {print $2}')
echo $version_line_old

  if [[ -z "${version_line_old}"  ]]; then
      echo "::error::There is no old version number in CHANGELOG.md, weird."
      exit 1
  fi

version_num=$(echo ${version_line} | grep -Eo [0-9].*[0-9]*.[0-9]*)

  #check_format

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
        echo "::error::CHANGELOG.md version must be incremented. Main version: $old_version_num, $GITHUB_REF version: $version_num"
        exit 1
      elif [[ ${new_version_split[2]} -lt ${old_version_split[2]} ]];then
        echo "::error::CHANGELOG.md version must be incremented. Main version: $old_version_num, $GITHUB_REF version: $version_num"
        exit 1
      fi
    elif [[ ${new_version_split[1]} -lt ${old_version_split[1]} ]];then
      echo "::error::CHANGELOG.md version must be incremented. Main version: $old_version_num, $GITHUB_REF version: $version_num"
      exit 1
    fi
    # output version
    echo "::set-output name=new_version::$version_num"
    echo "::notice::Version: $version_num"
  elif [[ ${new_version_split[0]} -lt ${old_version_split[0]} ]];then
    echo "::error::CHANGELOG.md version must be incremented. Main version: $old_version_num, $GITHUB_REF version: $version_num"
    exit 1
  fi