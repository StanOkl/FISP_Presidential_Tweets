
# coding: utf-8

# In[5]:

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import LinearSVC
from sklearn.naive_bayes import MultinomialNB
from sklearn.naive_bayes import BernoulliNB
from sklearn import metrics
from sklearn.model_selection import cross_val_score
from sklearn.ensemble import AdaBoostClassifier, RandomForestClassifier, BaggingClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.decomposition import TruncatedSVD
from sklearn.model_selection import train_test_split
from sklearn import metrics
from nltk.stem.porter import PorterStemmer
import nltk
import pandas as pd
import numpy as np
import sys
import matplotlib.pylab as plt
from importlib import reload


# In[6]:

## functions for lexical analysis

def stem_tokens(tokens, stemmer):
    stemmed = []
    for item in tokens:
        stemmed.append(stemmer.stem(item))
    return stemmed

def tokenize(text):
    tokens = nltk.word_tokenize(text)
    stems = stem_tokens(tokens,stemmer)
    return stems

def text2vec(full_text, use_stemmer=False):
    """
    Convert text to vectors using TFIDF
    ngram_range=(1,3) means unigrams, bigrams and trigrams; 
    if want to use bigrams only, define ngram_range=(2,2)
    
    """
    text=full_text[:]
    if use_stemmer:
        vectorizer = TfidfVectorizer(tokenizer=tokenize,ngram_range=(1,3))
    else:
        vectorizer = TfidfVectorizer(ngram_range=(1,3))
    text_vector = vectorizer.fit_transform(text)
    return text_vector


# 

# In[7]:

pd.options.display.float_format = '{:.2f}'.format


# In[8]:

#reload(sys)  
#sys.setdefaultencoding('utf8')


# # Step 1: Load the Data
# Load "human-coded-tweets" into a pandas dataframe. Data preprocessing (convert to lower case, remove punctuation, remove screen names. etc) should be done before this step.

# In[11]:

stemmer = PorterStemmer()
data = pd.DataFrame.from_csv('training_data.csv')

# take the 'text' column from the dataframe, and 
# convert the text to vectors
full_text = data['text'].astype('U')
text_vec = text2vec(full_text, use_stemmer=True)


# In[15]:

##Find the number of rows in the training data, reserve 725 test tweets
nrows = len(full_text)
train_end= nrows-725
print(train_end)


# # Step 2: Split the data
# Split the data into a training set and a test set. Ideally the data should be shuffled before the split to avoid implicit bias in the dataset.

# In[16]:

pred_train = text_vec[0:train_end,] # 7638 training tweets as of 2-21-2018
pred_test = text_vec[train_end:,] # 725 test tweets
pred_matrix = np.zeros((725,18))


# # Step 3: Pick the right models
# The classification pipeline is: fitting the model with the training set -> predict labels on the test set -> compare predicted labels to real labels(human-coded-labels). These are all done on the human-coded-tweets, for the purpose of finding the best classification model with appropriate hyper-parameter settings. 
# 
# These could be done in one big for-loop, but it takes a long time to run, and it did crash my computer several times. What I did was to run classifications on only a few categories at a time - there would be many repeated code.
# 

# - Sentiment (Multinomial Naive Bayes); different alpha values would yield slightly different classification results

# In[17]:

key = 'Sentiment'
alpha = 0.4

# real labels for the training set
tar_train = data[key][0:train_end,] 
# real labels for the test set
tar_test = data[key][train_end:,]

# specify the classification model
clf = MultinomialNB(alpha=alpha, fit_prior=True, class_prior=None)
# fit the model with the training set
clf.fit(pred_train, tar_train)
# compute training accuracy
train_score = clf.score(pred_train, tar_train)
# predict labels on the test set
y_pred = clf.predict(pred_test)

# compute standard metrics
test_accuracy = metrics.accuracy_score(tar_test.values.astype(int), y_pred)
class_report = metrics.classification_report(tar_test.values.astype(int), y_pred)
kappa = metrics.cohen_kappa_score(tar_test.values.astype(int), y_pred)

print(key)
print('='*50)
print('Training Accuracy: '+'{:.4f}'.format(train_score))
print('Test Accuracy: '+'{:.4f}'.format(test_accuracy))
print('Kappa: '+'{:.4f}'.format(kappa))
print(class_report)
print('\n')


# - Political & Makes_a_Factual_or_Verifiable_Claim (Linear SVC)

# In[18]:

keys = ['Political', 'Makes_a_Factual_or_Verifiable_Claim']

for key in keys: 
    # real labels for the training set
    tar_train = data[key][0:train_end,] 
    # real labels for the test set
    tar_test = data[key][train_end:,]

    # specify the classification model
    clf = LinearSVC(class_weight='balanced')
    # fit the model with the training set
    clf.fit(pred_train, tar_train)
    # compute training accuracy
    train_score = clf.score(pred_train, tar_train)
    # predict labels on the test set
    y_pred = clf.predict(pred_test)

    # compute standard metrics
    test_accuracy = metrics.accuracy_score(tar_test.values.astype(int), y_pred)
    class_report = metrics.classification_report(tar_test.values.astype(int), y_pred)
    kappa = metrics.cohen_kappa_score(tar_test.values.astype(int), y_pred)

    print(key)
    print('='*50)
    print('Training Accuracy: '+'{:.4f}'.format(train_score))
    print('Test Accuracy: '+'{:.4f}'.format(test_accuracy))
    print('Kappa: '+'{:.4f}'.format(kappa))
    print(class_report)
    print('\n')


# - Ideology & Immigration & Macroeconomic & National_Security & 
# Crime & Civil_Rights & Environment & Education & Health_Care (Bagging Classifier)

# In[19]:

max_samples=0.7
max_features=0.8
keys = ['Ideology', 'Immigration', 'Macroeconomic', 'National_Security', 'Crime', 'Civil_Rights',
        'Environment', 'Education']

for key in keys: 
    # real labels for the training set
    tar_train = data[key][0:train_end,] 
    # real labels for the test set
    tar_test = data[key][train_end:,]

    # specify the classification model
    clf = BaggingClassifier(LinearSVC(class_weight='balanced'), 
                            max_samples=max_samples, max_features=max_features)
    # fit the model with the training set
    clf.fit(pred_train, tar_train) 
    # compute training accuracy
    train_score = clf.score(pred_train, tar_train)
    # predict labels on the test set
    y_pred = clf.predict(pred_test)

    # compute standard metrics
    test_accuracy = metrics.accuracy_score(tar_test.values.astype(int), y_pred)
    class_report = metrics.classification_report(tar_test.values.astype(int), y_pred)
    kappa = metrics.cohen_kappa_score(tar_test.values.astype(int), y_pred)

    print(key)
    print('='*50)
    print('Training Accuracy: '+'{:.4f}'.format(train_score))
    print('Test Accuracy: '+'{:.4f}'.format(test_accuracy))
    print('Kappa: '+'{:.4f}'.format(kappa))
    print(class_report)
    print('\n')


# - Governance & No_Policy_Content & Asks_for_Donation &  Asks_you_to_watch_something_share_something_follow_something & Misc & Expresses_an_Opinion (Bagging Classifier)

# In[20]:

max_samples=0.7
max_features=0.8
keys = ['Governance', 'No_Policy_Content', 'Asks_for_Donation', 
        'Asks_you_to_watch_something_share_something_follow_something',
        'Misc', 'Expresses_an_Opinion']

for key in keys: 
    # real labels for the training set
    tar_train = data[key][0:train_end,] 
    # real labels for the test set
    tar_test = data[key][train_end:,]

    # specify the classification model
    clf = BaggingClassifier(LinearSVC(class_weight='balanced'),
                            max_samples=max_samples, max_features=max_features)
    # fit the model with the training set
    clf.fit(pred_train, tar_train)
    # compute training accuracy
    train_score = clf.score(pred_train, tar_train)
    # predict labels on the test set
    y_pred = clf.predict(pred_test)

    # compute standard metrics
    test_accuracy = metrics.accuracy_score(tar_test.values.astype(int), y_pred)
    class_report = metrics.classification_report(tar_test.values.astype(int), y_pred)
    kappa = metrics.cohen_kappa_score(tar_test.values.astype(int), y_pred)

    print(key)
    print('='*50)
    print('Training Accuracy: '+'{:.4f}'.format(train_score))
    print('Test Accuracy: '+'{:.4f}'.format(test_accuracy))
    print('Kappa: '+'{:.4f}'.format(kappa))
    print(class_report)
    print('\n')


# # Step Four: Final Classifications
# Having the appropriate models and hyper-parameter settings, we can use the models to predict labels for the entire corpus of tweets. At this step, we take all 7525 human-coded-tweets as the training set, and the whole corpus as the test set.

# In[22]:

# load training data and convert to a vector
train_data = pd.DataFrame.from_csv('training_data.csv')
train_text = train_data['text'].astype('U')
vectorizer = TfidfVectorizer(tokenizer=tokenize,ngram_range=(1,3))
pred_train = vectorizer.fit_transform(train_text)


# In[23]:

# load the full corpus and convert to a vector
final_data = pd.DataFrame.from_csv('ProcessedFullCorpus.csv')
final_text = final_data['text']
pred_final = vectorizer.transform(final_text.values.astype('unicode'))


# In[24]:

# specify classification models and hyper-parameter settings
alpha = 0.1
max_samples=0.7
max_features=0.8

def runClassifiers(classifier, pred_train, tar_train, pred_final):
    if classifier=='NB':
        clf = MultinomialNB(alpha=alpha, fit_prior=True, class_prior=None)
    elif classifier=='SVC':
        clf = LinearSVC(class_weight='balanced')
    elif classifier=='Bag':
        clf = BaggingClassifier(LinearSVC(class_weight='balanced'),
                                max_samples=0.7, max_features=0.8)
    clf.fit(pred_train,tar_train.values.astype(int))
    print('fit successfully')
    y_class_final = clf.predict(pred_final)
    print('predict successfully')
    return y_class_final

# A list hardcoded to specify the classifier to use for each category
classifiers = ['NB','SVC','Bag','Bag','Bag','Bag','Bag','Bag','Bag',
               'Bag','Bag','Bag','Bag','Bag','Bag','Bag','SVC','Bag']


# In[25]:

# obtain column names
keys = [key for key in train_data if key != 'text']
pred_matrix = np.zeros((len(final_data),18))


# In[26]:

# final classifications: save prediction results in a matrix
for n, key in enumerate(keys):
    tar_train = train_data[key]
    y_final = runClassifiers(classifiers[n], pred_train, tar_train, pred_final)
    print(key+' Classifications Done')
    print('-'*50)
    pred_matrix[:,n] = y_final


# In[29]:

# convert prediction matrix into dataframe
final_df = pd.DataFrame(pred_matrix).astype(int)
final_df.columns = keys


# In[30]:

final_df.sample(5)


# In[31]:


final_file = pd.concat([final_data.reset_index(drop=True), final_df], axis=1)


# In[32]:

# save prediction result to csv
out_file = 'finalPredictionTest.csv'
final_file.to_csv(out_file)


# In[33]:

list(final_file)


# In[ ]:



