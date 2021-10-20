##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~
##~~##~~##~~##~~  Model Visualization                                                         ##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~
##~~##~~##~~##~~  Purpose: Running a model to test if temp and/or urchin influences kelp cover       ##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~
##~~##~~##~~##~~  Thew Suskiewicz   - May 27, 2020                                         ##~~##~~##~~##~~##~
##~~##~~##~~##~~  Worked On: May 7th, 2021 (emerging from COVID like a cicada)             ##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~
##~~##~~##~~##~~  Last Worked On: Oct 12th, 2021                                    ##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~
##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~
##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~##~~

library(ggplot2)
library(emmeans)
library(dplyr)
library(tidyr)
library(glmmTMB)
library(here) # paths to data should 'just work' (though having problems with it)

setwd(here::here())
source("scripts/2_load_combined_data.R")
mod_urchin_add <- readRDS("model_output/mod_urchin_add.RDS")

regional_values <- combined_bio_temp_gmc %>%
    dplyr::group_by(region) %>%
    dplyr::select(mean_regional_urchin, mean_mean_temp_spring, mean_mean_temp_summer) %>%
    dplyr::slice(1L) %>%
    ungroup() %>%
    mutate(region = gsub("\\.", " ", region),
           region = stringr::str_to_title(region),
           region = gsub("Mdi", "MDI", region),
           region = factor(region,
                           levels = c("Downeast", "MDI", "Penobscot Bay",
                                      "Midcoast", "Casco Bay", "York")))

# Look at the spring temperature effect
spring_temp_effect <-
    emmeans(
        mod_urchin_add,
        ~ mean_temp_spring_dev +lag_mean_temp_summer_dev|
            mean_regional_urchin + mean_mean_temp_spring + mean_mean_temp_summer,
        at = list(
            mean_temp_spring_dev = seq(-2.5, 2.5, length.out=100),
            urchin_anom_from_region = 0,
            lag_mean_temp_summer_dev = c(-2.5, 0, 2.5),
            mean_regional_urchin = regional_values$mean_regional_urchin,
            mean_mean_temp_spring = regional_values$mean_mean_temp_spring,
            mean_mean_temp_summer = regional_values$mean_mean_temp_summer
        ),
        type = "response"
    ) %>%
    as_tibble() %>%
    right_join(regional_values) 

add_lag_label <- function(x, value) paste("Lag Temp. Anomaly =", x[value])

ggplot(spring_temp_effect%>% mutate(lag_mean_temp_summer_dev = paste0("Lag Temp. Anomaly: ", lag_mean_temp_summer_dev)),
       aes(x = mean_temp_spring_dev, y = 100*response, color = region)) +
    geom_line(size = 1) +
    facet_wrap(vars(lag_mean_temp_summer_dev)) +
    theme_bw(base_size = 12) +
    #scale_y_continuous(labels = function(x) paste0(x, "%")) +
    scale_color_brewer(type = "div") +
    theme(legend.position = "bottom") +
    labs(color = "", 
         x = "Regional Spring Temperature Anomaly (C)",
         y = "Kelp Percent Cover",
         subtitle = "Urchin anomaly held at 0",
         title ="Effect of spring temperature and lagged summer\ntemperature on kelp cover")

ggsave("figures/temperature_effect_on_kelp.jpg", dpi = 600)

# Now look at urchins

# Look at the spring temperature effect
temp_by_urchin_effect <-
    emmeans(
        mod_urchin_add,
        ~ mean_temp_spring_dev |urchin_anom_from_region +
            mean_regional_urchin + mean_mean_temp_spring + mean_mean_temp_summer,
        at = list(
            mean_temp_spring_dev = seq(-2.5, 2.5, length.out=100),
            urchin_anom_from_region = c(-10,40,80),
            lag_mean_temp_summer_dev = 0,
            mean_regional_urchin = regional_values$mean_regional_urchin,
            mean_mean_temp_spring = regional_values$mean_mean_temp_spring,
            mean_mean_temp_summer = regional_values$mean_mean_temp_summer
        ),
        type = "response"
    ) %>%
    as_tibble() %>%
    right_join(regional_values) 


ggplot(temp_by_urchin_effect %>% mutate(urchin_anom_from_region = paste0("Urchin Anomaly: ", urchin_anom_from_region)),
       aes(x = mean_temp_spring_dev, y = 100*response, color = region)) +
    geom_line(size = 1) +
    facet_wrap(vars(urchin_anom_from_region)) +
    theme_bw(base_size = 12) +
    #scale_y_continuous(labels = function(x) paste0(x, "%")) +
    scale_color_brewer(type = "div") +
    theme(legend.position = "bottom") +
    labs(color = "", 
         x = "Regional Spring Temperature Anomaly (C)",
         y = "Kelp Percent Cover",
         subtitle = "Lag Summer Temp anomaly held at 0")

ggsave("figures/urchin_temperature_effect_on_kelp.jpg", dpi = 600)


### Below here is old code
# DF.join <- read_csv("derived_data/combined_data_for_analysis.csv")
# mod_urchin_add <- readRDS("derived_data/mod_urchin_add.RDS")
# 
# 
# # Some info we will need
# region_df <- DF.join %>%
#     group_by(region) %>%
#     summarize(mean_temp_mn = mean_temp_mn[1],
#               urchin_mn = urchin_mn[1])
# 
# timeseries_df <- DF.join %>%
#     group_by(year) %>%
#     summarize(urchin_dev = mean(urchin_dev, na.rm=TRUE),
#               mean_temp_dev = mean(mean_temp_dev, na.rm=TRUE),
#               urchin = mean(urchin, na.rm = TRUE)) %>%
#     arrange(year)
# 
# 
# # heatmap-a-palooza
# source("scripts/make_kelp_heatmap.R")
# 
# # two sites at 0 and 50 urchins
# # note - we start with known urchin density and temp
# # then subtract our regional means to get the anomalies
# 
# pred_frame <- crossing(region_df,
#          urchin  = c(0,50),
#                 temp = seq(11, 18, length.out = 100),
#          year = 2015) %>%
#     mutate(mean_temp_dev = temp - mean_temp_mn,
#            urchin_dev = urchin - urchin_mn)
# 
# pred_values <- predict(mod_urchin_add, 
#                                 newdata = pred_frame, 
#                                 re.form = NULL, 
#                                 type = "response",
#                                 se.fit = TRUE)
# 
# pred_frame <- pred_frame %>%
#     mutate(kelp.perc = pred_values$fit,
#            lwr = kelp.perc - 1*pred_values$se.fit,
#            upr = kelp.perc + 1*pred_values$se.fit,
#            lwr = ifelse(lwr < 0, 0, lwr))
# #all sites
# ggplot(pred_frame,
#        aes(x = temp,
#            y = kelp.perc,
#            group = region, 
#            color = mean_temp_mn)) +
#     geom_line() +
#     facet_wrap(~urchin, ncol = 1) +
#     scale_color_gradient(low = "blue", high = "red")
# # 
# 
# #york v. downeast
# ggplot(pred_frame %>% 
#            filter(region %in% c("downeast", "york")) %>%
#            mutate(urchin = paste0(urchin, " urchins"),
#                   region = stringr::str_to_title(region)),
#        aes(x = temp,
#            y = kelp.perc*100,
#            group = region, 
#            color = region)) +
#     geom_line(size = 2) +
#     geom_ribbon(aes(ymin = lwr*100, ymax = upr*100), alpha = 0.2, color = NA, fill = "grey") +
#     facet_wrap(~urchin, ncol = 1) +
#     scale_color_manual(values = c("blue", "red")) +
#     theme_bw() +
#     labs(color = "",
#          x = "Temperature C",
#          y = "Percent Cover Kelp")
# 
# 
# ## scenarios!
# 
# scenario <- crossing(region_df, timeseries_df)
# 
# 
# scenario_values <- predict(mod_urchin_add, 
#                        newdata = scenario, 
#                        re.form = NULL, 
#                        type = "response",
#                        se.fit = TRUE)
# 
# scenario <- scenario %>%
#     mutate(kelp.perc = scenario_values$fit,
#            lwr = kelp.perc - 1*scenario_values$se.fit,
#            upr = kelp.perc + 1*scenario_values$se.fit,
#            lwr = ifelse(lwr < 0, 0, lwr))
# 
# 
# 
# 
# #york v. downeast
# ggplot(scenario %>% 
#            filter(region %in% c("downeast", "york")) %>%
#            mutate(region = stringr::str_to_title(region)),
#        aes(x = year,
#            y = kelp.perc*100,
#            group = region, 
#            color = region)) +
#     geom_line(size = 2) +
#     geom_ribbon(aes(ymin = lwr*100, ymax = upr*100), alpha = 0.2, color = NA, fill = "grey") +
#     scale_color_manual(values = c("blue", "red")) +
#     theme_bw() +
#     labs(color = "",
#          x = "",
#          y = "Percent Cover Kelp")
# 
# ## What happened according to the model!
# fit_df <- DF.join %>%
#     filter(!is.na(urchin)) %>%
#     group_by(region, year) %>%
#     summarize_all(mean, na.rm = TRUE) %>%
#     ungroup()
# 
# fit_values <- predict(mod_urchin_add, 
#                            newdata = fit_df, 
#                            re.form = NULL, 
#                            type = "response",
#                            se.fit = TRUE)
# 
# fit_df <- fit_df %>%
#     mutate(kelp.perc_raw = kelp.perc,
#            kelp.perc = fit_values$fit,
#            lwr = kelp.perc - 1*fit_values$se.fit,
#            upr = kelp.perc + 1*fit_values$se.fit,
#            lwr = ifelse(lwr < 0, 0, lwr))
# 
# 
# 
# #york v. downeast
# ggplot(fit_df %>% 
#            filter(region %in% c("downeast", "york")) %>%
#            mutate(region = stringr::str_to_title(region)),
#        aes(x = year,
#            y = kelp.perc*100,
#            group = region, 
#            color = region)) +
#     geom_line(size = 2) +
#     geom_ribbon(aes(ymin = lwr*100, ymax = upr*100), alpha = 0.2, color = NA, fill = "grey") +
#     scale_color_manual(values = c("blue", "red")) +
#     theme_bw() +
#     labs(color = "",
#          x = "",
#          y = "Percent Cover Kelp") +
#     geom_point(aes(y = kelp.perc_raw*100), size = 3)
# 
# 
# # all regions
# ggplot(fit_df %>% 
#            mutate(region = stringr::str_to_title(region)),
#        aes(x = year,
#            y = kelp.perc*100,
#            group = region)) +
#     geom_line(size = 2) +
#     geom_ribbon(aes(ymin = lwr*100, ymax = upr*100), alpha = 0.2, color = NA, fill = "grey") +
#     theme_bw() +
#     labs(color = "",
#          x = "",
#          y = "Percent Cover Kelp") +
#     geom_point(aes(y = kelp.perc_raw*100), size = 3) +
#     facet_wrap(~region)