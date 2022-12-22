#!/usr/bin/env bash


set -e


VFILE=contrib/babelfishpg_tsql/src/babelfish_version.h
if test -f "$VFILE"; then
    echo "Found $VFILE."
else
    echo "ERROR: Could not find the version file."
    echo "Please retry running the script from repo base directory"
    exit 1
fi


#update the internal version
export bbf_pre_version=$(awk '/BABELFISH_INTERNAL_VERSION_STR/ {print $4}' $vfile | sed 's/\"//')
sed -i -r 's/(.*)(BABELFISH_INTERNAL_VERSION_STR )"(Babelfish )([0-9]+.[0-9]+.)([0-9]+)(.[0-9]+)"/echo "\1\2\\"\3\4$((\5+1))\6\\""/ge' $vfile
export bbf_post_version=$(awk '/BABELFISH_INTERNAL_VERSION_STR/ {print $4}' $vfile | sed 's/\"//')

git commit -a -m "Bump Babelfish internal version from $bbf_pre_version to $bbf_post_version"

#update the extension version
export bbf_pre_version=$(awk '/BABELFISH_VERSION_STR/ {print $3}' $vfile | sed 's/\"//')
sed -i -r 's/(.*)(BABELFISH_VERSION_STR )"([0-9]+.[0-9]+.)([0-9]+)"/echo "\1\2\\"\3$((\4+1))\\""/ge' $vfile
export bbf_post_version=$(awk '/BABELFISH_VERSION_STR/ {print $3}' $vfile | sed 's/\"//')

git commit -a -m "Bump Babelfish version from $bbf_pre_version to $bbf_post_version"


