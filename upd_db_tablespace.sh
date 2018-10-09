#!/bin/ksh
#
# Script: upd_db_tablespace.sh
# Nagios Oracle Database Tablespace monitor
#
#

## Init Vars
PROGRAM_NAME=`basename $0`
PROGRAM=`basename $0 .sh`
HOSTNAME=$(/bin/hostname -s)

# Usage block
usage () {
                print "*\n* Usage: ${PROGRAM_NAME} DB_NAME TABLESPACES_NAME*"
                                print "*\t for example: ${PROGRAM_NAME} dbname USERS"

                                                exit 1
}

## Check to see if there are 1 arg
if [ $# -ne 1 ]
then
        # Params are incorrect - show usage and exit
        usage;
fi
NAGIOSUSER=nagios_oracle_username
NAGIOSPW=nagios_oracle_user_password
DB_NAME=$1
TABLESPACES_NAME=$2
NAGIOS_SERVER="nagiosxiserver"
config_dir="/usr/local/nagios/etc/services"
check_nrpe_dir="/usr/local/nagios/libexec"
scripts_dir="full path to the script"
apikey="apikey"
apipath="nagiosxi/api/v1"
contacts="nagiosadmin"
contact_groups="your_contact_group"
#service_description="Tablespace ${TABLESPACES_NAME} Free"
#service_description='Tablespace Free Space'
notification_period="xi_timeperiod_24x7"
notification_interval=60
notification_options=n
notifications_enabled=0
check_period="xi_timeperiod_24x7"
retry_interval=1
use="xiwizard_oracletablespace_service"
max_check_attempts=5
check_interval=900
#check_command="check_xi_oracletablespace!--connect ${DB_NAME} --username ${NAGIOSUSER} --password ${NAGIOSPW} --mode tablespace-free --name ${tablespaces} --warning 20: --critical 15:"
_xiwizard=oracletablespace
register=1
#See if there is an existing configuration file:
if [ ! -f ${config_dir}/${DB_NAME}.cfg ]
then
        echo "${config_dir}/${DB_NAME}.cfg does not exist!"
        echo "Please run add_ora_obj.sh first to create host object, ${DB_NAME}"
        exit 0
fi

if [ $? -ne 0 ]
then
        echo "NRPE cannot access ${DB_NAME}!"
        exit 101
fi
#get tablespaces 
${check_nrpe_dir}/check_oracle_health --connect ${DB_NAME} --mode list-tablespaces --user ${NAGIOSUSER} --password ${NAGIOSPW} |grep -Ev 'fun|TEMP|UNDOTBS1'>/tmp/tablespaces.$PROGRAM
exec 4<&0
exec 4</tmp/tablespaces.$PROGRAM
while read -u4 tablespaces
do
check_command="check_xi_oracletablespace!--connect ${DB_NAME} --username ${NAGIOSUSER} --password ${NAGIOSPW} --mode tablespace-free --name ${tablespaces} --warning 10: --critical 5:"
curl -XPOST "http://${NAGIOS_SERVER}/${apipath}/config/service?apikey=${apikey}&pretty=1" -d "host_name=${DB_NAME}&service_description=$tablespaces%20Free%20Space&check_command=$check_command}&check_interval=${check_interval}&retry_interval=${retry_interval}&max_check_attempts=${max_check_attempts}&check_period=${check_period}&contacts=${contacts}&notification_interval=${notification_interval}&notification_period=${notification_period}&notifications_enabled=${notifications_enabled}"
#curl -XDELETE "http://${NAGIOS_SERVER}/${apipath}/config/service?apikey=${apikey}&pretty=1&host_name=${DB_NAME}&service_description=Tablespace%20Free%20Space" 
done
#apply configuration
curl -XPOST "http://${NAGIOS_SERVER}/${apipath}/system/applyconfig?apikey=${apikey}"
