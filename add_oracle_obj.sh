#!/bin/ksh
#
# Script: add_oracle_obj.sh.sh
# check filesystem list and add missing filesystems to Nagios Services file
#
#

## Init Vars
PROGRAM_NAME=`basename $0`
PROGRAM=`basename $0 .sh`
HOSTNAME=$(/bin/hostname -s)

# Usage block 
usage () {
                print "*\n* Usage: ${PROGRAM_NAME} DATABASE_NAME *"
                                print "*\t for example: ${PROGRAM_NAME} qfddm"

                                                exit 1
}

## Check to see if there are 1 arg
if [ $# -ne 1 ]
then
        # Params are incorrect - show usage and exit
        usage;
fi

DB_NAME=$1
API_PATH="yournagiosxiservername/nagiosxi/api/v1"
config_dir="/usr/local/nagios/etc/services"
check_nrpe_dir="/usr/local/nagios/libexec"
scripts_dir="/root/scripts/jpl"
apikey="yourapikeyofauthorizedaccount"
address=`nslookup $1|tail -2|grep :|awk '{print $2}'`
echo ${address}
CURL_CA_BUNDLE=/etc/ssl/certs/ca-bundle.crt
#See if there is an existing configuration file:
if [ -f ${config_dir}/${DB_NAME}.cfg ]
then
        echo "${config_dir}/${DB_NAME}.cfg already exists!"
#       exit 1
fi


if [ $? -ne 0 ]
then
        echo "NRPE cannot access ${SERVER_NAME}!"
        exit 101
fi

#create database host objects
curl -k -XPOST "https://${API_PATH}/config/host?apikey=${apikey}&pretty=1" -d "host_name=${DB_NAME}&address=${address}&check_command=check_ping\!3000,80%\!5000,100%&max_check_attempts=2&check_period=24x7&contacts=nagiosadmin&notification_interval=5&notification_period=24x7&applyconfig=1"
#create database service Database status
curl -XPOST "http://${API_PATH}/config/service?apikey=${apikey}&pretty=1" -d "host_name=${DB_NAME}&service_description=Database%20status&check_command=check_nrpe\!check_procs\!%20\-a%20\'\-a%20ora_pmon_${DB_NAME}%20\-c%201\:\'&check_interval=5&retry_interval=1&max_check_attempts=5&check_period=xi_timeperiod_24x7&contacts=yourcontactgroup&notification_interval=60&contact_groups=yourcontactgroup&notification_period=xi_timeperiod_24x7"
#create database service Oracle internal errors
curl -XPOST "http://${API_PATH}/config/service?apikey=${apikey}&pretty=1" -d "host_name=${DB_NAME}&service_description=Oracle%20internal%20errors&check_command=check_nrpe\!check_singlepattern\!%20\-a%20\'\--logfile=/app/ora${DB_NAME}/diag/rdbms/${DB_NAME}/${DB_NAME}/trace/alert_${DB_NAME}.log%20\--criticalpattern=/\*ORA\-/\*\'&check_interval=5&retry_interval=1&max_check_attempts=5&check_period=xi_timeperiod_24x7&contacts=yourcontactgroup&notification_interval=60&contact_groups=yourcontactgroup&notification_period=xi_timeperiod_24x7"
#create database service listener status
curl -XPOST "http://${API_PATH}/config/service?apikey=${apikey}&pretty=1" -d "host_name=${DB_NAME}&service_description=Listener%20status&use=xiwizard_oracleserverspace_service&check_command=check_xi_oracleserverspace\!%20\--connect%20\'${DB_NAME}:1521/${DB_NAME}\'%20\--username%20\'nagios_username_in_oracle\'%20\--password%20\'ora_password_of_username_in_oracle\'%20\--mode%20tnsping%20\--warning%201%20\--critical%205\!\!\!\!\!\!\!&check_interval=1&retry_interval=1&max_check_attempts=5&check_period=xi_timeperiod_24x7&contacts=yourcontactgroup&notification_interval=60&contact_groups=yourcontactgroup&notification_period=xi_timeperiod_24x7&_xiwizard=oracleserverspace"
#apply configuration
curl -XPOST "http://${API_PATH}/system/applyconfig?apikey=${apikey}"
