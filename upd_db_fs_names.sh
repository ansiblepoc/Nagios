#!/bin/ksh
#
# Script: upd_db_fs_names.sh
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
NAGIOS_SERVER="yournagiosxiserver"
config_dir="/usr/local/nagios/etc/services"
check_nrpe_dir="/usr/local/nagios/libexec"
scripts_dir="/root/scripts/jpl"
apikey="yourapikey"
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
#getting a fresh list from the target database node
${check_nrpe_dir}/check_nrpe -H ${DB_NAME} -c check_fs_list |grep ${DB_NAME} > /tmp/dbfslist.$PROGRAM
exec 4<&0
exec 4</tmp/dbfslist.$PROGRAM
while read -u4 dbfsname
do
curl -XPOST "http://${NAGIOS_SERVER}/nagiosxi/api/v1/config/service?apikey=${apikey}&pretty=1" -d "host_name=${DB_NAME}&service_description=File%20System%20${dbfsname}&check_command=check_nrpe\!check_disk\!%20\-a%20\'\-w%2010\%%20\-c%205\%%20${dbfsname}\'&check_interval=5&retry_interval=1&max_check_attempts=5&check_period=xi_timeperiod_24x7&contacts=nagiosadmin&notification_interval=60&notification_period=xi_timeperiod_24x7"
done
#apply configuration
curl -XPOST "http://${NAGIOS_SERVER}/nagiosxi/api/v1/system/applyconfig?apikey=${apikey}"
