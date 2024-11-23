FROM nvidia/cuda:12.2.2-cudnn8-runtime-ubuntu22.04
RUN useradd --create-home --shell /bin/bash helixer_user
RUN apt-get update -y
# install wget and zip to run integration tests; nano to edit files if need be
# install cuda-compiler-12-2 to fix issue:
# W external/org_tensorflow/tensorflow/compiler/xla/service/gpu/llvm_gpu_backend/gpu_backend_lib.cc:559] libdevice is required by this HLO module but was not found at ./libdevice.10.bc
# error: libdevice not found at ./libdevice.10.bc
# installing devel image instead of runtime or  pip install tensorflow[and-cuda] fix the issue as well
# but increase the image size by 5 to 6 Gb
RUN apt-get install -y python3-dev \
  python3-pip \
  python3-venv \
  git \
  libhdf5-dev \
  curl \
  libbz2-dev \
  liblzma-dev \
  wget \
  zip \
  nano \
  cuda-compiler-12-2
RUN apt autoremove -y

# --- prep for hdf5 for HelixerPost --- #
WORKDIR /tmp/
RUN curl -L https://github.com/h5py/h5py/releases/download/3.10.0/h5py-3.10.0.tar.gz --output h5py-3.10.0.tar.gz
RUN tar -xzvf h5py-3.10.0.tar.gz
RUN cd h5py-3.10.0/lzf/ && gcc -O2 -fPIC -shared -Ilzf -I/usr/include/hdf5/serial/ lzf/*.c lzf_filter.c  -lhdf5_cpp -L/lib/x86_64-linux-gnu/hdf5/serial -o liblzf_filter.so
RUN mkdir /usr/lib/x86_64-linux-gnu/hdf5/plugins && mv h5py-3.10.0/lzf/liblzf_filter.so /usr/lib/x86_64-linux-gnu/hdf5/plugins
RUN rm -r /tmp/h5py*

# --- rust install for HelixerPost --- # 
RUN curl https://sh.rustup.rs -sSf > rustup.sh
RUN chmod 755 rustup.sh
RUN ./rustup.sh -y
RUN rm rustup.sh
ENV PATH="/root/.cargo/bin:${PATH}"

# --- Helixer and HelixerPost --- #
WORKDIR /home/helixer_user/
# v0.3.4
# upgrading pip fixes bug: pyproject.toml: name, version not recognized (UNKNOWN 0.0.0) when using Ubuntu 22.04 (https://github.com/pypa/setuptools/issues/3269)
RUN pip install --upgrade pip
RUN git clone https://github.com/weberlab-hhu/Helixer.git Helixer && cd Helixer && git checkout tags/v0.3.4 && pip install --no-cache-dir -r /home/helixer_user/Helixer/requirements.3.10.txt && pip install --no-cache-dir .

WORKDIR /home/helixer_user/
RUN git clone https://github.com/TonyBolger/HelixerPost.git
RUN cd HelixerPost && git checkout 4d4799bac4c05e574ae628040c5cb58eb4aa18fe
RUN mkdir bin
ENV PATH="/home/helixer_user/bin:${PATH}"
RUN cd HelixerPost/helixer_post_bin && cargo build --release
RUN mv /home/helixer_user/HelixerPost/target/release/helixer_post_bin /home/helixer_user/bin/
RUN rm -r /home/helixer_user/HelixerPost/target/release/

RUN chown -R helixer_user:helixer_user Helixer && \
    chown -R helixer_user:helixer_user HelixerPost

USER helixer_user
CMD ["bash"]
