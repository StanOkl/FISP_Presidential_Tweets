import subprocess
import zipfile
import urllib.request

url = 'https://www.dropbox.com/sh/vnu9linsuv5ouxe/AABSs1KHdw3fjPnY7TAIoHFPa?dl=1'  
urllib.request.urlretrieve(url, 'new_tweets.zip') 

with zipfile.ZipFile("new_tweets.zip","r") as zip_ref:
    zip_ref.extractall()

exec(open("convert_xlsx_csv.py").read())

subprocess.call (["/usr/bin/Rscript", "--vanilla", "preprocessing.R"])

exec(open("TFIDF_Classifications.py").read())

exec(open("polling_merge.py").read())
