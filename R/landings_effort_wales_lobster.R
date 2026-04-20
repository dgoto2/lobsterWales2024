# script for processing MMO/WG (IFISH) vessel-level landings, effort data of the welsh stock of European lobster

# set a working directory
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
# ices rectangles for wales
ices_rec_wales <- readr::read_delim(file = "ices_rectangles_wales.csv") |> 
  dplyr::filter(proportion != 0)

# read in data
# effort data from the previous dataset
ifish_landings_data2_effort <- readr::read_csv(file = "ifish_landings_data2_effort.csv", 
                                               col_types = readr::cols(Rectangle = readr::col_character())) |>
  dplyr::glimpse()
# effort data from catchup data
wales_u10m_catch_sub <- readr::read_csv(file = "wales_u10m_catch_sub.csv") |>
  dplyr::glimpse()

# catch data for all species 
ifish_landings_data <- readr::read_csv(file = "All Species caught in WW by vessels who have caught CRE,LBE,WHE in same period - iFish SN views.csv", 
                                       locale = readr::locale(encoding = "latin1"), # for non-standard letters
                                       col_types = readr::cols(RECTANGLE_CODE = readr::col_character())) |>
  dplyr::mutate(SPECIES_CODE = dplyr::case_when((SPECIES_CODE %in% c("WHE", "SCE", "CRE", "QSC", "NEP", "BSS", "LBE")) ~ SPECIES_CODE,
                                                !(SPECIES_CODE %in% c("WHE", "SCE", "CRE", "QSC", "NEP","BSS","LBE")) ~ "others")) |>
  dplyr::glimpse()

# plot time series by species
(plot1 <- ifish_landings_data |> 
    dplyr::filter(LandingsValue != "£-") |>
    dplyr::mutate(LandingsValue = (stringr::str_replace_all(LandingsValue, "£", "")),
                  year = lubridate::year(as.Date(Landing_Date, format = "%d/%m/%Y"))) |>
    dplyr::filter(year < 2025) |> # 2025 is incomplete
    dplyr::group_by(year, SPECIES_CODE) |>
    dplyr::reframe(n_vessels = length(unique(RSS_NO)),
                   total_landings = sum(LiveWeight)/1000,
                   total_value = sum(as.numeric(stringr::str_replace_all(LandingsValue, ",", ""))/1000000)) |>
    #dplyr::filter(gear_code %in% c("GEN", "GN", "GNS")) |>
    #dplyr::filter(gear_code %in% c("OT", "TBB")) |>
    dplyr::mutate(SPECIES_CODE = forcats::fct_reorder(SPECIES_CODE, -total_landings)) |>
    ggplot2::ggplot(ggplot2::aes(fill = SPECIES_CODE, y = n_vessels, x = year)) + 
    ggsci::scale_fill_jco() +
    ggplot2::geom_bar(position="stack", stat="identity") +
    ggplot2::xlab("year") +
    ggplot2::ylab("number of fishing vessels") +
    #ggplot2::ylab("annual total landings (t)") +
    #ggplot2::ylab("annual total value (£ million)") +
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
    ggplot2::guides(color = ggplot2::guide_legend(override.aes = list(size = 3)))) 


# clean data & estimate effort
ifish_landings_data <- readr::read_csv(file = "All Species caught in WW by vessels who have caught CRE,LBE,WHE in same period - iFish SN views.csv", 
                                       locale = readr::locale(encoding = "latin1"), # for non-standard letters
                                       col_types = readr::cols(RECTANGLE_CODE = readr::col_character())) |> 
  dplyr::filter(!is.na(VOYAGE_ID)) |>
  dplyr::filter(!is.na(LiveWeight)) |>
  dplyr::mutate(recordID = dplyr::row_number()) |>
  dplyr::filter(SPECIES_CODE %in% c("LBE")) |> 
  dplyr::filter(GEAR_CODE %in% c("FPO")) |> # traps only 

  # get effort data from another dataset
  dplyr::left_join(ifish_landings_data2_effort, by = c("RSS_NO"="RSS_number", "GEAR_CODE"="Gear", 
                                                       "SPECIES_CODE"="Species", "DEPARTURE_DATE_TIME"="DepartureDateTime",
                                                       "RETURN_DATE_TIME"="ReturenDateTIme", "RECTANGLE_CODE"="Rectangle"), 
                   relationship = "many-to-many") |>
  dplyr::distinct(recordID, .keep_all = TRUE) |> # exclude all duplicates
  dplyr::mutate(Landing_Date = as.Date(Landing_Date, format = "%d/%m/%Y"), # reformat all dates
                DEPARTURE_DATE_TIME = as.Date(DEPARTURE_DATE_TIME, format = "%d/%m/%Y"),
                RETURN_DATE_TIME = as.Date(RETURN_DATE_TIME, format = "%d/%m/%Y")) |>
  dplyr::mutate(DepartureDate = dplyr::case_when(is.na(DepartureDate) ~ as.Date(DEPARTURE_DATE_TIME, format = "%d/%m/%Y"),
                                                 !is.na(DepartureDate) ~ DepartureDate),
                ReturnDate = dplyr::case_when(is.na(ReturenDate) ~ as.Date(RETURN_DATE_TIME, format = "%d/%m/%Y"),
                                               !is.na(ReturenDate) ~ ReturenDate)) |>
  dplyr::mutate(Year = lubridate::year(Landing_Date),
                Month = lubridate::month(Landing_Date),
                Quarter = lubridate::quarter(Landing_Date)) |>
  dplyr::rename(year = Year,
                month = Month,
                quarter = Quarter) |>
  
  # get effort data from catchapp data
  dplyr::left_join(wales_u10m_catch_sub, by = c("RSS_NO"="rss_no", "year", "month", "GEAR_CODE"="gear", "SPECIES_CODE"="species_code", 
                                                "DEPARTURE_DATE_TIME"="trip_start_date"), relationship = "many-to-many") |>
  dplyr::distinct(recordID, .keep_all = TRUE) |> # exclude all duplicates
  # replace only NAs
  dplyr::mutate(NumberOfPots = dplyr::case_when(is.na(NumberOfPots) ~ n_pot_catchapp,
                                               !is.na(NumberOfPots) ~ NumberOfPots)) |>
  
  # estimate effort
  # replace NAs w/ median effort (number of pots or or calculated from n of string) from the same vessel, year & month
  dplyr::group_by(RSS_NO, year, month) |>
  dplyr::mutate(NumberOfPots = dplyr::case_when(is.na(NumberOfPots) ~ ceiling(median(NumberOfPots, na.rm = TRUE)),
                                                !is.na(NumberOfPots) ~ NumberOfPots),
                NumberOfString = dplyr::case_when(NumberOfPots < 50 ~ NumberOfPots, 
                                                  NumberOfPots >= 50 ~ NA),
                NumberOfString = dplyr::case_when(is.na(NumberOfString) ~ ceiling(median(NumberOfString, na.rm = TRUE)),
                                                  !is.na(NumberOfString) ~ NumberOfString),
                NumberOfPots = dplyr::case_when(is.na(NumberOfPots) ~ ceiling(median(NumberOfPots, na.rm = TRUE)),
                                                !is.na(NumberOfPots) ~ NumberOfPots),
                NumberOfPots_per_string = dplyr::case_when(is.na(NumberOfString) ~ NA,
                                                           !is.na(NumberOfString) & (NumberOfPots >= 50) ~ ceiling(NumberOfPots/NumberOfString),
                                                           !is.na(NumberOfString) & (NumberOfPots < 50) ~ NA),
                NumberOfPots_per_string = dplyr::case_when(!is.na(NumberOfPots_per_string) ~ NumberOfPots_per_string,
                                                           is.na(NumberOfPots_per_string) ~ median(NumberOfPots_per_string, na.rm = TRUE)),
                NumberOfPots = dplyr::case_when(NumberOfPots < 50 ~ ceiling(median(NumberOfPots_per_string, na.rm = TRUE) * 
                                                                               median(NumberOfString, na.rm = TRUE)),
                                                is.na(NumberOfPots) ~ ceiling(median(NumberOfPots_per_string, na.rm = TRUE) *
                                                                                median(NumberOfString, na.rm = TRUE)),
                                                NumberOfPots >= 50 ~ NumberOfPots)) |>
  dplyr::ungroup() |>
  
  # replace NAs w/ median effort (number of pots or or calculated from n of string) from the same vessel & year
  dplyr::group_by(RSS_NO, year) |>
  dplyr::mutate(NumberOfPots = dplyr::case_when(is.na(NumberOfPots) ~ ceiling(median(NumberOfPots, na.rm = TRUE)),
                                                !is.na(NumberOfPots) ~ NumberOfPots),
                NumberOfString = dplyr::case_when(is.na(NumberOfString) ~ ceiling(median(NumberOfString, na.rm = TRUE)),
                                                  !is.na(NumberOfString) ~ NumberOfString),
                NumberOfPots = dplyr::case_when(is.na(NumberOfPots) ~ ceiling(median(NumberOfPots, na.rm = TRUE)),
                                                !is.na(NumberOfPots) ~ NumberOfPots),
                NumberOfPots_per_string = dplyr::case_when(is.na(NumberOfString) ~ NA,
                                                           !is.na(NumberOfString) & (NumberOfPots >= 50) ~ ceiling(NumberOfPots/NumberOfString),
                                                           !is.na(NumberOfString) & (NumberOfPots < 50) ~ NA),
                NumberOfPots_per_string = dplyr::case_when(!is.na(NumberOfPots_per_string) ~ NumberOfPots_per_string,
                                                           is.na(NumberOfPots_per_string) ~ median(NumberOfPots_per_string, na.rm = TRUE)),
                NumberOfPots = dplyr::case_when(NumberOfPots < 50 ~ ceiling(median(NumberOfPots_per_string, na.rm = TRUE) * 
                                                                               median(NumberOfString, na.rm = TRUE)),
                                                is.na(NumberOfPots) ~ ceiling(median(NumberOfPots_per_string, na.rm = TRUE) *
                                                                                median(NumberOfString, na.rm = TRUE)),
                                                NumberOfPots >= 50 ~ NumberOfPots)) |>
  dplyr::ungroup() |>
  
  # replace NAs w/ median effort (number of pots or or calculated from n of string) from the same vessel
  dplyr::group_by(RSS_NO) |>
  dplyr::mutate(NumberOfString = dplyr::case_when(is.na(NumberOfString) ~ ceiling(median(NumberOfString, na.rm = TRUE)),
                                                  !is.na(NumberOfString) ~ NumberOfString),
                NumberOfPots = dplyr::case_when(is.na(NumberOfPots) ~ ceiling(median(NumberOfPots, na.rm = TRUE)),
                                                !is.na(NumberOfPots) ~ NumberOfPots),
                NumberOfPots_per_string = dplyr::case_when(is.na(NumberOfString) ~ NA,
                                                           !is.na(NumberOfString) & (NumberOfPots >= 50) ~ ceiling(NumberOfPots/NumberOfString),
                                                           !is.na(NumberOfString) & (NumberOfPots < 50) ~ NA),
                NumberOfPots_per_string = dplyr::case_when(!is.na(NumberOfPots_per_string) ~ NumberOfPots_per_string,
                                                           is.na(NumberOfPots_per_string) ~ median(NumberOfPots_per_string, na.rm = TRUE)),
                NumberOfPots = dplyr::case_when(NumberOfPots < 50 ~ ceiling(median(NumberOfPots_per_string, na.rm = TRUE) * 
                                                                               median(NumberOfString, na.rm = TRUE)),
                                                is.na(NumberOfPots) ~ ceiling(median(NumberOfPots_per_string, na.rm = TRUE) *
                                                                                median(NumberOfString, na.rm = TRUE)),
                                                NumberOfPots >= 50 ~ NumberOfPots)) |>
  dplyr::ungroup() |>
  
  # adjust for welsh waters only 
  dplyr::filter(RECTANGLE_CODE %in% ices_rec_wales$"ICES Rectangle") |>
  dplyr::left_join(ices_rec_wales, by = c("RECTANGLE_CODE"="ICES Rectangle")) |>
  dplyr::mutate(trip_length_days = as.numeric(ceiling(ReturnDate - DepartureDate))) |> 
  dplyr::mutate(trip_length_days = dplyr::case_when(trip_length_days < 1 ~ 1,
                                               trip_length_days >= 1 ~ trip_length_days),
                nominal_cpue_per_day = LiveWeight/NumberOfPots/trip_length_days,
                nominal_cpue_per_day_catchapp = live_weight_kg_catchapp/n_pot_catchapp/trip_length_days,
                LiveWeight_per_day = LiveWeight/trip_length_days) |>
  janitor::clean_names() |>
  dplyr::select(-name, -pln, -vessel_name, -record_id) |> # exclude some vessel info
  dplyr::glimpse()


# plot catch data
# by vessel size per species
(plot2 <- ifish_landings_data |> 
    dplyr::filter(year < 2025) |> # 2025 data is incomplete
    dplyr::mutate(vessel_len_cat = factor(vessel_length_category, levels = c("Under 10", "10 to 12", "12 to 15", "Over 15"))) |>
    dplyr::filter(species_code == "LBE") |> 
    #dplyr::filter(gear_code %in% c("GEN", "GN", "GNS")) |>
    #dplyr::filter(gear_code %in% c("OT", "TBB")) |>
    dplyr::filter(landings_value != "£-") |>
    dplyr::mutate(landings_value = (stringr::str_replace_all(landings_value, "£", ""))) |>
    dplyr::group_by(year) |>
    dplyr::mutate(
      n_vessels_all = length(unique(rss_no)),
      total_landings_all = sum(live_weight)/1000,
      total_value_all = sum(as.numeric(stringr::str_replace_all(landings_value, ",", ""))/1000000),
    ) |>
    dplyr::ungroup() |>
    dplyr::group_by(year, vessel_len_cat) |>
    dplyr::reframe(n_vessels = length(unique(rss_no)),
                  total_landings = sum(live_weight)/1000,
                  total_value = sum(as.numeric(stringr::str_replace_all(landings_value, ",", ""))/1000000),
                  n_vessels_percent = n_vessels/unique(n_vessels_all)*100,
                  total_landings_percent = total_landings/unique(total_landings_all)*100,
                  total_value_percent = total_value/unique(total_value_all)*100
    ) |>
    dplyr::ungroup() |>
   
    ggplot2::ggplot(ggplot2::aes(fill = vessel_len_cat, y = n_vessels, x = year)) + 
    ggplot2::xlab("year") +
    ggplot2::ylab("number of fishing vessels") +
    #ggplot2::ylab("annual total landings (t)") +
    #ggplot2::ylab("annual total value (£ million)") + 
    ggsci::scale_fill_jco() +
    ggplot2::geom_bar(position="stack", stat="identity") +
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
    ggplot2::guides(color = ggplot2::guide_legend(override.aes = list(size = 3)))) 


# subset by species and vessel size group
ifish_landings_data_lobster <- ifish_landings_data |> 
  dplyr::mutate(vessel_length_group = dplyr::case_when(vessel_length_category %in% c("Under 10") ~ "under10",
                                                       vessel_length_category %in% c("10 to 12") ~ "10to12",
                                                       vessel_length_category %in% c("12 to 15", "Over 15") ~ "over12")) |>
  dplyr::filter(species_code == "LBE") |>
  dplyr::glimpse()
  
# save output
readr::write_csv(ifish_landings_data_lobster, file = "ifish_nominal_catch_pot_lobster_clean.csv") 

# reformat landing time series for ss - set for annual time step
# Catch data: yr, season, fleet, catch, catch_se
ifish_landings_wales_lobster_yr <- ifish_landings_data_lobster |>
  dplyr::group_by(year, vessel_length_group) |>
  dplyr::reframe(year = unique(year),
                 quarter = 1,
                 fleet = unique(vessel_length_group),
                 landing = sum(live_weight)/1000,
                 catch.se = 0.05) |>
  dplyr::select(year, quarter, fleet, landing, catch.se) |>
  dplyr::arrange(fleet, year, quarter) |>
  dplyr::glimpse()

# export datasets
readr::write_csv(ifish_landings_wales_lobster_yr, file = "landing.data_lobster_wales_ss-format_yr.csv") 
