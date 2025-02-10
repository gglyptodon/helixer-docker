# helixer-docker

This repository accompanies https://github.com/weberlab-hhu/Helixer .

The aim is to provide a mostly hassle-free way to use Helixer via docker (or singularity).

For more information on how to run Helixer, please refer to its [documentation](https://github.com/weberlab-hhu/Helixer).

--------

### Instructions for docker (for use with Nvidia GPUs) ###

- Prerequisites (on host):
  - Nvidia GPU with CUDA capabilities >=6.1; installed driver version >=525.60.13 
  
> Note that the code _will_ run on the CPU if an Nvidia GPU or appropriate drivers are not available.
> However, the walltime requirements will increase _substantially_. If not running on the GPU
> exclude the parameter `--gpus all` when running `docker run`, or the parameter `--nv` when
> running `singularity run`, respectively.

- Prepare, install Docker (https://docs.docker.com/engine/install/ubuntu/) and the
Nvidia Container Toolkit (https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
(on host), e.g. for ubuntu. Please also be aware of Dockers Firewall limitations mentioned on the installation
instructions website.
```
##################
# install Docker #
##################

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# install the latest Docker packages
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# verify Docker installation
sudo docker run hello-world

####################################
# install Nvidia Container Toolkit #
####################################

# configure the production repository
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# update the packages list from the repository
sudo apt update

# install the NVIDIA Container Toolkit packages
sudo apt-get install -y nvidia-container-toolkit

####################
# configure Docker #
####################

# configure the container runtime
sudo nvidia-ctk runtime configure --runtime=docker

# restart the Docker daemon
sudo systemctl restart docker

# Hint: you can also configure Docker in rootless mode (see the Nvidia Container Toolkit installation instructions website)
```
> **Note**: The Nvidia-Docker wrapper (https://github.com/NVIDIA/nvidia-docker) has been deprecated.
> It is recommended to switch to the Nvidia Container Toolkit to use Helixer via Docker.

### Pull prepared image ###
```
docker pull gglyptodon/helixer-docker:helixer_v0.3.4_cuda_12.2.2-cudnn8
# run container interactively 
docker run --gpus all -it gglyptodon/helixer-docker:helixer_v0.3.4_cuda_12.2.2-cudnn8
```
(Note: nvidia-docker v2 uses `--runtime=nvidia` instead of `--gpus all`)
```
# additionally, set up a shared directory and mount it, e.g.:
# on host:
mkdir -p data/out
chmod o+w data/out # something the container can write to
# mount directory and run interactively:
docker run --gpus all -it --name helixer_testing_v0.3.4_cuda_12.2.2-cudnn8 --rm --mount type=bind,source="$(pwd)"/data,target=/home/helixer_user/shared gglyptodon/helixer-docker:helixer_v0.3.4_cuda_12.2.2-cudnn8
```

### Alternatively, build it yourself ###
- Build:
```
mkdir SOME_DIR
cd SOME_DIR
wget https://raw.githubusercontent.com/gglyptodon/helixer-docker/main/Dockerfile

mkdir -p data/out
chmod o+w data/out # something the container can write to

docker build -t helixer_v0.3.4 --rm .
```


- Run:
```
docker run --gpus all -it --name helixer_v0.3.4 --rm --mount type=bind,source="$(pwd)"/data,target=/home/helixer_user/shared helixer_v0.3.4:latest
```


### Try out:
```
# Download models (models will be saved to ~/.local/share/Helixer/models/ )
helixer_user@03356047d15f:~$ Helixer/scripts/fetch_helixer_models.py
helixer_user@03356047d15f:~$ cd shared/out/

# get some test data
helixer_user@03356047d15f:~/shared/out$ curl -L ftp://ftp.ensemblgenomes.org/pub/plants/release-47/fasta/arabidopsis_lyrata/dna/Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz --output Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz

# predict gene models
helixer_user@03356047d15f:~/shared/out$ Helixer.py --fasta-path Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz --lineage land_plant --gff-output-path Arabidopsis_lyrata_chromosome8_helixer.gff3

# see start and end of expected output below:

# No config file found

# Helixer.py config: 
# {'batch_size': 32,
# 'compression': 'gzip',

# [...]

# Total: 12727167bp across 2300 windows

# Helixer successfully finished the annotation of Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz in 0.06 hours. GFF file written to Arabidopsis_lyrata_chromosome8_helixer.gff3.

```
-----------------------------------

Notes on running via Singularity 
---

### Installing Singularity ###

( If you already have singularity available, skip to section "Running via Singularity" below.)

For singularity install, see also: 
https://github.com/sylabs/singularity/blob/master/INSTALL.md

Install go:
```
export VERSION=1.18.1 OS=linux ARCH=amd64  # change this as you need

wget -O /tmp/go${VERSION}.${OS}-${ARCH}.tar.gz \
  https://dl.google.com/go/go${VERSION}.${OS}-${ARCH}.tar.gz
sudo tar -C /usr/local -xzf /tmp/go${VERSION}.${OS}-${ARCH}.tar.gz

echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

Clone syslabs' singularity repo and install: 
```
mkdir  -p github.com/syslabs/
cd github.com/syslabs
git clone --recurse-submodules https://github.com/sylabs/singularity.git
cd singularity/
git checkout --recurse-submodules v3.9.9

./mconfig
make -C builddir
sudo make -C builddir install

```

If all went well, you should be able to see a version number:
```
singularity --version
# -->  singularity-ce version 3.9.9

```

### Running via Singularity ###

```
# pull current docker image 
singularity pull docker://gglyptodon/helixer-docker:helixer_v0.3.4_cuda_12.2.2-cudnn8
```
> **Warning**: If the pulled singularity image claims that 'helixer_post_bin' is not
> installed, try `sudo singularity pull docker://gglyptodon/helixer-docker:helixer_v0.3.4_cuda_12.2.2-cudnn8`.
> When pulling the singularity image it's possible that the permissions set in the image get
> reset, so that 'helixer_post_bin' is not accessible. Pulling the image as superuser retains all
> permissions correctly.
```
# in this example, the directory "helixer_test" already contains downloaded data
singularity run --nv helixer-docker_helixer_v0.3.4_cuda_12.2.2-cudnn8.sif Helixer.py --fasta-path helixer_test/Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz --lineage land_plant --gff-output-path Arabidopsis_lyrata_chromosome8_helixer.gff3
# notice '--nv' for GPU support
```
