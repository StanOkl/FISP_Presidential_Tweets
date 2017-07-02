
# coding: utf-8

# In[1]:

import sys
sys.path.append("/usr/local/lib/python2.7/site-packages")
import tweepy
import csv
import time
import os
from datetime import datetime
from collections import defaultdict
import logging

logging.basicConfig(level=logging.WARN)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

#Twitter API credentials
consumer_key = "4DpnU3wXjbRTmTbD54lCOR1JA"
consumer_secret = "AmOucdmRf3beW0iWIjfFflQMBLymtc9cdWIf7Nr2WEaerwuU2n"
access_key = "729532267152838660-BdKw01XvE3W2MdQ59AuDLxv7QgGR17O"
access_secret = "rJBYmT49o2BvQbeqUbA8f6fYCvFYPZ6vorVRXcZwRIlsF"

import gspread
from oauth2client.service_account import ServiceAccountCredentials
def authenticate_gspread():
    scope = ['https://spreadsheets.google.com/feeds']
    credentials = ServiceAccountCredentials.from_json_keyfile_name('FISPPresidentialProject-1e0a0d30cfd1.json', scope)
    gc = gspread.authorize(credentials)
    return gc

def authenticate_twitter():
    auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
    auth.set_access_token(access_key, access_secret)
    api = tweepy.API(auth)
    return api


# In[ ]:

def get_new_tweets(tweet_name, since_id):
    api = authenticate_twitter()
    tweets = []
    new_tweets = api.user_timeline(screen_name = tweet_name, since_id = since_id, count = 200)
    tweets.extend(new_tweets)
    if len(tweets) > 0:
        max_id = tweets[-1].id - 1
    while (len(new_tweets)):
        new_tweets = api.user_timeline(screen_name = tweet_name, since_id = since_id, count = 200, max_id = max_id)
        tweets.extend(new_tweets)
        max_id = tweets[-1].id - 1

    tweets = [[tweet.id_str, tweet.created_at, tweet.text, "", "", "",tweet.retweet_count, tweet.favorite_count] for tweet in tweets]
    logger.info("Downloading %d tweets from %s" % (len(tweets), tweet_name))
    return tweets[::-1]

def get_lists(worksheet, is_cand):
    names = filter(lambda x: len(x) > 0, worksheet.col_values(2))
    max_ids = worksheet.col_values(3)[:len(names)]
    counts = worksheet.col_values(4)[:len(names)]
    indices = range(1,len(names)+1)
    lists = zip(names, max_ids, counts, indices)
    del lists[0] # the first one is column title
    return lists

def collect_addition_data(is_cand):
    logger.info("Start...")
    gc = authenticate_gspread()
    list_spreadsheet_id = "11HeMXQIslUJ6bEOq26I5M8ZeTyxSP8hmYROu2uTdW8g"
    list_sp = gc.open_by_key(list_spreadsheet_id)
    if is_cand:
        list_worksheet = list_sp.worksheet('candidate')
    else:
        list_worksheet = list_sp.worksheet('pac')
    lists = get_lists(list_worksheet, is_cand)
    if is_cand:
        orginal_spreadsheet_id =  '1WJRUEWr-wou5PlOu7D0WFa-ROn451FtdyT0WGD_9BRE'
        new_spreadsheet_id = '15f13hTa2mYJvyO5qp8m2t-1QkozacKafCNzN7vwpB80'
        path = 'candidate_tweets/'
    else:
        orginal_spreadsheet_id = '1sDnRCwNtAHAK35o1ttXVReJhKHdgjfovFckbWd6ZkYI'
        new_spreadsheet_id = '1-CXoWSIXDD7Qd56Fll6fhYJdDTf8trWgykMW_BbKR7Q'
        path = 'pac_tweets/'

    logger.info("Downloaded tweets list")
    for e, entry in enumerate(lists):

        gc = authenticate_gspread()
        sp = gc.open_by_key(new_spreadsheet_id)
        d = defaultdict(list)
        name, since_id, count, index = entry[0], entry[1],entry[2], entry[3]
        worksheet  = sp.worksheet(name)

        ids = worksheet.col_values(1)
#         short_urls = worksheet.col_values(6)
        logger.info("Retrived data from spreadsheet for %s" % name)

        tweets = get_new_tweets(name, 1)
        retweets = ['' for i in xrange(len(ids))]
        favorites = ['' for i in xrange(len(ids))]
        url_datas = ['' for i in xrange(len(ids))]
        retweets[0] = 'retweets'
        favorites[0] = 'favorites'
        url_datas[0] = 'full URL'

#         get_full_url(short_urls, url_datas) # transfer short url to full urls and store in url_datas

        d = {}
        for tweet in tweets:
            d[tweet[0]] = tweet[6:]

        index = 0
        for i, id_ in enumerate(ids):
            if id_ in d:
                retweets[i] = d[id_][0]
                favorites[i] = d[id_][1]

        data = []
        for i in range(len(retweets)):
            data.append(retweets[i])
            data.append(favorites[i])
#             data.append(url_datas[i])

        list_worksheet.update_acell('D'+str(e+2), len(ids)-1)

        cells = worksheet.range('G1:'+'H'+str(len(ids)))
        logger.info("Retrived cell from spreadsheet for %s" % name)

        assert(len(cells) == len(data))
        for i, cell in enumerate(cells):
            cell.value = data[i]

        worksheet.update_cells(cells)
        logger.info("Updated data on spreadsheet for %s" % name)

        time.sleep(300)

# collect_addition_data(True)
# collect_addition_data(False)


# In[ ]:




# In[ ]:

import requests
def get_full_url(short_urls, full_urls):
    for i, us in enumerate(short_urls):
        full = []
        if not us.startswith("http"):
                continue
        for url in us.split(" "):
            if not url.startswith("http"):
                continue
            try:
                r = requests.head(url, allow_redirects=True)
                full.append(r.url)
            except:
                logger.info("Error occurred for URL - %s" % url)
                continue
        if i % 500 == 0:
            logger.info("Extracting URL %d/%d" % (i, len(short_urls)))
            time.sleep(60)
        full_urls[i] = " ".join(full)


def get_lists(worksheet, is_cand):
    names = filter(lambda x: len(x) > 0, worksheet.col_values(2))
    max_ids = worksheet.col_values(3)[:len(names)]
    counts = worksheet.col_values(4)[:len(names)]
    indices = range(1,len(names)+1)
    lists = zip(names, max_ids, counts, indices)
    del lists[0] # the first one is column title
    return lists

def update_full_url(is_cand):
    logger.info("Start...")
    gc = authenticate_gspread()
    list_spreadsheet_id = "11HeMXQIslUJ6bEOq26I5M8ZeTyxSP8hmYROu2uTdW8g"
    list_sp = gc.open_by_key(list_spreadsheet_id)
    if is_cand:
        list_worksheet = list_sp.worksheet('candidate')
    else:
        list_worksheet = list_sp.worksheet('pac')
    lists = get_lists(list_worksheet, is_cand)
    if is_cand:
        orginal_spreadsheet_id =  '1WJRUEWr-wou5PlOu7D0WFa-ROn451FtdyT0WGD_9BRE'
        new_spreadsheet_id = '15f13hTa2mYJvyO5qp8m2t-1QkozacKafCNzN7vwpB80'
        path = 'candidate_tweets/'
    else:
        orginal_spreadsheet_id = '1sDnRCwNtAHAK35o1ttXVReJhKHdgjfovFckbWd6ZkYI'
        new_spreadsheet_id = '1-CXoWSIXDD7Qd56Fll6fhYJdDTf8trWgykMW_BbKR7Q'
        path = 'pac_tweets/'
    logger.info("Successfully download the list...")
    for e, entry in enumerate(lists):
        if e < 15:
            continue

        gc = authenticate_gspread()
        sp = gc.open_by_key(new_spreadsheet_id)
        d = defaultdict(list)
        name, since_id, count, index = entry[0], entry[1],entry[2], entry[3]
        worksheet  = sp.worksheet(name)

        short_urls = worksheet.col_values(6)
        logger.info("Downloaded %s URL", name)
        url_datas = ['' for i in xrange(len(short_urls))]
        url_datas[0] = 'full URL'

        get_full_url(short_urls, url_datas) # transfer short url to full urls and store in url_datas

        count = 1

        gc = authenticate_gspread()
        sp = gc.open_by_key(new_spreadsheet_id)
        worksheet  = sp.worksheet(name)

        while count < len(short_urls):
            amount = min(100, len(short_urls) - count)
            cells = worksheet.range('I'+str(count)+':'+'I'+str(count+amount-1))
            assert(len(cells) == amount)
            for i in range(amount):
                cells[i].value = url_datas[count-1]
                count += 1
            worksheet.update_cells(cells)
            logger.info("Update cells %d/%d for %s" %(count, len(short_urls), name))


update_full_url(True)
#update_full_url(False)



# In[ ]:



