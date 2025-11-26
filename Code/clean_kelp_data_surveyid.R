###############################################################################
## The raw dataset initially recorded approximately 500 species but lacked  ###
## entries for absent species in specific quadrats; it only included species ##
## that were present. To refine this, we inserted zero values for species   ###
## not recorded in particular sites and years, including those observed at  ###
## the same sites in other years. After modifying the dataset, we verified  ###
## its quality with the NRMN team.
###############################################################################

library(ggplot2)
library(plyr)
library(reshape2)
library(dplyr) 
library(tidyr)
library(viridis)

theme_format <- theme_bw()+
  theme(axis.text.x  = element_text(vjust=0.5,size=12, colour = "black"))+
  theme(axis.text.y  = element_text(size=12, colour = "black"))+
  theme(axis.title.x = element_text(size=14, colour = "black"))+
  theme(axis.title.y = element_text(size=14, colour = "black"))+
  #panel.background = element_rect(fill="white"),
  theme(axis.ticks = element_line(colour="black"))+
  theme(panel.grid.minor=element_blank())+
  theme(panel.grid.major=element_blank())

# import data -------------------------------------------------------------
### Raw NRMN seaweed data can be downloaded from Raw data and instructions can be accessed from 
### https://catalogue-imos.aodn.org.au/geonetwork/srv/eng/catalog.search#/metadata/ec424e4f-0f55-41a5-a3f2-726bc4541947
### Read `rawdata_download_use.md`
alg.rls<-read.csv("er_atrc.csv") #import seaweed data 

## convert to percentage number
alg.rls <- mutate(alg.rls,percentage=round(total/50*100,2))  
str(alg.rls) 

#convert characters to factors
MI.atrc$location<-as.factor(MI.atrc$location)
MI.atrc$area<-as.factor(MI.atrc$area)
MI.atrc$country<-as.factor(MI.atrc$country)
MI.atrc$ecoregion<-as.factor(MI.atrc$ecoregion)
MI.atrc$realm<-as.factor(MI.atrc$realm)
MI.atrc$site_code<-as.factor(MI.atrc$site_code)
MI.atrc$phylum<-as.factor(MI.atrc$phylum)
MI.atrc$class<-as.factor(MI.atrc$class)
MI.atrc$order<-as.factor(MI.atrc$order)
MI.atrc$family<-as.factor(MI.atrc$family)
MI.atrc$survey_id<-as.factor(MI.atrc$survey_id)
MI.atrc$percentage<-as.integer(MI.atrc$percentage)
str(MI.atrc)

#convert survey_date from Character to date.
MI.atrc$survey_date <- as.Date(MI.atrc$survey_date, format = "%Y-%m-%d")
#Create new factor with survey year
MI.atrc$survey_year<-format(as.Date(MI.atrc$survey_date, format="%d-%m-%YY"),"%Y")
# MI.atrc$survey_year<-as.factor(MI.atrc$survey_year)
str(MI.atrc)

# Determine the unique time period for each location
location_time_periods_sites <- MI.atrc %>%
  group_by(location) %>%
  summarize(unique_taxon = list(unique(taxon)), unique_ids = list(unique(survey_id))) #unique_years = list(unique(survey_year)), unique_sites = list(unique(site_name)), 

complete_data <- location_time_periods_sites %>%
  rowwise() %>%
  mutate(data_frame = list(expand_grid(taxon = unique_taxon, survey_id = unique_ids))) %>%  # survey_year = unique_years, site_name = unique_sites, 
  select(-unique_taxon, -unique_ids) %>%  # -unique_years, -unique_sites, 
  unnest(cols = data_frame)

## Join the complete dataset with the original data
MI.atrc$survey_year<-as.factor(MI.atrc$survey_year)

MI.atrc_short = MI.atrc[, c("survey_id", "location", "site_code", "site_name", "quadrat",
                            "latitude", "longitude", "survey_date", "program", "taxon", "percentage", "survey_year")]
data_joined <- complete_data %>%
  left_join(MI.atrc_short, by = c("location","survey_id", "taxon"))  #"survey_year", , "site_name"

df_joined_filled <- data_joined %>%
       group_by(survey_id) %>%
       mutate(across(c(site_code, site_name, latitude, longitude, program, survey_year), ~ if_else(is.na(.), first(na.omit(.)), .))) %>%
       ungroup() %>%
       # Replace NA in percentage column with 0
       mutate(percentage = replace_na(percentage, 0))

## select specifc species
finaldata <- df_joined_filled %>% filter(taxon =="Ecklonia radiata")


# Filter data based on specific location and month criteria if needed
finaldata_lo <- df_joined_filled %>% filter(
  location == "Maria Island" & format(survey_date, "%m") %in% c("03", "04", "05")
  | location == 'Jurien'| location=="Jervis Bay"
)

# Average into site/location level ----------------------------------------
####average data, first by survey_id, then by site and location
quad.id<-ddply(finaldata,c("survey_id","location","site_code","site_name", "latitude", "longitude",
                             "survey_year","taxon"),summarise, survey.mean = sum(percentage)/5)
quad.site<-ddply(quad.id,c("location","site_name","survey_year",
                              "taxon", "latitude", "longitude"),summarise, survey.mean = mean(survey.mean))
#average data by location
quad.loca <-ddply(quad.site,c("location","survey_year","taxon"),summarise, survey.mean = mean(survey.mean))


# neat data into csv ------------------------------------------------------
write.table(quad.id, "kelp/er_atrc_id.csv", sep = ",", row.names = FALSE, col.names = TRUE) # change to site if needed


