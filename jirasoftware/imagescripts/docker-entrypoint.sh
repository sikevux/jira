#!/bin/bash
#
# A helper script for ENTRYPOINT.
#
# If first CMD argument is 'jira', then the script will start jira
# If CMD argument is overriden and not 'jira', then the user wants to run
# his own process.

set -o errexit

if [ -n "${JIRA_DELAYED_START}" ]; then
  sleep ${JIRA_DELAYED_START}
fi

if [ -n "${JIRA_ENV_FILE}" ]; then
  source ${JIRA_ENV_FILE}
fi

if [ -n "${JIRA_PROXY_NAME}" ]; then
  xmlstarlet ed -P -S -L --insert "//Connector[not(@proxyName)]" --type attr -n proxyName --value "${JIRA_PROXY_NAME}" ${JIRA_INSTALL}/conf/server.xml
fi

if [ -n "${JIRA_PROXY_PORT}" ]; then
  xmlstarlet ed -P -S -L --insert "//Connector[not(@proxyPort)]" --type attr -n proxyPort --value "${JIRA_PROXY_PORT}" ${JIRA_INSTALL}/conf/server.xml
fi

if [ -n "${JIRA_PROXY_SCHEME}" ]; then
  xmlstarlet ed -P -S -L --insert "//Connector[not(@scheme)]" --type attr -n scheme --value "${JIRA_PROXY_SCHEME}" ${JIRA_INSTALL}/conf/server.xml
fi

if [ -n "${JIRA_LOGFILE_LOCATION}" ]; then
  TARGET_PROPERTY=1catalina.org.apache.juli.AsyncFileHandler.directory
  sed -i "/${TARGET_PROPERTY}/d" ${JIRA_INSTALL}/conf/logging.properties
  echo "${TARGET_PROPERTY} = ${JIRA_LOGFILE_LOCATION}" >> ${JIRA_INSTALL}/conf/logging.properties
  TARGET_PROPERTY=2localhost.org.apache.juli.AsyncFileHandler.directory
  sed -i "/${TARGET_PROPERTY}/d" ${JIRA_INSTALL}/conf/logging.properties
  echo "${TARGET_PROPERTY} = ${JIRA_LOGFILE_LOCATION}" >> ${JIRA_INSTALL}/conf/logging.properties
  TARGET_PROPERTY=3manager.org.apache.juli.AsyncFileHandler.directory
  sed -i "/${TARGET_PROPERTY}/d" ${JIRA_INSTALL}/conf/logging.properties
  echo "${TARGET_PROPERTY} = ${JIRA_LOGFILE_LOCATION}" >> ${JIRA_INSTALL}/conf/logging.properties
  TARGET_PROPERTY=4host-manager.org.apache.juli.AsyncFileHandler.directory
  sed -i "/${TARGET_PROPERTY}/d" ${JIRA_INSTALL}/conf/logging.properties
  echo "${TARGET_PROPERTY} = ${JIRA_LOGFILE_LOCATION}" >> ${JIRA_INSTALL}/conf/logging.properties
  mkdir -p ${JIRA_LOGFILE_LOCATION}
fi

if [ "$1" = 'jira' ]; then
  /bin/bash ${JIRA_SCRIPTS}/launch.sh
  /bin/bash ${JIRA_INSTALL}/bin/start-jira.sh -fg "$@"
fi

exec "$@"