###################################################################################################################################
#Program Copyright, 2020, Mark J. Lamias, The Stochastic Group, Inc.
#Version 1.0 - Initial Update
#Version 2.0 - Modified code to account for site changes implemented by GDPH on 3/28/2020 (evening) which 
#              included new table of death by age, county, gender, and presence of underlying medical condition.
#Last Updated:  03/29/2020 02:01 AM EDT
#
#Terms of Service
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
#
#BACKGROUND NOTE:  This program was created after the GDPH COVID-19 report format change was implemented on 
#March 27, 2020.  Previous to this change, the script Update_covid_figures_from_gdph.R was used.  
#
#About this Program:  This program was developed in response to the COVID-19 global pandemic.  The Georgia (USA) Department of
#Public Health Publishes updated COVID-19 testing and case counts twice daily at noon and 7 pm Eastern time.  However, the
#agtency does not publish a historical record of testing and case counts by date.  Without this historical data, it's impossible
#to develop predictive statistical models, make forecastst of disease spread, or develop longitudinal statistical analyses. This
#program has loaded all historical data from the Georgia Deaprtment of Public Health using the search results from the
#Internet archive service "Wayback Machine - Internet Archive" (www.archive.org) and then updates this data twice a day
#(for the noon and 7 pm figures) by scraping data from the Georgia Department of Public Health's website.  After reading this
#data, data is updated and stored in both RDS and CSV formats.
#
#Frequency of Update & Uses:
#This program will execute twice daily at 1 pm and 8 pm EDT and output files will be updated accordingly.
#Users may use this program directly or simply use the output data that has been compiled so long as attribution is made as
#follows:  Lamias, Mark J., The Stochastic Group, Inc. 2020.  COVID-19 Historical Data for Georgia.
#
#Inputs/Global Variables Set by User:
#DATA_DIRECTORY:  A valid R pathname to the directory where this program and the existing data reside
#COVID_19_GEORIGA_DATA.Rds:  The R RDS file that contains the most recent GA COVID-19 data
#COVID_19_GEORIGA_COUNTIES_DATA:  The R RDS file that contains the most recent GA COVID-19 data by county
#URL:  The Uniform Resource Locator to the Georgia Department of Public Health's COVID-19 daily report page
#
#Outputs:
#This program outputs 4 files:
#(1) An Updated COVID_19_GEORIGA_DATA RDS file;
#(2) An Updated COVID_19_GEORIGA_DATA CSV file;
#(3) An Updated COVID_19_GEORIGA_COUNTIES_DATA RDS file;
#(4) An Updated COVID_19_GEORIGA_COUNTIES_DATA CSV file;
#All output is sent to the DATA_DIRECTORY and files are overwritten.

###################################################################################################################################

library(rvest)
library(httr)
library(tidyverse)
library(stringr)
library(readxl)
library(git2r)

#Set data directory
DATA_DIRECTORY <- "D:/Code/Github/COVID-19-Georgia"

#Import historical GDPH COVID-19 Data and Import historical GDPH COVID-19 Data for counties
COVID_19_GEORIGA_DATA <- readRDS(file = paste0(DATA_DIRECTORY, "/COVID_19_GEORIGA_DATA.Rds"))
COVID_19_GEORIGA_COUNTIES_DATA <- readRDS(file = paste0(DATA_DIRECTORY, "/COVID_19_GEORIGA_COUNTIES_DATA.Rds"))
COVID_19_GEORIGA_DEATHS_DATA <- readRDS(file = paste0(DATA_DIRECTORY, "/COVID_19_GEORIGA_DEATHS_DATA.Rds"))

#Create a report instance ID to differentiate reports from one another
new_instance_id <- max(COVID_19_GEORIGA_DATA$Instance_ID) + 1

#Convert to POSIXct format for date times to facilitate date/time handling
COVID_19_GEORIGA_DATA$report_datetime <- as.POSIXct(COVID_19_GEORIGA_DATA$report_datetime)
COVID_19_GEORIGA_DATA$report_generated_datetime <- as.POSIXct(COVID_19_GEORIGA_DATA$report_generated_datetime)

#Connect to GDPH website and read web page
URL <- "https://d20s4vd27d0hk0.cloudfront.net/"
session <- html_session(URL)
html <- read_html(session)

#Get report date and time from page header
report_date_parts <-
  html %>% html_nodes('span.ltitle') %>% as.character() %>% simplify() %>% pluck(1) %>% 
  strsplit(split = "These data represent confirmed cases of COVID-19 reported to the Georgia Department of Public Health as of ") %>%
  simplify() %>%
  pluck(2) %>% strsplit(split = ". <")  %>% simplify() %>% pluck(1) 

#Create datetime variable from date and time parts
report_date <- report_date_parts %>% as.Date(format = "%m/%d/%Y")
report_time <- report_date_parts %>% strsplit(split = " ")  %>% simplify() %>% pluck(2)
report_datetime_str <- paste(report_date, report_time)
report_datetime <-
  strptime(report_datetime_str, "%Y-%m-%d %H:%M:%S")

#Read in first and second table which define test/case counts by lab type
cases_table <-
  #html %>% html_nodes(xpath = '//*[@id="main-content"]/div/div[3]/div[1]/div/main/div[2]/table[1]') %>% html_table() %>% pluck(1)
  html %>%  html_nodes(xpath = '//*[@id="summary"]/table[1]') %>%  simplify() %>%  pluck(1) %>% html_table(header=TRUE)

lab_table <-
  #html %>% html_nodes(xpath = '//*[@id="main-content"]/div/div[3]/div[1]/div/main/div[2]/table[2]') %>% html_table() %>% pluck(1)
  html %>%  html_nodes(xpath = '//*[@id="testing"]/table') %>%  simplify() %>%  pluck(1) %>% html_table(header=TRUE)



#Obtain case counts by county
html %>%  html_nodes(xpath = '//*[@id="summary"]/table[2]') %>% html_table(header=TRUE) %>%  simplify() %>%  pluck(1) ->counties
names(counties)<-c("County", "Cases", "Deaths")
counties$Cases=as.numeric(counties$Cases)
counties$Deaths=as.numeric(counties$Deaths)
#remove last line in table which is just a footnote
counties<-counties[!grepl("patient county of residence", counties$County),]

#Function to extract case totals
extract_totals<-function(statistic){
  cases_table[cases_table$`COVID-19 Confirmed Cases`==statistic,2] %>% strsplit("\\(") %>% simplify() %>% pluck(1) %>% as.numeric()
}


#Store total cases and total deaths
total_cases <- extract_totals("Total")
total_hospitalized <- extract_totals("Hospitalized")
total_deaths <- extract_totals("Deaths")







#Break out test/case counts into individual variables
commercial_lab_pos          <- lab_table[
                                          toupper(trimws(lab_table$"COVID-19 Testing By Lab Type:")) == "COMMERCIAL LAB", 
                                          toupper(trimws(names(lab_table))) == "NO. POS. TESTS"
                                        ]
gphl_pos                    <- lab_table[
                                          toupper(trimws(lab_table$"COVID-19 Testing By Lab Type:")) == "GPHL", 
                                          toupper(trimws(names(lab_table))) == "NO. POS. TESTS"
                                        ]
commercial_total_tests      <- lab_table[
                                          toupper(trimws(lab_table$"COVID-19 Testing By Lab Type:")) == "COMMERCIAL LAB", 
                                          toupper(trimws(names(lab_table))) == "TOTAL TESTS"
                                        ]
gphl_total_tests            <- lab_table[
                                          toupper(trimws(lab_table$"COVID-19 Testing By Lab Type:")) == "GPHL", 
                                          toupper(trimws(names(lab_table))) == "TOTAL TESTS"
                                        ]


#Import the date and time the report was generated as denoted in GDPH COVID-19 footer and format variable as datetime
report_generated_datetime <- html %>%
  html_nodes(xpath = '/html/body/i') %>%
  as.character() %>% strsplit(split = "\\Report Generated On : ") %>%
  simplify() %>%
  pluck(2)

report_generated_datetime <- strptime(report_generated_datetime, "%m/%d/%Y %H:%M:%S")

json_text <- html %>%  html_nodes(xpath = '/html/head/script[2]/text()') %>% as_list() 

json_text_vec<-strsplit(json_text[[c(1,1)]],"\n")[[1]]
json_text_vec2 <- grep("dataPoints : [ ", json_text_vec, value = T, fixed = TRUE)
json_text_vec2 <- gsub("dataPoints : [ ","",json_text_vec2, fixed = TRUE)
json_text_vec2 <- gsub("\t","",json_text_vec2)
json_text_vec2 <- gsub("\\\\","",json_text_vec2)
json_text_vec2 <- gsub("';$","",json_text_vec2)
json_text_vec2 <- paste0("[", gsub("^'","",json_text_vec2))

library(jsonlite)
age_results <- fromJSON(json_text_vec2[2])
gender_results <- fromJSON(json_text_vec2[1])

#Extract Demographic Percentage Statistics into a vector
get_demographic_stats<-function(table_name, column){
  table_name[
    toupper(trimws(table_name$"name")) == column, 
    toupper(trimws(names(table_name))) == "Y"
    ]
  
}

#Obtain Age and Gender Demographics
categories <- c("0-17", "18-59", "60+", "UNK")
demographic_var_names <- c("age_0_17_pct", "age_18_59_pct", "age_60_plus_pct", "age_unknown_pct")
age_stats <- get_demographic_stats(age_results, categories)
age_name_vec <- setNames(age_stats, demographic_var_names)

categories <- c("FEMALE", "MALE", "UNKNOWN")
demographic_var_names <- c("sex_female_pct", "sex_male_pct", "sex_unknown_pct")
gender_stats <- get_demographic_stats(gender_results, categories)
gender_name_vec <- setNames(gender_stats, demographic_var_names)


#New Table Of Individuals Deaths and Reorder columns with Instance_ID first
individual_deaths <- html %>%  
  html_nodes(xpath = '//*[@id="deaths"]/table') %>% 
  simplify() %>%  pluck(1) %>% 
  html_table(header=TRUE) %>% 
  mutate(Instance_ID=new_instance_id) %>% 
  select(Instance_ID,  everything())


#Create update record from newly imported statistics by county referencing the instance ID obtained above
counties <-
  data.frame(
    Instance_ID = new_instance_id,
    County = counties$County,
    Cases = counties$Cases,
    Deaths = counties$Deaths
  )


#Create update record from newly imported statistics referencing the instance ID obtained above
new_record <-
  data.frame(
    Instance_ID = new_instance_id,
    report_datetime,
    report_generated_datetime,
    Confirmed = total_cases,
    Hospitalized = total_hospitalized,
    Deaths = total_deaths,
    age_0_17_pct = age_name_vec["age_0_17_pct"],
    age_18_59_pct = age_name_vec["age_18_59_pct"],
    age_60_plus_pct = age_name_vec["age_60_plus_pct"],
    age_unknown_pct = age_name_vec["age_unknown_pct"],
    sex_female_pct = gender_name_vec["sex_female_pct"],
    sex_male_pct = gender_name_vec["sex_male_pct"],
    sex_unknown_pct = gender_name_vec["sex_unknown_pct"],
    commercial_lab_pos,
    gphl_pos,
    commercial_total_tests,
    gphl_total_tests
  )
row.names(new_record) <- NULL

#Append update records to existing dataset
COVID_19_GEORIGA_DATA_CURRENT <-
  rbind(COVID_19_GEORIGA_DATA, new_record)
tail(COVID_19_GEORIGA_DATA)
tail(COVID_19_GEORIGA_DATA_CURRENT)


COVID_19_GEORIGA_COUNTIES_DATA_CURRENT <-
  rbind(COVID_19_GEORIGA_COUNTIES_DATA, counties)
tail(COVID_19_GEORIGA_COUNTIES_DATA_CURRENT)
tail(COVID_19_GEORIGA_COUNTIES_DATA)

COVID_19_GEORIGA_DEATHS_DATA_CURRENT<-
  rbind(if(exists("COVID_19_GEORIGA_DEATHS_DATA")) COVID_19_GEORIGA_DEATHS_DATA, new_individual_deaths)
  
#Save updated data.
saveRDS(
  COVID_19_GEORIGA_DATA_CURRENT,
  file = paste0(DATA_DIRECTORY, "/COVID_19_GEORIGA_DATA.Rds")
)
saveRDS(
  COVID_19_GEORIGA_COUNTIES_DATA_CURRENT,
  file = paste0(DATA_DIRECTORY, "/COVID_19_GEORIGA_COUNTIES_DATA.Rds")
)
saveRDS(
  COVID_19_GEORIGA_DEATHS_DATA_CURRENT,
  file = paste0(DATA_DIRECTORY, "/COVID_19_GEORIGA_DEATHS_DATA.Rds")
)

#Save updated data in alternative CSV format
write.csv(
  COVID_19_GEORIGA_DATA_CURRENT,
  file = paste0(DATA_DIRECTORY, "/COVID_19_GEORIGA_DATA.csv"),
  row.names = FALSE
)
write.csv(
  COVID_19_GEORIGA_COUNTIES_DATA_CURRENT,
  file = paste0(DATA_DIRECTORY, "/COVID_19_GEORIGA_COUNTIES_DATA.csv"),
  row.names = FALSE
)
write.csv(
  COVID_19_GEORIGA_DEATHS_DATA_CURRENT,
  file = paste0(DATA_DIRECTORY, "/COVID_19_GEORIGA_DEATHS_DATA.csv"),
  row.names = FALSE
)

#Upload revised data to public github repository
source(paste0(DATA_DIRECTORY, "/Commit_to_public_github_repo.R"))
git_upload(DATA_DIRECTORY, paste0("Update for ", report_datetime))




       
       