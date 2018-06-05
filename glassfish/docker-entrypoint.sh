#!/bin/bash

#set -e


#for ALIAS in $ALIAS_NAME ; do 
    #echo "=== Check $ALIAS keystore ==="
#    $KEYTOOL -list -v -alias $ALIAS -storepass $GF_PASS -keystore $WORK_DIR/certs/$ALIAS.jks
    #echo "=== Import self-keystore into Glassfish's keystore ==="
#    $KEYTOOL -importkeystore -noprompt -srcstorepass $GF_PASS -srckeystore $WORK_DIR/certs/$ALIAS.jks -deststorepass $GF_PASS -destkeystore $GF_CONFIG/keystore.jks ; done
    #echo "=== Check Glassfish keystore ==="
#    $KEYTOOL -list -storepass $GF_PASS -keystore $GF_CONFIG/keystore.jks
#    echo "AS_ADMIN_MASTERPASSWORD=$GF_PASS" > $PASS_FILE
#    echo "AS_ADMIN_NEWMASTERPASSWORD=$PASS" >> $PASS_FILE
#    $GFADMIN --passwordfile $PASS_FILE change-master-password --savemasterpassword=true
#    chmod 600 $GF_CONFIG/domain-passwords
#    /bin/rm -r -f $PASS_FILE

/opt/glassfish/bin/asadmin start-domain 

#FRONT_DB_NAME=$FRONT_DB_NAME

echo "AS_ADMIN_PASSWORD=" > $PASS_FILE
GFOPTS="--user admin --passwordfile /tmp/pass.txt --secure=false --host 127.0.0.1"

echo "$GFADMIN $GFOPTS create-jdbc-connection-pool --restype javax.sql.DataSource --datasourceclassname $JDBC --steadypoolsize=16 --maxpoolsize=100 --property User=$FRONT_DB_USER:Password=$FRONT_DB_PASS:URL="jdbc\:mysql\://$ALL_HOST\:3306/$FRONT_DB_NAME\?characterEncoding\=utf-8" $FRONT_DB_NAME" > $PASS_FILE
$GFADMIN $GFOPTS create-jdbc-connection-pool --restype javax.sql.DataSource --datasourceclassname $JDBC --steadypoolsize=16 --maxpoolsize=100 --property User=$FRONT_DB_USER:Password=$FRONT_DB_PASS:URL="jdbc\:mysql\://$ALL_HOST\:3306/$FRONT_DB_NAME\?characterEncoding\=utf-8" $FRONT_DB_NAME
$GFADMIN $GFOPTS create-jdbc-resource --connectionpoolid $FRONT_DB_NAME jdbc/$POOL
$GFADMIN $GFOPTS list-jdbc-connection-pools
$GFADMIN $GFOPTS list-jdbc-resources

$GFADMIN $GFOPTS delete-jvm-options "-client"
$GFADMIN $GFOPTS delete-jvm-options "-Xmx512m"
$GFADMIN $GFOPTS delete-jvm-options "-XX\:MaxPermSize=192m"

$GFADMIN $GFOPTS create-jvm-options "-server"
$GFADMIN $GFOPTS create-jvm-options "-verbose\:gc"
#$GFADMIN $GFOPTS create-jvm-options "-XX\:NewRatio=2"
$GFADMIN $GFOPTS create-jvm-options "-XX\:MaxPermSize=256m"
$GFADMIN $GFOPTS create-jvm-options "-Xmx1536m"
$GFADMIN $GFOPTS create-jvm-options "-Xms1536m"
$GFADMIN $GFOPTS create-jvm-options "-XX\:+UseConcMarkSweepGC"
$GFADMIN $GFOPTS create-jvm-options "-XX\:SoftRefLRUPolicyMSPerMB=1"
$GFADMIN $GFOPTS create-jvm-options "-XX\:+DisableExplicitGC"
$GFADMIN $GFOPTS list-jvm-options

$GFADMIN $GFOPTS set configs.config.server-config.thread-pools.thread-pool.admin-thread-pool.max-queue-size=256
$GFADMIN $GFOPTS set configs.config.server-config.thread-pools.thread-pool.admin-thread-pool.max-thread-pool-size=50
$GFADMIN $GFOPTS set configs.config.server-config.thread-pools.thread-pool.http-thread-pool.max-queue-size=10240
$GFADMIN $GFOPTS set configs.config.server-config.thread-pools.thread-pool.http-thread-pool.max-thread-pool-size=200
$GFADMIN $GFOPTS set configs.config.server-config.thread-pools.thread-pool.thread-pool-1.max-thread-pool-size=200
$GFADMIN $GFOPTS set configs.config.server-config.network-config.network-listeners.network-listener.admin-listener.address=127.0.0.1

$GFADMIN $GFOPTS set-log-attributes com.sun.enterprise.server.logging.GFFileHandler.maxHistoryFiles=30
$GFADMIN $GFOPTS set-log-attributes com.sun.enterprise.server.logging.GFFileHandler.rotationOnDateChange=true
$GFADMIN $GFOPTS list-log-attributes

for APP in $WARS ; do
    COUNT=5
    while [ "$COUNT" -gt "0" ] ; do
        RES=`$GFADMIN $GFOPTS list-applications | grep $APP`
        if [ ! "$RES" = "" ] ; then
            break
        fi
        echo "deploy $APP: $COUNT"
        COUNT=$[COUNT-1]
        WARFILE=$WORK_DIR/frontend/${APP}.war
        #$GFADMIN undeploy $APP
        $GFADMIN $GFOPTS deploy --force=true --contextroot $APP --properties keepSessions=true $WARFILE
        sleep 1
    done
done
$GFADMIN $GFOPTS list-applications
#/opt/glassfish/bin/asadmin stop-domain 
if [ "$MONITOR_HOST" = "" ] ; then
    MONITOR_HOST=$ALL_HOST
fi

CLOUD_TYPE=`echo "$CLOUD_TYPE" | awk '{print toupper($0)}'`
if [ "$CLOUD_TYPE" = "" -o "$CLOUD_TYPE" = "PUBLIC" ] ; then
    CLOUD_TYPE=Public
else
    CLOUD_TYPE=Private
fi

if [ ! "$ROLE_LEVEL" = "2" ] ; then
    ROLE_LEVEL="3"
fi

STORAGE_TYPE=`echo "$STORAGE_TYPE" | awk '{print toupper($0)}'`
if [ "$STORAGE_TYPE" = "CEPH" ] ; then
    STORAGE_TYPE=Ceph
else
    STORAGE_TYPE=NAS
fi

if [ "$FRONT_DB_NAME" = "" ] ; then
    FRONT_DB_NAME=iSoftCloudFrontEndDB
fi
if [ "$FRONT_DB_USER" = "" ] ; then
    FRONT_DB_USER=isoftcloud
fi
if [ "$FRONT_DB_PASS" = "" ] ; then
    FRONT_DB_PASS=openstack
fi

if [ "$ZBX_USER" = "" ] ; then
    ZBX_USER="Admin"
fi
if [ "$ZBX_PASS" = "" ] ; then
    ZBX_PASS="openstack123!@#"
fi

if [ "$AD_TYPE" = "" ] ; then
    AD_TYPE=none
fi
if [ "$AD_TYPE" = "none" ] ; then
    AD_ENABLE=false
else
    AD_ENABLE=true
fi

FNAME=/home/frontend/template/web.xml
sed -e "s,%KEYSTONE_HOST%,$ALL_HOST,g" -i $FNAME
sed -e "s,%KEYSTONE_PORT%,$KEYSTONE_PORT,g" -i $FNAME
sed -e "s,%KEYSTONE_ADMIN_PORT%,$KEYSTONE_ADMIN_PORT,g" -i $FNAME
sed -e "s,%III_URL%,$III_URL,g" -i $FNAME
sed -e "s,%FRONT_DB%,$ALL_HOST,g" -i $FNAME
sed -e "s,%BUSINESS_SYSTEM%,$ALL_HOST,g" -i $FNAME
sed -e "s,%MONITOR_HOST%,$MONITOR_HOST,g" -i $FNAME
sed -e "s,%ZABBIX_HOST%,$MONITOR_HOST,g" -i $FNAME
sed -e "s,%GLASSFISH_PORT%,$GLASSFISH_PORT,g" -i $FNAME
sed -e "s,%GLASSFISH_PORTS%,$GLASSFISH_PORTS,g" -i $FNAME
sed -e "s,%WEB_LB_HOST%,$ALL_HOST,g" -i $FNAME
sed -e "s,%FRONT_AP_HOSTS%,$ALL_HOST,g" -i $FNAME
sed -e "s,%APACHE_HTTP%,$APACHE_HTTP,g" -i $FNAME
sed -e "s,%FRONT_DB_NAME%,$FRONT_DB_NAME,g" -i $FNAME
sed -e "s,%FRONT_DB_USER%,$FRONT_DB_USER,g" -i $FNAME
sed -e "s,%FRONT_DB_PASS%,$FRONT_DB_PASS,g" -i $FNAME
ALLOW_HOSTS="127.0.0.1,$ALL_HOST"
if [ ! "$ALL_HOSTS" = "" ] ; then
    ALLOW_HOSTS="$ALLOW_HOSTS,$ALL_HOSTS"
fi
TMPVAL=`echo $ALLOW_HOSTS | sed "s/,/\\\\\\,/g"`
sed -e "s,%ALLOW_HOSTS%,$TMPVAL,g" -i $FNAME
sed -e "s,%PLATFORM_VERSION%,$PLATFORM_VERSION,g" -i $FNAME
sed -e "s,%DOMAIN_UUID%,$DOMAIN_UUID,g" -i $FNAME
sed -e "s,%ADMIN_PROJECT_UUID%,$ADMIN_PROJECT_UUID,g" -i $FNAME
sed -e "s,%ADMIN_USER_UUID%,$ADMIN_USER_UUID,g" -i $FNAME
sed -e "s,%CLOUD_TYPE%,$CLOUD_TYPE,g" -i $FNAME
sed -e "s,%ROLE_LEVEL%,$ROLE_LEVEL,g" -i $FNAME
sed -e "s,%ZBX_USER%,$ZBX_USER,g" -i $FNAME
sed -e "s,%ZBX_PASS%,$ZBX_PASS,g" -i $FNAME
sed -e "s,%STORAGE_TYPE%,$STORAGE_TYPE,g" -i $FNAME
if [ "$STORAGE_TYPE" = "Ceph" ] ; then
    sed -e "s,%CEPH_API_HOST%,$CEPH_API_HOST,g" -i $FNAME
    sed -e "s,%CEPH_API_PORT%,$CEPH_API_PORT,g" -i $FNAME
fi
sed -e "s,%ADenable%,$AD_ENABLE,g" -i $FNAME
sed -e "s,%ADType%,$AD_TYPE,g" -i $FNAME
sed -e "s,%ADHost%,$AD_HOST,g" -i $FNAME
sed -e "s,%ADAdminOU%,$AD_ADMIN_OU,g" -i $FNAME
TMPVAL=`echo $AD_BASEDN | sed "s/,/\\\\\\,/g"`
sed -e "s,%ADBaseDN%,$TMPVAL,g" -i $FNAME

#WARS="BusinessSystem"
#for WAR in $WARS ; do
#    cp -p $FNAME $GLASSFISH_PATH/glassfish/domains/domain1/applications/$WAR/WEB-INF/web.xml
#done
mv /home/frontend/template/web.xml /opt/glassfish/glassfish/domains/domain1/applications/BusinessSystem/WEB-INF/
#/opt/glassfish/bin/asadmin start-domain --verbose
SCHEDULER=Scheduler.jar
LIB_PATH=/opt/glassfish/glassfish/domains/domain1/applications/BusinessSystem/WEB-INF/lib
SCHEDULER_JAR=$LIB_PATH/$SCHEDULER
$JAVA_HOME/bin/java -jar $SCHEDULER_JAR > $WORK_DIR/log/scheduler.log 2>&1 &

/opt/glassfish/bin/asadmin stop-domain 

exec "$@"
