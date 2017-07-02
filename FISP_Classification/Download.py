
# coding: utf-8

# In[4]:

import sys
sys.path.append("/usr/local/lib/python2.7/site-packages")
import tweepy
import csv
import time 
import os
from datetime import datetime
import requests
import gspread
from oauth2client.service_account import ServiceAccountCredentials


def authenticate_gspread():
    scope = ['https://spreadsheets.google.com/feeds']
    credentials = ServiceAccountCredentials.from_json_keyfile_name('FISPPresidentialProject-1e0a0d30cfd1.json', scope)
    gc = gspread.authorize(credentials)
    return gc


# In[14]:


def download(is_cand):
    
    if is_cand:
        list_spreadsheet_id = '15f13hTa2mYJvyO5qp8m2t-1QkozacKafCNzN7vwpB80'
        path = 'candidate_tweets_data/'
    else:
        list_spreadsheet_id = '1-CXoWSIXDD7Qd56Fll6fhYJdDTf8trWgykMW_BbKR7Q'
        path = 'pac_tweets_data/'
        
    if not os.path.isdir(path):
        os.mkdir(path)
        
    gc = authenticate_gspread()
    list_sp = gc.open_by_key(list_spreadsheet_id)

    for i in range(len(list_sp.worksheets())):
        curr_sheet = list_sp.get_worksheet(i)
        title = curr_sheet.title
        datas = curr_sheet.get_all_values()
        del datas[0]
        with open(path+title+'.csv', 'w') as f:
            writer = csv.writer(f)
            writer.writerows(datas)
download(True)
download(False)

