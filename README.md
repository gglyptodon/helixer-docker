# helixer-docker

- Prerequisites (on host):
  - Nvidia GPU with CUDA capabilities >=3.5; installed driver version >= 450.80.02 

- Prepare, install nvidia docker runtime (on host), e.g. for ubuntu:
```
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list |  sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt update

sudo apt-get install nvidia-docker2
sudo pkill -SIGHUP dockerd 
```
Or follow instruction from https://github.com/NVIDIA/nvidia-docker



- Build:
```
mkdir SOME_DIR
cd SOME_DIR
wget https://raw.githubusercontent.com/gglyptodon/helixer-docker/tmp_helixer_v0.2.0/Dockerfile
mkdir -p data/out
chmod o+w data/out # something the container can write to

docker build -t helixer_v0.2.0_10.0-cudnn7-runtime-ubuntu18.04_testing --rm .
```


- Run:
```
docker run --runtime=nvidia -it helixer_v0.2.0_10.0-cudnn7-runtime-ubuntu18.04_testing
```
