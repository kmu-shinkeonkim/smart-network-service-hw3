# Dockerfile for Smart Network Service HW3
# Ubuntu-based container with Mininet, Ryu Controller, and Python 3
# For SDN Firewall Lab

FROM ubuntu:20.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies for Mininet, OpenFlow
RUN apt-get update && apt-get install -y \
    # Basic utilities
    software-properties-common \
    git \
    curl \
    wget \
    vim \
    net-tools \
    iputils-ping \
    iproute2 \
    tcpdump \
    iptables \
    # Python 3 (default 3.8 in Ubuntu 20.04)
    python3 \
    python3-venv \
    python3-dev \
    python3-pip \
    # Build dependencies for Ryu (from official docs)
    gcc \
    libffi-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    # Mininet and OpenFlow
    mininet \
    openvswitch-switch \
    openvswitch-common \
    # Network testing tools
    iperf \
    iperf3 \
    hping3 \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

# Upgrade pip and install compatible setuptools for Ryu
# Install eventlet with compatible version for Python 3.8
RUN python3 -m pip install --upgrade pip && \
    pip3 install setuptools==58.2.0 wheel 'eventlet==0.30.2'

# Set working directory
WORKDIR /app

# Install Mininet Python package
RUN pip3 install mininet

# Install Ryu from source with patch
RUN git clone https://github.com/faucetsdn/ryu.git /tmp/ryu && \
    cd /tmp/ryu && \
    git checkout v4.34 && \
    # Patch the problematic hooks.py file
    sed -i '36s/.*/    pass  # Removed problematic get_script_args/' ryu/hooks.py && \
    pip3 install --no-cache-dir . && \
    cd / && rm -rf /tmp/ryu

# Copy requirements and install additional Python dependencies
COPY requirements.txt ./
RUN grep -v "^ryu==" requirements.txt > /tmp/requirements_no_ryu.txt && \
    pip3 install --no-cache-dir -r /tmp/requirements_no_ryu.txt && \
    rm /tmp/requirements_no_ryu.txt

# Copy application code
COPY sdn_topology.py /app/
COPY simple_firewall_student.py /app/

# Create necessary directories for OpenVSwitch
RUN mkdir -p /var/run/openvswitch && \
    mkdir -p /var/log/openvswitch && \
    mkdir -p /etc/openvswitch && \
    mkdir -p /tmp/mininet

# Expose ports
# 6633: OpenFlow controller port
# 6653: Alternative OpenFlow port
# 8080: Ryu REST API port
EXPOSE 6633 6653 8080

# Create entrypoint script to start OpenVSwitch
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
# Clean up any stale OVS database\n\
rm -f /var/run/openvswitch/ovs-vswitchd.pid\n\
rm -f /var/run/openvswitch/ovsdb-server.pid\n\
rm -f /etc/openvswitch/conf.db\n\
\n\
# Initialize OVS database if needed\n\
if [ ! -f /etc/openvswitch/conf.db ]; then\n\
    ovsdb-tool create /etc/openvswitch/conf.db /usr/share/openvswitch/vswitch.ovsschema\n\
fi\n\
\n\
# Start Open vSwitch\n\
ovsdb-server --remote=punix:/var/run/openvswitch/db.sock \\\n\
    --remote=db:Open_vSwitch,Open_vSwitch,manager_options \\\n\
    --pidfile --detach\n\
\n\
ovs-vsctl --no-wait init || true\n\
ovs-vswitchd --pidfile --detach\n\
\n\
# Execute the command\n\
exec "$@"\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
