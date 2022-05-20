#!/bin/bash

mkdir -p example/train
mkdir -p example/test

python3 Helixer/export.py --db-path-in three_algae/three_algae.sqlite3   --genomes Ostreococcus_lucimarinus,Cyanidioschyzon_merolae --out-dir example/unfiltered_train

python3 Helixer/export.py --db-path-in three_algae/three_algae.sqlite3 --genomes Chlamydomonas_reinhardtii --out-dir example/unfiltered_test --only-test-set

python3 Helixer/scripts/filter_fully_erroneous.py -d example/unfiltered_train/training_data.h5 -o example/train/training_data.h5

python3 Helixer/scripts/filter_fully_erroneous.py -d example/unfiltered_train/validation_data.h5 -o example/train/validation_data.h5

python3 Helixer/scripts/filter_fully_erroneous.py -d example/unfiltered_test/test_data.h5 -o example/test/test_data.h5

python3 Helixer/helixer/prediction/LSTMModel.py --data-dir example/train/ --save-model-path example/best_helixer_model.h5 --epochs 5 --units 64 --pool-size 10

## python3 Helixer/helixer/prediction/LSTMModel.py --data-dir example/train/ --save-model-path example/best_helixer_model.h5 --epochs 5 --units 256 --pool-size 10 --batch-size 52 --layers 4 --layer-normalization --class-weights '[0.7, 1.6, 1.2, 1.2]'
