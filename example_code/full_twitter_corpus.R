##Create random sample of 5000 PAC Tweets and Pres Tweets

library(googlesheets)
library(data.table)
library(plyr)
library(dplyr)


options(httr_oob_default=TRUE) 
gs_auth(new_user = TRUE) 
gs_ls()

#auth code:
#4/mtIsRqfOY8VuQyrAvWicwCHaxMLwIwPIuuT8HsHiXfc

##combine the Candidate and the PAC tweets

cands <- gs_title("Presidential Tweets")

cand.tw <- NULL
for (i in 1:cands$n_ws){
  x <- data.frame(gs_read_csv(cands, ws=i))
  x$source <- gs_ws_ls(cands)[i]
  cand.tw <- rbind.fill(cand.tw, x)
  Sys.sleep(7)
}

pacs <- gs_title("PAC Tweets")

pac.tw <- NULL
for (i in 1:pacs$n_ws){
  x <- data.frame(gs_read_csv(pacs, ws=i))
  x$source <- gs_ws_ls(pacs)[i]
  pac.tw <- rbind.fill(pac.tw, x)
  Sys.sleep(10)
}

pac.tw$PAC <- NULL

##subset out dates for campaign

dates <- read.csv("dates.csv")
dates$announce <- as.POSIXct(as.character(dates$announce), "%Y-%m-%d", tz="PST")
dates$dropout <- as.POSIXct(as.character(dates$dropout), "%Y-%m-%d", tz="PST")

##If there is no dropout date, make it super far in the future

dates$dropout <- as.POSIXct(ifelse(is.na(dates$dropout), as.character("2018-01-01"), as.character(dates$dropout)), "%Y-%m-%d")

##import key

#twitterID <- c("GovernorPataki","LindseyGrahamSC","BobbyJindal","Lessig2016","JimWebbUSA","LincolnChafee","ScottWalker","GovernorPerry","marcorubio","RealBenCarson","JebBush","gov_gilmore","CarlyFiorina","ChrisChristie","RandPaul","RickSantorum","GovMikeHuckabee","MartinOMalley","BernieSanders","HillaryClinton","JohnKasich","realDonaldTrump","tedcruz")

#dates$twitterID <- twitterID

#write.csv(dates, "dates.csv")

##remove candidate tweets outside of announce range

cand.names <- unique(cand.tw$source)

format.str <- "%m/%d/%Y %H:%M:%S"

x <- NULL
clean_dates_cand <- data.table()
for (i in seq_along(cand.names)){
  #obtain name
  x <- data.table(subset(cand.tw, cand.tw$source==cand.names[i]))
  #name ticker
  y <- cand.names[i]
  #getting announcement date
  call.date <- subset(dates, dates$twitterID==y)
  #make a date variable
  x$date <- as.POSIXct(strptime(x$created_at, format.str, tz = "GMT"), tz = "EST")
  #subset tweets to those between announcement and dropout
  #x <- x[x$date %in% call.date$announce:call.date$dropout, ]
  ##rbind result 
  clean_dates_cand <- rbind(clean_dates_cand, x, fill=F)
}

#### get candidate 5k and then remove those that fall out of date range




##now do this for PACs

pac.test <- gs_title("Tweet List")

pac.key <-data.table(gs_read_csv(pac.test, ws=2))

pac.key$SuperPAC_Twitter[26] <- "KeepPromise1"

pac.key$Candidate[26] <- "Ted Cruz"

##create candidate column

pac.tw <- merge(pac.tw, subset(pac.key, select=c("SuperPAC_Twitter","Candidate")), by.x="source",by.y="SuperPAC_Twitter", all.x=T)

pac.tw$Candidate <- gsub(" ","_", pac.tw$Candidate)

cand.names <- unique(as.character(dates$name))

format.str <- "%m/%d/%Y %H:%M:%S"

x <- NULL
clean_dates_pac <- data.table()
for (i in seq_along(cand.names)){
  #obtain name
  x <- data.table(subset(pac.tw, pac.tw$Candidate==cand.names[i]))
  #name ticker
  y <- cand.names[i]
  #getting announcement date
  call.date <- subset(dates, dates$name==y)
  #make a date variable
  x$date <- as.POSIXct(strptime(x$created_at, format.str, tz = "GMT"), tz = "EST")
  #subset tweets to those between announcement and dropout
  #x <- x[x$date %in% call.date$announce:call.date$dropout, ]
  ##rbind result 
  clean_dates_pac <- rbind(clean_dates_pac, x, fill=T)
}

##output

write.csv(clean_dates_cand,"candidate.tweets.csv", row.names=F)
write.csv(clean_dates_pac,"pac.tweets.csv",row.names=F)
