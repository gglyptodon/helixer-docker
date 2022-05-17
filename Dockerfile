FROM nvidia/cuda:9.2-cudnn7-runtime-ubuntu18.04
RUN useradd --create-home --shell /bin/bash helixer_user
RUN apt-get update -y
RUN apt-get install python3-pip -y
RUN apt-get install git libbz2-dev libzip-dev liblzma-dev libjpeg-dev -y
RUN apt-get autoremove -y

# --- Helixer --- #

WORKDIR /home/helixer_user/
RUN python3 --version
RUN git clone -b v0.2.0 https://github.com/weberlab-hhu/Helixer.git Helixer
#RUN pwd && ls 
RUN sed -i s/==1.15.4/==1.14.0/ Helixer/requirements.txt
RUN sed -i s/HTSeq/HTSeq==0.13.5/ Helixer/requirements.txt
#RUN cat Helixer/requirements.txt
RUN pip3 install numpy
RUN pip3 install --no-cache-dir -r /home/helixer_user/Helixer/requirements.txt
RUN pip3 install https://github.com/weberlab-hhu/GeenuFF/archive/at-helixer-v0.1.0.tar.gz#egg=geenuff
RUN cd Helixer && pip3 install --no-cache-dir .
RUN pip3 freeze > Helixer_v0.2.0_installed_python_packages.txt
RUN apt list --installed > Helixer_v0.2.0_installed_apt_packages.txt
USER helixer_user
CMD ["bash"]
