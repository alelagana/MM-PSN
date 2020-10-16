import os
import re
import sys
import pandas as pd
import numpy as np
pd.options.mode.chained_assignment = None
from sklearn.svm import LinearSVC
from sklearn.svm import SVC
from itertools import cycle
from xgboost import XGBClassifier
from sklearn.preprocessing import StandardScaler
from dummyPy import OneHotEncoder
#from dummyPy import OneHotEncoder
from sklearn.ensemble import RandomForestClassifier
import joblib


### Read input files 1. Translocations 2. CNV and 3. Expresssion. The given list of features should be there in files. We will extract the required features from each file and if any feature is not there the prgram will stop and throw the error message

exp_file = sys.argv[1]
cnv_file = sys.argv[2]
trans_file = sys.argv[3]
out_file = sys.argv[4]

trans=pd.read_csv(trans_file,index_col=0)
cnv=pd.read_csv(cnv_file,index_col=0)
exp=pd.read_csv(exp_file,index_col=0)

### these files are the features required by this code for predicting the class

with open('/bin/expression_features_rem.tsv') as f:
        exp_list = f.read().splitlines()
with open('/bin/CNV_features.tsv') as f:
        cnv_list = f.read().splitlines()
with open('/bin/translocation_features.tsv') as f:
        trans_list= f.read().splitlines()

cc=cnv.columns.values.tolist()
c=len(list(set(cc).intersection(set(cnv_list))))

if c != 50:
            print("CNV Feature are missing. Please make sure all the features in  CNV_features.tsv is present in your Copy number variation input file ") # you will get an error
cc=trans.columns.values.tolist()
c=len(list(set(cc).intersection(set(trans_list))))
if c != 8:
        print("Translocations Feature are missing. Please make sure all the features in  translocation_features.tsv is present in your translocation input file ") # you will get an error
        # selecting the required features from  all the features 

sel_exp=exp[exp_list]
sel_cnv=cnv[cnv_list]
sel_trans=trans[trans_list]

### load the scaler and z score the vst normalised counts

filename = '/bin/scaler1.sav'
sc = joblib.load(filename)
sel_exp_scaled=sc.transform(sel_exp)
sel_exp_scaled = pd.DataFrame(sel_exp_scaled, index=sel_exp.index, columns=sel_exp.columns)


#### Convert expression data to bins
bins = [-np.inf, -1.5, 1.5, np.inf]
names = ['0','1','2']
sel_exp_bin=sel_exp_scaled.apply(lambda x: pd.cut(x, bins,labels=names), axis=0)

### OneHot encode the expression data
filename = '/bin/encoder1.sav'
encoder1 = joblib.load(filename)
exp_encoded=encoder1.transform(sel_exp_bin)
exp_encoded1 = pd.DataFrame(exp_encoded.toarray())
exp_encoded1.index=sel_exp_bin.index

type(exp_encoded1)

exp_encoded1.columns=encoder1.get_feature_names(sel_exp_bin.columns)
exp_encoded1.iloc[0:5,0:5]

### Convert CNV data to bins
bins = [0, 0.5,1.5, 2.5, 3.5,np.inf]
#bins = [-np.inf,1.5, 2.5,np.inf]
names = ['0','1','2','3','4']
#names = ['0','1','2']
sel_cnv_bin=sel_cnv.apply(lambda x: pd.cut(x, bins,labels=names), axis=0)
#sel_cnv.to_csv("sel_cnv_w")
#sel_cnv_bin.to_csv("sel_cnv_bin_w")
## onehot encoding of CNV data
filename = '/bin/encoder_cnv1.sav'
encoder_cnv = joblib.load(filename)
cnv_encoded=encoder_cnv.transform(sel_cnv_bin)

cnv_encoded1 = pd.DataFrame(cnv_encoded.toarray())
cnv_encoded1.index=sel_cnv_bin.index

type(cnv_encoded1)

cnv_encoded1.columns=encoder_cnv.get_feature_names(sel_cnv_bin.columns)
#cnv_encoded1.iloc[0:5,0:5]
cnv_encoded.index=sel_cnv_bin.index

### Join the different omics 
test = pd.concat([cnv_encoded1,exp_encoded1, sel_trans], axis=1, sort=False)
test = test.infer_objects()
test.to_csv("test")

### load the model and predict the sample and save the file

filename = '/bin/Model1.sav'
clf = joblib.load(filename)
predic_test=clf.predict(test)
predict_test_data = pd.DataFrame(predic_test, index=test.index)
predict_test_data.columns = ['subGroup']
predict_test_data['Subgroup'] = '1a'
predict_test_data['Subgroup'][predict_test_data['subGroup'] == 2] = '1b'
predict_test_data['Subgroup'][predict_test_data['subGroup'] == 3] = '1c'
predict_test_data['Subgroup'][predict_test_data['subGroup'] == 4] = '1d'
predict_test_data['Subgroup'][predict_test_data['subGroup'] == 5] = '2a'
predict_test_data['Subgroup'][predict_test_data['subGroup'] == 6] = '2b'
predict_test_data['Subgroup'][predict_test_data['subGroup'] == 7] = '2c'
predict_test_data['Subgroup'][predict_test_data['subGroup'] == 8] = '2d'
predict_test_data['Subgroup'][predict_test_data['subGroup'] == 9] = '2e'
predict_test_data['Subgroup'][predict_test_data['subGroup'] == 10] = '3a'
predict_test_data['Subgroup'][predict_test_data['subGroup'] == 11] = '3b'
predict_test_data['Subgroup'][predict_test_data['subGroup'] == 12] = '3c'
predict_test_data['Subgroup'][predict_test_data['subGroup'] == 1] = '1a'

df=predict_test_data['Subgroup']
df = pd.DataFrame(df)

#df.to_csv("Predicted_class.csv")
df.to_csv(out_file)



