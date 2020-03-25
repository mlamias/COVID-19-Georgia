###################################################################################################################################
#Program Copyright, 2020, Mark J. Lamias, The Stochastic Group, Inc.
#Version 1.0 - Initial Update
#Version 1.1- Formatt and cleaned up code
#Version 1.2- Fix typos in header
#Version 1.3- Changed the method to extract demographic statistics from alt text
#Version 1.4- Updated script to include total_hospitalizations.  This was not previously available from GA DPH
#Last Updated:  03/24/2020 11:17 PM EDT
#
#Terms of Service
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
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
library(tesseract)
library(stringr)
library(readxl)

#Set data directory
DATA_DIRECTORY <- "D:/Code/Github/COVID-19-Georgia"

#Import historical GDPH COVID-19 Data and Import historical GDPH COVID-19 Data for counties
COVID_19_GEORIGA_DATA <- readRDS(file = paste0(DATA_DIRECTORY, "/COVID_19_GEORIGA_DATA.Rds"))
COVID_19_GEORIGA_COUNTIES_DATA <- readRDS(file = paste0(DATA_DIRECTORY, "/COVID_19_GEORIGA_COUNTIES_DATA.Rds"))
#Create a report instance ID to differentiate reports from one another
new_instance_id <- max(COVID_19_GEORIGA_DATA$Instance_ID) + 1

#Convert to POSIXct format for date times to facilitate date/time handling
COVID_19_GEORIGA_DATA$report_datetime <- as.POSIXct(COVID_19_GEORIGA_DATA$report_datetime)
COVID_19_GEORIGA_DATA$report_generated_datetime <- as.POSIXct(COVID_19_GEORIGA_DATA$report_generated_datetime)


#Connect to GDPH website and read web page
URL <- "https://dph.georgia.gov/covid-19-daily-status-report"
session <- html_session(URL)
html <- read_html(session)


#Get report date and time from page header
report_date_parts <-
  html %>% html_nodes(xpath = '//*[@id="main-content"]/div/div[3]/div[1]/div/main/div[2]') %>%
  as.character() %>% strsplit(split = "\\For: ") %>%
  simplify() %>%
  pluck(2) %>% strsplit(split = " <")  %>% simplify()

#Create datetime variable from date and time parts
report_date <- report_date_parts[1] %>% as.Date(format = "%m/%d/%Y")
report_time <-
  gsub("[\\(\\)]", "", regmatches(
    report_date_parts[2],
    gregexpr("\\(.*?\\)", report_date_parts[2])
  )[[1]])[1]

report_datetime_str <- paste(report_date, report_time)
report_datetime <-
  strptime(report_datetime_str, "%Y-%m-%d %I:%M %p")


#Read in first and second table which define test/case counts by lab type
cases_table <-
  html %>% html_nodes(xpath = '//*[@id="main-content"]/div/div[3]/div[1]/div/main/div[2]/table[1]') %>% html_table() %>% pluck(1)
lab_table <-
  html %>% html_nodes(xpath = '//*[@id="main-content"]/div/div[3]/div[1]/div/main/div[2]/table[2]') %>% html_table() %>% pluck(1)

#Function to extract case totals
extract_totals<-function(statistic){
  cases_table[cases_table$`COVID-19 Confirmed Cases`==statistic,2] %>% strsplit("\\(") %>% simplify() %>% pluck(1) %>% as.numeric()
}


#Store total cases and total deaths
total_cases <- extract_totals("Total")
total_hospitalized <- extract_totals("Hospitalized")
total_deaths <- extract_totals("Deaths")

#Break out test/case counts into individual variables
commercial_lab_pos          <- lab_table[1, 2]
gphl_pos                    <- lab_table[2, 2]
commercial_total_tests      <- lab_table[1, 3]
gphl_total_tests            <- lab_table[2, 3]

#Obtain case counts by county
counties <-
  html %>% html_nodes(xpath = '//*[@id="main-content"]/div/div[3]/div[1]/div/main/div[2]/table[3]') %>% html_table() %>% pluck(1)

#Import the date and time the report was generated as denoted in GDPH COVID-19 footer and format variable as datetime
report_generated_datetime <- html %>%
  html_nodes(xpath = '//*[@id="main-content"]/div/div[3]/div[1]/div/main/div[2]') %>%
  as.character() %>% strsplit(split = "\\on: ") %>%
  simplify() %>%
  pluck(2)

report_generated_datetime <- strptime(report_generated_datetime, "%m/%d/%Y %H:%M:%S")

#Since case counts by demographics are not available in plain text, dynamically obtain the image name that displays the percentage breakdowns in a graphic
image_name_text <-
  read_html(session) %>% html_nodes('#main-content img') %>%
  magrittr::extract2(2) %>%
  html_attr("alt") %>%
  strsplit(split = "\\?") %>%
  simplify() %>%
  pluck(1)

#Extract Demographic Percentage Statistics into a vector
demographics <- as.numeric(str_replace(str_extract_all(image_name_text, "[0-9]+%")[[1]], "%", ""))

age_0_17_pct    <- demographics[1]
age_18_59_pct   <- demographics[2]
age_60_plus_pct <- demographics[3]
age_unknown_pct <- demographics[4]
sex_female_pct	<- demographics[5]
sex_male_pct    <- demographics[6]
sex_unknown_pct <- demographics[7]

#Create update record from newly imported statistics by county referencing the instance ID obtained above
counties <-
  data.frame(
    Instance_ID = new_instance_id,
    County = counties$County,
    Percent = counties$Cases
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
    age_0_17_pct,
    age_18_59_pct,
    age_60_plus_pct,
    age_unknown_pct,
    sex_female_pct,
    sex_male_pct,
    sex_unknown_pct,
    commercial_lab_pos,
    gphl_pos,
    commercial_total_tests,
    gphl_total_tests
  )

#Append update records to existing dataset
COVID_19_GEORIGA_DATA_CURRENT <-
  rbind(COVID_19_GEORIGA_DATA, new_record)
tail(COVID_19_GEORIGA_COUNTIES_DATA_CURRENT) <-
  rbind(COVID_19_GEORIGA_COUNTIES_DATA, counties)

#Save updated data.
saveRDS(
  COVID_19_GEORIGA_DATA_CURRENT,
  file = paste0(DATA_DIRECTORY, "/COVID_19_GEORIGA_DATA.Rds")
)
saveRDS(
  COVID_19_GEORIGA_COUNTIES_DATA_CURRENT,
  file = paste0(DATA_DIRECTORY, "/COVID_19_GEORIGA_COUNTIES_DATA.Rds")
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

