# docker build -t lyonfnal/devenv_cvmfs:sl6 .
# To run, you need environment variable CVMFS_EXP to be set (e.g. gm2, nova, uboone)

FROM lyonfnal/devenv:sl6
MAINTAINER Adam Lyon <lyon@fnal.gov>

# Set the time correctly
RUN echo 'ZONE="America/Chicago"' > /etc/sysconfig/clock
RUN rm -rf /etc/localtime
RUN ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime

# Install cvmfs and configure
RUN yum install -y osg-oasis
RUN /bin/echo CVMFS_REPOSITORIES="`echo $((ls /cvmfs)|sort -u)|tr ' ' ,`" > /etc/cvmfs/default.local
RUN /bin/echo CVMFS_QUOTA_LIMIT=20000 >> /etc/cvmfs/default.local
RUN /bin/echo CVMFS_HTTP_PROXY=DIRECT >> /etc/cvmfs/default.local

RUN cvmfs_config setup

# Following https://success.docker.com/article/use-a-script-to-initialize-stateful-container-data
COPY start_cvmfs.sh /usr/local/bin/start_cvmfs.sh
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT docker-entrypoint.sh
