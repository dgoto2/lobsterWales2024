# data entry check for the observer data - wales
# created: 10/20/2025 by D. Goto (d.goto@bangor.ac.uk)

# Check if required packages are installed
required <- c("readr", "dplyr", "lubridate", "tidyr", "pointblank", "janitor")
installed <- rownames(installed.packages())
(not_installed <- required[!required %in% installed])
install.packages(not_installed, dependencies=TRUE)

# read in data
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd("..")
observer_data_unprocessed <- readxl::read_excel("data/wales/Welsh_Observer_Data_2019-2025.xlsx", sheet = "Catch Data") |>
  dplyr::glimpse()
# save the output as a csv file
readr::write_csv(observer_data_unprocessed, "data/wales/observer_data_unprocessed.csv")

observer_data_unprocessed <- readr::read_csv("data/wales/observer_data_unprocessed.csv",
                                 col_types = readr::cols(ICES_sub_rect = readr::col_character())) |>
  dplyr::select(-colnames(observer_data_unprocessed)[stringr::str_detect(colnames(observer_data_unprocessed), "\\...")]) |> 
  janitor::clean_names() |>
  dplyr::glimpse()

# take a quick look at the data
observer_data_unprocessed |> View()

# take a quick look at some basic stats
observer_data_unprocessed |> summary() 

# check for data entry errors
al <- pointblank::action_levels(warn_at = 0.2,
                                stop_at = 0.8,
                                notify_at = 0.5)

(observer_data_checked <- observer_data_unprocessed |>
  pointblank::create_agent(
    #tbl = observer_data_unprocessed,
    tbl_name = "observer_data_unprocessed_tbl",
    label = "initial data entry check",
    actions = al
  ) |>
    pointblank::col_is_numeric(day) |>
    pointblank::col_is_numeric(month) |>
    pointblank::col_is_numeric(year) |>
    pointblank::col_is_numeric(timeframe) |>
    pointblank::col_is_character(fisher) |>
    pointblank::col_is_numeric(vessel_length) |>
    pointblank::col_is_character(observer) |>
    pointblank::col_is_character(location) |>
    pointblank::col_vals_between(latitude, left = 50, right = 55, na_pass = TRUE) |>
    pointblank::col_vals_between(longitude, left = -5.5, right = -3.0, na_pass = TRUE) |>
    pointblank::col_vals_between(end_latitude, left = 50, right = 55, na_pass = TRUE) |>
    pointblank::col_vals_between(end_longitude, left = -5.5, right = -3.0, na_pass = TRUE) |>
    pointblank::col_vals_in_set(ices_sub_rect, set = c("32E44", "32E47", "34E51", "34E54", "34E52", 
                                                       "36E66", "35E64", "35E61", "35E55", "35E57", 
                                                       "35E58", "34E55", "35E56", "35E62", "33E57", 
                                                       "36E63", "32E59", "36E69", "32E63", "32E56")) |>
    pointblank::col_is_numeric(string) |>
    pointblank::col_is_numeric(pot) |>
    pointblank::col_is_numeric(pots_per_string) |>
    pointblank::col_vals_in_set(escape_gaps, set = c("N", "Y")) |>
    pointblank::col_vals_in_set(species, set = c("H.gammarus", "C.pagurus")) |>
    pointblank::col_vals_in_set(sex, set = c("M", "F")) |>
    pointblank::col_is_numeric(carapace_length_width) |>
    pointblank::col_is_numeric(abdomen_width) |>
    pointblank::col_is_numeric(claw_length) |>
    pointblank::col_is_numeric(claw_height) |>
    pointblank::col_is_numeric(claw_depth) |>
    pointblank::col_is_numeric(weight) |>
    pointblank::col_vals_in_set(berried, set = c("N", "Y")) |>
    pointblank::col_is_factor(crusty_condition) |>
    pointblank::col_is_factor(moult_stage) |>
    pointblank::col_vals_in_set(v_notch, set = c("N", "Y")) |>
    pointblank::col_vals_in_set(landed, set = c("N", "Y")) |>
    pointblank::col_is_numeric(soak_time) |>
    pointblank::col_is_numeric(lowest_astronomical_tide) |>
    pointblank::col_is_numeric(temperature) |>
    pointblank::col_is_numeric(temperature_interpolation_dist) |>
    pointblank::col_is_numeric(distance_from_shore) |>
    pointblank::col_is_numeric(roughness) |>
    pointblank::col_is_numeric(roughness_interpolation_distance) |>
    pointblank::col_is_numeric(sediment) |>
    pointblank::col_is_numeric(sediment_interpolation_distance) |>
    pointblank::interrogate())
