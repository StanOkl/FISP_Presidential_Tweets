library(googlesheets)
library(data.table)
library(plyr)
library(dplyr)

options(httr_oob_default=TRUE) 
gs_auth(new_user = TRUE) 
gs_ls()

setwd('icr')

files = list.files(pattern='.csv')
coders = c("zoe","kennedy","eamon","emily","stan")


keys <- NULL
for (i in coders){
  x <- subset(files, grepl(i, files)==T)
  if (length(x)==2) {
  keys <- rbind(keys, gsub(".csv", paste(".",i,".csv",sep=""), x[1]))
  keys <- rbind(keys, gsub(".csv", paste(".",i,".csv",sep=""), x[2]))
  }
  else{
    keys <- rbind(keys, gsub(".csv", paste(".",i,".csv",sep=""), x[1]))
    keys <- rbind(keys, gsub(".csv", paste(".",i,".csv",sep=""), x[2]))
    keys <- rbind(keys, gsub(".csv", paste(".",i,".csv",sep=""), x[3]))}
}

for (i in keys){
  x <- gs_title(i)
  x <- data.frame(gs_read_csv(x, ws=1))
  y <- i
  assign(y,x)
}

for (i in keys){
  matches <- grep(gsub("\\..*","", i),keys, value=T)
  idfiles <- grep(gsub("\\..*","", i),list.files(pattern=".csv"),value=T)
  id.nums <- read.csv(idfiles)
  id.nums <- id.nums$id
  comb <- cbind(get(matches[1])[,1:3], get(matches[1])[,4:19], get(matches[2])[,4:19])
  colnames(comb)[4:19] <- paste("coder1", names(get(matches[1])[,4:19]), sep="-")
  colnames(comb)[20:35] <- paste("coder2", names(get(matches[2])[,4:19]), sep="-")
  comb$id <- id.nums
  comb$src <- idfiles
  assign(paste("combined",i,"joined",sep="--"), comb)
}

##This removes the name of the coder from the csv
##gsub(".*\\.(.*)\\..*", "\\1",x)

coded.500 <- gs_title('Candidate_tweets_to_code')
coded.500 <- data.frame(gs_read_csv(coded.500, ws=1))
coded.500 <- coded.500[1:499,]
colnames(coded.500)[3:18] <- paste("coder1",names(coded.500)[3:18], sep=".")

##merge the two
joined.2coders.data <- data.frame(do.call(rbind, lapply(ls(pattern = "combined"), get)))

unq.joined.2coders.data <-  joined.2coders.data[!duplicated(joined.2coders.data$id),]

##fix the zero

unq.joined.2coders.data[174,16] <- 1

##return only complete cases

unq.joined.2coders.data <- unq.joined.2coders.data[complete.cases(unq.joined.2coders.data$text),]

joined.data <- rbind.fill(unq.joined.2coders.data, coded.500)

joined.data <- joined.data[sample(nrow(joined.data), 750, replace=F),]

#joined.data$id <- as.numeric(joined.data$id)

##
tweets <- gs_title("cand.5k.csv")
tweets <- data.frame(gs_read_csv(tweets, ws=1))
tweets$id <- as.numeric(tweets$id)
##merge on id
setDT(tweets, key="id")
setDT(joined.data, key="id")

merge.tweets <- merge(joined.data, tweets, by="text")

merge.tweets$X1.y <- NULL
merge.tweets$text.y <- NULL
##This removes the name of the coder from the csv
##gsub(".*\\.(.*)\\..*", "\\1",x)  

##Turn NAs to 0s

rts <- merge.tweets$retweets

favs <- merge.tweets$favorites

merge.tweets[is.na(merge.tweets)] <- 0

merge.tweets$retweets <- rts

merge.tweets$favorites <- favs

#setwd("..")
write.csv(merge.tweets, "merged.tweets.csv")
###
library(irr)

df.tweets <- data.frame(unq.joined.2coders.data)

df.tweets[is.na(df.tweets)] <- 0

##find people coding zero by accident

#df.tweets[174,16] <- 1

###simple matches for topic matching

var.names <- names(staneamon.stan.csv)[4:19]

counter = 0
inter.rater.reliability <- NULL
inter.rater.reliability <- data.frame(variable=as.character(0), pct=as.numeric(0), 
                                      cohens.kappa=as.numeric(0),
                                      kripp.alpha=as.numeric(0),stringsAsFactors = F)

for (i in var.names){
  matches <- df.tweets[,4+counter]==df.tweets[,20+counter]
  y <- length(matches[matches==TRUE])/length(matches)
  inter.rater.reliability[counter+1,1] <- as.character(i)
  inter.rater.reliability[counter+1,2] <- y
  counter = counter +1
}

##cohen's kappa

counter = 0
for (i in var.names){
  x <- kappa2(df.tweets[,c(4+counter,20+counter)], "unweighted")
  inter.rater.reliability[counter+1,3] <- x$value
  counter = counter +1
}

##krippendorfs alpha

counter = 0
for (i in var.names){
  ka <- t(as.matrix(df.tweets[,c(4+counter, 20+counter)]))
  ka.score <- ifelse(counter < 3, kripp.alpha(ka, method="ordinal"), kripp.alpha(ka, method="nominal"))
  ka.score <- kripp.alpha(ka, method="ordinal")
  inter.rater.reliability[counter+1,4] <- ka.score$value
  counter = counter +1
}

write.csv(df.tweets, "IRR.250.tweets.csv")

write.csv(inter.rater.reliability, "IRR.tweets.csv")
