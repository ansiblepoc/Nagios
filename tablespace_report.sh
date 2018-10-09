database=yourdatabase
username=oracle_username_for_nagios
password=oracle_password_for_nagios
tablename=yourtablename
/usr/local/nagios/libexec/check_oracle_health --connect $database --mode tablespace-free  --username $username --password $password --name $tablename|grep MB|tr " " "\n"|cut -f1 -d";" 
