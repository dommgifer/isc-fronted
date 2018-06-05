FROM ubuntu:16.04
MAINTAINER jeffxie@iii.org.tw
WORKDIR /home

ENV JAVA_HOME=/home/jdk \
    WORK_DIR=/home/localadmin \
    KEYTOOL=/home/jdk/bin/keytool \
    GF_CONFIG=/opt/glassfish/glassfish/domains/domain1/config \
    GF_PASS=changeit \
    KEYSIZEZ=2048 \
    MAX_DAYS=7300 \
    ALIAS_NAME="glassfish-instance s1as" \
    GLASSFISH_PATH=/opt/glassfish \
    GFADMIN=/opt/glassfish/bin/asadmin \
    PASS=iServCloudGlassFish! \
    PASS_FILE=/tmp/pass.txt \
    JDBC=com.mysql.jdbc.jdbc2.optional.MysqlDataSource \
    POOL=iSoftCloudDataSource \
    WARS="BusinessSystem iServCloud" \ 
    GFOPTS="--user admin --passwordfile /tmp/pass.txt --secure=false --host 127.0.0.1"

COPY public/jdk-7u79-linux-x64.tar.gz \
     public/glassfish-4.0-ml.zip \
     public/mysql-connector-java-5.1.39-bin.jar /home/
COPY frontend/ /home/localadmin/frontend/
#COPY template/ frontend/template/
COPY template/front_web.xml.tmpl frontend/template/web.xml
#COPY conf/allone_deploy.conf /home/localadmin/conf/
COPY certs/ /home/localadmin/certs/


RUN apt-get update && \
    apt-get install -y apt-utils tar unzip inotify-tools && \
    rm -rf /var/lib/apt/lists/* && \
    tar xfz /home/jdk-7u79-linux-x64.tar.gz && \
    ln -s -f /home/jdk1.7.0_79 /home/jdk && \
    ln -s -f /home/jdk/bin/java /usr/local/bin/java && \
    unzip -o -q -d /opt /home/glassfish-4.0-ml.zip && \
    ln -s -f /opt/glassfish4 /opt/glassfish && \
    rm -f /home/jdk-7u79-linux-x64.tar.gz && \
    rm -f /home/glassfish-4.0-ml.zip && \
    mkdir -p $WORK_DIR/certs && \
    mkdir -p $WORK_DIR/update/frontend && \
    mv /home/mysql-connector-java-5.1.39-bin.jar /opt/glassfish/glassfish/lib/ && \
    echo "AS_JAVA=/home/jdk" >> /opt/glassfish/glassfish/config/asenv.conf && \
    mv /home/localadmin/frontend/*.txt /home/localadmin/update/frontend/ && \
    #mv /home/frontend/template/front_web.xml.tmpl /home/frontend/template/web.xml && \
    #glassfish key create
    for ALIAS in $ALIAS_NAME ; do \
        #echo "=== Check $ALIAS keystore ==="
        $KEYTOOL -list -v -alias $ALIAS -storepass $GF_PASS -keystore /home/localadmin/certs/$ALIAS.jks; \
        #echo "=== Import self-keystore into Glassfish's keystore ==="
        $KEYTOOL -importkeystore -noprompt -srcstorepass $GF_PASS -srckeystore /home/localadmin/certs/$ALIAS.jks -deststorepass $GF_PASS -destkeystore $GF_CONFIG/keystore.jks ; \ 
    done && \
    #echo "=== Check Glassfish keystore ==="
    $KEYTOOL -list -storepass $GF_PASS -keystore $GF_CONFIG/keystore.jks && \
    echo "AS_ADMIN_MASTERPASSWORD=$GF_PASS" > $PASS_FILE && \
    echo "AS_ADMIN_NEWMASTERPASSWORD=$PASS" >> $PASS_FILE  && \
    $GFADMIN --passwordfile $PASS_FILE change-master-password --savemasterpassword=true && \
    chmod 600 $GF_CONFIG/domain-passwords && \
    /bin/rm -r -f $PASS_FILE

COPY docker-entrypoint.sh /usr/local/bin/

EXPOSE 8080 4848 8181
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["/opt/glassfish/bin/asadmin", "start-domain", "--verbose"]

