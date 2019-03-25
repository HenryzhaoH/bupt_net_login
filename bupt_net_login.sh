#!/bin/sh

USERNAME=2015000000
PASSWORD=123456
# Mode: NGW or 211
MODE=NGW
# NGW_LINE: CUC-BRAS, CMCC-BRAS, CT-BRAS, __none__ for default, [empty] for original gateway (use mode 211 instead)
NGW_LINE=CUC-BRAS

INTERFACE=ens160
CHECK_IP=0
LOG_FILE=/var/log/bupt_net_login.log

CHECK_INTERVAL=120
MAX_FAIL_TIMES=100

SERVICE_URL_NGW=http://ngw.bupt.edu.cn
SERVICE_URL_211=http://10.3.8.211

current_fail_time=0

# Check function. Echo 1 if passed, Echo 0 if failed.
check()
{
    if [ $MODE = "NGW" ]; then
        echo `curl -s --output - $SERVICE_URL_NGW/index | grep '<div class="login-success"' | wc -l`
    fi
    if [ $MODE = "211" ]; then
        echo `curl -s --output - $SERVICE_URL_211 | grep ';flow=' | wc -l`
    fi
}

login()
{
    echo "`date` - Login $MODE..." | tee -a $LOG_FILE
    if [ $MODE = "NGW" ]; then
        curl -s $SERVICE_URL_NGW/login --data "user=$USERNAME&pass=$PASSWORD&line=$NGW_LINE" -o /dev/null -s
        sleep 5
        # Logout 211 for other devices.
        curl -s $SERVICE_URL_211/F.html
    fi
    if [ $MODE = "211" ]; then
        curl -s $SERVICE_URL_211/ --data "DDDDD=$USERNAME&upass=$PASSWORD&0MKKey=" -o /dev/null -s
    fi
    if [ `check` -ne "1" ]; then
        echo "`date` - $MODE Login failed. Please check username/password." | tee -a $LOG_FILE
    fi
}

init()
{
    current_ip=`ip addr show dev $INTERFACE | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1`
    echo "`date` - Mode: $MODE" | tee -a $LOG_FILE
    if [ $MODE = "NGW" ]; then
        echo "`date` - Using line: $NGW_LINE" | tee -a $LOG_FILE
    fi
    echo "`date` - Account: $USERNAME" | tee -a $LOG_FILE
    echo "`date` - Check interval: $CHECK_INTERVAL" | tee -a $LOG_FILE
    echo "`date` - Current IP: $current_ip" | tee -a $LOG_FILE
    
    if [ $CHECK_IP -eq "1" ]; then
        if [[ ${current_ip:0:3} != "10." ]]; then
            echo "`date` - IP Check failed, exit." | tee -a $LOG_FILE
            exit 1
	    fi
    fi

    echo "`date` - Script started." | tee -a $LOG_FILE
}

init

if [ `check` -ne "1" ]; then
    login
fi

while true
do
    sleep $CHECK_INTERVAL
    #echo "`date` - Checking..." | tee -a $LOG_FILE
    if [ `check` -ne "1" ]
    then
        echo "`date` - Check failed `expr $current_fail_time + 1` time(s)." | tee -a $LOG_FILE
        if [ $current_fail_time -eq $MAX_FAIL_TIMES ]; then
            echo "`date` - Max fail times exceeded, exit!" | tee -a $LOG_FILE
            exit 1
        fi
        current_fail_time=`expr $current_fail_time + 1`
	    login
    else
        echo "`date` - Check passed." | tee -a $LOG_FILE
        current_fail_time=0
    fi
done 
