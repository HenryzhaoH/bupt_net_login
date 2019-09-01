#!/bin/sh

USERNAME=2015000000
PASSWORD=123456
# Mode: ISP or CAMPUS
MODE=ISP
# ISP_LINE: CUC-BRAS, CMCC-BRAS, CT-BRAS, __none__ for default, [empty] for original gateway (use mode CAMPUS instead)
ISP_LINE=CUC-BRAS

INTERFACE=ens160
CHECK_IP=0
LOG_FILE=/var/log/bupt_net_login.log

CHECK_INTERVAL=120
MAX_FAIL_TIMES=100

SERVICE_URL_ISP=http://cu.byr.cn
SERVICE_URL_CAMPUS=http://gw.bupt.edu.cn

current_fail_time=0

# Check function. Echo 1 if passed, Echo 0 if failed.
check()
{
    if [ $MODE = "ISP" ]; then
        echo `curl -s --output - $SERVICE_URL_ISP/index | grep '<div class="login-success"' | wc -l`
    fi
    if [ $MODE = "CAMPUS" ]; then
        echo `curl -s --output - $SERVICE_URL_CAMPUS/index | grep '<div class="login-success"' | wc -l`
    fi
}

login()
{
    echo "`date` - Login $MODE..." | tee -a $LOG_FILE
    if [ $MODE = "ISP" ]; then
        curl -s $SERVICE_URL_ISP/login --data "user=$USERNAME&pass=$PASSWORD&line=$ISP_LINE" -o /dev/null -s
    fi
    if [ $MODE = "CAMPUS" ]; then
        curl -s $SERVICE_URL_CAMPUS/login --data "user=$USERNAME&pass=$PASSWORD" -o /dev/null -s
    fi
    if [ `check` -ne "1" ]; then
        echo "`date` - $MODE Login failed. Please check username/password." | tee -a $LOG_FILE
    fi
}

init()
{
    current_ip=`ip addr show dev $INTERFACE | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1`
    echo "`date` - Mode: $MODE" | tee -a $LOG_FILE
    if [ $MODE = "ISP" ]; then
        echo "`date` - Using line: $ISP_LINE" | tee -a $LOG_FILE
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
