FROM ubi9/ubi:latest

# Copy Custom ceph repo files
COPY *.repo /etc/yum.repos.d/

RUN dnf update -y \
    && dnf install -y \
    fio \
    net-tools \
    procps \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    && dnf install -y \
    ceph \
    https://rpmfind.net/linux/centos-stream/9-stream/CRB/ppc64le/os/Packages/lua-devel-5.4.4-4.el9.ppc64le.rpm \
    https://rpmfind.net/linux/centos-stream/9-stream/AppStream/ppc64le/os/Packages/lua-5.4.4-4.el9.ppc64le.rpm \
    https://rpmfind.net/linux/epel/9/Everything/ppc64le/Packages/l/luarocks-3.9.2-5.el9.noarch.rpm \
    https://rpmfind.net/linux/epel/9/Everything/ppc64le/Packages/l/liboath-2.6.12-1.el9.ppc64le.rpm \
    && dnf clean all \
    && rm -rf /var/cache/dnf \
    && rm -rf /var/cache/yum \
    && rm -rf /var/lib/yum \
    && rm -rf /var/log/dnf* \
    && rm -rf /var/log/yum* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/* \
    && rm -rf /var/lib/rpm \
    && mkdir /fio

# Copy scripts and documentation to /fio
COPY *.sh /fio/
COPY README.md /fio/

WORKDIR /fio

ENTRYPOINT ["/fio/entrypoint.sh"]