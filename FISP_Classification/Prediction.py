
# coding: utf-8

# In[1]:

import csv
import os
import re
from util import load_data, process_text, category
from collections import defaultdict
import nltk
import string
import os
from nltk.stem.porter import PorterStemmer

stemmer = PorterStemmer()

def stem_tokens(tokens, stemmer):
    stemmed = []
    for item in tokens:
        stemmed.append(stemmer.stem(item))
    return stemmed

def tokenize(text):
    tokens = nltk.word_tokenize(text)
    stems = stem_tokens(tokens, stemmer)
    return stems


# In[2]:

training_datas = load_data()


# In[3]:

header = ['id','created_at','text','hashtag#','at@','link','retweets','favorites','full URL','from','Human Encoded']
header.extend(training_datas.keys())


# In[4]:

human_encoded_text = set(map(lambda x: x[0], training_datas[training_datas.keys()[0]]))
CANDID_RAW_DIR = 'candidate_tweets_data/'
PAC_RAW_DIR = 'pac_tweets_data/'

def load_tweets(folder):

    data = []
    human_encoded_index = header.index('Human Encoded')
    from_index = header.index('from')
    
    files = filter(lambda x: x.endswith('.csv'),os.listdir(folder))
    for f in files:
        with open(folder+f) as data_in:
            cand_name = f.split('.')[0]
            reader = csv.reader(data_in)
            new_header = reader.next()
            for tweet in reader:
                try:
                    tweet[2].decode('utf-8')
                except:
                    continue
                while len(tweet) < len(header):
                    tweet.append('')
                tweet[from_index] = cand_name
                tweet[human_encoded_index] = tweet[2] in human_encoded_text #check whether this is human encoded
                data.append(tweet)
    return data
data = load_tweets(CANDID_RAW_DIR) + load_tweets(PAC_RAW_DIR)


# In[5]:

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import LinearSVC
from sklearn.ensemble import AdaBoostClassifier, RandomForestClassifier, BaggingClassifier
from sklearn.decomposition import TruncatedSVD
from collections import defaultdict
import numpy as np

def run(use_stemmer=False):
    for key,training_data in training_datas.items():
        if use_stemmer:
            training_text = map(lambda x: process_text(x[0]), training_data)
            testing_text = map(lambda x: process_text(x[2]), data)
        else:
            training_text = map(lambda x: x[0], training_data)
            testing_text = map(lambda x: x[2], data)

        training_label = map(lambda x: x[1], training_data)
        training_data_lookup = dict(zip(training_text, training_label))

        output_space = set([tweet[1] for tweet in training_data])
        weight_mode = None

        if use_stemmer:
            vectorizer = TfidfVectorizer(tokenizer=tokenize, ngram_range=(1,3))
        else:
            vectorizer = TfidfVectorizer(ngram_range=(1,3))

        training_matrix = vectorizer.fit_transform(training_text)
        testing_matrix = vectorizer.transform(testing_text)

        for label in output_space:
            if prior(training_data,label) < 0.1:
                weight_mode = 'balanced'
                break

        svc = LinearSVC(class_weight = weight_mode)
        svc.fit(training_matrix, training_label)
        prediction = svc.predict(testing_matrix)

        prediction_index = header.index(key) # index of prediction in header
        for i in range(len(data)):
            text = data[i][2]
            is_human_encoded = data[i][human_encoded_index]
            if is_human_encoded:
                try:
                    data[i][prediction_index] = training_data_lookup[text]
                except:
                    data[i][prediction_index] = prediction[i]
            else:
                data[i][prediction_index] = prediction[i]
            


# In[6]:

run()
with open('result.csv','w') as f:
    writer = csv.writer(f)
    writer.writerow(header)
    writer.writerows(data)


# In[ ]:



