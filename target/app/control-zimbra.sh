#!/bin/bash

case "$1" in

    start)
        service supervisor start
        service cron start
        service ssh start

        if [ ! -f "/.dont_start_zimbra" ]; then

            # start Zimbra services
            service zimbra start
            sudo -u zimbra -- /opt/zimbra/bin/zmauditswatchctl start

            # stop the certificate updater service, if it is running
            if [ -f "/run/tls-cert-updater.pid" ]; then
                TLS_UPDATER_PID=`cat /run/tls-cert-updater.pid`
                kill $TLS_UPDATER_PID > /dev/null 2>&1
                rm -f /run/tls-cert-updater.pid
            fi

            # start the certificate updater service (needs Zimbra to be running)
            /bin/bash -c '
                source /app/venv/bin/activate
                python3 /app/tls-cert-updater.py &> /var/log/tls-cert-updater.py &
                echo -n $! > /run/tls-cert-updater.pid
            '
        fi
        ;;

    stop)
        # stop the certificate updater service
        if [ -f "/run/tls-cert-updater.pid" ]; then
            TLS_UPDATER_PID=`cat /run/tls-cert-updater.pid`
            kill $TLS_UPDATER_PID > /dev/null 2>&1
            rm -f /run/tls-cert-updater.pid
        fi

        # stop Zimbra services
        if [ ! -f "/.dont_start_zimbra" ]; then
            sudo -u zimbra -- /opt/zimbra/bin/zmauditswatchctl stop
            service zimbra stop
        fi

        service ssh stop
        service cron stop
        service supervisor stop
        ;;

    reload)
        # TODO
        ;;
  esac
