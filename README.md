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
wget https://raw.githubusercontent.com/gglyptodon/helixer-docker/main/Dockerfile
mkdir -p data/out
chmod o+w data/out # something the container can write to

docker build -t helixer_testing_tf11_2_cudnn8 --rm .
```


- Run:
```
docker run --runtime=nvidia -it --name helixer_testing --rm --mount type=bind,source="$(pwd)"/data,target=/home/helixer_user/shared helixer_testing_tf11_2_cudnn8:latest
```


- Try out:
```
helixer_user@03356047d15f:~$ cd shared/out/

helixer_user@03356047d15f:~/shared/out$ mkdir models
curl https://uni-duesseldorf.sciebo.de/s/4NqBSieS9Tue3J3/download --output models/land_plant.h5

helixer_user@03356047d15f:~/shared/out$ curl -L ftp://ftp.ensemblgenomes.org/pub/plants/release-47/fasta/arabidopsis_lyrata/dna/Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz --output Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz

helixer_user@03356047d15f:~/shared/out$ gunzip Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa.gz

helixer_user@03356047d15f:~/shared/out$ fasta2h5.py --species Arabidopsis_lyrata --h5-output-path Arabidopsis_lyrata.h5 --fasta-path Arabidopsis_lyrata.v.1.0.dna.chromosome.8.fa
# ->  Numerification of 0-22951293 of the sequence of 8 took 3.50 secs
# 1 Numerified Fasta only Coordinate (seqid: 8, len: 22951293)
# in 8.59 secs [...]

helixer_user@03356047d15f:~/shared/out$ ~/Helixer/helixer/prediction/HybridModel.py --load-model-path models/land_plant.h5 --test-data Arabidopsis_lyrata.h5 --overlap --val-test-batch-size 32 -v
# -->
# Total params: 2,105,672
# Trainable params: 2,105,096
# Non-trainable params: 576
# [...]

helixer_user@03356047d15f:~/shared/out$ helixer_post_bin Arabidopsis_lyrata.h5 predictions.h5 100 0.1 0.8 60 Arabidopsis_lyrata_chromosome8_helixer.gff3
# --> Total: 12727167bp across 2300 windows

```
