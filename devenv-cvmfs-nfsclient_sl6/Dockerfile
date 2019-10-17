# docker build -t lyonfnal/devenv_cvmfs_nfsclient:sl6 .

FROM lyonfnal/devenv:sl6

RUN yum -y install nfs-utils nfs-utils-lib && \
    yum clean all

# Set the time correctly
RUN echo 'ZONE="America/Chicago"' > /etc/sysconfig/clock
RUN rm -rf /etc/localtime
RUN ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT ["docker-entrypoint.sh"]