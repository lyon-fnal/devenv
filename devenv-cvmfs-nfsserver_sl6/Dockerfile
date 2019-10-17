# docker build -t lyonfnal/devenv_cvmfs_nfsserver:sl6 .

FROM lyonfnal/devenv_cvmfs:sl6

RUN yum -y install nfs-utils nfs-utils-lib  && \
    yum clean all

EXPOSE 2049

RUN /bin/echo CVMFS_NFS_SOURCE=yes    >> /etc/cvmfs/default.local
RUN /bin/echo CVMFS_MEMCACHE_SIZE=256 >> /etc/cvmfs/default.local

RUN cvmfs_config setup

# Following https://success.docker.com/article/use-a-script-to-initialize-stateful-container-data
COPY etc_sysconfig_nfs /etc/sysconfig/nfs
COPY start_nfs_server.sh /usr/local/bin/start_nfs_server.sh
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT docker-entrypoint.sh