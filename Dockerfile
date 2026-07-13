FROM registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.26-openshift-5.0 AS builder
WORKDIR /go/src/github.com/openshift/network-tools
COPY . .

# needed for ovnkube-trace
FROM registry.ci.openshift.org/ocp/5.0:ovn-kubernetes AS ovnkube-trace

# tools (openshift-tools) is based off cli
FROM registry.ci.openshift.org/ocp/5.0:tools
COPY --from=builder /go/src/github.com/openshift/network-tools/debug-scripts/ /opt/bin/
COPY --from=ovnkube-trace /usr/bin/ovnkube-trace /usr/bin/

# remove internal scripts from the image and create a symlink for network-tools and gather entrypoint for must-gather
RUN rm -rf /opt/bin/local-scripts && ln -s /opt/bin/network-tools /usr/bin/network-tools && ln -s /opt/bin/network-tools /usr/bin/gather


# Install EPEL repository for hping3
RUN curl --fail --show-error -L https://dl.fedoraproject.org/pub/epel/9/Everything/x86_64/Packages/e/epel-release-9-11.el9.noarch.rpm -o /tmp/epel.rpm && \
    echo "b434245bffd8b40ea486157e72363d08b36e38145c8f917c5c00adfca3f2101b  /tmp/epel.rpm" | sha256sum -c - && \
    rpm -ivh /tmp/epel.rpm && \
    rm -f /tmp/epel.rpm

# Make sure to maintain alphabetical ordering when adding new packages.
# hping3 is available in EPEL (Extra Packages for Enterprise Linux)
RUN INSTALL_PKGS="\
    conntrack-tools \
    hping3 \
    iproute \
    nmap-ncat \
    nginx \
    numactl \
    tcl \
    traceroute \
    wireshark-cli \
    " && \
    yum -y install --setopt=tsflags=nodocs --setopt=skip_missing_names_on_install=False $INSTALL_PKGS && \
    yum clean all && rm -rf /var/cache/*
