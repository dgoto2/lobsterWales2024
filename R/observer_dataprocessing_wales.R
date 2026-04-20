# script for cleaning the crab & lobster observer dataset - wales
# created: 6/6/2024 by Daisuke Goto (d.goto@bangor.ac.uk)
# updated: 11/5/2025

# Check if required packages are installed
required <- c("readr", "dplyr", "lubridate", "tidyr", "janitor")
installed <- rownames(installed.packages())
(not_installed <- required[!required %in% installed])
install.packages(not_installed, dependencies=TRUE)

# read in data
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
setwd("..")
observer_data <- readr::read_csv("Welsh_Observer_Data_2019-2025.csv",
                                 col_types = readr::cols(ICES_sub_rect = readr::col_character())) |>
    dplyr::glimpse()

# delete empty columns (no colnames) if any
colnames(observer_data)
observer_data <- observer_data |> 
  dplyr::select(-colnames(observer_data)[stringr::str_detect(colnames(observer_data), "\\...")]) |> 
  dplyr::select(-A) |> # another empty col
  janitor::clean_names() |>
  dplyr::glimpse()

# add vessel id info
vessel_id <- readr::read_csv("observer_vessel_id.csv") |> 
  dplyr::filter(!is.na(fisher)) |>
  dplyr::rename(vessel_len = length,
                year_contruction = yaer_construction) |>
  dplyr::glimpse()
observer_data <- observer_data |>
  dplyr::left_join(vessel_id) |>
  dplyr::glimpse()

# reformat some gps coords
observer_data$latitude[!is.na(observer_data$latitude) & stringr::str_detect(observer_data$latitude, "'")] <- 
  stringr::str_replace(stringr::str_replace(observer_data$latitude[!is.na(observer_data$latitude) & 
                                                                     stringr::str_detect(observer_data$latitude, "'")], 
                                            stringr::fixed("."), ""), "'", ".")
observer_data$longitude[!is.na(observer_data$longitude) & stringr::str_detect(observer_data$longitude, "'")] <- 
  stringr::str_replace(stringr::str_replace(observer_data$longitude[!is.na(observer_data$longitude) & 
                                                                      stringr::str_detect(observer_data$longitude, "'")], 
                                            stringr::fixed("."), ""), "'", ".")

# convert ices subrectangles to coordinates
observer_data <- observer_data |> 
  dplyr::mutate(
    latitude = dplyr::case_when(
      latitude %in% c("Faulty GPS", "FAULTY GPS", "GPS FAULTY", "NO GPS", "No Waypoint") ~ NA,
      !(latitude %in% c("Faulty GPS", "FAULTY GPS", "GPS FAULTY", "NO GPS", "No Waypoint")) ~ latitude),
    longitude = dplyr::case_when(
      longitude %in% c("Faulty GPS", "FAULTY GPS", "NO GPS") ~ NA,
      !(longitude %in% c("Faulty GPS", "FAULTY GPS", "NO GPS")) ~ longitude)) |>
  dplyr::mutate(longitude = as.numeric(longitude),
                latitude = as.numeric(latitude)) |>
  dplyr::mutate(latitude = dplyr::case_when(is.na(latitude) ~ mapplots::ices.rect(ices_sub_rect)$lat,
                                            !is.na(latitude) ~ latitude),
                longitude = dplyr::case_when(is.na(longitude) ~ mapplots::ices.rect(ices_sub_rect)$lon,
                                             !is.na(longitude) ~ longitude)) |>
  dplyr::glimpse()


# clean up data
observer_data_clean <- observer_data |> 
  dplyr::mutate(species = dplyr::recode(species, C.Pagurus = 'C.pagurus', "C. Pagurus" = 'C.pagurus', 
                                        H.Gammarus = 'H.gammarus', "H. Gammarus" = 'H.gammarus', 
                                        "NO LOBSTERS" = "NA", "NO LOBTERS" = "NA", "na" = "NA")) |>  # old=new
  dplyr::mutate(month = dplyr::recode(month, April=4, August=8, December=12, February=2, January=1, 
                                      July=7, June=6, March=3, May=5, November=11, October=10, September=9)) |> 
  dplyr::mutate(berried = dplyr::recode(berried, Y=1, N=0, y=1, n=0, C=1, "Y - CAST" = 1, "2" = 0, 
                                        CAST=1, Cast=1, Shedding=0)) |> # yes=1; no=0
  dplyr::mutate(landed = dplyr::recode(landed, Y=1, N=0, y=1, Bait=2)) |> # yes=1; no=0
  dplyr::mutate(sex = dplyr::recode(sex, F=1, M=0)) |> 
    tidyr::unite(date, c(day, month, year), sep = "-", remove = FALSE) |> 
  dplyr::mutate(date = as.Date(date, format = "%d-%m-%Y")) |>  
  tidyr::unite(month.yr, c(year, month), sep = "-", remove = FALSE) |> 
  dplyr::mutate(qtr = lubridate::quarter(date, with_year = FALSE)) |> 
  tidyr::unite(qrt.yr, c(year, qtr), sep = "-", remove = FALSE) |> 
  tidyr::unite(trip, c(fisher, date), sep = "|", remove = FALSE) |> 
  tidyr::unite(lat_lon, c(latitude, longitude), sep = "|", remove = FALSE) |> # haul location id
  tidyr::unite(lat_lon_trip, c(latitude, longitude, trip), sep = "|", remove = FALSE) |> # trip id
  dplyr::mutate(weight = as.numeric(weight), 
                latitude = as.numeric(latitude),
                soak_time = as.numeric(soak_time)) |>
  dplyr::rename(mass = weight) |>
  dplyr::mutate(mass = dplyr::case_when(species=="H.gammarus" & sex==0 ~ 0.00179*carapace_length_width^2.791/1000, # convert length to mass
                                        species=="H.gammarus" & sex==1 ~ 0.00023*carapace_length_width^3.219/1000,
                                        species=="C.pagurus" & sex==0 ~ 0.0002*carapace_length_width^3.03/1000,
                                        species=="C.pagurus" & sex==1 ~ 0.0002*carapace_length_width^2.94/1000)) |>
  dplyr::mutate(vessel_length = dplyr::case_when(!is.na(vessel_length) ~ vessel_length, # replace NAs 
                                                 is.na(vessel_length) & fisher==2 ~ 10.7,
                                                 is.na(vessel_length) & fisher==5 ~ 9.98,
                                                 is.na(vessel_length) & fisher==8 ~ 6.9,
                                                 is.na(vessel_length) & fisher==10 ~ 6.9)) |>
  dplyr::mutate(escape_gaps = dplyr::case_when(!is.na(escape_gaps) ~ escape_gaps, # replace NAs; traps w/100% escape gap 2=Y, 3=Y, 5=N, 6=N, 10=Y
                                               is.na(escape_gaps) & fisher==2 ~ "Y",
                                               is.na(escape_gaps) & fisher==3 ~ "Y",
                                               is.na(escape_gaps) & fisher==4 ~ "Y",
                                               is.na(escape_gaps) & fisher==5 ~ "N",
                                               is.na(escape_gaps) & fisher==10 ~ "Y",
                                               is.na(escape_gaps) & fisher==11 ~ "N"
                                               )) |>
  dplyr::filter(carapace_length_width <= 300) |>  # remove likely data entry errors
  dplyr::glimpse()

# fill missing pots per string w/ max pots# per string
observer_data_clean <- observer_data_clean |>
  dplyr::group_by(lat_lon_trip, string) |>
  dplyr::mutate(pots_per_string = dplyr::case_when(is.na(pots_per_string) ~ max(pot),
                                                 !is.na(pots_per_string) ~ pots_per_string)) |>
  dplyr::ungroup() |>
  dplyr::glimpse()

# find records w/ missing coordinates and replace w/ medians of records for each trip if possible 
observer_data_clean <- observer_data_clean |>
  dplyr::group_by(fisher, date) |>
  dplyr::mutate(latitude = dplyr::case_when(is.na(latitude) ~ median(latitude, na.rm = TRUE),
                                            !is.na(latitude) ~ latitude),
                longitude = dplyr::case_when(is.na(longitude) ~ median(longitude, na.rm = TRUE),
                                             !is.na(longitude) ~ longitude)) |>
  dplyr::group_by(fisher, year, month) |>
  dplyr::mutate(latitude = dplyr::case_when(is.na(latitude) ~ median(latitude, na.rm = TRUE),
                                            !is.na(latitude) ~ latitude),
                longitude = dplyr::case_when(is.na(longitude) ~ median(longitude, na.rm = TRUE),
                                            !is.na(longitude) ~ longitude)) |>
  dplyr::group_by(fisher, year, qtr) |>
  dplyr::mutate(latitude = dplyr::case_when(is.na(latitude) ~ median(latitude, na.rm = TRUE),
                                            !is.na(latitude) ~ latitude),
                longitude = dplyr::case_when(is.na(longitude) ~ median(longitude, na.rm = TRUE),
                                             !is.na(longitude) ~ longitude)) |>
  dplyr::group_by(fisher, year) |>
  dplyr::mutate(latitude = dplyr::case_when(is.na(latitude) ~ median(latitude, na.rm = TRUE),
                                            !is.na(latitude) ~ latitude),
                longitude = dplyr::case_when(is.na(longitude) ~ median(longitude, na.rm = TRUE),
                                             !is.na(longitude) ~ longitude)) |>
  dplyr::group_by(fisher) |>
  dplyr::mutate(latitude = dplyr::case_when(is.na(latitude) ~ median(latitude, na.rm = TRUE),
                                            !is.na(latitude) ~ latitude),
                longitude = dplyr::case_when(is.na(longitude) ~ median(longitude, na.rm = TRUE),
                                             !is.na(longitude) ~ longitude)) |>
  dplyr::ungroup() |>
  tidyr::unite(lat_lon, c(latitude, longitude), sep = "|", remove = FALSE) |> # haul location id
  tidyr::unite(lat_lon_trip, c(latitude, longitude, trip), sep = "|", remove = FALSE) |> # trip id
  
  dplyr::glimpse()

# fill missing ices rectangles using estimated coordinates
observer_data_clean <- observer_data_clean |> 
  dplyr::mutate(ices_sub_rect = dplyr::case_when(is.na(ices_sub_rect) ~ mapplots::ices.rect2(longitude, latitude),
                                                 !is.na(ices_sub_rect) ~ ices_sub_rect)) |>
  dplyr::glimpse()

# check length-mass conversion
observer_data_clean |>
  dplyr::group_by(year, species) |>
  dplyr::reframe(mean_mass = mean(mass, na.rm = TRUE),
                 mass_na = mean(is.na(mass)),
                 length_na = mean(is.na(carapace_length_width)))


# subset by species
observer_data_lobster <- observer_data_clean |> 
  dplyr::filter(species == "H.gammarus") |> 
  dplyr::glimpse()
observer_data_crab <- observer_data_clean |> 
  dplyr::filter(species == "C.pagurus") |> 
  dplyr::glimpse()

# export dataset
readr::write_csv(observer_data_lobster, file = "observer_data_lobster_clean.csv") 
readr::write_csv(observer_data_crab, file = "observer_data_crab_clean.csv")
