#!/usr/bin/env python
# coding: utf-8

# In[ ]:


import os
import re
import sys
import pandas as pd
import numpy as np
from sklearn.svm import LinearSVC
from sklearn.svm import SVC
from itertools import cycle
from xgboost import XGBClassifier
from sklearn.preprocessing import StandardScaler
from dummyPy import OneHotEncoder
from sklearn.ensemble import RandomForestClassifier
import joblib


### Read input files 1. Translocations 2. CNV and 3. Expresssion. The given list of features should be there in files. We will extract the required features from each file and if any feature is not there the prgram will stop and throw the error message

exp_file = sys.argv[1]
cnv_file = sys.argv[2]
trans_file = sys.argv[3]
trans=pd.read_csv(trans_file,index_col=0)
cnv=pd.read_csv(cnv_file,index_col=0)
exp=pd.read_csv(exp_file,index_col=0)

### these files are the features required by this code for predicting the class

with open('expression_features.tsv') as f:
    exp_list = f.read().splitlines()
with open('CNV_features.tsv') as f:
    cnv_list = f.read().splitlines()
with open('translocation_features.tsv') as f:
    trans_list= f.read().splitlines()
    
cc=cnv.columns.values.tolist()
c=len(list(set(cc).intersection(set(cnv_list))))
if c != 50:
        print("CNV Feature are missing. Please make sure all the features in  CNV_features.tsv is present in your Copy number variation input file ") # you will get an error
            
cc=exp.columns.values.tolist()
c=len(list(set(cc).intersection(set(exp_list))))
if c != 109:
    print("Expression Feature are missing. Please make sure all the features in  expression_features.tsv is present in your expression input file ") # you will get an error
                        
cc=trans.columns.values.tolist()
c=len(list(set(cc).intersection(set(trans_list))))
if c != 8:
    print("Translocations Feature are missing. Please make sure all the features in  translocation_features.tsv is present in your translocation input file ") # you will get an error
# selecting the required features from  all the features 
sel_exp=exp[exp_list]
sel_cnv=cnv[cnv_list]
sel_trans=trans[trans_list]


### load the scaler and z score the vst normalised counts

filename = 'scaler.sav'
sc = joblib.load(filename)
sel_exp_scaled=sc.transform(sel_exp)
sel_exp_scaled = pd.DataFrame(sel_exp_scaled, index=sel_exp.index, columns=sel_exp.columns)


#### Convert expression data to bins
bins = [-np.inf, -1.5, 1.5, np.inf]
names = ['0','1','2']
sel_exp_bin=sel_exp_scaled.apply(lambda x: pd.cut(x, bins,labels=names), axis=0)

### OneHot encode the expression data
filename = 'encoder.sav'
encoder1 = joblib.load(filename)
exp_encoded=encoder1.transform(sel_exp_bin)
exp_encoded.index=sel_exp_bin.index

### Convert CNV data to bins
bins = [0, 0.5,1.5, 2.5, 3.5,np.inf]
names = ['0','1','2','3','4']
sel_cnv_bin=sel_cnv.apply(lambda x: pd.cut(x, bins,labels=names), axis=0)

## onehot encoding of CNV data
filename = 'encoder_cnv.sav'
encoder_cnv = joblib.load(filename)
#encoder_cnv = load(open('onehotencoder_cnv.pkl', 'rb'))
cnv_encoded=encoder_cnv.transform(sel_cnv_bin)
cnv_encoded.index=sel_cnv_bin.index


### Join the different omics 
test = pd.concat([cnv_encoded,exp_encoded, trans, ], axis=1, sort=False)
test = test.infer_objects() 


### load the model and predict the sample and save the file

filename = 'Model.sav'
clf = joblib.load(filename)
predic_test=clf.predict(test)
predict_test_data = pd.DataFrame(predic_test, index=test.index)
predict_test_data.columns = ['subGroup']
predict_test_data.to_csv("Predicted_class.csv")

