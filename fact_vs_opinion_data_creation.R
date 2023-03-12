#packages necessary for analysis

packages <- c("data.table","tidyverse","readxl","irr",
              "reticulate","haven","estimatr","stringr","tm",
              "modelsummary","AER","googlesheets4")

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

###