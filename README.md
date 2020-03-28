# COVID-19-Georgia
## Provides historical testing/case counts by date for COVID-19 (coronavirus) from the Georgia Department of Public Health and updates data automatically

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

This program uses Hadley Wickham's rvest package to navigate to and "screen scrape" web data from the Georgia Department of
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

Note that the COVID_19_GEORIGA_COUNTIES_DATA data files may be joined to the COVID_19_GEORIGA_DATA data file on Instance ID to obtain additional details associated with each county case counts.

The CSV files are comma separated values datasets.  They can be opened in any text editor or in MS Excel.  The RDS files such as COVID_19_GEORIGA_DATA.Rds can be read into R using synatx such as:
> readRDS(file = "COVID_19_GEORIGA_DATA.Rds")

Assuming the COVID_19_GEORIGA_DATA.Rds is in the R working directory.  Otherwise, you can specify the full path to the file in the file argument of the readRDS function.


### Dataset Variables
#### COVID_19_GEORGIA_DATA

| Variable Name  | Variable Description |
| ------------- | ------------- |
| Instance_ID   | The report instance.  Each separate report from GDPH corresponds to a unique (but not necessarily sequential) Instance ID.  |
| report_datetime  | The date and time that appears at the top of each GDPH report.  Currently reports are produced twice at day at noon and 7 pm.  |
| report_generated_datetime   | The actual date and time that the report was generated prior to posting at noon and 7.  |
| Confirmed   | The number of confirmed COVID-19 positive cases.  |
| Hospitalized   | The number of confirmed COVID-19 hospitalizations.  |
| Deaths   | The number of confirmed COVID-19 related deaths.  |
| age_0_17_pct   | The percentage of those age 0-17 years testing positive for COVID-19.  |
| age_18_59_pct   | The percentage of those age 18-59 years testing positive for COVID-19.  |
| age_60_plus_pct   | The percentage of those age 60+ years testing positive for COVID-19.  |
| age_unknown_pct   | The percentage of those of uknown/unclassified age testing positive for COVID-19.  |
| sex_female_pct   | The percentage of females testing positive for COVID-19.  |
| sex_male_pct   | The percentage of males testing positive for COVID-19.  |
| sex_unknown_pct   | The percentage of those of unknown/unclassified sex testing positive for COVID-19.  |
| commercial_lab_pos   | The number of COVID-19 positive cases tested by commercial laboratories.  |
| gphl_pos   | The number of COVID-19 positive cases tested by Georgia Public Health Laboratories.  |
| commercial_total_tests   | The total number of COVID-19 tests carried out by commercial laboratories.	  |
| gphl_total_tests   | The total number of COVID-19 tests carried out by Georgia Public Health Laboratories.  |

#### COVID_19_GEORIGA_COUNTIES_DATA

| Variable Name  | Variable Description |
| ------------- | ------------- |
| Instance_ID   | The report instance.  Each separate report from GDPH corresponds to a unique (but not necessarily sequential) Instance ID.  |
| County  | County Name  |
| Cases   | The number of COVID-19 positive cases in the given Georgia county.  |

#### MISCELLANEOUS NOTES

* The GDPH COVID-19 report format changed on the evening of 3/27/2020.  This new format included deaths by county for the first time.  Previousu to the report dated 2020-03-27 18:27:51 EDT, county level deaths are not available.
* Because of the report format change on 2020-03-27 18:27:51 EDT, a new data extraction script called Update_covid_figures_from_gdph-ReportFormatStarting2020_03_28.R is used.  Before this date, the Update_covid_figures_from_gdph.R script was used.
