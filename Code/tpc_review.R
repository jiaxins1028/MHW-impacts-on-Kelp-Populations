#Loading required packages
library(rTPC)
library(nls.multstart)
library(broom)
library(tidyverse)
library(ggpubr)
library(readr)
library(investr)
library(car)
library(patchwork)
library(xts)
library(ncdf4)


# Themes ------------------------------------------------------------------
theme_format <- theme_bw()+
  theme(axis.text.x  = element_text(vjust=0.5,size=12, colour = "black"))+
  theme(axis.text.y  = element_text(size=12, colour = "black"))+
  theme(axis.title.x = element_text(size=14, colour = "black"))+
  theme(axis.title.y = element_text(size=14, colour = "black"))+
  #panel.background = element_rect(fill="white"),
  theme(axis.ticks = element_line(colour="black"))+
  theme(panel.grid.minor=element_blank())+
  theme(panel.grid.major=element_blank())+
  theme(strip.text = element_text(size = 14))

theme_format_1 <- theme_bw()+
  theme(axis.text.x  = element_text(vjust=0.5,size=12, colour = "black"))+
  theme(axis.text.y  = element_text(size=12, colour = "black"))+
  theme(axis.title.x = element_text(size=14, colour = "black"))+
  theme(axis.title.y = element_text(size=14, colour = "black"))+
  #panel.background = element_rect(fill="white"),
  theme(axis.ticks = element_line(colour="black"))+
  theme(axis.title.x=element_blank(),
  axis.text.x=element_blank(),
  axis.ticks.x=element_blank())+
  theme(panel.grid.minor=element_blank())+
  theme(panel.grid.major=element_blank())+
  theme(strip.text = element_text(size = 14))


#  ------------------------------------------------------
###Import Data; only change the file path

# TPC data sources from Wernberg et al. (2016b) and Britton et al. (2024)

df <- read_csv('populations_TPC.csv', show_col_types = FALSE)
df$location <- factor(df$location, levels = unique(df$location))
df_warm <- df %>% filter(!location == 'Coal Point')
df_cool <- df %>% filter(location == 'Coal Point')

# get mean for each temp
df_cool_mean <- df_cool %>%
  group_by(temperature) %>%
  summarize(
    mean_net_photo = mean(net_photo, na.rm = TRUE),
    sd_net_photo = sd(net_photo, na.rm = TRUE),  # Ensure na.rm = TRUE is set
    n = n(),
    location = 'Coal Point'
  ) %>%
  mutate(
    lower = ifelse(is.na(sd_net_photo), NA, mean_net_photo - sd_net_photo / sqrt(n)),
    upper = ifelse(is.na(sd_net_photo), NA, mean_net_photo + sd_net_photo / sqrt(n))
  )


# initial visualisation ---------------------------------------------------
p1 <- ggplot(data=df_warm, aes(y = net_photo, x = temperature)) +
  geom_line(linewidth = 1)+  geom_point(size = 2.5)+
  scale_x_continuous(limits = c(5, 30), breaks=seq(5, 30, 5))+
  scale_y_continuous(limits = c(0,3), breaks=seq(0,3,1))+
  facet_grid(location ~ ., scales="free_y")+
  # xlab(expression(paste("Temperature (",degree,"C)")))+
  ylab(expression("Net photosynthesis (mg " * "O" [2] * "g " * "dw" ^ {-1} * "h" ^ {-1} * ")")) +
  theme_format_1

p2 <- ggplot(data=df_cool_mean, aes(y=mean_net_photo, x=temperature)) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.4) +  # Add error bars
  geom_line(linewidth = 1)+  geom_point(size = 2.5)+
  scale_x_continuous(limits = c(5, 30), breaks=seq(5, 30, 5))+
  scale_y_continuous(limits = c(0,6), breaks=seq(0,6,2))+
  facet_grid(location ~ ., scales="free_y")+
  xlab(expression(paste("Temperature (",degree,"C)")))+
  ylab(expression(atop("Net photosynthesis", paste("(µmol ", O[2], "/L/g/h)"))))+
  theme_format

p1/p2 + plot_layout(heights = c(3, 1))


# mark realised Tmax ------------------------------------------------------
nc_sst <- nc_open("real_sst_lab_tmax.nc")

sst <- ncvar_get(nc_sst, "sst")
lat <- ncvar_get(nc_sst, "lat")
lon <- ncvar_get(nc_sst, "lon")
time <- ncvar_get(nc_sst, "time") 
# Generate daily dates from 1990-2021 (adjust as necessary)
date_seq <- seq(from = as.Date("1990-01-01"), to = as.Date("2021-12-31"), by = "day")

# Define multiple lat-lon ranges
unique_location <- unique(df[, c("location", "lat", "lon")])

# Initialize data frame for storing summary information
summary_df <- data.frame()

# Loop over each unique location
for (i in 1:nrow(unique_location)) {
  
  lat_i = as.numeric(unique_location[i, "lat"])
  lon_i = as.numeric(unique_location[i, "lon"])
  
  lat_idx <- which(lat >= lat_i-0.5 & lat <= lat_i+0.5)
  lon_idx <- which(lon >= lon_i-0.5 & lon <= lon_i+0.5)
  
  # print(paste("Lat indices: ", length(lat_idx)))
  # print(paste("Lon indices: ", length(lon_idx)))
  
  sst_i <- sst[lon_idx, lat_idx, ]
  
  # The 'apply' function has to operate along the 3rd dimension (time), hence 'MARGIN=3'
  avg_sst_i <- apply(sst_i, MARGIN = 3, function(x) mean(x, na.rm = TRUE))
  
  # Create an xts object
  x <- xts(avg_sst_i, order.by = date_seq)
  
  # Resample to monthly frequency, calculating the mean for each month
  monthly_sst <- apply.monthly(x, mean)
  
  # Find max daily and max monthly temperature
  max_daily_temp <- max(coredata(x), na.rm = TRUE)
  max_monthly_temp <- max(coredata(monthly_sst), na.rm = TRUE)
  
  # Add to the summary data frame
  # location_label <- paste("location:", unique_location[i, "location"])
  summary_df <- rbind(summary_df, data.frame(
    location = unique_location[i, "location"],
    maxdailytemp = max_daily_temp,
    maxmonthlytemp = max_monthly_temp,
    stringsAsFactors = FALSE
  ))
}

# Show the summary data frame
print(summary_df)

summary_df_warm <- summary_df%>% filter(!location == 'Coal Point')
summary_df_cool <- summary_df%>% filter(location == 'Coal Point')


# fit Gaussian TPC --------------------------------------------------------

preds_total <- data.frame() 
boot1_conf_preds <- data.frame() 
param_df <- data.frame()

for (i in unique(df$location)) {
  df_i <- df %>% filter(location == i) 
  df_i <- df_i  %>%
    group_by(temperature) %>%
    summarize(
          mean_net_photo = mean(net_photo, na.rm = TRUE),
          sd = sd(net_photo, na.rm = TRUE),  # Ensure na.rm = TRUE is set
          groups = 'drop')
  start_vals<- get_start_vals(df_i$temperature, df_i$mean_net_photo, model_name = 'oneill_1972')
  
  # # fit model
  mod <- nls.multstart::nls_multstart(mean_net_photo ~ oneill_1972(temp = temperature,rmax, ctmax, topt, q10),
                                      data = df_i,
                                      iter = c(4,4,4,4),
                                      start_lower = start_vals - 10,
                                      start_upper = start_vals + 10,
                                      lower = get_lower_lims(df_i$temperature, df_i$mean_net_photo, model_name = 'oneill_1972'),
                                      upper = get_upper_lims(df_i$temperature, df_i$mean_net_photo, model_name = 'oneill_1972'),
                                      supp_errors = 'Y',
                                      convergence_count = FALSE)
  # get Topt and CTmax
  params <- calc_params(mod) %>%  mutate_all(round, 2)
  print(paste("Parameters in location", i, ":"))
  print(params)
  param_df <- rbind(param_df, data.frame(
    location = i,
    topt = params$topt,
    ctmax = params$ctmax,
    stringsAsFactors = FALSE
  ))
  # get predictions
  new_data <- data.frame(temperature = seq(min(df_i$temperature), max(df_i$temperature), length.out = 100))
  preds_i <- augment(mod, newdata = new_data)
  preds_i$location <- i
  preds_total <- rbind(preds_total, preds_i)
  
  # refit model using nlsLM
  fit_nlsLM <- minpack.lm::nlsLM(mean_net_photo ~ oneill_1972(temp = temperature, rmax, ctmax, topt, q10),
                                 data = df_i,
                                 start = start_vals,
                                 lower = get_lower_lims(df_i$temperature, df_i$mean_net_photo, model_name = 'oneill_1972'),
                                 upper = get_upper_lims(df_i$temperature, df_i$mean_net_photo, model_name = 'oneill_1972'))
  # boot1 <- Boot(fit_nlsLM, method = 'case') ###if that fails use method = "residual"
  
  # # perform residual bootstrap
  boot1 <- Boot(fit_nlsLM, method = 'residual')
  # predict over new data
  boot1_preds_i <- boot1$t %>%
    as.data.frame() %>%
    drop_na() %>%
    mutate(iter = 1:n()) %>%
    group_by_all() %>%
    do(data.frame(temperature = seq(min(df_i$temperature), max(df_i$temperature), length.out = 100))) %>%
    ungroup() %>%
    mutate(pred = oneill_1972(temperature, rmax, ctmax, topt, q10)) 
  # %>%     filter(!is.na(pred) & !is.nan(pred))
  
  # calculate bootstrapped confidence intervals
  boot1_conf_preds_i <- group_by(boot1_preds_i, temperature) %>%
    summarise(conf_lower = quantile(pred, 0.025),
              conf_upper = quantile(pred, 0.975),
              .groups = 'drop')
  boot1_conf_preds_i$location <- i
  boot1_conf_preds <- rbind(boot1_conf_preds, boot1_conf_preds_i)
}


# Plot the scatter and regression of TPC

preds_total$location <- factor(preds_total$location, levels = unique(preds_total$location))
preds_total_warm <- preds_total %>% filter(!location == 'Coal Point')
preds_total_cool <- preds_total %>% filter(location == 'Coal Point')
param_df$location <- factor(param_df$location, levels = unique(df$location))
param_df_warm <- param_df %>% filter(!location == 'Coal Point')
param_df_cool <- param_df %>% filter(location == 'Coal Point')
boot1_conf_preds$location <- factor(boot1_conf_preds$location, levels = unique(df$location))
boot1_conf_preds_warm <- boot1_conf_preds %>% filter(!location == 'Coal Point')
boot1_conf_preds_cool <- boot1_conf_preds %>% filter(location == 'Coal Point')

p1 <- ggplot() +
  geom_vline(data=param_df_warm, aes(xintercept=topt), color='limegreen', linewidth = 2) +
  geom_vline(data=param_df_warm, aes(xintercept=ctmax), color='darkred', linewidth = 2) +
  # geom_vline(data=summary_df_warm, aes(xintercept=maxmonthlytemp), color='sandybrown', linewidth = 2) +  # Added this line   , linetype='dashed'
  geom_vline(data=summary_df_warm, aes(xintercept=maxdailytemp), color='orangered', linewidth = 2) +
  # geom_ribbon(data = boot1_conf_preds_warm, aes(temperature, ymin = conf_lower, ymax = conf_upper), fill = 'blue', alpha = 0.3) +
  geom_line(data=preds_total_warm, aes(y = .fitted, x = temperature), linewidth = 1, color = 'blue')+  
  geom_point(data=df_warm, aes(y = net_photo, x = temperature))+  #, size = 2
  
  
  scale_x_continuous(limits = c(5, 30), breaks=seq(5, 30, 5))+
  scale_y_continuous(limits = c(0,3), breaks=seq(0,3,1))+
  facet_grid(location ~ ., scales="free_y")+
  # xlab(expression(paste("Temperature (",degree,"C)")))+
  ylab(expression("Net photosynthesis (mg " * "O" [2] * "g " * "dw" ^ {-1} * "h" ^ {-1} * ")")) +
  theme_format_1

p2 <- ggplot() +
  geom_vline(data=param_df_cool, aes(xintercept=topt, color="Topt"), linewidth = 2) +
  geom_vline(data=param_df_cool, aes(xintercept=ctmax, color="CTmax"), linewidth = 2) +
  # geom_vline(data=summary_df_cool, aes(xintercept=maxmonthlytemp, color="Max Monthly SST"), linewidth = 2) +
  geom_vline(data=summary_df_cool, aes(xintercept=maxdailytemp, color="Max Daily SST"), linewidth = 2) +
  # geom_ribbon(data=boot1_conf_preds_cool, aes(temperature, ymin = conf_lower, ymax = conf_upper), fill = 'blue', alpha = 0.3) +
  geom_line(data=preds_total_cool, aes(y = .fitted, x = temperature), linewidth = 1, color = 'blue')+  
  geom_point(data=df_cool_mean, aes(y=mean_net_photo, x=temperature)) +
  geom_errorbar(data=df_cool_mean, aes(x = temperature, ymin = lower, ymax = upper), width = 0.4) +  # Add error bars
  
  scale_x_continuous(limits = c(5, 30), breaks=seq(5, 30, 5)) +
  scale_y_continuous(limits = c(0, 8), breaks=seq(0,8,2)) +
  facet_grid(location ~ ., scales="free_y") +
  xlab(expression(paste("Temperature (",degree,"C)"))) +
  ylab(expression(atop("Net photosynthesis", paste("(µmol ", O[2], "/L/g/h)")))) +
  theme_format +
  scale_color_manual(NULL, values = c("Topt" = "limegreen", "CTmax" = "darkred", "Max Monthly SST" = "sandybrown", "Max Daily SST" = "orangered"),
                     guide = guide_legend(direction = "horizontal", title.position = "top", label.position = "bottom",
                       byrow = FALSE, keywidth = unit(3, "cm"), keyheight = unit(0.5, "cm"))) +
  theme(legend.position = "bottom", legend.text = element_text(size = 11))
p2

p_final = p1/p2 + plot_layout(heights = c(3, 1))
p_final



