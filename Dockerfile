FROM nvidia/cuda:12.2.2-cudnn8-runtime-ubuntu22.04

ARG APP_HOME=/opt/helixer
ENV PATH="${APP_HOME}/bin:/root/.cargo/bin:${PATH}"

RUN apt-get update -y && \
  apt-get install -y --no-install-recommends \
    python3-dev python3-pip python3-venv git libhdf5-dev curl \
    libbz2-dev liblzma-dev wget zip nano cuda-compiler-12-2 gcc g++ make && \
  rm -rf /var/lib/apt/lists/*

# --- prep for hdf5 for HelixerPost --- #
WORKDIR /tmp
RUN curl -L https://github.com/h5py/h5py/releases/download/3.10.0/h5py-3.10.0.tar.gz -o h5py-3.10.0.tar.gz && \
  tar -xzvf h5py-3.10.0.tar.gz && \
  cd h5py-3.10.0/lzf/ && \
  gcc -O2 -fPIC -shared -Ilzf -I/usr/include/hdf5/serial/ lzf/*.c lzf_filter.c -lhdf5_cpp -L/lib/x86_64-linux-gnu/hdf5/serial -o liblzf_filter.so && \
  install -d /usr/lib/x86_64-linux-gnu/hdf5/plugins && \
  mv liblzf_filter.so /usr/lib/x86_64-linux-gnu/hdf5/plugins && \
  rm -rf /tmp/h5py*

# --- rust install for HelixerPost --- #
RUN curl https://sh.rustup.rs -sSf > /tmp/rustup.sh && \
  chmod 755 /tmp/rustup.sh && \
  /tmp/rustup.sh -y && \
  rm /tmp/rustup.sh

# --- Helixer and HelixerPost --- #
WORKDIR ${APP_HOME}
RUN pip install --upgrade pip && \
  git clone https://github.com/weberlab-hhu/Helixer.git Helixer && \
  cd Helixer && git checkout tags/v0.3.6 && \
  pip install --no-cache-dir -r requirements.3.10.txt && \
  pip install --no-cache-dir .

RUN git clone https://github.com/TonyBolger/HelixerPost.git && \
  cd HelixerPost && git checkout 4d4799bac4c05e574ae628040c5cb58eb4aa18fe && \
  mkdir -p ${APP_HOME}/bin && \
  cd helixer_post_bin && cargo build --release && \
  mv ${APP_HOME}/HelixerPost/target/release/helixer_post_bin ${APP_HOME}/bin/ && \
  rm -rf ${APP_HOME}/HelixerPost/target/release/
