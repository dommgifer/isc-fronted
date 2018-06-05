FROM nginx:stable
MAINTAINER jeffxie@iii.org.tw
WORKDIR /home/localadmin
ENV NGINX_OPENSTACK=/etc/nginx/openstack \
    NGINX_HOME=/etc/nginx

RUN mkdir -p $NGINX_OPENSTACK \ 
    && mkdir -p $NGINX_OPENSTACK/upstream \
    && mkdir -p $NGINX_OPENSTACK/site 

COPY template/nginx/ $NGINX_OPENSTACK/
RUN mv $NGINX_OPENSTACK/openstack.conf $NGINX_OPENSTACK/site \
    && mv $NGINX_OPENSTACK/nginx.conf $NGINX_HOME \
    && mv $NGINX_OPENSTACK/mime.types $NGINX_HOME 

COPY docker-entrypoint.sh /usr/local/bin/

EXPOSE 8080 8088 80
#EXPOSE 80
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
#CMD bash
