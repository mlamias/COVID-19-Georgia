# COVID-19-Georgia
## Provides historical testing/case counts by date from the Georgia Department of Public Health and updates data automatically

### About this Program:

This program was developed in response to the COVID-19 global pandemic.  The Georgia (USA) Department of
Public Health Publishes updated COVID-19 testing and case counts twice daily at noon and 7 pm Eastern time.  However, the
agtency does not publish a historical record of testing and case counts by date.  Without this historical data, it's impossible
to develop predictive statistical models, make forecastst of disease spread, or develop longitudinal statistical analyses. This
program has loaded all historical data from the Georgia Deaprtment of Public Health using the search results from the
Internet archive service "Wayback Machine - Internet Archive" (www.archive.org) and then updates this data twice a day
(for the noon and 7 pm figures) by scraping data from the Georgia Department of Public Health's website.  After reading this
data, data is updated and stored in both RDS and CSV formats.

### Frequency of Update & Uses:

This program will execute twice daily at 1 pm and 8 pm EDT and output files will be updated accordingly.
Users may use this program directly or simply use the output data that has been compiled so long as attribution is made as
follows:  
> Lamias, Mark J., The Stochastic Group, Inc. 2020.  COVID-19 Historical Data for Georgia.

### Features:

Hadley Wickham's rvest package to navigate to and "screen scrape" web data from the Georgia Department of
Public Health's (GDPH) website.  In addition, since much of the demographic data provided by the GDPH is 
in images of graphics (i.e. pie charts of the percentage of certain populations to be classified as COVID-19 positive cases),
this program uses the tesseract package to virtually "scan" the image, and then to use optical character recognition (OCR)
to extract the relevant text containing the statistical figures.

### Inputs/Global Variables Set by User:
* **DATA_DIRECTORY**:  A valid R pathname to the directory where this program and the existing data reside
* **COVID_19_GEORIGA_DATA.Rds**:  The R RDS file that contains the most recent GA COVID-19 data
* **COVID_19_GEORIGA_COUNTIES_DATA**:  The R RDS file that contains the most recent GA COVID-19 data by county
* **URL**:  The Uniform Resource Locator to the Georgia Department of Public Health's COVID-19 daily report page

### Outputs:
This program outputs 4 files:
1. An Updated COVID_19_GEORIGA_DATA RDS file;
1. An Updated COVID_19_GEORIGA_DATA CSV file;
1. An Updated COVID_19_GEORIGA_COUNTIES_DATA RDS file;
1. An Updated COVID_19_GEORIGA_COUNTIES_DATA CSV file;
All output is sent to the DATA_DIRECTORY and files are overwritten.
