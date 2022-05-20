#!/bin/bash

python3 Helixer/helixer/prediction/LSTMModel.py --load-model-path example/best_helixer_model.h5 --test-data example/test/test_data.h5 --prediction-output-path example/Chlamydomonas_reinhardtii_predictions.h5

python3 Helixer/helixer/prediction/LSTMModel.py --load-model-path example/best_helixer_model.h5 --test-data example/test/test_data.h5 --eval
