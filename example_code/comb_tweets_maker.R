setwd("/media/hng/1TB/FISP_Project/Coded_tweets_Feb10/coded/")

files = list.files(pattern=".csv")

heder <- names(read.csv(files[1]))

comb_text <- NA
for (i in seq_along(files)){
  x <- read.csv(files[i])
  colnames(x) <- heder
  comb_text <- rbind(comb_text, x)
}

write.csv(comb_text,"comb_feb10tweets.csv", row.names = F)
########

setwd("/media/hng/1TB/FISP_Project/Coded_tweets_March17/coded/")

files = list.files(pattern=".csv")

heder <- names(read.csv(files[1]))

comb_text <- NA
for (i in seq_along(files)){
  x <- read.csv(files[i])
  colnames(x) <- heder
  comb_text <- rbind(comb_text, x)
}

write.csv(comb_text,"comb_march17tweets.csv", row.names = F)

#######
library(plyr)

setwd("/media/hng/1TB/FISP_Project/coded_tweets_all")

files = list.files(pattern=".csv")

#heder <- names(read.csv(files[1]))

comb_text <- data.frame()
for (i in seq_along(files)){
  x <- read.csv(files[i])
  #colnames(x) <- heder
  comb_text <- rbind.fill(comb_text, x)
}

write.csv(comb_text,"comb_all_tweets.csv", row.names = F)
