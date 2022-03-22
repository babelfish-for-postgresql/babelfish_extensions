#!/usr/bin/env bash

# Remove AWS/RDS references from code

set -e

BASEDIR=$(dirname $0)
BASENAME=$(basename $0)

# This breaks if you try running the script from a different checkout, which stinks, so don't do it...
#cd $BASEDIR

count () (

POSITIONAL_ARGS=()
ANTIPATTERNS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -a|--anti-pattern)
      ANTIPATTERNS+=("$2")
      shift
      shift
      ;;
    -f|--filter)
      FILTER="$2"
      shift
      shift
      ;;
    -o|--only)
      ONLY="$2"
      shift
      shift
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [ -n "$FILTER" -a -n "$ONLY" ]; then
    echo "ERROR: --filter and --only may not be used togother" >&2
    exit 9
fi

set -- "${POSITIONAL_ARGS[@]}"

# replace commas in the filter with a space
FILTER=(${FILTER//,/ })
for file in ${FILTER[@]}; do
    formatted_filter+=" :!$file"
done

ONLY=(${ONLY//,/ })
for file in ${ONLY[@]}; do
    formatted_filter+=" :$file"
done

search=$1
shift
options="$@"

if [ "$formatted_filter" == "" ]; then
    excludes=":!$BASENAME :!*.jar"
else
    excludes=":!$BASENAME :!*.jar $formatted_filter"
fi

result=0

matches=$(git grep --line-number $options "$search" -- $excludes) || result=$?
if [[ $result -lt 0 || $result -gt 1 ]]; then
    echo ERROR: The following grep command failed: "git grep --line-number $options "$search" -- $excludes"
    exit $result
fi

for (( i=0; i<"${#ANTIPATTERNS[@]}" && $result == 0; i++ )) do
    antipattern="${ANTIPATTERNS[$i]}"

    # each match has the following format: "file/path:line-number:match-text"
    # grepping against ".*:.*:.*$antipattern" allows us to apply the
    # anti-pattern to only the match-text portion
    matches=$(grep -v ".*:.*:.*$antipattern" <<< "$matches") || result=$?
    if [[ $result -lt 0 || $result -gt 1 ]]; then
        echo ERROR: grep failed when trying to apply an antipattern
        exit $result
    fi
done

# if matches is empty, using "wc -l" returns 1, but match_count should be 0 in this case
if [[ "$matches" == "" ]]; then
    match_count=0
else
    match_count=$(wc -l <<< "$matches")
fi

if [[ $match_count -ne 0 ]]; then
    declare -A files
    while IFS= read -r line; do
        filename=$(cut -d: -f1 <<< "$line")
        files["$filename"]=1
    done <<< "$matches"
    file_count=${#files[@]}

    echo "'$search' found $match_count times in $file_count files:"

    while IFS= read -r line; do
        echo "$line"
    done <<< "$matches"

    printf '\n'
else
    printf "No references to '$search' found.\n\n"
    exit 0
fi

exit 1
)

printf '\nScanning the project for critical keywords...\n\n'

retcode=0

# Note: anti-patterns provided with -a are evaluated as basic regular expressions.
# As such, special characters within anti-patterns will need to be escaped. See
# https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap09.html#tag_09_03
# for info about special characters in basic regular expressions

count Aurora -i || retcode=1
count APG -a 'INSTR_TSQL_' || retcode=1
count Grover -i || retcode=1
count CSD -a CSDYjzmOlGRVuXfMf9yaEyW79cY1ALOGxfSJX9ZcyxTo7pquQAJSNheiNXXfjOa5JKdG5uwUi25e6ea83 || retcode=1
count '\<CP\>' || retcode=1
count brazil -i -a '// Portuguese: Brazil' -a 'PORTUGUESE (BRAZIL)' -a "            'BRAZILIAN'" -a "            'BRAZIL'," || retcode=1
count Manfred -i || retcode=1 # Will also catch RDSManfred and RDSManfredBabel
count RDSSUSET -i || retcode=1 # Will also catch PGC_RDSSUSET
count rds_superuser -i || retcode=1
count rds-jira -i || retcode=1
count '\(\<\|_\)rds.' -i -e || retcode=1
count rdsadmin -i || retcode=1
count 'rds_' -i -a 'WORDS_' -a 'is_transform_noise_words_on' || retcode=1

# Will also catch "Amazon Web Services"
count Amazon -i -f MAINTAINERS.md,.github/ISSUE_TEMPLATE/bug.yaml,.github/ISSUE_TEMPLATE/enhancement.yaml,.github/ISSUE_TEMPLATE/question.yaml,CODE_OF_CONDUCT.md,CONTRIBUTING.md,SECURITY.md -a 'Copyright (c)' -a 'Copyright Amazon' -a 'Amazon Linux 2 environment' || retcode=1

count '\<AWS\>' -f MAINTAINERS.md,SECURITY.md,CONTRIBUTING.md -a 'Portions Copyright (c)' || retcode=1

if [ $retcode -ne 0 ]; then
  printf '\nERROR: Critical keywords were found in the project files. Please remove them and re-run this script\n'
fi

if ! git status | grep 'nothing to commit, working tree clean'; then
    printf '\nERROR: your git working tree is not clean. Showing git status...\n\n'
    git status
    exit 1
fi

exit $retcode
