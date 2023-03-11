##Run this after every pull

##load dependencies
library(quanteda)
library(dplyr)
library(Matrix)
library(ggplot2)
library(RCurl)
library(stringr)
library(XML)
library(gdata)
library(plyr)

##load presidential text corpi
setwd("FOLDER WHERE YOU ARE STORING THE TWEETS")

temp = list.files(pattern="*.csv")
ptext = lapply(temp, read.csv)

##Candidate names
cand.names <- as.vector(c("Bernie Sanders", "Bobby Jindal","Carly Fiorina","Chris Christie", "George Pataki", "Rick Perry",
                          "Jim Gilmore", "Mike Huckabee", "Hillary Clinton", "Jeb Bush",
                          "Jim Webb", "John Kasich", "Lawrence Lessig", "Lincoln Chafee", "Lindsey Graham",
                          "Marco Rubio", "Martin O'Malley", "Rand Paul", "Ben Carson", "Donald Trump",
                          "Rick Santorum", "Scott Walker", "Ted Cruz"))

cand.names <- gsub(" ", "_", cand.names)

###Import list of Candidate entry and exit dates
dates <- read.csv("dates.csv",header=T)
dates[,2] <- as.Date(as.character(dates$announce),"%m/%d/%y")
dates[,3] <- as.Date(as.character(dates$dropout),"%m/%d/%y")

##If there is no dropout date, make it super far in the future

dates[,3] <- as.Date(ifelse(is.na(dates[,3]), as.character("2018-01-01"), as.character(dates$dropout)), "%Y-%m-%d")

###Create a dataframe for each list object
##Naming each list object by candidate
ptext<- mapply(cbind, ptext, "candidate"=cand.names, SIMPLIFY=F)

##converts from list into dataframe
ptext <- do.call(rbind, lapply(ptext, data.frame, stringsAsFactors=FALSE))

##clean corpi function

drop.names <- as.vector(c("Bernie Sanders", "Bobby Jindal","Carly Fiorina","Chris Christie", "George Pataki", "Rick Perry",
                          "Jim Gilmore", "Mike Huckabee", "Hillary Clinton", "Jeb Bush",
                          "Jim Webb", "John Kasich", "Lawrence Lessig", "Lincoln Chafee", "Lindsey Graham",
                          "Marco Rubio", "Martin O'Malley", "Rand Paul", "Ben Carson", "Donald Trump",
                          "Rick Santorum", "Scott Walker", "Ted Cruz","omalley"))

drop.names<- tolower(unlist(strsplit(drop.names, " ")))

##url string to match
url_pattern <- "http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\\(\\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+"

###short url decoder

extraire <- function(entree,motif){
  res <- regexec(motif,entree)
  if(length(res[[1]])==2){
    debut <- (res[[1]])[2]
    fin <- debut+(attr(res[[1]],"match.length"))[2]-1
    return(substr(entree,debut,fin))
  }else return(NA)}
unshorten <- function(url){
  uri <- getURL(url, header=TRUE, nobody=TRUE, followlocation=FALSE, 
                cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl"))
  res <- try(extraire(uri,"\r\nlocation: (.*?)\r\nserver"))
  return(res)
  close(uri)}

###decode other non-twitter-URLS
decode_short_url <- function(url, ...) {
  # PACKAGES #
  require(RCurl)
  
  # LOCAL FUNCTIONS #
  decode <- function(u) {
    Sys.sleep(0.5)
    x <- try( getURL(u, header = TRUE, nobody = TRUE, followlocation = FALSE, cainfo = system.file("CurlSSL", "cacert.pem", package = "RCurl")) )
    if(inherits(x, 'try-error') | length(grep(".*Location: (\\S+).*", x))<1) {
      return(u)
    } else {
      return(gsub('.*Location: (\\S+).*', '\\1', x))
    }
  }
  
  # MAIN #
  gc()
  # return decoded URLs
  urls <- c(url, ...)
  l <- vector(mode = "list", length = length(urls))
  l <- lapply(urls, decode)
  names(l) <- urls
  return(l)
}

##cleaning loop--output only htmls in all tweets

x <- NULL
y <- NULL
z <- NULL
w <- NULL
b <- NULL
for (i in seq_along(cand.names)){
  #obtain name
  x <- subset(ptext, ptext$candidate==cand.names[i])
  #name ticker
  y <- cand.names[i]
  #getting announcement date
  call.date <- subset(dates, dates$name==y)
  #make a date variable
  x$date <- as.Date(gsub(" .*$", "",x$created_at), "%Y-%m-%d")
  #subset tweets to those between announcement and dropout
  x <- x[x$date %in% call.date$announce:call.date$dropout, ]
  #strip only htmls
  x$url <- str_extract(x[,3], url_pattern)
  ##null out z
  z <- NULL
  ##loop to extract tiny url
  for (j in 1:nrow(x)){
    if (is.na(x[j,6])==TRUE){z[j] <- NA}
    else if (x[j,6]=="NA"){z[j] <- NA}
    else if (grepl(".com", x[j,6])==TRUE){z[j]<-x[j,6]}
    else {z[j] <- tryCatch(unshorten(x[j,6]), error=function(w) {print(paste(x[j,6],"FAIL!",sep="****"));return(NA)})}
  }
  #verbose output
  print(paste("***done untwittering",y,sep="__"))
  ##attach to x
  x$url_1 <- z
  ##null out b
  b <- NULL
  ##decode bitlys
  for (j in 1:nrow(x)){
    if (is.na(z[j])==TRUE){b[j] <- NA}
    else if (z[j]=="NA"){b[j] <- NA}
    else if (grepl(".com", z[j])==TRUE){b[j]<-z[j]}
    else {b[j] <- tryCatch(decode_short_url(z[j]), error=function(w) {print(paste(x[j],"FAIL!",sep="****"));return(NA)})}
  }
  #verbose output
  print(paste("***done un-bitlying",y,sep="__"))
  ##attach to x
  x$url_2 <- b
  ##paste text
  #a <- paste(b, sep ="")
  #move past the loop
  #a <- as.vector(a)
  ##create a quanteda corpus
  #w <- corpus(a)
  #name the corpus
  #docvars(w, "origin") <- y
  # output corpus
  assign(y, x)
}

##PAC Twitter load

##load PAC text corpi
setwd("FOLDER WITH THE PAC TWEETS")

temp = list.files(pattern="*.csv")
pactext = lapply(temp, read.csv)

##PAC names
setwd("MAIN FOLDER")

pacnames <- read.csv("PACtwitter.csv", header=T)

pacnames$paccand <- paste(pacnames$SuperPAC, pacnames$Candidate, sep="--")

pacnames <- pacnames[order(pacnames$SuperPAC_Twitter),]

###Bind PAC name
pactext<- mapply(cbind, pactext, "SuperPAC"=pacnames$paccand, SIMPLIFY=F)

pactext <- do.call(rbind, lapply(pactext, data.frame, stringsAsFactors=FALSE))

pactext[] <- lapply(pactext, as.character)

##standardize names 
pacnames$paccand <- toLower(pacnames$paccand)
pactext$SuperPAC <- toLower(pactext$SuperPAC)

##cleaning loop and output character vector

x <- NULL
y <- NULL
z <- NULL
w <- NULL
a <- NULL
for (i in seq_along(pacnames$paccand)){
  #obtain name
  x <- subset(pactext, pactext$SuperPAC==pacnames$paccand[i])
  #name ticker
  y <- pacnames$paccand[i]
  #strip only htmls
  x$url <- str_extract(x[,3], url_pattern)
  #null out z
  z <- NULL
  ##unshortening loop
  for (j in 1:nrow(x)){
    if (is.na(x[j,5])==TRUE){z[j] <- NA}
    else if (x[j,5]=="NA"){z[j] <- NA}
    else if (grepl(".com", x[j,5])==TRUE){z[j]<-x[j,5]}
    else {z[j] <- tryCatch(unshorten(x[j,5]), error=function(w) {print(paste(x[j,5],"FAIL!",sep="****"));return(NA)})}
  }
  #attach to df
  x$url_1 <- z
  #null out b
  b <- NULL
  ##decode bitlys
  for (j in 1:nrow(x)){
    if (is.na(z[j])==TRUE){b[j] <- NA}
    else if (z[j]=="NA"){b[j] <- NA}
    else if (grepl(".com", z[j])==TRUE){b[j]<-z[j]}
    else {b[j] <- tryCatch(decode_short_url(z[j]), error=function(w) {print(paste(z[j],"FAIL!",sep="****"));return(NA)})}
  }
  #verbose output
  print(paste("***done un-bitlying",y,sep="__"))
  ##paste text
  #w <- paste(b, sep="")
  #attach next
  x$url_2 <- b
  #verbose output
  print(paste("***done shortening",y,sep="__"))
  ##skip over 
  #w <- as.vector(w)
  ##create a quanteda corpus
  #a <- corpus(w)
  #name the corpus
  #docvars(a, "origin") <- y
  # output corpus
  assign(y, x)
}

save.image("post-pull.save.RData")

##For candidates only
##create candidate domain vector

###Finding domains
t <- NULL
u <- NULL
v <- NULL
w <- NULL
x <- NULL
y <- NULL
z <- NULL
for (i in seq_along(cand.names)){
  #Create name
  x <- cand.names[i]
  #obtain name object and unshorten
  y <- get(x)
  #create a hashtag list
  z <-  sapply(y$url_1, domain)
  names(z) <- as.POSIXlt(y$created_at)
  #create a domain dataframe
  w <- stack(z)
  colnames(w)[1] <- "domain"
  colnames(w)[2] <- "time"
  w$srce <- rep(x, nrow(w))
  assign(paste("df.domain",x,sep="_"), w)
}

#removing fuckups
#rm(list=ls(pattern="df.domains"))

##binding all of them in a dataframe
doms <- ls(pattern="df.domain")

domains <- lapply(doms, get)

domains <- mapply(cbind, domains, SIMPLIFY=F)

##converts from list into dataframe
domains <- do.call(rbind, lapply(domains, data.frame, stringsAsFactors=FALSE))
domains$time <- as.POSIXlt(domains$time)
domains$date <- as.Date(domains$time)
domains$week <- as.Date(cut(domains$date, breaks = "week"))
domains$month <- as.Date(cut(domains$date, breaks = "month"))

###creating a party vector

dems <- c("Bernie_Sanders", "Hillary_Clinton", "Lawrence_Lessig", "Lincoln_Chafee", "Jim_Webb", "Martin_O'Malley")
gop <- cand.names[!(cand.names %in% dems)]
fr.rn <- c("Bernie_Sanders", "Hillary_Clinton", "Ted_Cruz", "Donald_Trump")
###
domains$dem <- ifelse(domains$srce %in% dems, 1,0)

##remove NA's
domains <- subset(domains, is.na(domains$domain)==F)
##remove twitter
dom.drop <- c("twitter.com","t.co","amp.twimg.com", "youtube.com")
##remove candidates own sites
own.dom <- sapply(cand.names, agrep, domains$domain, max.distance=.4, value=TRUE)
own.dom <- unlist(unique(own.dom))
own.dom[891] <- "jameswebb.com"
##drop
domains <- subset(domains, !(domains$domain %in% dom.drop))
domains <- subset(domains, !(domains$domain %in% own.dom))

##DOMAINS ONLY
##For PACs 
##create PAC domain vector

###Finding Domains
t <- NULL
u <- NULL
v <- NULL
w <- NULL
x <- NULL
y <- NULL
z <- NULL
for (i in seq_along(pacnames$paccand)){
  #Create name
  x <- pacnames$paccand[i]
  #obtain name object and unshorten
  y <- get(x)
  #create a domain list
  z <-  sapply(y$url_1, domain)
  names(z) <- as.POSIXlt(y$created_at)
  #create a domain dataframe
  w <- stack(z)
  colnames(w)[1] <- "domain"
  colnames(w)[2] <- "time"
  w$srce <- rep(x, nrow(w))
  assign(paste("df.pac.domains",x,sep="_"), w)
}

pdoms <- ls(pattern="df.pac.domains")

pacdoms <- lapply(pdoms, get)

pacdoms <- mapply(cbind, pacdoms, SIMPLIFY=F)

##converts from list into dataframe
pacdoms <- do.call(rbind, lapply(pacdoms, data.frame, stringsAsFactors=FALSE))
pacdoms$time <- as.POSIXlt(pacdoms$time)
pacdoms$date <- as.Date(pacdoms$time)
pacdoms$week <- as.Date(cut(pacdoms$date, breaks = "week"))
pacdoms$month <- as.Date(cut(pacdoms$date, breaks = "month"))

##remove NA's
pacdoms <- subset(pacdoms, is.na(pacdoms$domain)==F)
##remove twitter
dom.drop <- c("twitter.com","t.co","amp.twimg.com", "youtube.com")
##remove candidates own sites
own.pac <- sapply(pacnames$SuperPAC, agrep, pacdoms$domain, max.distance=.4, value=TRUE)
own.pac <- unlist(unique(own.pac))

##drop
pacdoms <- subset(pacdoms, !(pacdoms$domain %in% dom.drop))
pacdoms <- subset(pacdoms, !(pacdoms$domain %in% own.pac))


###find pac leaning with agrep
pacdoms$dem <- ifelse(agrepl("hillary o'malley", pacdoms$srce, max.distance = .4)==T, 1,0)

###Preparing data for an edge list

##create id for pacs/not pacs

domains$pac <- rep(0, nrow(domains))
pacdoms$pac <- rep(1, nrow(pacdoms))

##bind
all.doms <- rbind(domains, pacdoms)

doms.el <- all.doms[,c(3, 1, 7, 8)]

doms.el$hashtag <- tolower(doms.el$domain)

write.csv(doms.el, "el.doms.csv", row.names = F)
###

##Hashtags 

##Hashtag only analysis
##For candidates only
##create candidate hashtag vector

###Finding Hashtags
t <- NULL
u <- NULL
v <- NULL
w <- NULL
x <- NULL
y <- NULL
z <- NULL
for (i in seq_along(cand.names)){
  #Create name
  x <- cand.names[i]
  #obtain name object and unshorten
  y <- get(x)
  #create a hashtag list
  z <-  str_extract_all(y$text, "#\\S+")
  names(z) <- as.POSIXlt(y$created_at)
  #create a hashtag dataframe
  w <- stack(z)
  colnames(w)[1] <- "hashtag"
  colnames(w)[2] <- "time"
  w$srce <- rep(x, nrow(w))
  assign(paste("df.hashtags",x,sep="_"), w)
}

#removing fuckups
#rm(list=ls(pattern="df.hashtags"))

##binding all of them in a dataframe
hids <- ls(pattern="df.hashtags")

hashtags <- lapply(hids, get)

hashtags <- mapply(cbind, hashtags, SIMPLIFY=F)

##converts from list into dataframe
hashtags <- do.call(rbind, lapply(hashtags, data.frame, stringsAsFactors=FALSE))
hashtags$time <- as.POSIXlt(hashtags$time)
hashtags$date <- as.Date(hashtags$time)
hashtags$week <- as.Date(cut(hashtags$date, breaks = "week"))
hashtags$month <- as.Date(cut(hashtags$date, breaks = "month"))

###creating a party vector

dems <- c("Bernie_Sanders", "Hillary_Clinton", "Lawrence_Lessig", "Lincoln_Chafee", "Jim_Webb", "Martin_O'Malley")
gop <- cand.names[!(cand.names %in% dems)]
fr.rn <- c("Bernie_Sanders", "Hillary_Clinton", "Ted_Cruz", "Donald_Trump")
###
hashtags$dem <- ifelse(hashtags$srce %in% dems, 1,0)


##Hashtag only analysis
##For PACs 
##create PAC hashtag vector

###Finding Hashtags
t <- NULL
u <- NULL
v <- NULL
w <- NULL
x <- NULL
y <- NULL
z <- NULL
for (i in seq_along(pacnames$paccand)){
  #Create name
  x <- pacnames$paccand[i]
  #obtain name object and unshorten
  y <- get(x)
  #create a hashtag list
  z <-  str_extract_all(y$text, "#\\S+")
  names(z) <- as.POSIXlt(y$created_at)
  #create a hashtag dataframe
  w <- stack(z)
  colnames(w)[1] <- "hashtag"
  colnames(w)[2] <- "time"
  w$srce <- rep(x, nrow(w))
  assign(paste("df.pac.hashtags",x,sep="_"), w)
}

hids <- ls(pattern="df.pac.hashtags")

###Stripping Priorities USA stuff from the last election. 

`df.pac.hashtags_priorities usa action --hillary clinton`$time <- as.POSIXlt(`df.pac.hashtags_priorities usa action --hillary clinton`$time)

`df.pac.hashtags_priorities usa action --hillary clinton` <- subset(`df.pac.hashtags_priorities usa action --hillary clinton`, 
                                                                    `df.pac.hashtags_priorities usa action --hillary clinton`$time > "2015-08-01")
#######

pactags <- lapply(hids, get)

pactags <- mapply(cbind, pactags, SIMPLIFY=F)

##converts from list into dataframe
pactags <- do.call(rbind, lapply(pactags, data.frame, stringsAsFactors=FALSE))
pactags$time <- as.POSIXlt(pactags$time)
pactags$date <- as.Date(pactags$time)
pactags$week <- as.Date(cut(pactags$date, breaks = "week"))
pactags$month <- as.Date(cut(pactags$date, breaks = "month"))

###find pac leaning with agrep
pactags$dem <- ifelse(agrepl("hillary o'malley", pactags$srce, max.distance = .4)==T, 1,0)


hashtags$pac <- rep(0, nrow(hashtags))
pactags$pac <- rep(1, nrow(pactags))

##bind
all.tags <- rbind(hashtags, pactags)

tags.el <- all.tags[,c(3, 1, 7, 8)]

tags.el$hashtag <- gsub(",|[.]|!|:", "", tags.el$hashtag)
tags.el$hashtag <- tolower(tags.el$hashtag)

write.csv(tags.el, "el.tags.csv", row.names = F)

### Create PAC and Candidate Objects
candwpac <- subset(pacnames, select=c("Candidate","paccand"))
##insert underscores
candwpac$Candidate <- gsub(" ","_",candwpac$Candidate)

##loop to merge candidates with their PACs
#Candidate Name
x <- NULL
#Candidate Tweets
y <- NULL
#PAC ticker
z <- NULL
#PAC 1 Tweets
z1 <- NULL
#PAC 2 Tweets
z2 <- NULL
#final accumulation of Candidate + PAC
a <- NULL
#Name of Combination
b <- NULL

for (i in seq_along(candwpac$Candidate)){
  x <- candwpac$Candidate[i]
  y <- get(candwpac$Candidate[i])
  z <- subset(candwpac, candwpac$Candidate==x)
  if (nrow(z)==1) {
    z1 <- get(z$paccand[1])
    z2 <- z1
  }
  else {
    z1 <- get(z$paccand[1])
    z2 <- rbind.fill(z1, get(z$paccand[2]))}
  a <- rbind.fill(y, z2)
  b <- paste(candwpac$Candidate[i], "_all", sep="")
  assign(b,a)
}

#create domain variable

##domain function
domain <- function(x) strsplit(gsub("http://|https://|www\\.", "", x), "/")[[c(1, 1)]]

###Finding domains
x <- NULL
y <- NULL
for (i in seq_along(cands.w.pacs)){
  #Create name
  x <- cands.w.pacs[i]
  #obtain name object and unshorten
  y <- get(paste(x,"_all", sep=""))
  #create a hashtag list
  y$domain <-  sapply(y$url_2, domain)
  ##
  assign(paste(x,"all",sep="_"), y)
}


##REGEX the Youtube links
#name
x <- NULL
#corpus
y <- NULL
#youtube links
z <- NULL
#Curl object
a <- NULL
#logical vector
b <- NULL
#url position
p <- NULL
#hidden urls
c <- NULL
for (i in seq_along(cands.w.pacs)){
  #Create name
  x <- paste(cands.w.pacs[i], "_all", sep="")
  #obtain name object and unshorten
  y <- get(x)
  #subset youtube links
  z <- subset(y, y$domain=="youtube.com" | y$domain=="youtu.be")
  #null out variables
  a <- NULL
  p <- NULL
  b <- NULL
  c <- NULL
  ##loop through youtube subset
  for (j in 1:length(z$url_2)){
    a <- getURL(z$url_2[j])
    p  <- gregexpr("<meta itemprop=\"unlisted\" content=\"", a, fixed = TRUE)[[1]]
    # to get whether the page is hidden or not by T or F
    b <- substring(a, first=p+35, last = p + 35)
    c[j] <- ifelse(b=="T", z$url_2[j], NA)
    print(paste("***checked",z$url_2[j], sep="......"))
  }
  assign(paste("ytlinks",cands.w.pacs[i],sep="_"),c)
  print(paste("**************DONE CHECKING", cands.w.pacs[i],sep="......"))
}

#vector of the hidden links

hidelink <- ls(pattern="ytlinks")

df.links <- sapply(hidelink, get, simplify=T)

df.links<- mapply(cbind, df.links, "candidate"=gsub("ytlinks_","",hidelink), SIMPLIFY=F)
##converts from list into dataframe
df.links <- do.call(rbind, lapply(df.links, data.frame, stringsAsFactors=FALSE))
row.names(df.links) <- NULL
colnames(df.links)[1] <- "hidden_link"
colnames(df.links)[2] <- "name"

df.links <- data.frame(lapply(df.links, as.character), stringsAsFactors=FALSE)

w <- NULL

##create a master list of youtube links

for (i in seq_along(cands.w.pacs)){
  #Create name
  x <- paste(cands.w.pacs[i], "_all", sep="")
  #obtain name object and unshorten
  y <- get(x)
  #subset youtube links
  z <- subset(y, y$domain=="youtube.com" | y$domain=="youtu.be")
  ##rbind to last set
  w <- rbind(w,z)
}

assign("youtube_master", w)

### dummy for hidden links

youtube_master$hidden <- ifelse(youtube_master$url_1 %in% df.links$hidden_link, 1,0)

youtube_master$url_1 <- unlist(youtube_master$url_1)

youtube_master$url_2 <- unlist(youtube_master$url_2)

write.csv(youtube_master, "ytmaster.csv", row.names=F)



