# import necessary python packages
import sys
#sys.path.append("/usr/local/lib/python2.7/site-packages")
import pandas as pd
import numpy as np

##############################################
# load in the data
forecast_df = pd.read_csv('538_polling.csv')

df = pd.read_csv('finalPrediction.csv')

df['date'] = df['created_at']

df['date'] = pd.to_datetime(df.date)

df['date'] = df['date'].dt.strftime('%Y-%m-%d')

forecast_df['date'] = pd.to_datetime(forecast_df.date)
forecast_df['date'] = forecast_df['date'].dt.strftime('%Y-%m-%d')

merged_df = df.merge(forecast_df, left_on=['Name','date'],right_on=['lastname','date'], how='inner')
merged_df.to_csv('polling_merged_df.csv')
