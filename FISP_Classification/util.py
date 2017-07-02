
# coding: utf-8

# In[3]:



# In[80]:

import csv
import os
import re
from collections import defaultdict
import string

DATA_DIR = 'data/'

category = ['No_Policy_Content',
        'Macroeconomic_Policy___Taxes__Gov__Spending__Wall_St___Jobs__Trade__Infrastructure__Labor_',
        'Education',
        'National_Security__Veterans__Military__Foreign_Terrorism_',
        'Immigration',
        'Civil_Rights__Race__LGBT_issues__Abortion__Gender_issues_',
        'Environment___Energy__Global_warming__Fracking__Agriculture__Oil_',
        'Crime___Law_Enforcement__Police__Guns__Second_Amendment_',
        'Health_Care__Obamacare_',
        'Governance']

def process_text(text):
    text = re.sub('http.*?\s', 'http ', text)
    text = re.sub('http.*?$', 'http ', text)
    text = text.lower()
    text = text.translate(None, string.punctuation)
    return text


# In[9]:

import random
def load_data1():
    data_dir = 'raw_data/'
    files = filter(lambda x: x.endswith('.csv'),os.listdir(data_dir))

    header = []
    data = []
    for f in files:
        with open(data_dir+f) as data_in:
            reader = csv.reader(data_in)
            new_header = reader.next()
            header.extend(new_header)
            for l in reader:
                tweet = dict(zip(new_header,l))
                data.append(tweet)
    classifications = defaultdict(list)
    count = 0
    for tweet in data:
        single_tweet = defaultdict(list)
        text = tweet['text']
        for key,val in tweet.items():
            if key.startswith('coder1') or key.startswith('coder2'):

                key = key.replace('coder1.','')
                key = key.replace('coder2.','')
                key = key.replace('.','_')

                # skip coder, it's not a label
                if key == 'coder':
                    continue
                
                if key in category:
                    if val == '1':
                        single_tweet['Policy'].append(int(category.index(key)))
                else:
                    single_tweet[key].append(val)

        for key in single_tweet:
            if len(single_tweet[key]) == 2:
                if single_tweet[key][0] != single_tweet[key][1]:
#                     if random.random() > 0.5:
#                         classifications[key].append([text, single_tweet[key][0]])
#                     else:
#                         classifications[key].append([text, single_tweet[key][1]])
                    continue
                else:
                    classifications[key].append([text, single_tweet[key][0]])
            else:
                classifications[key].append([text, single_tweet[key][0]])
    return classifications


# In[ ]:

def save_data():
    classifications = load_data()
    for key, val in classifications.items():
        with open(DATA_DIR+key+'.csv', 'w') as f:
            writer = csv.writer(f)
            writer.writerows(val)


# In[6]:

# In[81]:

def load_data2():
    data_dir = 'raw_data2/'
    files = filter(lambda x: x.endswith('.csv'),os.listdir(data_dir))
    header = []
    data = []
    classifications = defaultdict(list)
    for f in files:
        with open(data_dir+f) as data_in:
            reader = csv.reader(data_in)
            new_header = reader.next()
            header.extend(new_header)
            for l in reader:
                tweet = dict(zip(new_header,l))
                data.append(tweet)

    classifications = defaultdict(list)
    
    for tweet in data:
        text = tweet['text']
        try:
            text.decode('utf-8')
        except:
            continue
        single_tweet = {}
        for key, val in tweet.items():
            if key in ['id', 'created_at', 'text']:
                continue
            
            key = key.replace('.','_')
            
            if val == 'NA':
                val = '0'
            
            if key in category:
                if val == '1':
                    single_tweet['Policy'] = int(category.index(key))
            else:
                single_tweet[key] = val
        for key in single_tweet:
            classifications[key].append([text, single_tweet[key]])
        
    return classifications


# In[7]:

# In[82]:

def load_data():
    data1 = load_data1()
    data2 = load_data2()
    data = {}
    for key in data1:
        data[key] = data1[key] + data2[key]
    return data


# In[8]:

load_data2()


# In[ ]:



