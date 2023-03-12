#packages necessary for analysis

packages <- c("data.table","tidyverse","readxl","irr",
              "reticulate","haven","estimatr","stringr","tm",
              "modelsummary","AER")

##install any uninstalled packages
installed_packages <- packages %in% rownames(installed.packages())
if (any(installed_packages == FALSE)) {
  install.packages(packages[!installed_packages])
}

#Load packages
invisible(lapply(packages, library, character.only = TRUE))

##set display options
options(scipen=999)
options(dplyr.width=Inf)

setwd("bko_sppq_rep/dataverse/")
###Table 1 
####Measures of Intercoder Reliability: Humans Agreeing with Humans

###get human coded tweets
joined.2coders.data <- read_csv('irr_training_tweets.csv')

###
df.tweets <- data.frame(joined.2coders.data[!is.na(joined.2coders.data$coder1.Sentiment) &
                                              !is.na(joined.2coders.data$coder2.Sentiment),])

df.tweets[is.na(df.tweets)] <- 0

df.tweets <- df.tweets[df.tweets$src !="0",]

###simple matches for topic matching

var.names <- names(df.tweets[c(5:21)])

##IRR loop

counter = 0
inter.rater.reliability <- NULL
inter.rater.reliability <- data.frame(variable=as.character(0), pct=as.numeric(0), 
                                      cohens.kappa=as.numeric(0),stringsAsFactors = F)

for (i in var.names){
  matches <- df.tweets[,5+counter]==df.tweets[,24+counter]
  y <- length(matches[matches==TRUE])/length(matches)
  inter.rater.reliability[counter+1,1] <- as.character(gsub("coder1.","",i))
  inter.rater.reliability[counter+1,2] <- y
  counter = counter +1
}

##cohen's kappa

counter = 0
for (i in var.names){
  x <- kappa2(df.tweets[,c(5+counter,24+counter)], "unweighted")
  inter.rater.reliability[counter+1,3] <- x$value
  counter = counter +1
}

###rename variables, reorder rows and output table

row_order <- c("Is the Tweet a Factual Claim or an Opinion?","Ideology (Liberal, Neutral, or Conservative)",
               "Sentiment (Negative, Neutral, or Positive)","Is the Tweet Political or Personal?",
               "Topic: Immigration","Topic: Macroeconomics",
               "Topic: Defense","Topic: Law and Crime","Topic: Civil Rights","Topic: Environment",
               "Topic: Education","Topic: Health","Topic: Government Operations",
               "Topic: No Policy Content","Asks for a Donation?","Asks to Watch, Share, Or Follow?",
               "Asks for Miscellaneous Action?")

inter.rater.reliability %>% 
  mutate(Name=c("Sentiment (Negative, Neutral, or Positive)","Is the Tweet Political or Personal?",
                "Ideology (Liberal, Neutral, or Conservative)","Topic: Immigration","Topic: Macroeconomics",
                "Topic: Defense","Topic: Law and Crime","Topic: Civil Rights","Topic: Environment",
                "Topic: Education","Topic: Health","Topic: Government Operations",
                "Topic: No Policy Content","Asks for a Donation?","Asks to Watch, Share, Or Follow?",
                "Asks for Miscellaneous Action?","Is the Tweet a Factual Claim or an Opinion?"),
         across(where(is.numeric), round,2)) %>%
  rename("Agreement Rate"=pct,
         "Cohen's Kappa"=cohens.kappa) %>%
  select(-variable) %>%
  relocate(Name) %>%
  slice(match(row_order, Name)) 

####Table 2
######Examples of Variables and Tweets in Each Category

##This dataset is produced in the chunk for Table 3. 
##For replication purposes, this dataset is also included in finished form.
data <- fread("finalPredictionState.csv")

###Education Issue
prop.table(table(data$education)) %>% `*`(100) %>% round(1)

###Health Care Issue
prop.table(table(data$health_care)) %>% `*`(100) %>% round(1)

###Ideology
####Liberal = -1, Neutral = 0, Conservative = 1.
prop.table(table(data$ideology)) %>% `*`(100) %>% round(1)

###Sentiment
####Negative = -1, Neutral = 0, Positive = 1.
prop.table(table(data$sentiment))%>% `*`(100) %>% round(1)

####Table 3
###Measures of Classification Accuracy: Computers Replicating Humans

state_data <- read_xlsx("CodedStateTweetsMarch2020.xlsx") %>%
  select(-`__000000`) %>% relocate("id","text","sentiment","political",
                                   "ideology","immigration",
                                   "macroeconomics","national_security","crime_law_enforcement",
                                   "civil_rights","environment","education","healthcare","governance",
                                   "no_policy_content","asks_for_donation","ask_to_watch_read_share_follow_s",
                                   "ask_misc","factual_claim")


pres_data <- read_csv('training_data.csv') %>%
  select(-Expresses_an_Opinion) %>% rename_all(~names(state_data)) %>%
  mutate(id=as.character(id))

data <- bind_rows(pres_data, state_data) %>%
  rename("crime"=crime_law_enforcement, "ask_to_etc"=ask_to_watch_read_share_follow_s,
         "health_care"=healthcare, "macroeconomic"=macroeconomics)

names_to_remove = c('america next','believeagaingop',
                    'berniesanders','bobbyjindal',
                    'carlyfiorina','chrischristie',
                    'correctrecord','draftrunbenrun',
                    'genfwdpac','govmikehuckabee',
                    'governorpataki','governorperry',
                    'hillaryclinton','jebbush',
                    'jimwebbusa','johnkasich',
                    'keeppromise1','lessing2016',
                    'lincolnchafee','lindseygrahamsc',
                    'martinomalley','millenniarise',
                    'newday4america','oppandfreedom',
                    'ourrevival','pagpac','randpaul',
                    'realbencarson','rebuildingamnow',
                    'ricksantorum','scottwalker',
                    'the purple pac','unintimidated16',
                    'workingagainpac','america leads',
                    'americasliberty','carlyforamerica',
                    'cspac','feelthebernorg','gov gilmore',
                    'greatamericapac','marcorubio','mkdclsn',
                    'prioritiesUSA','progressivekick',
                    'r2rusa','realdonaldtrump',
                    'securestrength','tedcruz','tedcruz45')

state_leg_names <- read_csv("State Legislator Twitter Handles - Lower House.csv") %>%
  select(`Session Twitter Handle`)

names_to_remove <-  c(names_to_remove,as.vector(state_leg_names$`Session Twitter Handle`))

#lowercase
processed_text <- tolower(data$text)
# # Get rid of URLs
processed_text <- gsub(" ?(f|ht)(tp)(s?)(://)(.*)[.|/](.*)", "", processed_text)
##Drop "RT"
processed_text <- gsub("rt","",processed_text)
# # remove punctuations
processed_text <- gsub('[[:punct:] ]+',' ',processed_text)
#drop screennames
processed_text  <- removeWords( processed_text, names_to_remove) %>% 
  removeWords(., stopwords())
# #get rid of unnecessary spaces
data$text <- str_squish(processed_text)

write_csv(data,"training_data_stateprez_processed.csv")

############################
##Process full text corpus

data <- read_csv('State_Leg_Tweets_corpus.csv') %>%
  dplyr::select(-c(1:2,6:8)) %>%
  rename("id"=1,
         "created_at"=2,
         "text"=3,
         "likes"=4,
         "rts"=5,
         "user"=6)

###Due to Twitter TOS, text data must be "hydrated" by pulling data from Twitter's\
###REST API using the tweet id's provided in this dataset. 
###For guidance on this procedure, please visit: https://towardsdatascience.com/learn-how-to-easily-hydrate-tweets-a0f393ed340e

# lowercase
processed_text <- tolower(data$text)
# Get rid of URLs
processed_text <- gsub(" ?(f|ht)(tp)(s?)(://)(.*)[.|/](.*)", "", processed_text)
#get rid of unnecessary spaces
processed_text <- str_replace_all(processed_text," "," ")
# remove punctuations
processed_text <- gsub('[[:punct:] ]+',' ',processed_text)

data$text <- processed_text

write_csv(data,"ProcessedFullCorpus_state.csv")

##This line calls one's local version of Python to run the file "ml_classifier_final.py"
###This is the equivalent of running python3 from terminal. 
py_run_file("ml_classifier_final.py")

####Table 4
###Does Gender Affect Twitter Activity?

load("regression_data.rda")

##multiply all percentages by 100
data <- data %>% mutate_at(c("sentiment_total", "health_care", "education", "womens_issues"), list(~.*100))

handle <- data %>% lm_robust(has_handle ~ fem_dum + dem_dum,data=., fixed_effects = ~ state_num) 

counts <- data %>% lm_robust(counts ~ fem_dum + dem_dum,data=., fixed_effects = ~ state_num) 

counts_tobit <- data %>% tobit(counts_tobit ~ fem_dum + dem_dum + factor(state_num),
                               left=0,right=Inf,data=.) 

modelsummary(list(handle, counts, counts_tobit), coef_omit = 'state|Intercept')

##Table 5. 
##Does Gender Affect Sentiment and Attention to “Women’s Issues”?

sent_tot <- lm_robust(sentiment_total ~ fem_dum + dem_dum, data=data,
                      fixed_effects = ~ state_num)

wom_iss <- lm_robust(womens_issues ~ fem_dum + dem_dum, data=data,
                     fixed_effects = ~ state_num)

health_care <- lm_robust(health_care ~ fem_dum + dem_dum, data=data,
                         fixed_effects = ~ state_num)  

education <- lm_robust(education ~ fem_dum + dem_dum, data=data,
                       fixed_effects = ~ state_num)

modelsummary(list(sent_tot, wom_iss, education,health_care))

#Table 6. 
#Does Gender Predict Twitter Ideology?

all <- lm_robust(ideology_total ~ np_score + fem_dum + dem_dum, data=data, 
                 fixed_effects = ~ state_num)
  
dem <- lm_robust(ideology_total ~ np_score + fem_dum , data=data[data$dem_dum==1,], 
                 fixed_effects = ~ state_num)

gop <- lm_robust(ideology_total ~ np_score + fem_dum , data=data[data$rep_dum==1,], 
                 fixed_effects = ~ state_num)

modelsummary(list(all, dem, gop))


#Table 7. 
##How do Race, Ethnicity, and Gender Affect Twitter Activity?

handle <- data %>% lm_robust(has_handle ~ fem_dum + BlackorLatino_legislator + fem_dum*BlackorLatino_legislator + dem_dum,data=., 
                             fixed_effects = ~ state_num) 

counts <- data %>% lm_robust(counts ~ fem_dum + BlackorLatino_legislator + 
                               fem_dum*BlackorLatino_legislator+ dem_dum,data=., 
                             fixed_effects = ~ state_num) 

counts_tobit <- data %>% tobit(counts_tobit ~ fem_dum + 
                                 BlackorLatino_legislator + 
                                 fem_dum*BlackorLatino_legislator+ dem_dum+ 
                                 factor(state_num) ,left=0,right=Inf,data=.) 

modelsummary(list(handle, counts, counts_tobit), coef_omit = 'factor|Intercept')


###Table 8. 
###How do Race, Ethnicity, and Gender Affect Sentiment and Attention to “Women’s Issues”?

sent_tot <- lm_robust(sentiment_total ~ fem_dum + BlackorLatino_legislator + fem_dum*BlackorLatino_legislator + dem_dum, data=data,fixed_effects = ~ state_num)

wom_iss <- lm_robust(womens_issues ~ fem_dum + BlackorLatino_legislator + fem_dum*BlackorLatino_legislator + dem_dum, data=data,fixed_effects = ~ state_num)

health_care <- lm_robust(health_care ~ fem_dum + BlackorLatino_legislator + fem_dum*BlackorLatino_legislator + dem_dum, data=data,fixed_effects = ~ state_num)  

education <- lm_robust(education ~ fem_dum + BlackorLatino_legislator + fem_dum*BlackorLatino_legislator + dem_dum, data=data,fixed_effects = ~ state_num)

modelsummary(list(sent_tot, wom_iss, education,health_care))

###Appendix Table 1
###Testing the Validity of Tweet-Based Ideology Measure

all <- data %>% lm(np_score ~ ideology_total, data=.)

dem <- data %>% filter(dem_dum==1) %>% lm(np_score ~ ideology_total, data=.)

gop <- data %>% filter(rep_dum==1) %>% lm(np_score ~ ideology_total, data=.)

all_fe <- data %>% lm_robust(np_score ~ ideology_total, fixed_effects = ~state_num, data=.)

dem_fe <- data %>% filter(dem_dum==1) %>% lm_robust(np_score ~ ideology_total, fixed_effects = ~state_num, data=.)

gop_fe <- data %>% filter(rep_dum==1) %>% lm_robust(np_score ~ ideology_total, fixed_effects = ~state_num, data=.)


modelsummary(list(all,dem,dem_fe,gop,gop_fe))

##Appendix Table 2. How does Legislative Professionalism Shape the Impact of Gender on
###Twitter Activity?

handle <- data %>% lm_robust(has_handle ~ fem_dum + dem_dum +SquireXfemale,data=., 
                             fixed_effects = ~ state_num) 

counts <- data %>% lm_robust(counts ~ fem_dum + dem_dum+SquireXfemale,data=., fixed_effects = ~ state_num) 

counts_tobit <- data %>% tobit(counts_tobit ~ fem_dum + dem_dum+SquireXfemale + 
                                 factor(state_num),left=0,right=Inf,data=.) %>%
  coeftest() %>%
  tibble()

n_counts_tobit <- data %>% tobit(counts_tobit ~ fem_dum + dem_dum+SquireXfemale + 
                                 factor(state_num),left=0,right=Inf,data=.)

counts_tobit <- list(
  tidy=tibble(term=names(counts_tobit$.[,"Estimate"]), estimate=counts_tobit$.[,"Estimate"],
                       std.error=counts_tobit$.[,"Std. Error"]),
  glance=tibble("Num.Obs."=length(n_counts_tobit$y)))

class(counts_tobit) <- "modelsummary_list"

modelsummary(list(handle, counts, counts_tobit), coef_omit = 'state|Intercept|scale')

##Appendix Table 3. How does Legislative Professionalism Shape the Impact of Gender on
##Sentiment and Attention to “Women’s Issues”?
  
sent_tot <- lm_robust(sentiment_total ~ fem_dum + dem_dum+SquireXfemale, data=data,fixed_effects = ~ state_num)

wom_iss <- lm_robust(womens_issues ~ fem_dum + dem_dum+SquireXfemale, data=data,fixed_effects = ~ state_num)

health_care <- lm_robust(health_care ~ fem_dum + dem_dum+SquireXfemale, data=data,fixed_effects = ~ state_num)  

education <- lm_robust(education ~ fem_dum + dem_dum+SquireXfemale, data=data,fixed_effects = ~ state_num)

modelsummary(list(sent_tot, wom_iss, education,health_care))

##Appendix Table 4. Controlling for Years Since First Election to Estimate the Impact of
##Gender on Twitter Activity

handle <- data %>% lm_robust(has_handle ~ fem_dum + dem_dum +years_since_elected,
                             data=., fixed_effects = ~ state_num) 

counts <- data %>% lm_robust(counts ~ fem_dum + dem_dum + years_since_elected,
                             data=., fixed_effects = ~ state_num) 

counts_tobit <- data %>% tobit(counts_tobit ~ fem_dum + dem_dum + 
                                 factor(state_num)+ years_since_elected,left=0,right=Inf,data=.) %>%
  coeftest() %>%
  tibble()

n_counts_tobit <- data %>% tobit(counts_tobit ~ fem_dum + dem_dum + 
                                   factor(state_num)+ years_since_elected,left=0,right=Inf,data=.)

counts_tobit <- list(
  tidy=tibble(term=names(counts_tobit$.[,"Estimate"]), estimate=counts_tobit$.[,"Estimate"],
              std.error=counts_tobit$.[,"Std. Error"]),
  glance=tibble("Num.Obs."=length(n_counts_tobit$y)))

class(counts_tobit) <- "modelsummary_list"

modelsummary(list(handle, counts, counts_tobit), coef_omit = 'state|Intercept|scale')


###Appendix Table 5. Controlling for Years Since First Election to Estimate the Impact of
##Gender on Sentiment and Attention to “Women’s Issues”

sent_tot <- lm_robust(sentiment_total ~ fem_dum + dem_dum+ years_since_elected, data=data,fixed_effects = ~ state_num)

wom_iss <- lm_robust(womens_issues ~ fem_dum + dem_dum+ years_since_elected, data=data,fixed_effects = ~ state_num)

health_care <- lm_robust(health_care ~ fem_dum + dem_dum+ years_since_elected, data=data,fixed_effects = ~ state_num)  

education <- lm_robust(education ~ fem_dum + dem_dum+ years_since_elected, data=data,fixed_effects = ~ state_num)

modelsummary(list(sent_tot, wom_iss, education,health_care))



##Figure 1
###Testing the Validity of Tweet-Based Ideology Measure


###Both Parties
data %>% filter(counts>10 & party %in% c("D","R")) %>% ggplot(aes(ideology_total,np_score)) + 
  geom_point(aes(color=factor(party))) +
  geom_text(aes(label=party, color=party)) +
  geom_smooth(method="lm") + xlim(c(-.3,.7)) + 
  scale_color_manual(values = c("blue","red"))+
  theme_bw() +
  theme(legend.position="none") + xlab("Twitter Ideology") + ylab("Roll Call Ideology") 

##Democrats
data %>% filter(counts>10 & party %in% c("D")) %>% ggplot(aes(ideology_total,np_score)) + 
  geom_point(aes(color=factor(party))) +
  geom_text(aes(label=party, color=party)) +
  geom_smooth(method="lm") + xlim(c(-.3,.7)) +
  scale_color_manual(values = c("blue","red"))+
  theme_bw() +
  theme(legend.position="none") + xlab("Twitter Ideology") + ylab("Roll Call Ideology") 

##Republicans
data %>% filter(counts>10 & party %in% c("R")) %>% ggplot(aes(ideology_total,np_score)) + 
  geom_point(aes(color=factor(party))) +
  geom_text(aes(label=party, color=party)) +
  geom_smooth(method="lm") + xlim(c(-.3,.7)) + 
  scale_color_manual(values = c("red"))+
  theme_bw() +
  theme(legend.position="none") + xlab("Twitter Ideology") + ylab("Roll Call Ideology") 
