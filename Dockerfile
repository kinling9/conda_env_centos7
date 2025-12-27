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
    yum -y install make python3 epel-release centos-release-scl yum-utils && \
    echo "[centos-sclo-rh]" > /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo && \
    echo "name=CentOS-7 - SCLo rh" >> /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo && \
    echo "baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/7.9.2009/sclo/x86_64/rh/" >> /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo && \
    echo "gpgcheck=1" >> /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo && \
    echo "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo" >> /etc/yum.repos.d/CentOS-SCLo-scl-rh.repo && \
    echo "[centos-sclo-sclo]" > /etc/yum.repos.d/CentOS-SCLo-scl.repo && \
    echo "name=CentOS-7 - SCLo sclo" >> /etc/yum.repos.d/CentOS-SCLo-scl.repo && \
    echo "baseurl=https://mirrors.tuna.tsinghua.edu.cn/centos-vault/7.9.2009/sclo/x86_64/sclo/" >> /etc/yum.repos.d/CentOS-SCLo-scl.repo && \
    echo "gpgcheck=1" >> /etc/yum.repos.d/CentOS-SCLo-scl.repo && \
    echo "enabled=1" >> /etc/yum.repos.d/CentOS-SCLo-scl.repo && \
    echo "gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-SCLo" >> /etc/yum.repos.d/CentOS-SCLo-scl.repo && \
    yum clean all && \
    yum makecache && \
    yum -y install ninja-build cmake3 bzip2 zlib-devel && \
    ln -s /usr/bin/cmake3 /usr/bin/cmake

# Install GCC 11
RUN yum -y install devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutils

# Enable GCC 11
ENV PATH="/opt/rh/devtoolset-11/root/usr/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/rh/devtoolset-11/root/usr/lib64:/opt/rh/devtoolset-11/root/usr/lib:${LD_LIBRARY_PATH}"
ENV CC=/opt/rh/devtoolset-11/root/usr/bin/gcc
ENV CXX=/opt/rh/devtoolset-11/root/usr/bin/g++

RUN yum -y install bzip2 wget gmp-devel mpfr-devel libmpc-devel git

# Install Miniconda
ARG TARGET_CONDA_DIR=/root/miniconda3
ENV MINICONDA_VERSION=py39_4.12.0
ENV PATH="${TARGET_CONDA_DIR}/bin:${PATH}"
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -O miniconda.sh && \
    bash miniconda.sh -b -p "${TARGET_CONDA_DIR}" && \
    rm miniconda.sh && \
    conda init bash && \
    conda config --add channels conda-forge && \
    conda config --set channel_priority strict
RUN conda update -n base conda -y && \
    conda install -n base conda-libmamba-solver -y && \
    conda config --set solver libmamba

# Install CUDA 12.4
RUN yum -y install yum-utils && \
    yum-config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-rhel7.repo && \
    yum -y install libglvnd-opengl libX11 && \
    yum -y install cuda-toolkit-12-4

ENV PATH="/usr/local/cuda-12.4/bin:${PATH}"
ENV LD_LIBRARY_PATH="/usr/local/cuda-12.4/lib64"
ENV MAX_JOBS=4

# Create a conda environment
RUN conda create -n gcn_env python=3.9 -y

# Copy packing script
COPY pack_incremental.sh /usr/local/bin/pack_incremental.sh
COPY restore_env.sh /usr/local/bin/restore_env.sh
COPY refresh_snapshot.sh /usr/local/bin/refresh_snapshot.sh
RUN chmod +x /usr/local/bin/pack_incremental.sh /usr/local/bin/restore_env.sh /usr/local/bin/refresh_snapshot.sh
