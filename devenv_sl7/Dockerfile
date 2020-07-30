# docker build -t lyonfnal/devenv:sl7 .

FROM sl:7
MAINTAINER Adam Lyon <lyon@fnal.gov>

RUN yum update -y && \
    yum install -y epel-release redhat-lsb-core perl perl-Module-Pluggable expat-devel glibc-devel gdb time git curl-devel \
        emacs screen gcc meld valgrind ncurses-devel perf htop libunwind-devel libtool autoconf automake \
        openssl-devel tar zip xz bzip2 patch wget which sudo strace kernel-devel patch \
        freetype-devel libXpm-devel libXmu-devel mesa-libGL-devel mesa-libGLU-devel libXt-devel \
        zlib-devel libuuid-devel libmnl-devel make \
        autoconf-archive autogen pkgconfig curl lsof && \
    yum clean all

# Get rh-python36 for CLion debugging
RUN yum install -y "http://ftp.scientificlinux.org/linux/scientific/7/external_products/softwarecollections/yum-conf-softwarecollections-2.0-1.el7.noarch.rpm" && \
    yum install -y rh-python36 && \
    yum clean all

# # Got the right repo from http://ftp.scientificlinux.org/linux/fermi/slf7/docs/
RUN yum install -y yum-conf-repos && \
    yum install -y yum-conf-context-fermilab && \
    sleep 2 && \
    yum upgrade -y && \
	yum install -y fermilab-base_kerberos cigetcert fermilab-util_kx509 && \
    yum clean all

# Install the opensciencegrid client for voms-proxy-init
RUN rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm ;\
    rpm -Uvh https://repo.opensciencegrid.org/osg/3.5/osg-3.5-el7-release-latest.rpm ; \
    yum install -y osg-wn-client xrootd-server ;\
	yum clean all

# Install netdata
RUN git clone https://github.com/netdata/netdata.git --depth=1 && \
    yum install -y autoconf automake curl gcc git libmnl-devel libuuid-devel openssl-devel libuv-devel lz4-devel Judy-devel make nc pkgconfig python zlib-devel cmake && \
    cd netdata && \
    ./netdata-installer.sh --dont-wait --dont-start-it && \
    echo 'art: gm2* nova* art* uboone*' >> /etc/netdata/apps_groups.conf && \
    cd ..  && \
    rm -rf ./netdata

# UPS gets the flavor of the machine running docker instead of the docker container.
#   We can force the correct flavor with UPS_OVERRIDE
#   Note that mrb changes UPS_OVERRIDE (adding the -B). The mrb code has been updated
#   to copy UPS_FLAVOR_OVERRIDE into UPS_OVERRIDE when necessary.
ENV UPS_FLAVOR_OVERRIDE "-H Linux64bit+3.10-2.17-sl7-7"
ENV UPS_OVERRIDE $UPS_FLAVOR_OVERRIDE

# 7777 for gdb server. 19999 for netdata
EXPOSE 7777 19999

# Upon start, run bash
CMD ["/bin/bash"]
