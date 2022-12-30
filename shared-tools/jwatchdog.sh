#!/usr/local/bin/bash
#
# simple monitor, originally for ELK but easily customized for other services
# change log
# 2021-11-10 - initial creation
# 2021-11-11 - variablized pushover tokens
# 2021-11-15 - take services from command-line arguments as well
# 2021-11-16 - if service=homeassistant, check the URL response - if nothing after a timeout, restart it

LOGDIR=${HOME}/logs
LOGFILE=${LOGDIR}/$(basename $0).log
SERVICES=${SERVICES:-"logstash elasticsearch kibana"}
PO_TOKEN="a3c7q6yh7qsto3mg6yb2v1uapf1v9n"
PO_USER="ud7hdmj21ot1b8y9u48rwvni7a159x"
# Specific services
HASSURL="https://homeassistant2.pa.jacix.net:8123"
CONNECTION_TIMEOUT=10

if test "$1"; then
    SERVICES="$*"
else
    SERVICES=${SERVICES:-"logstash elasticsearch kibana"}
fi

function err_exit() {
# report an error and run the help function to stderr, then exit. If no exit code is given, exit 1.
# Usage: err_exit "Err Message" exit_code
#  e.g.: error_return "Insufficient parameters" 2
        exit_message="${1:-'oops'}"
        exit_code=${2:-1}
        echo >&2
        logit "Fail: ${exit_message} - Exiting ${exit_code}."
        echo "Fail: ${exit_message} - Exiting ${exit_code}." >&2
        echo "---"
        printhelp >&2
        echo "Exiting" >&2
        exit ${exit_code}
}


function pfc(){
    test -d ${LOGDIR} || mkdir -p ${LOGDIR} || err_exit "Problem with logdir ${LOGDIR}"
    test -w ${LOGFILE} || touch ${LOGFILE} || err_exit "Problem with logfile ${LOGFILE}"
}

function send_callout(){
test "${1}" || echo "won't send empty callout" >> ${LOGFILE}
curl -s \
  --form-string "token=${PO_TOKEN}" \
  --form-string "user=${PO_USER}" \
  --form-string "message=${1}" \
  https://api.pushover.net/1/messages.json >> ${LOGFILE}
}


# main
pfc
echo "### $(date +%Y%m%d.%H%M.%S) - start" >> ${LOGFILE}

for service in ${SERVICES}; do
    if service ${service} status > /dev/null; then
        echo "OK: ${service} service" >> ${LOGFILE}
    else
        service ${service} start >> ${LOGFILE}
        send_callout "jwd: ${HOSTNAME} ${service} restarted"
    fi
# service-specific checks
	if test "${service}" == "homeassistant"; then
		if curl -Ss -m ${CONNECTION_TIMEOUT} ${HASSURL} > /dev/null; then
			echo "OK: ${service} connection" >> ${LOGFILE}
		else
			echo "${service} connect timeout. Restarting." >> ${LOGFILE}
			service ${service} restart
        	send_callout "jwd: ${HOSTNAME} ${service} timeout. restarted."
		fi
	fi
done


echo "######### $(date +%Y%m%d.%H%M.%S) - end" >> ${LOGFILE}
