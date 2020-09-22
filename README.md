# MM-PSN
Multiple Myeloma Patient Similarity Network
This is the classifier that’s predicts the subgroup of the multiple myeloma patients based on the multi-omics data. It requires gene expression, Copy Number Alterations (CNA) and Translocation calls to predict the patient subgroups. Theses subgroups have been determined using Patient Similarity Networks on the multi-omics data.

#Usage:
python predict_psn_subgroup.py sample_exp.csv sample_cnv.csv sample_trans.csv


This classifier requires 109 expression features, 50 CNA features and 8 translocation calls. The sample files are provided in the repository (sample_exp.csv, sample_cnv.csv and sample_trans.csv). The list of three types of features is also provided in the files (expression_features.tsv, CNV_features.tsv and translocation_features.csv). This program gives the output file “Predicted_class.csv” which provides predicted class for each patient. 

The versions of the following packages were used to develop the Multiple Myeloma Patient Similarity Network

xgboost: 0.90, 
Python: 3.7.3, 
Scikit: 0.22.2
