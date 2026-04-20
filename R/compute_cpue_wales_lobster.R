# script for computing nominal total catch, effort, landings, CPUE, and LPUE for the observer dataset - wales-lobster

# check if required packages are installed
required <- c("readr", "dplyr", "lubridate", "tidyr", "RColorBrewer", "rgdal", "sp", "rnaturalearth", "ggplot2", "ggridges")
installed <- rownames(installed.packages())
(not_installed <- required[!required %in% installed])
install.packages(not_installed, dependencies=TRUE)

# run input data processing script
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("observer_dataprocessing_wales.R")

# read in data
observer_data_lobster <- readr::read_csv("observer_data_lobster_clean.csv", 
                                         col_types = readr::cols(ices_sub_rect = readr::col_character(),
                                                                 latitude = readr::col_double())) |> 
  dplyr::glimpse()
observer_data_crab <- readr::read_csv("observer_data_crab_clean.csv", 
                                      col_types = readr::cols(ices_sub_rect = readr::col_character())) |> 
  dplyr::glimpse()

# define a function to compute nominal catch, landings, cpue, and lpue per fishing trip and haul
compute_cpue.lpue <- function(data) {

  # per fishing trip
  # compute effort (number of pots lifted per trip)
  observer_data_effort <- data |> 
    dplyr::group_by(string, fisher, date, escape_gaps) |> 
    dplyr::reframe(pots_per_string = unique(pots_per_string, na.rm = FALSE)) |> # get total number of pots per string
    dplyr::ungroup() |>
    dplyr::group_by(fisher, date, escape_gaps) |> 
    dplyr::reframe(nominal.effort = sum(pots_per_string, na.rm = FALSE)) |>
    dplyr::ungroup() |>
    dplyr::group_by(fisher, lubridate::year(date), lubridate::month(date), escape_gaps) |>
    dplyr::mutate(nominal.effort = dplyr::case_when(is.na(nominal.effort) ~ median(nominal.effort, na.rm = TRUE),
                                                    !is.na(nominal.effort) ~ nominal.effort)) |> # replace NAs w/ medians per month per fisher
    dplyr::ungroup() |>
    dplyr::group_by(fisher, lubridate::year(date), escape_gaps) |>
    dplyr::mutate(nominal.effort = dplyr::case_when(is.na(nominal.effort) ~ median(nominal.effort, na.rm = TRUE),
                                                    !is.na(nominal.effort) ~ nominal.effort)) |> # replace NAs w/ medians per year per fisher
    dplyr::ungroup() |>
    dplyr::select(fisher, date, nominal.effort, escape_gaps)
    
  # compute total catch (kg) per trip
  observer_data_catch <- data |> 
    dplyr::group_by(fisher, date, escape_gaps) |> 
    dplyr::reframe(nominal.catch = sum(mass, na.rm = TRUE)) 
  
  # compute total landings (kg)
  observer_data_landing <- data |> 
    dplyr::group_by(fisher, date, escape_gaps) |> 
    dplyr::filter(landed==1) |> 
    dplyr::reframe(nominal.landing = sum(mass, na.rm = TRUE)) 
  
  # compute total discard per trip
  observer_data_discard <- data |> 
    dplyr::group_by(fisher, date, escape_gaps) |> 
    dplyr::filter(landed==0) |> 
    dplyr::reframe(nominal.discard = sum(mass, na.rm = TRUE))  
  
  # compute total berried per trip
  observer_data_berried <- data |> 
    dplyr::group_by(fisher, date, escape_gaps) |> 
    dplyr::filter(berried==1) |> 
    dplyr::reframe(nominal.berried = sum(mass, na.rm = TRUE))  
  
  # compute total undersize per trip
  observer_data_recruit <- data |> 
    dplyr::group_by(fisher, date, escape_gaps) |> 
    dplyr::filter(landed==0 & carapace_length_width < 90) |> 
    dplyr::reframe(nominal.recruit = dplyr::n())  
  
  # merge datasets and add vessel info
  observer_data_trip <- observer_data_effort |> 
    list(observer_data_landing, observer_data_catch, observer_data_discard, 
         observer_data_berried, observer_data_recruit, observer_data_effort) |> 
    purrr::reduce(dplyr::left_join) |>
    dplyr::mutate(nominal.cpue = nominal.catch/nominal.effort, 
                  nominal.lpue = nominal.landing/nominal.effort,
                  nominal.recruit = nominal.recruit/nominal.effort,
                  nominal.berriedpue = nominal.berried/nominal.effort) 
  observer_data_select_trip <- data |> 
    dplyr::group_by(fisher, date, escape_gaps) |> 
    dplyr::reframe(cfr_no = unique(cfr_no),
                   vessel_len = unique(vessel_length), 
                   loc = unique(location), 
                   species = unique(species)) # trip-level info
  observer_data_trip <- observer_data_trip |> 
    dplyr::left_join(observer_data_select_trip, by = c("fisher", "date", "escape_gaps")) |>
    #tidyr::separate_wider_delim(cols = trip, delim = "|", names = c("fisher", "date")) |>
    dplyr::mutate(month = lubridate::month(date), 
                  quarter = lubridate::quarter(date), 
                  year = lubridate::year(date))
  
  
  # per pot set (w/ unique gps coordinates)
  # compute total number of pots set in each location in each trip
  observer_data_effort_potset <- data |> 
    dplyr::filter(!is.na(longitude)) |>
    dplyr::group_by(ices_sub_rect, string, latitude, longitude, fisher, date, escape_gaps) |> 
    dplyr::reframe(pots_per_string = unique(pots_per_string, na.rm = FALSE)) |> # get total number of pots per string
    dplyr::ungroup() |>
    dplyr::group_by(ices_sub_rect, fisher, date, latitude, longitude, escape_gaps) |> 
    dplyr::reframe(nominal.effort_potset = sum(pots_per_string, na.rm = FALSE)) |>
    dplyr::ungroup() |>
    dplyr::group_by(ices_sub_rect, fisher, lubridate::year(date), lubridate::month(date), escape_gaps) |>
    dplyr::mutate(nominal.effort_potset = dplyr::case_when(is.na(nominal.effort_potset) ~ median(nominal.effort_potset, na.rm = TRUE),
                                                    !is.na(nominal.effort_potset) ~ nominal.effort_potset)) |> # replace NAs w/ medians per month per fisher
    dplyr::ungroup() |>
    dplyr::group_by(ices_sub_rect, fisher, lubridate::year(date), escape_gaps) |>
    dplyr::mutate(nominal.effort_potset = dplyr::case_when(is.na(nominal.effort_potset) ~ median(nominal.effort_potset, na.rm = TRUE),
                                                    !is.na(nominal.effort_potset) ~ nominal.effort_potset)) |> # replace NAs w/ medians per year per fisher
    dplyr::ungroup() |>
    dplyr::select(ices_sub_rect, fisher, date, latitude, longitude, nominal.effort_potset, escape_gaps)  
  # replace NAs in effort in some records for fishers 5 & 10
  observer_data_potset_fisherfisher5 <- observer_data_effort_potset |>
    dplyr::filter(lubridate::year(date) != 2020 & fisher == 5) |>
    dplyr::mutate(nominal.effort_potset = dplyr::case_when(is.na(nominal.effort_potset) ~ median(nominal.effort_potset, na.rm = TRUE),
                                                           !is.na(nominal.effort_potset) ~ nominal.effort_potset))
  observer_data_potset_fisherfisher10 <- observer_data_effort_potset |>
    dplyr::filter(lubridate::year(date) != 2021 & fisher == 10) |>
    dplyr::mutate(nominal.effort_potset = dplyr::case_when(is.na(nominal.effort_potset) ~ median(nominal.effort_potset, na.rm = TRUE),
                                                           !is.na(nominal.effort_potset) ~ nominal.effort_potset))
  observer_data_effort_potset <- observer_data_effort_potset |>
    dplyr::filter(!(fisher %in% c(5, 10))) |>
    list(observer_data_potset_fisherfisher5, observer_data_potset_fisherfisher10) |>
    purrr::reduce(dplyr::bind_rows) |>
    dplyr::arrange(fisher, date)
  
  # compute total catch (kg) per location in each trip
  observer_data_catch_potset <- data |> 
    dplyr::filter(!is.na(longitude)) |>
    dplyr::group_by(ices_sub_rect, latitude, longitude, fisher, date, escape_gaps) |> 
    dplyr::reframe(nominal.catch_potset = sum(mass, na.rm = TRUE)) 
  
  # compute total landings (kg) per location in each trip
  observer_data_landing_potset <- data |>     
    dplyr::filter(!is.na(longitude)) |>
    dplyr::group_by(ices_sub_rect, latitude, longitude, fisher, date, escape_gaps) |> 
    dplyr::filter(landed==1) |> 
    dplyr::reframe(nominal.landing_potset = sum(mass, na.rm = TRUE)) 
  
  # compute total discard per each location in each trip
  observer_data_discard_potset <- data |> 
    dplyr::filter(!is.na(longitude)) |>
    dplyr::group_by(ices_sub_rect, latitude, longitude, fisher, date, escape_gaps) |> 
    dplyr::filter(landed==0) |> 
    dplyr::reframe(nominal.discard_potset = sum(mass, na.rm = TRUE))  
  
  # compute total berried per location in each trip
  observer_data_berried_potset <- data |> 
    dplyr::filter(!is.na(longitude)) |>
    dplyr::group_by(ices_sub_rect, latitude, longitude, fisher, date, escape_gaps) |> 
    dplyr::filter(berried==1) |> 
    dplyr::reframe(nominal.berried_potset = sum(mass, na.rm = TRUE))  
  
  # compute total undersize per location in each trip
  observer_data_recruit_potset <- data |> 
    dplyr::filter(!is.na(longitude)) |>
    dplyr::group_by(ices_sub_rect, latitude, longitude, fisher, date, escape_gaps) |> 
    dplyr::filter(landed==0 & carapace_length_width < 90) |> 
    dplyr::reframe(nominal.recruit_potset = dplyr::n())  
  
  # merge all datasets
  observer_data_potset <- observer_data_effort_potset |>
    dplyr::filter(!is.na(latitude)) |>
    list(observer_data_catch_potset, observer_data_landing_potset, observer_data_discard_potset,
         observer_data_berried_potset, observer_data_recruit_potset) |> 
    purrr::reduce(dplyr::left_join) |>
    dplyr::mutate(nominal.cpue_potset = nominal.catch_potset/nominal.effort_potset, 
                  nominal.lpue_potset = nominal.landing_potset/nominal.effort_potset,
                  nominal.recruit_potset = nominal.recruit_potset/nominal.effort_potset,
                  nominal.berried.cpue_potset = nominal.berried_potset/nominal.effort_potset) |>
    dplyr::mutate(date = as.Date(date)) |>
    dplyr::mutate(latitude = as.numeric(latitude), 
                  longitude = as.numeric(longitude), 
                  ices_sub_rect = (ices_sub_rect), 
                  fisher = as.numeric(fisher),
                  month = lubridate::month(date), 
                  quarter = lubridate::quarter(date), 
                  year = lubridate::year(date))
  
  # add covariate info
  observer_data_select_potset <- data |> 
    dplyr::group_by(lat_lon_trip, trip, fisher, date, qtr, latitude, longitude, escape_gaps) |> 
    dplyr::filter(!is.na(latitude)) |>
    dplyr::filter(!is.na(temperature)) |>
    dplyr::reframe(vessel_len = unique(vessel_length), 
                   loc = unique(location), 
                   ices_sub_rect = unique(ices_sub_rect), 
                   species = unique(species), 
                   lowest_tide = unique(lowest_astronomical_tide), 
                   temp = unique(temperature), 
                   temp_interpol_dist = unique(temperature_interpolation_dist), 
                   dist_shore = unique(distance_from_shore), 
                   roughness = unique(roughness), 
                   roughness_interpol_distance = unique(roughness_interpolation_distance), 
                   sediment = unique(sediment), 
                   sediment_interpol_distance = unique(sediment_interpolation_distance)) # potset-level info
  observer_data_potset <- observer_data_potset |> 
    dplyr::left_join(observer_data_select_potset, by = c("ices_sub_rect", "fisher", "date", "latitude", "longitude", "quarter"="qtr", "escape_gaps"))
  
  return(list(observer_data_trip, observer_data_potset))
}


# apply the function to each stock
observer_data_lobster_out <- compute_cpue.lpue(observer_data_lobster) # lobster
observer_data_crab_out <- compute_cpue.lpue(observer_data_crab) # crab

# apply the function to each stock for under 10m
observer_data_lobster_u10 <- observer_data_lobster |> dplyr::filter(vessel_length <= 10)
observer_data_lobster_out_u10 <- compute_cpue.lpue(observer_data_lobster_u10) # lobster

# create crab as covariates
observer_data_crab_cov <- observer_data_crab_out[[2]] |>
  dplyr::rename(nominal.effort_potset_crab = nominal.effort_potset, 
                nominal.catch_potset_crab = nominal.catch_potset,
                nominal.landing_potset_crab = nominal.landing_potset,
                nominal.cpue_potset_crab = nominal.cpue_potset,
                nominal.lpue_potset_crab = nominal.lpue_potset,
                nominal.discard_potset_crab = nominal.discard_potset, 
                nominal.berried_potset_crab = nominal.berried_potset,
                nominal.recruit_potset_crab = nominal.recruit_potset,
                nominal.berried.cpue_potset_crab = nominal.berried.cpue_potset
                ) |>
  dplyr::select(-species, ) |>
  dplyr::glimpse()
# quick tally on effort
observer_data_crab_cov |> dplyr::group_by(fisher) |>
  dplyr::reframe(min_pot = min(nominal.effort_potset_crab, na.rm = TRUE),
                 mean_pot = mean(nominal.effort_potset_crab, na.rm = TRUE),
                 max_pot = max(nominal.effort_potset_crab, na.rm = TRUE))

# merge with the main datasets
observer_data_lobster_out[[2]] <- observer_data_lobster_out[[2]] |>
  dplyr::full_join(observer_data_crab_cov) |>
  dplyr::mutate(nominal.effort_potset = dplyr::case_when(is.na(nominal.effort_potset) & !is.na(nominal.effort_potset_crab) ~ nominal.effort_potset_crab,
                                                       !is.na(nominal.effort_potset) & !is.na(nominal.effort_potset_crab) ~ nominal.effort_potset,
                                                       !is.na(nominal.effort_potset) & is.na(nominal.effort_potset_crab) ~ nominal.effort_potset),
                nominal.cpue_potset = dplyr::case_when(is.na(nominal.cpue_potset) & !is.na(nominal.cpue_potset_crab) ~ 0,
                                                       !is.na(nominal.cpue_potset) & !is.na(nominal.cpue_potset_crab) ~ nominal.cpue_potset,
                                                       !is.na(nominal.cpue_potset) & is.na(nominal.cpue_potset_crab) ~ nominal.cpue_potset),
                nominal.recruit_potset = dplyr::case_when(is.na(nominal.recruit_potset) & !is.na(nominal.cpue_potset_crab) ~ 0,
                                                       !is.na(nominal.recruit_potset) & !is.na(nominal.cpue_potset_crab) ~ nominal.recruit_potset,
                                                       !is.na(nominal.recruit_potset) & is.na(nominal.cpue_potset_crab) ~ nominal.recruit_potset),
                nominal.lpue_potset = dplyr::case_when(is.na(nominal.lpue_potset) & !is.na(nominal.cpue_potset_crab) ~ 0,
                                                       !is.na(nominal.lpue_potset) & !is.na(nominal.cpue_potset_crab) ~ nominal.lpue_potset,
                                                       !is.na(nominal.lpue_potset) & is.na(nominal.cpue_potset_crab) ~ nominal.lpue_potset),
                nominal.berried.cpue_potset = dplyr::case_when(is.na(nominal.berried.cpue_potset) & !is.na(nominal.cpue_potset_crab) ~ 0,
                                                       !is.na(nominal.berried.cpue_potset) & !is.na(nominal.cpue_potset_crab) ~ nominal.berried.cpue_potset,
                                                       !is.na(nominal.berried.cpue_potset) & is.na(nominal.cpue_potset_crab) ~ nominal.berried.cpue_potset)) |>
  dplyr::mutate(nominal.cpue_potset_crab = dplyr::case_when(is.na(nominal.cpue_potset_crab) ~ 0,
                                                       !is.na(nominal.cpue_potset_crab) ~ nominal.cpue_potset_crab),
                nominal.catch_potset_crab = dplyr::case_when(is.na(nominal.catch_potset_crab) ~ 0,
                                                            !is.na(nominal.catch_potset_crab) ~ nominal.catch_potset_crab),
                nominal.landing_potset_crab = dplyr::case_when(is.na(nominal.landing_potset_crab) ~ 0,
                                                            !is.na(nominal.landing_potset_crab) ~ nominal.landing_potset_crab),
                nominal.lpue_potset_crab = dplyr::case_when(is.na(nominal.lpue_potset_crab) ~ 0,
                                                            !is.na(nominal.lpue_potset_crab) ~ nominal.lpue_potset_crab)) |>
    dplyr::glimpse()

# export output as rds (as a list)
readr::write_rds(observer_data_lobster_out, file = "observer_data_lobster_nominal.cpue.rds") 
# export output as csv
readr::write_csv(observer_data_lobster_out[[1]], file = "observer_data_lobster_nominal.cpue_trip.csv") 
readr::write_csv(observer_data_lobster_out[[2]], file = "observer_data_lobster_nominal.cpue_potset.csv") 


# plot output
# temporal variation
# select a dataset and a parameter
data <- observer_data_lobster_out[[2]] 
response <- data$nominal.cpue_potset 
response.name <- "nominal catch rate (kg per number of pots hauled)"

# plot1
mycolors <- c(RColorBrewer::brewer.pal(name = "Paired", n = 12), RColorBrewer::brewer.pal(name = "Set3", n = 7))
(plot1 <- data |> ggplot2::ggplot(ggplot2::aes(lubridate::quarter(date, with_year = TRUE), response, 
                                               group = lubridate::quarter(date, with_year = TRUE))) +
    ggplot2::scale_color_manual(values = mycolors) +
    ggplot2::geom_boxplot(outlier.shape = NA) +
    ggplot2::geom_jitter(size = 2., ggplot2::aes(lubridate::quarter(date, with_year = TRUE), response,
                                                 group = lubridate::quarter(date, with_year = TRUE),
                                                 color = as.factor(lubridate::quarter(date))), alpha = 0.4) +
    ggplot2::xlab("year") +
    ggplot2::ylab(response.name) +
    ggplot2::theme_classic() +
    ggplot2::theme( 
      panel.grid.minor = ggplot2::element_blank(), 
      panel.background = ggplot2::element_blank(), 
      axis.line = ggplot2::element_line(colour = "black"),
      axis.title.x = ggplot2::element_text(size=10),
      axis.title.y = ggplot2::element_text(size=10),	
      axis.text.x = ggplot2::element_text(size=8), 
      axis.text.y = ggplot2::element_text(size=8),
      legend.background = ggplot2::element_blank(),
      legend.position = "top",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(colour="black", size = 8),
      plot.title = ggplot2::element_text(hjust = 0.4, size = 4),
      legend.key = ggplot2::element_blank(),
      strip.background = ggplot2::element_blank(), 
      strip.placement = "outside",
      strip.text.x = ggplot2::element_text(size = 10, colour = "darkblue")) +  
    ggplot2::guides(color = ggplot2::guide_legend(override.aes = list(size = 2))))


# plot2
observer_data_lobster_yr <- data |>
  dplyr::filter(!is.na(escape_gaps)) |>
  dplyr::group_by(year, escape_gaps) |>
  dplyr::reframe(year = unique(year),
                 month = max(month),
                 fleet = 2,
                 obj = mean(nominal.lpue_potset, na.rm = TRUE),
                 stdrr = sd(nominal.lpue_potset, na.rm = TRUE)) |>
  dplyr::glimpse()
observer_data_lobster_yr <- observer_data_lobster_yr |>
  dplyr::mutate(obj = obj/mean(obj, na.rm = TRUE),
                stdrr = stdrr/mean(stdrr, na.rm = TRUE))
observer_data_lobster_yr |> ggplot2::ggplot(ggplot2::aes(x=as.numeric(year), y=obj, group = escape_gaps, color = escape_gaps)) +  
  ggplot2::geom_errorbar(ggplot2::aes(ymin=obj-stdrr, ymax=obj+stdrr), color = "darkblue", 
                         width = 0, alpha=1, position = ggplot2::position_dodge(width = 0.3)) +
  ggplot2::scale_color_hue(l=40, c=35) +   
  ggplot2::geom_point(position = ggplot2::position_dodge(width = 0.3), size = 5) + 
  ggplot2::labs(x = "year", y = "nominal landing rate (kg per N of pots hauled)") +
  ggplot2::theme_classic() +
  ggplot2::theme( 
    panel.grid.minor = ggplot2::element_blank(), 
    panel.background = ggplot2::element_blank(), 
    axis.line = ggplot2::element_line(colour = "black"),
    axis.title.x = ggplot2::element_text(size=15),
    axis.title.y = ggplot2::element_text(size=15),	
    axis.text.x = ggplot2::element_text(size=10), 
    axis.text.y = ggplot2::element_text(size=10),
    legend.background = ggplot2::element_blank(),
    legend.position = "top",
    legend.title = ggplot2::element_blank(),
    legend.text = ggplot2::element_text(colour="black", size = 12),
    plot.title = ggplot2::element_text(hjust = 0.4, size = 4),
    legend.key = ggplot2::element_blank(),
    strip.background = ggplot2::element_blank(), 
    strip.placement = "outside",
    strip.text.x = ggplot2::element_text(size = 15, colour = "darkblue")) +  
  ggplot2::guides(color = ggplot2::guide_legend(override.aes = list(size = 5)))


# spatial distribution
# select a dataset and a parameter
data <- observer_data_lobster_out[[2]]
response <- data$nominal.cpue_potset
response.name <- "nominal cpue (kg per number of pots hauled)"
xlim <- c(min(data$longitude, na.rm = TRUE)*1.05,
          max(data$longitude, na.rm = TRUE)*0.85)
ylim <- c(min(data$latitude, na.rm = TRUE)*.995,
          max(data$latitude, na.rm = TRUE)*1.01)

# wales shape file
wales <- sf::read_sf(dsn = "data/wales/shapefiles/wnmp_areas.shp", stringsAsFactors = FALSE)
# icea rectangles
shp_ices.rec <- sf::read_sf(dsn = "data/shapefiles/ICES_Rect/ICES_Statistical_Rectangles_Eco.shp", stringsAsFactors = FALSE)
shp_ices.subrec <- sf::read_sf(dsn = "data/shapefiles/ICES_Sub_Rect/ICES_SubStatrec_20150113_3857.shp", stringsAsFactors = FALSE)
# read in ICES rectangles for wales
ices_rec <- readr::read_delim(file = "data/wales/ices_rectangles_wales.csv")
ices_rec_wales <- ices_rec |> 
  dplyr::filter(proportion != 0)
ices_rec_wales <- ices_rec_wales |> 
  janitor::clean_names()
# subset wales
shp_ices.rec_wales <- shp_ices.rec |> 
  dplyr::right_join(ices_rec_wales, by = c("ICESNAME"="ices_rectangle")) |>
  dplyr::mutate(PERCENTAGE = PERCENTAGE*proportion)
# subrec
shp_ices.rec_wales <- shp_ices.subrec |> 
  dplyr::right_join(ices_rec_wales, by = c("ICESNAME"="ices_rectangle")) 

# merge polygons
shp_ices.rec_wales <- sf::st_transform(shp_ices.rec_wales, 4326)
shp_ices.rec_wales <- sf::st_intersection(shp_ices.rec_wales, wales) 

# get midpoints in each grid
n <- nrow(as.data.frame(shp_ices.rec_wales$geometry))
shp_ices.rec_wales$x <- NA
shp_ices.rec_wales$y <- NA
for (i in (1:n)) {
  print(i)
  shp_ices.rec_wales$x[i] <- median(sf::st_coordinates(sf::st_as_sf(shp_ices.rec_wales$geometry)$x[i])[,1])
  shp_ices.rec_wales$y[i] <- median(sf::st_coordinates(sf::st_as_sf(shp_ices.rec_wales$geometry)$x[i])[,2])
}
xlim <- c(min(shp_ices.rec_wales$WEST, na.rm = TRUE),
          max(shp_ices.rec_wales$EAST, na.rm = TRUE))
ylim <- c(min(shp_ices.rec_wales$SOUTH, na.rm = TRUE),
          max(shp_ices.rec_wales$NORTH, na.rm = TRUE))
data <- data |> dplyr::filter((longitude >= min(shp_ices.rec_wales$WEST)) & (longitude <= max(shp_ices.rec_wales$EAST)) & 
                                (latitude >= min(shp_ices.rec_wales$SOUTH)) & (latitude <= max(shp_ices.rec_wales$NORTH)))
(plot2 <- ggplot2::ggplot() +  
    ggplot2::scale_color_manual(values = mycolors) +
    ggplot2::geom_sf(data = wales, ggplot2::aes(fill = name), alpha = 0.2,  colour = "black") +
    ggplot2::geom_sf(data = shp_ices.rec_wales, fill = NA, colour = "darkblue") +
    ggplot2::scale_fill_manual(values = mycolors) +
    ggplot2::geom_point(data=data,
                        ggplot2::aes(x=longitude, y=latitude, size = nominal.cpue_potset),
                        fill="darkred", color="darkgray", shape = 21, 
                        alpha=I(0.3)) +
    ggplot2::theme_classic() +
    ggplot2::labs(x = "longitude", y = "latitude") +
    ggplot2::theme( 
      panel.grid.minor = ggplot2::element_blank(), 
      panel.background = ggplot2::element_blank(), 
      axis.line = ggplot2::element_line(colour = "black"),
      axis.title.x = ggplot2::element_text(size=10),
      axis.title.y = ggplot2::element_text(size=10),	
      axis.text.x = ggplot2::element_text(size=8), 
      axis.text.y = ggplot2::element_text(size=8),
      legend.background = ggplot2::element_blank(),
      legend.position = "top",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(colour="black", size = 8),
      plot.title = ggplot2::element_text(hjust = 0.4, size = 4),
      legend.key = ggplot2::element_blank(),
      strip.background = ggplot2::element_blank(), 
      strip.placement = "outside",
      strip.text.x = ggplot2::element_text(size = 10, colour = "darkblue")) +  
    ggplot2::guides(color = ggplot2::guide_legend(override.aes = list(size = 3)))  +
    ggplot2::guides(fill=ggplot2::guide_legend(title="Month")) +
    ggplot2::facet_wrap(~ year, strip.position = "top", ncol = 3))
