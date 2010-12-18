#!/bin/bash

PROD_NAME=TenTwenty.osirixplugin
DEV_BUILD=${PWD}/build/Development/${PROD_NAME}

PLUGIN_DIR="${HOME}/Library/Application Support/Osirix/Plugins"

pushd "${PLUGIN_DIR}"

if [ -e ${PROD_NAME} ]
	then
			rm -rf ${PROD_NAME}
fi

ln -s ${DEV_BUILD}
popd
