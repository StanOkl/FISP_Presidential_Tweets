
# coding: utf-8

# In[248]:

import re
import urllib2
import argparse

from bs4 import BeautifulSoup

# Landing page where the campaign and PAC urls are found.
main_url = 'http://www.p2016.org/ads1/paidads.html'
base_url = main_url[: main_url.rfind('/')+1]


main = urllib2.urlopen(main_url)
soup_main = BeautifulSoup(main, "html.parser")



# In[249]:

ads = soup_main.findAll('a', href=re.compile('ad[\d]'))



# In[250]:

# Make soup.

org=[]
title = []
desc = []
ov = []

for ad in ads:
    f = urllib2.urlopen(base_url + ad.get('href'))     
    soup = BeautifulSoup(f, 'html.parser')
    # Get key tags.
    try:
        org.append(soup.find('div', id='adorg').get_text(strip=True).replace('\n',' '))
    except:
        org.append('NA')
    try:
        title.append(soup.find('div', id='adtitle').get_text(strip=True).replace('\n',' ').split('+')[0])
        desc.append(soup.find('div', id='adtitle').get_text(strip=True).replace('\n',' ').split('+')[1])
    except:
        title.append('NA')
        desc.append('NA')
        
    ov.append(soup.find('div', id='overview'))
    
        # Navigate and extract content.

    content = []
    for item in ov:
        sub_content = []
        compiler = []
        for tag in item.children:
            if tag.name == 'p':
                sub_content.append(tag.get_text(strip=True).replace('\n',' '))
            elif tag.name == 'br':

                for tag2 in tag.children:
                    if tag2.name == 'p':
                        sub_content.append(tag2.get_text(strip=True).replace('\n',' '))
        
        for s in sub_content:
            compiler.append(s.encode('utf-8'))
        
        content.append(compiler)
                



# In[264]:

def recursive_ascii_encode(lst):
    ret = []
    for x in lst:
        if isinstance(x, basestring):  # covers both str and unicode
            ret.append(x.encode('ascii', 'ignore'))
        else:
            ret.append(recursive_ascii_encode(x))
    return ret

print recursive_ascii_encode(content)


# In[265]:

org = [o.encode('utf-8') for o in org]
title = [t.encode('utf-8') for t in title]
desc = [d.encode('utf-8') for d in desc]
content = [recursive_ascii_encode(c) for c in content]




# In[269]:

import csv

rows = zip(org, title, desc, content)

with open("ads.csv", "wb") as f:
    fileWriter = csv.writer(f, delimiter='|',quotechar='"', lineterminator="\n")
    fileWriter.writerow(['source','title','desc','text'])
    for row in rows:
        fileWriter.writerow(row)


