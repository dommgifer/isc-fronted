#!/bin/bash

NGINX_OPENSTACK=/etc/nginx/openstack/site/openstack.conf
#HOST_IP="$(cat /etc/hosts | grep $(cat /etc/hostname) | cut -f 1)"
HOST_IP=glassfish
sed -e "s,%HOST_IP%,$HOST_IP,g" -i $NGINX_OPENSTACK
sed -e "s,%APACHE_HTTP%,$APACHE_HTTP,g" -i $NGINX_OPENSTACK
sed -e "s,%GLASSFISH_PORT%,$GLASSFISH_PORT,g" -i $NGINX_OPENSTACK
sed -e "s,%GLASSFISH_PORTS%,$GLASSFISH_PORTS,g" -i $NGINX_OPENSTACK

exec "$@"
