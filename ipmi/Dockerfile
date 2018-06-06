FROM python:2.7
MAINTAINER jeffxie@iii.org.tw
WORKDIR /home/localadmin/backend/openstack_mitaka/

COPY backend/openstack_mitaka/backend_api/ backend_api/ 

RUN pip install Flask && \
    pip install SQLAlchemy && \
    pip install pyyaml && \
    pip install pyghmi==1.0.30 && \
    rm -rf backend_api/pyghmi-1.0.30.tar.gz && \
    rm -rf backend_api/vm_snapshot_sql && \
    mkdir -p /home/localadmin/conf && \
    mkdir -p /home/localadmin/log && \
    touch /home/localadmin/log/backend_api.log

EXPOSE 9487

CMD python backend_api/backend_api.py 
