![](helixer.svg)

# Helixer-Docker

This repository accompanies https://github.com/weberlab-hhu/Helixer.
The aim is to provide a mostly hassle-free way to use Helixer via Docker (or Apptainer/Singularity).
For more information on how to run Helixer, please refer to its [documentation](https://github.com/weberlab-hhu/Helixer).

## Table of contents
1. [Docker](#instructions-for-docker-for-use-with-nvidia-gpus)
2. [Apptainer/Singularity](#instructions-for--apptainersingularity)
--------
## Instructions for docker (for use with Nvidia GPUs)
### Installing Docker
- Prerequisites (on host):
  - Nvidia GPU with CUDA capabilities >=6.1; installed driver version >=525.60.13 
  
> Note that the code _will_ run on the CPU if an Nvidia GPU or appropriate drivers are not available.
> However, the wall time requirements will increase _substantially_. If not running on the GPU
> exclude the parameter `--gpus all` when running `docker run`, or the parameter `--nv` when
> running `singularity run`, respectively.

- Prepare, install Docker (https://docs.docker.com/engine/install/ubuntu/) and the
Nvidia Container Toolkit (https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
(on host), e.g. for ubuntu. Please also be aware of Dockers Firewall limitations mentioned on the installation
instructions website.
> **Note**: The Nvidia-Docker wrapper (https://github.com/NVIDIA/nvidia-docker) has been deprecated.
> It is recommended to switch to the Nvidia Container Toolkit to use Helixer via Docker.
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

### Use prepared image ###
```
docker pull gglyptodon/helixer-docker:helixer_v0.3.6_cuda_12.2.2-cudnn8
# run container interactively 
docker run --gpus all -it gglyptodon/helixer-docker:helixer_v0.3.6_cuda_12.2.2-cudnn8
```
(Note: the old nvidia-docker v2 uses `--runtime=nvidia` instead of `--gpus all`)  

Docker containers are by default immutable. So if you restart the Helixer container all your
stored data gets erases. But you can create a directory and mount/bind it to your container.
Then the files created by Helixer will stay in this folder even after restarting the container.
```
# set up a shared directory and mount it, e.g.:
# on host:
mkdir -p data/out
chmod o+w data/out # something the container can write to
# mount directory and run interactively:
docker run --gpus all -it --name helixer_testing_v0.3.6_cuda_12.2.2-cudnn8 --rm \
 --mount type=bind,source="$(pwd)"/data,target=/home/helixer_user/shared gglyptodon/helixer-docker:helixer_v0.3.6_cuda_12.2.2-cudnn8
```

### Alternatively, build it yourself ###
- Build the Helixer-Docker container locally:
```
mkdir SOME_DIR
cd SOME_DIR
wget https://raw.githubusercontent.com/gglyptodon/helixer-docker/main/Dockerfile

mkdir -p data/out
chmod o+w data/out # something the container can write to

docker build -t helixer_v0.3.6 --rm .
```


- Run:
```
docker run --gpus all -it --name helixer_v0.3.6 --rm \
  --mount type=bind,source="$(pwd)"/data,target=/home/helixer_user/shared helixer_v0.3.6:latest
```


### Start using Helixer:
```
# Download models (models will be saved to ~/.local/share/Helixer/models/ )
helixer_user@03356047d15f:~$ Helixer/scripts/fetch_helixer_models.py
helixer_user@03356047d15f:~$ cd shared/out/

# get some test data
helixer_user@03356047d15f:~/shared/out$ curl -L ftp://ftp.ensemblgenomes.org/pub/plants/release-47/fasta/arabidopsis_lyrata/dna/Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz --output Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz

# predict gene models
helixer_user@03356047d15f:~/shared/out$ Helixer.py --fasta-path Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz --lineage land_plant --gff-output-path Arabidopsis_lyrata_chromosome8_helixer.gff3
```
See start and end of expected output below:
```raw
No config file found

Helixer.py config: 
{'batch_size': 32,
'compression': 'gzip',

[...]

Total: 12727167bp across 2300 windows

Helixer successfully finished the annotation of Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz in 0.06 hours. GFF file written to Arabidopsis_lyrata_chromosome8_helixer.gff3.

```
-----------------------------------

Instructions for  Apptainer/Singularity
---
In general Apptainer is recommended over Singularity, since on very rare occasions
Singularity will report the following error `Error: helixer_post_bin not found in $PATH, this is 
required for Helixer.py to complete.`. This is an issue produced by permissions
not being set correctly/reset when pulling the image. See [down below](#running-via-singularity-)
for more information if you'd prefer to use Singularity instead of Apptainer.

### Installing Apptainer ###
If you already have Apptainer available, skip to section
[Running via Apptainer](#running-via-apptainer-).

For Apptainer install, see also:
https://apptainer.org/docs/admin/main/installation.html#install-ubuntu-packages


On Ubuntu based containers install software-properties-common package
to obtain add-apt-repository command. On Ubuntu Desktop/Server derived
systems skip this step.
```
$ sudo apt update
$ sudo apt install -y software-properties-common
```
For the non-setuid installation use these commands:
```
$ sudo add-apt-repository -y ppa:apptainer/ppa
$ sudo apt update
$ sudo apt install -y apptainer
```
For the setuid installation do above commands first and then these:
```
$ sudo add-apt-repository -y ppa:apptainer/ppa
$ sudo apt update
$ sudo apt install -y apptainer-suid
```
On Ubuntu 23.10+ you likely also need to execute this command
(see  https://github.com/apptainer/apptainer/blob/release-1.3/INSTALL.md#apparmor-profile-ubuntu-2310
for more information) unless you install Apptainer using the `.deb` package
from a GitHub release(https://github.com/apptainer/apptainer/releases):
```
sudo tee /etc/apparmor.d/apptainer << 'EOF'
# Permit unprivileged user namespace creation for apptainer starter
abi <abi/4.0>,
include <tunables/global>
profile apptainer /usr/local/libexec/apptainer/bin/starter{,-suid} 
    flags=(unconfined) {
  userns,
  # Site-specific additions and overrides. See local/README for details.
  include if exists <local/apptainer>
}
EOF
```
Hint: You may need to remove the 'local' in the path to Apptainer. If you
are unsure where your Apptainer installation is located, use 
`whereis apptainer`.

Reload the system apparmor profiles after you have created the file:
```
sudo systemctl reload apparmor
```

If all went well, you should be able to see a version number:
```
apptainer --version
# -->  apptainer version 1.3.4
```

### Running via Apptainer ###
Running Helixer via Apptainer was tested for the following versions recently:
- Apptainer v1.3.4 on Ubuntu 22.04 and Ubuntu 24.04 (with the extra setup command)
- Apptainer v1.3.6 on Ubuntu 22.04

If you want to build locally instead of pulling the Docker image, use the
`Apptainer.def` recipe in this repo:
```
apptainer build --fakeroot HelixerApptainer.sif Apptainer.def
```
Note: `--fakeroot` lets unprivileged users perform build steps that require root
inside the container; if your system is configured for setuid builds, you can
omit it.
To verify the build worked, you can run a quick help command:
```
apptainer run --nv HelixerApptainer.sif Helixer.py --help
```
Full example using the locally built image and example data:
```
# fetch models, they will be downloaded into /home/<user>/.local/share
# unless specified otherwise
apptainer run HelixerApptainer.sif fetch_helixer_models.py

# download an example chromosome
wget ftp://ftp.ensemblgenomes.org/pub/plants/release-47/fasta/arabidopsis_lyrata/dna/Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz

# test Helixer
apptainer run --nv HelixerApptainer.sif Helixer.py \
  --fasta-path Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz --lineage land_plant \
  --gff-output-path Arabidopsis_lyrata_chromosome8_helixer.gff3
```

Alternatively, pull current docker image

```
# pull current docker image 
apptainer pull docker://gglyptodon/helixer-docker:helixer_v0.3.6_cuda_12.2.2-cudnn8

# fetch models, they will be downloaded into /home/<user>/.local/share
# unless specified otherwise
apptainer run helixer-docker_helixer_v0.3.6_cuda_12.2.2-cudnn8.sif fetch_helixer_models.py

# download an example chromosome
wget ftp://ftp.ensemblgenomes.org/pub/plants/release-47/fasta/arabidopsis_lyrata/dna/Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz

# test Helixer
apptainer run --nv helixer-docker_helixer_v0.3.6_cuda_12.2.2-cudnn8.sif Helixer.py \
  --fasta-path Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz --lineage land_plant \
  --gff-output-path Arabidopsis_lyrata_chromosome8_helixer.gff3
# notice '--nv' for GPU support
```


### Installing Singularity ###
If you already have Singularity available, skip to section
[Running via Singularity](#running-via-singularity-).

For Singularity install, see also: 
https://github.com/sylabs/singularity/blob/master/INSTALL.md
or https://docs.sylabs.io/guides/3.0/user-guide/installation.html

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
# use the version you prefer here:
git checkout --recurse-submodules v3.9.9

./mconfig
make -C builddir
sudo make -C builddir install

```
On Ubuntu 23.10+ you likely also need to execute this command
(see  https://github.com/sylabs/singularity/blob/main/INSTALL.md#apparmor-profile-ubuntu-2404
for more information) unless you install Singularity using the `.deb` package
from a GitHub release(https://github.com/sylabs/singularity/releases):
```
sudo tee /etc/apparmor.d/singularity-ce << 'EOF'
# Permit unprivileged user namespace creation for SingularityCE starter
abi <abi/4.0>,
include <tunables/global>

profile singularity-ce /usr/local/libexec/singularity/bin/starter{,-suid} flags=(unconfined) {
  userns,

  # Site-specific additions and overrides. See local/README for details.
  include if exists <local/singularity-ce>
}
EOF
```
Hint: You may need to remove the 'local' in the path to Singularity. If you
are unsure where your Singularity installation is located, use 
`whereis singularity`.

Reload the system apparmor profiles after you have created the file:
```
sudo systemctl reload apparmor
```
If all went well, you should be able to see a version number:
```
singularity --version
# -->  singularity-ce version 3.9.9
```

### Running via Singularity ###
Running Helixer via Singularity was tested for the following versions recently:
- Singularity v3.9.9 on Ubuntu 22.04

> **Warning**: There is a known issue with Singularity that causes the error
> `Error: helixer_post_bin not found in $PATH, this is required for
> Helixer.py to complete.`. To circumvent this issue either use this command to
> pull the image: `sudo singularity pull
> docker://gglyptodon/helixer-docker:helixer_v0.3.6_cuda_12.2.2-cudnn8`
> or use Apptainer instead as this issue doesn't show up.
> Known Singularity version with this issue: singularity-ce 4.2.2 on
> Ubuntu 24.04.
```
# pull current docker image 
singularity pull docker://gglyptodon/helixer-docker:helixer_v0.3.6_cuda_12.2.2-cudnn8

# fetch models, they will be downloaded into /home/<user>/.local/share
# unless specified otherwise
singularity run helixer-docker_helixer_v0.3.6_cuda_12.2.2-cudnn8.sif fetch_helixer_models.py

# download an example chromosome
wget ftp://ftp.ensemblgenomes.org/pub/plants/release-47/fasta/arabidopsis_lyrata/dna/Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz

# test Helixer
singularity run --nv helixer-docker_helixer_v0.3.6_cuda_12.2.2-cudnn8.sif Helixer.py \
  --fasta-path Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz --lineage land_plant \
  --gff-output-path Arabidopsis_lyrata_chromosome8_helixer.gff3
# notice '--nv' for GPU support
```
