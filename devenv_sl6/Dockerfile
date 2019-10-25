# docker build -t lyonfnal/devenv:sl6 .

FROM sl:6
MAINTAINER Adam Lyon <lyon@fnal.gov>

RUN yum update -y && \
    yum install -y epel-release redhat-lsb-core perl expat-devel glibc-devel gdb time git curl-devel \
        emacs screen gcc meld valgrind ncurses-devel perf htop libunwind-devel libtool autoconf automake \
        openssl-devel tar zip xz bzip2 patch wget which sudo strace kernel-devel patch \
        freetype-devel libXpm-devel libXmu-devel mesa-libGL-devel mesa-libGLU-devel libXt-devel \
        zlib-devel libuuid-devel libmnl-devel make \
        autoconf-archive autogen pkgconfig curl lsof && \
    yum clean all

# Get rh-python36 for CLion debugging
RUN yum install -y "http://ftp.scientificlinux.org/linux/scientific/6/external_products/softwarecollections/yum-conf-softwarecollections-2.0-1.el6.noarch.rpm" && \
    yum install -y rh-python36 && \
    yum clean all

# # Got the right repo from http://ftp.scientificlinux.org/linux/fermi/slf6x/readme.html
COPY slf6x.repo /etc/yum.repos.d/slf.repo
RUN wget http://ftp.scientificlinux.org/linux/fermi/slf6.10/x86_64/os/RPM-GPG-KEY-sl && \
    rpm --import RPM-GPG-KEY-sl && \
    rm -f RPM-GPG-KEY-sl && \
	yum install -y krb5-fermi-base cigetcert fermilab-util_kx509 && \
    yum clean all

# Install the opensciencegrid client for voms-proxy-init
RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm ;\
    rpm -Uvh https://repo.opensciencegrid.org/osg/3.4/osg-3.4-el6-release-latest.rpm ; \
    yum install -y osg-wn-client xrootd-server ;\
	yum clean all

# Install netdata
RUN git clone https://github.com/firehol/netdata.git --depth=1 && \
    cd netdata && \
    ./netdata-installer.sh --dont-wait --dont-start-it && \
    echo 'art: gm2* nova* art* uboone*' >> /etc/netdata/apps_groups.conf && \
    cd ..  && \
    rm -rf ./netdata

# UPS gets the flavor of the machine running docker instead of the docker container.
#   We can force the correct flavor with UPS_OVERRIDE
#   Note that mrb changes UPS_OVERRIDE (adding the -B). The mrb code has been updated
#   to copy UPS_FLAVOR_OVERRIDE into UPS_OVERRIDE when necessary.
ENV UPS_FLAVOR_OVERRIDE "-H Linux64bit+2.6-2.12"
ENV UPS_OVERRIDE $UPS_FLAVOR_OVERRIDE

# 7777 for gdb server. 19999 for netdata
EXPOSE 7777 19999

# Upon start, run bash
CMD ["/bin/bash"]
