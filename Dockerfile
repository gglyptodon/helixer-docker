FROM nvidia/cuda:11.2.0-cudnn8-devel-ubuntu20.04
RUN useradd --create-home --shell /bin/bash helixer_user
RUN apt-get update -y
RUN apt-get install python3-dev -y
RUN apt-get install python3-pip -y
RUN apt-get install python3-venv -y
RUN apt-get install git -y
RUN apt-get install libhdf5-dev -y
RUN apt-get install curl -y
RUN apt-get autoremove -y

# --- prep for hdf5 for HelixerPost --- #
WORKDIR /tmp/
RUN curl -L https://github.com/h5py/h5py/releases/download/3.2.1/h5py-3.2.1.tar.gz --output h5py-3.2.1.tar.gz
RUN tar -xzvf h5py-3.2.1.tar.gz 
#RUN gcc -O2 -fPIC -shared -Ilzf -I/usr/include/hdf5/serial/ lzf/*.c lzf_filter.c -lhdf5 -L/lib/x86_64-linux-gnu/hdf5/serial -o liblzf_filter.so
RUN cd h5py-3.2.1/lzf/ && gcc -O2 -fPIC -shared -Ilzf -I/usr/include/hdf5/serial/ lzf/*.c lzf_filter.c  -lhdf5_cpp -L/lib/x86_64-linux-gnu/hdf5/serial -o liblzf_filter.so
RUN mkdir /usr/lib/x86_64-linux-gnu/hdf5/plugins && cp h5py-3.2.1/lzf/liblzf_filter.so /usr/lib/x86_64-linux-gnu/hdf5/plugins

# --- rust install for HelixerPost --- # 
RUN curl https://sh.rustup.rs -sSf > rustup.sh
RUN chmod 755 rustup.sh
RUN ./rustup.sh -y
RUN rm rustup.sh
ENV PATH="/root/.cargo/bin:${PATH}"

# --- Helixer and HelixerPost --- #

WORKDIR /home/helixer_user/
RUN git clone https://github.com/weberlab-hhu/Helixer.git
RUN pip install --no-cache-dir -r /home/helixer_user/Helixer/requirements.txt
RUN cd Helixer && pip install --no-cache-dir .

WORKDIR /home/helixer_user/
RUN git clone https://github.com/TonyBolger/HelixerPost.git
RUN mkdir bin
ENV PATH="/home/helixer_user/bin:${PATH}"
RUN cd HelixerPost/helixer_post_bin && cargo build --release 
RUN ln -s /home/helixer_user/HelixerPost/target/release/helixer_post_bin /home/helixer_user/bin/

USER helixer_user
CMD ["bash"] 
