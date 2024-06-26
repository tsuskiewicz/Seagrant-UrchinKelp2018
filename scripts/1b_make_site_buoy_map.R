#' -----------------------------------------------------------------------------
#' Make map of sites from DMR and Rasher/Steneck
#' biological sampling and NOAA buoys used for temperature 
#' measurements for Figure 1 of the paper
#' 
#' @date 2023-10-30 last update
#' @author: Jarrett Byrnes     
#' -----------------------------------------------------------------------------

library(rnaturalearth)
library(rnaturalearthdata)
library(dplyr)
library(sf)
library(readr)
library(scales)
library(ggplot2)
library(wesanderson)
pal <- wes_palette("Zissou1", 6, type = "continuous")


coastline <- ne_states(country = "United States of America", returnclass = "sf")

#get map and check
new_england <- coastline %>%
    dplyr::filter(name %in% c("Maine", "New Hampshire", "Massachusetts", "Rhode Island",
                       "Vermont", "Connecticut"))


#crop box
mbox <- c(xmin = -71.5,
          xmax = -66,
          ymin = 43.,
          ymax = 45) %>% st_bbox()


ggplot() +
    geom_sf(data = new_england %>% st_crop(mbox) , fill = "lightgreen") +
    theme_bw() +
    theme(axis.text.x = element_text(size = 12, color = "black"),
          axis.text.y = element_text(size = 12, color = "black"),
          panel.grid.major = element_blank(),
          panel.background = element_rect(fill = "lightblue"))

#get sites
sites <- read_csv("derived_data/combined_bio_data.csv") %>%
    st_as_sf(coords = c("longitude", "latitude"), crs=4326)  %>%
    mutate(region = gsub("\\.", " ", region),
           region = stringr::str_to_title(region),
           region = gsub("Mdi", "MDI", region),
           region = factor(region,
                           levels = c("Downeast", "MDI", "Penobscot Bay",
                                      "Midcoast", "Casco Bay", "York"))) %>%
    group_by(year, region, site) %>%
    slice(1L)

# get buoys
buoy_ids <- read_csv("raw_data/buoyID.csv") %>%
    st_as_sf(coords = c("longitude", "latitude"), crs =4326)

# The plot
ggplot() +
    geom_sf(data = new_england %>% st_crop(mbox) , fill = "#AAd1AC") +
    geom_sf(data = sites, aes(color = region), alpha = 0.8) +
    geom_sf(data = buoy_ids, color = "red", shape = 17, size = 5, alpha = 0.7) +
    theme_bw(base_size = 14) +
    theme(axis.text.x = element_text(size = 12, color = "black"),
          axis.text.y = element_text(size = 12, color = "black"),
          panel.grid.major = element_blank(),
          #panel.background = element_rect(fill = "#9ebddc77"),
          panel.background = element_rect(fill = "white"),
          legend.title.align = 0.5,
          legend.position = "bottom") +
    scale_color_manual(values = pal) +
    scale_fill_manual(values = pal) +
    coord_sf(expand=FALSE) +
    labs(color = "Sites Sampled", fill = "Sites Sampled") +
    guides(colour = guide_legend(title.position = "top",
                                 override.aes = list(shape = 15, size = 5))
    )


ggsave("figures/map_of_project.jpg", dpi = 800)
