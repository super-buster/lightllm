FROM nvidia/cuda:11.8.0-runtime-ubuntu20.04 as base
ARG PYTORCH_VERSION=2.0.0
ARG PYTHON_VERSION=3.9
ARG CUDA_VERSION=11.8
ARG MAMBA_VERSION=23.1.0-1
ARG CUDA_CHANNEL=nvidia
ARG INSTALL_CHANNEL=pytorch
ARG TARGETPLATFORM

ENV PATH=/opt/conda/bin:$PATH \
    CONDA_PREFIX=/opt/conda

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        libssl-dev \
        curl \
        g++ \
        make \
        git && \
        rm -rf /var/lib/apt/lists/*

RUN case ${TARGETPLATFORM} in \
         "linux/arm64")  MAMBA_ARCH=aarch64  ;; \
         *)              MAMBA_ARCH=x86_64   ;; \
    esac && \
    curl -fsSL -o ~/mambaforge.sh -v "http://47.93.190.43:8503/Mambaforge-Linux-x86_64.sh" && \
    bash ~/mambaforge.sh -b -p /opt/conda && \
    rm ~/mambaforge.sh

RUN case ${TARGETPLATFORM} in \
         "linux/arm64")  exit 1 ;; \
         *)              /opt/conda/bin/conda update -y conda &&  \
                        /opt/conda/bin/conda install -c "${INSTALL_CHANNEL}" -c "${CUDA_CHANNEL}" -c nvidia -y "python=${PYTHON_VERSION}" pytorch==$PYTORCH_VERSION "pytorch-cuda=$(echo $CUDA_VERSION | cut -d'.' -f 1-2)" -c anaconda -c conda-forge ;; \
    esac && \
    /opt/conda/bin/conda clean -ya

COPY ./cuda.h /usr/local/cuda/include/cuda.h
# workaround
RUN mkdir ~/cuda-nvcc && cd ~/cuda-nvcc && \
    curl -fsSL -o package.tar.bz2 https://conda.anaconda.org/nvidia/label/cuda-12.1.1/linux-64/cuda-nvcc-12.1.105-0.tar.bz2 && \
    tar xf package.tar.bz2 &&\
    mkdir -p /usr/local/cuda/bin && \
    mkdir -p /usr/local/cuda/include && \
    cp bin/ptxas /usr/local/cuda/bin/ptxas && \
    rm ~/cuda-nvcc -rf

WORKDIR /root

RUN pip install -U pip && pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple \
&& pip config set install.trusted-host pypi.tuna.tsinghua.edu.cn
COPY . /lightllm
RUN pip install -r /lightllm/requirements.txt --no-cache-dir && \
    pip install -e /lightllm --no-cache-dir
