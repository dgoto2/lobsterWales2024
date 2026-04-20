# reformat the observer size composition data of the Welsh stock of European lobster for elefan

# run input data processing script
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("compute_observer.size.comp_lobster_wales.R")

# read in data sets
size.dist_lobster_month <- readr::read_csv("observer.size.comp.data_lobster_wales_month_ss_all.csv") |> 
  dplyr::glimpse()

size.dist_lobster_month2 <- size.dist_lobster_month 
colnames(size.dist_lobster_month2) <- c("year", "month", "fleet", "sex", "part", "nsample", seq(size.min, size.max-width, by = width), "date")
size.dist_lobster_month_lfd <- size.dist_lobster_month2 |>
  tidyr::gather(lnclass, catch, colnames(size.dist_lobster_month2)[7]:colnames(size.dist_lobster_month2[ncol(size.dist_lobster_month2)-1]), factor_key=TRUE) |>
  dplyr::select(-fleet, -part) |>
  dplyr::mutate(year = as.numeric(year),
                month = as.numeric(month),
                sex = as.numeric(sex),
                nsample = as.numeric(nsample),
                lnclass = as.numeric(as.character(lnclass)),
                catch = as.numeric(catch)) |>
  dplyr::arrange(year, month, date, sex, nsample) |>
  dplyr::filter(lnclass >= 3.2 & lnclass <= 15) |> # select size classes used for elefan
  dplyr::glimpse()

# id dates w/data
zero_dates <- size.dist_lobster_month_lfd |> 
  dplyr::group_by(date) |> 
  dplyr::reframe(total=sum(catch)) |> 
  dplyr::ungroup() |> 
  dplyr::filter(total==0)

# delete dates w/o samples
size.dist_lobster_month_lfd <- size.dist_lobster_month_lfd |> 
  dplyr::filter(!(date %in% c("2020-10-15", "2020-11-15", "2021-04-15", "2021-06-15", "2021-07-15",
                              "2021-12-15", "2022-09-15", "2024-09-15", "2024-10-15", "2025-03-15",
                              "2025-04-15", "2025-05-15", "2025-06-15", "2025-07-15", "2025-08-15", 
                              "2025-09-15", "NA" )))

# export output
readr::write_csv(size.dist_lobster_month_lfd, file = "observer_lobster_wales_month_lfd.csv") 
