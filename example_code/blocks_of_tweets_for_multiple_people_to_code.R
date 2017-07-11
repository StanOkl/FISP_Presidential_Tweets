library(googlesheets)
library(data.table)
library(plyr)
library(dplyr)


options(httr_oob_default=TRUE) 
gs_auth(new_user = TRUE) 
gs_ls()


##you can combine the "tweets" object with the comb_tweets_maker.R code to do this all as one script. 

tweets <- fread("NAME_OF_YOUR_ENTIRE_TWEET_CORPUS")

##previously coded tweets

already.coded <- fread("NAME_OF_YOUR_ALREADY_CODED_TWEETS_CSV")

filtered.x <- subset(x, !(tweets$id %in% already.coded$id))

coders = c("christopher","christian","emily","lauryn","brittany")

partner = sample(coders, 5, replace=F)

pairs = data.frame(coders, partner)

setwd("/mainstorage/stano/FISP_Project/Coded_tweets_Nov28")

unused <- subset(filtered.x, !is.na(filtered.x$text))
tocode <- NULL
for (i in seq_along(pairs$coders)){
  fname <- paste(pairs$coders[i], pairs$partner[i],".csv",sep="")
  tocode <- unused[sample(nrow(unused),size=75,replace=FALSE),]
  assign(fname,tocode)
  write.csv(get(fname), fname, row.names = F)
  unused <- unused[!(unused$text %in% tocode$text),]
}

