
# coding: utf-8

# In[2]:

from util import load_data, process_text
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import LinearSVC
from sklearn.ensemble import AdaBoostClassifier, RandomForestClassifier, BaggingClassifier
from sklearn.decomposition import TruncatedSVD
from collections import defaultdict
import numpy as np
import nltk
import string
import os
from nltk.stem.porter import PorterStemmer


# In[3]:

def avg(l):
    return sum(l) * 1.0 / len(l)

def prior(l, label):
    return sum(map(lambda x: x[1] == label, l)) * 1.0 / len(l)


# In[4]:

def cross_validation_decomp(data, group_size = 10):
    for i in range(group_size):
        sub_size = len(data) / group_size
        first_half = data[:(i-1)*sub_size] if i > 0 else []
        second_half = data[(i+1)*sub_size:] if i < group_size - 1 else []
        train_data = first_half + second_half
        test_data = data[i*sub_size:(i+1)*sub_size]
        yield (train_data, test_data)


# In[5]:

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

def run_classifer(classifier, use_stemmer=False, dimension_reduction=False):
    data = load_data()
    for key in data:

        accuracies = []
        sub_acc = defaultdict(list)
        sub_recall = defaultdict(list)
        category = set([tweet[1] for tweet in data[key]])

        for train_data, test_data in cross_validation_decomp(data[key]):
            
            if use_stemmer:
                training_text = [process_text(tweet[0]) for tweet in train_data]
                testing_text = [process_text(tweet[0]) for tweet in test_data]
            else:
                training_text = [tweet[0] for tweet in train_data]
                testing_text = [tweet[0] for tweet in test_data]

            training_label = [tweet[1] for tweet in train_data]
            testing_label = [tweet[1] for tweet in test_data]

            if use_stemmer:
                vectorizer = TfidfVectorizer(tokenizer=tokenize, ngram_range=(1,3))
            else:
                vectorizer = TfidfVectorizer(ngram_range=(1,3))
            training_matrix = vectorizer.fit_transform(training_text)
            testing_matrix = vectorizer.transform(testing_text)


            weight_mode = None
            for label in category:
                if prior(train_data,label) < 0.1:
                    weight_mode = 'balanced'
                    break

            if dimension_reduction: 
                dimension_reduction = TruncatedSVD(n_components = 1000)
                training_matrix = dimension_reduction.fit_transform(training_matrix)
                testing_matrix = dimension_reduction.transform(testing_matrix)
            
            if classifier == 'LinearSVC':
                clf = LinearSVC(class_weight = weight_mode)
            elif classifier == 'RandomForest':
                clf = RandomForestClassifier(n_estimators=10)
            elif classifier == 'AdaBoostClassifier':
                clf = AdaBoostClassifier(n_estimators=100)
            elif classifier == 'BaggingClassifier':
                clf = BaggingClassifier(LinearSVC(),max_samples=0.5, max_features=0.7)

            clf.fit(training_matrix, training_label)
            prediction = clf.predict(testing_matrix)
            
            for label in category:
                sub_acc[label].append(sum([a[0] == a[1] and a[0] == label for a in zip(testing_label, prediction)]) * 1.0 / (sum([a == label for a in testing_label]) + 1))
                sub_recall[label].append(sum([a[0] == a[1] and a[1] == label for a in zip(testing_label, prediction)])* 1.0 / (sum([a == label for a in prediction]) + 1))
            accuracies.append(clf.score(testing_matrix,testing_label))
        
        print("===================")
        print(classifier)
        print(key+':')
        print("label     prior     accuracy  recall")
        for label in category:
            print("%-9s%1.7f  %1.7f  %1.7f" %(label, prior(data[key],label),avg(sub_acc[label]), avg(sub_recall[label])))

        print('overall accuracy:' + str(avg(accuracies)))
        print('\n\n')


# In[12]:

run_classifer('LinearSVC', use_stemmer=True)


# In[ ]:

run_classifer('RandomForest')


# In[ ]:

run_classifer('AdaBoostClassifier')


# In[ ]:

run_classifer('BaggingClassifier',use_stemmer=True)


# In[ ]:

run_classifer('LinearSVC', use_stemmer=True)


# In[ ]:



