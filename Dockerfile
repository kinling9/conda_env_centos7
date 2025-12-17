# Use the official CentOS 7 image
FROM centos:centos7.9.2009

# Install the necessary tools to compile C++
# RUN sed -i.bak \
#     -e 's|^mirrorlist=|#mirrorlist=|g' \
#     -e 's|^#baseurl=http://mirror.centos.org/centos|baseurl=https://mirrors.ustc.edu.cn/centos-vault/centos|g' \
#     /etc/yum.repos.d/CentOS-*.repo && \
#     yum clean all && \
#     yum makecache
RUN sed -e "s|^mirrorlist=|#mirrorlist=|g" \
    -e "s|^#baseurl=http://mirror.centos.org/centos/\$releasever|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/7.9.2009|g" \
    -e "s|^#baseurl=http://mirror.centos.org/\$contentdir/\$releasever|baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/7.9.2009|g" \
    -i.bak \
    /etc/yum.repos.d/CentOS-*.repo && \
    yum clean all && \
    yum makecache
RUN yum -y update && \
    yum -y install gcc gcc-c++ make python3 epel-release && \
    yum -y install ninja-build cmake3 bzip2 zlib-devel && \
    ln -s /usr/bin/cmake3 /usr/bin/cmake

RUN yum -y install bzip2 wget gmp-devel mpfr-devel libmpc-devel git

# Install Miniconda
ENV MINICONDA_VERSION=py39_4.12.0
ENV PATH="/root/miniconda3/bin:${PATH}"
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p /root/miniconda3 && \
    rm miniconda.sh && \
    conda init bash && \
    conda config --add channels conda-forge && \
    conda config --set channel_priority strict

# Copy packing script
COPY pack_incremental.sh /usr/local/bin/pack_incremental.sh
COPY restore_env.sh /usr/local/bin/restore_env.sh
COPY refresh_snapshot.sh /usr/local/bin/refresh_snapshot.sh
RUN chmod +x /usr/local/bin/pack_incremental.sh /usr/local/bin/restore_env.sh /usr/local/bin/refresh_snapshot.sh

# Create a conda environment
RUN conda create -n test_env python=3.9 -y
