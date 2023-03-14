#!/bin/bash

RELEASE_VERSION=
SKIP_ISSUEOPS=

while getopts ':st:' opt; do
  case "$opt" in
    s) SKIP_ISSUEOPS="true" ;;
    t) RELEASE_VERSION="$OPTARG" ;;
  esac
done

if [ "" == "$RELEASE_VERSION" ];then
  echo "Release tag not specified, fetching the latest version..."
  LATEST_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/planetscale/pscale-workflow-helper-scripts/releases/latest)
  RELEASE_VERSION=$(echo $LATEST_RELEASE | sed -e 's/.*"tag_name":"\([^"]*\)".*/\1/')
  echo "Found version ${RELEASE_VERSION}!"
else
  echo "Checking if version ${RELEASE_VERSION} exists..."
  TAG_RELEASE=$(curl -L -s -H 'Accept: application/json' https://github.com/planetscale/pscale-workflow-helper-scripts/releases/${RELEASE_VERSION})
  IS_ERROR=$(echo $TAG_RELEASE | sed -e 's/.*"error":"\([^"]*\)".*/\1/')
  if [ "Not Found" == "$IS_ERROR" ]; then
    echo "Cannot find version ${RELEASE_VERSION}."
    exit 1
  fi
fi

PSCALE_CLI_HELPER_SCRIPTS_NAME=pscale-workflow-helper-scripts
PSCALE_SCRIPTS_DIR=.pscale/

curl -L -o ${PSCALE_CLI_HELPER_SCRIPTS_NAME}.zip https://github.com/planetscale/pscale-workflow-helper-scripts/archive/refs/tags/${RELEASE_VERSION}.zip
unzip -o ${PSCALE_CLI_HELPER_SCRIPTS_NAME}.zip

# create .pscale directory
mkdir -p ${PSCALE_SCRIPTS_DIR}

# copy scripts to .pscale directory
cp -r ${PSCALE_CLI_HELPER_SCRIPTS_NAME}-${RELEASE_VERSION}/.pscale/cli-helper-scripts ${PSCALE_SCRIPTS_DIR}/

echo
echo "Successfully installed pscale-workflow-helper-scripts"
echo

if [ "true" != "${SKIP_ISSUEOPS}" ];then
  # create .github/workflows directory
  mkdir -p .github/workflows

  # copy workflow to .github/workflows directory
  cp ${PSCALE_CLI_HELPER_SCRIPTS_NAME}-${RELEASE_VERSION}/.github/workflows/*.yml .github/workflows/

  echo "Please run 'git add .pscale .github/workflows' and commit changes using 'git commit -m \"Add pscale helper scripts and IssueOps workflows\"'"
  echo "Then run 'git push' to push changes"
fi

# remove zip file and extracted directory
rm ${PSCALE_CLI_HELPER_SCRIPTS_NAME}.zip
rm -rf ${PSCALE_CLI_HELPER_SCRIPTS_NAME}-${RELEASE_VERSION}

echo
echo "All done!"
echo
