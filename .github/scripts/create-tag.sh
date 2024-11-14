#!/usr/bin/bash

set -e

# Set user name and email
git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"

export usage="$(basename "$0") [-h] [-c commit] [-r repo][-m]\n
  -h    help\n
  -c    commit hash; Default commit:HEAD\n
  -t    tag name"


while getopts hc:t:m flag
do
    case "${flag}" in
        h) echo -e "Usage: $usage"
            exit;;
        c) commit=${OPTARG};;
        t) new=${OPTARG};;
    esac
done

# get current commit hash for tag if not provided
if [ -z "$commit" ]
then
    commit=$(git rev-parse HEAD)
fi

# if tagname is not provided, exit
if [ -z "$new" ]
then
    echo "Error: Tag not provided!"
    exit 1
fi

# check the tag format (need manual update when necessary)
format=BABEL_
if ! [[ "$new" =~ "$format"[0-9]_[0-9]+_[0-9] ]]
then
    echo "Error: Invalid tag prefix, expected: ${format}<digit>_<number>_<digit>"
    exit 1
fi

echo Creating tag $new for commit $commit

git tag -a "${new}" $commit -m "${message}"
git push origin "${new}"
