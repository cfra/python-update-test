#!/usr/bin/env bash
# This file:
#
#  - Update requirements only under specific conditions
#
# Usage:
#
#  ./bin/update-requirements.sh
#
# Based on a template by BASH3 Boilerplate v2.3.0
# http://bash3boilerplate.sh/#authors
#
# The MIT License (MIT)
# Copyright (c) 2013 Kevin van Zonneveld and contributors
# You are not obligated to bundle the LICENSE file with your b3bp projects as long
# as you leave these references intact in the header comments of your source files.

# Exit on error. Append "|| true" if you expect an error.
set -o errexit
# Exit on error inside any functions or subshells.
set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
set -o pipefail
# Turn on traces, useful while debugging but commented out by default
# set -o xtrace

GH_REPO="PicturePipe/hatch"
GH_USER_EMAIL="machine@picturepipe.com"
GH_USER_NAME="picturepipe-machine"

COMMITS=$(git rev-list --count HEAD ^origin/integration/prototype)

echo "Updating requirements."
make requirements.txt

if git diff --exit-code requirements.txt; then
    echo "Requirements unchanged."
    exit 0
fi

case "$CIRCLE_BRANCH" in
    renovate/*)
        echo "Detected renovate branch."
        if [ "${COMMITS}" != 1 ]; then
            echo "Detected more than one commit. Requirements update canceled."
            exit 1
        fi
        ;;
    *)
        echo "Current branch is not suitable for an automatic update."
        exit 1
        ;;
esac

git config --global user.email "${GH_USER_EMAIL}"
git config --global user.name "${GH_USER_NAME}"
git add requirements.txt
git commit --message="Recompile and upgrade production requirements"
git remote add origin-update "https://${GH_TOKEN}@github.com/${GH_REPO}.git"
git push --set-upstream origin-update HEAD:"${CIRCLE_BRANCH}"
