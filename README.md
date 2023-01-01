# helixer-docker

This repository accompanies https://github.com/weberlab-hhu/Helixer .

The aim is to provide a mostly hassle-free way to use Helixer via docker (or singularity).

For more information on how to run Helixer, please refer to its [documentation](https://github.com/weberlab-hhu/Helixer).

--------

### Instructions for docker (for use with Nvidia GPUs) ###

- Prerequisites (on host):
  - Nvidia GPU with CUDA capabilities >=3.5; installed driver version >= 450.80.02 
  
> Note that the code _will_ run on the CPU if an Nvidia GPU or appropriate drivers are not available.
> However, the walltime requirements will increase _substantially_. If not running on the GPU
> exclude the parameter `--runtime=nvidia` when running `docker run`, or the parameter `--nv` when
> running `singularity run`, respectively.

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

### Pull prepared image ###
```
docker pull gglyptodon/helixer-docker:helixer_v0.3.0_cuda_11.2.0-cudnn8
# run container interactively 
docker run --runtime=nvidia -it gglyptodon/helixer-docker:helixer_v0.3.0_cuda_11.2.0-cudnn8
```
```
# additionally, set up a shared directory and mount it, e.g.:
# on host:
mkdir -p data/out
chmod o+w data/out # something the container can write to
# mount directory and run interactively:
docker run --runtime=nvidia -it --name helixer_testing_v0.3.0_cuda_11.2.0-cudnn8 --rm --mount type=bind,source="$(pwd)"/data,target=/home/helixer_user/shared gglyptodon/helixer-docker:helixer_v0.3.0_cuda_11.2.0-cudnn8
```

### Alternatively, build it yourself ###
- Build:
```
mkdir SOME_DIR
cd SOME_DIR
wget https://raw.githubusercontent.com/gglyptodon/helixer-docker/main/Dockerfile

mkdir -p data/out
chmod o+w data/out # something the container can write to

docker build -t helixer_v0.3.0 --rm .
```


- Run:
```
docker run --runtime=nvidia -it --name helixer_v0.3.0 --rm --mount type=bind,source="$(pwd)"/data,target=/home/helixer_user/shared helixer_v0.3.0:latest
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
singularity pull  docker://gglyptodon/helixer-docker:helixer_v0.3.0_cuda_11.2.0-cudnn8

# in this example, the directory "helixer_test" already contains downloaded data
singularity run --nv helixer-docker_helixer_v0.3.0_cuda_11.2.0-cudnn8.sif Helixer.py --fasta-path helixer_test/Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz --lineage land_plant --gff-output-path Arabidopsis_lyrata_chromosome8_helixer.gff3
# notice '--nv' for GPU support
```
