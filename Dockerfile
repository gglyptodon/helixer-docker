FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04
RUN useradd --create-home --shell /bin/bash helixer_user
RUN apt-get update -y
RUN apt-get install -y python3-dev \
  python3-pip \
  python3-venv \
  git \
  libhdf5-dev \
  curl \
  libbz2-dev \
  liblzma-dev
RUN apt autoremove -y

# --- prep for hdf5 for HelixerPost --- #
WORKDIR /tmp/
RUN curl -L https://github.com/h5py/h5py/releases/download/3.2.1/h5py-3.2.1.tar.gz --output h5py-3.2.1.tar.gz
RUN tar -xzvf h5py-3.2.1.tar.gz
RUN cd h5py-3.2.1/lzf/ && gcc -O2 -fPIC -shared -Ilzf -I/usr/include/hdf5/serial/ lzf/*.c lzf_filter.c  -lhdf5_cpp -L/lib/x86_64-linux-gnu/hdf5/serial -o liblzf_filter.so
RUN mkdir /usr/lib/x86_64-linux-gnu/hdf5/plugins && mv h5py-3.2.1/lzf/liblzf_filter.so /usr/lib/x86_64-linux-gnu/hdf5/plugins
RUN rm -r /tmp/h5py*

# --- rust install for HelixerPost --- # 
RUN curl https://sh.rustup.rs -sSf > rustup.sh
RUN chmod 755 rustup.sh
RUN ./rustup.sh -y
RUN rm rustup.sh
ENV PATH="/root/.cargo/bin:${PATH}"

# --- Helixer and HelixerPost --- #
WORKDIR /home/helixer_user/
# v0.3.3 
RUN git clone https://github.com/weberlab-hhu/Helixer.git Helixer && cd Helixer && git checkout tags/v0.3.3 && pip install --no-cache-dir -r /home/helixer_user/Helixer/requirements.3.8.txt && pip install --no-cache-dir .

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
