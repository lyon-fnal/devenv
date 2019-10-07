# docker build -t lyonfnal/devenv_cvmfs_vnc:sl6 .

FROM lyonfnal/devenv_cvmfs:sl6

RUN yum -y groupinstall "X Window System" "Desktop" && \
    yum -y groupinstall fonts && \
    yum -y install tigervnc-server xorg-x11-fonts-Type1 tzdata && \
    yum clean all

EXPOSE 5901

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT docker-entrypoint.sh
