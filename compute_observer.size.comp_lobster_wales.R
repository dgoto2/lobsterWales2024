# script to reformat the observer size composition data as SS model input for the Welsh stock of European lobster

# check if required packages are installed
required <- c("readr", "dplyr", "lubridate", "tidyr", "RColorBrewer", "rgdal", "sp", "rnaturalearth", "ggplot2", "ggridges")
installed <- rownames(installed.packages())
(not_installed <- required[!required %in% installed])
install.packages(not_installed, dependencies=TRUE)

# run input data processing script
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("observer_dataprocessing_wales.R")

# read in datasets
observer_data_lobster <- readr::read_csv("observer_data_lobster_clean.csv", 
                                         col_types = readr::cols(ices_sub_rect = readr::col_character())) |> 
  tidyr::unite(month.yr.rect, c(year, month, ices_sub_rect), sep = "-", remove = FALSE) |> 
  dplyr::filter(!is.na(latitude)) |>
  dplyr::glimpse()
# quick tally on sample size
observer_data_lobster |>
  dplyr::group_by(year) |> 
  dplyr::reframe(nsample = length(carapace_length_width)) |>
  dplyr::glimpse()                                            
observer_cpue_lobster <- readr::read_csv("observer_data_lobster_nominal.cpue_potset.csv", 
                                         col_types = readr::cols(ices_sub_rect = readr::col_character())) |> 
  tidyr::unite(month.yr.rect, c(year, month, ices_sub_rect), sep = "-", remove = FALSE) |> 
  dplyr::mutate(nominal.discard.ratio = (nominal.catch_potset -nominal.landing_potset)/nominal.catch_potset) |>
  dplyr::glimpse()
  
# compute discard ratio
observer_lobster_discard.ratio <- observer_cpue_lobster |>
  dplyr::group_by(year) |>
  dplyr::reframe(month = 12,
                 fleet = 1,
                 nominal.discard.ratio_mean = mean(nominal.discard.ratio, na.rm = TRUE),
                 nominal.discard.ratio.sd = sd(nominal.discard.ratio, na.rm = TRUE)) |>
  dplyr::glimpse()

# merge CPUE and size comp datasets
observer_cpue_lobster_rect <- observer_cpue_lobster |>
  dplyr::group_by(month.yr.rect) |>
  dplyr::reframe(nominal.cpue_potset = mean(nominal.cpue_potset, na.rm = TRUE)) |>
  dplyr::ungroup() 
observer_data_lobster <- observer_data_lobster |> 
  dplyr::left_join(observer_cpue_lobster_rect) |>
  dplyr::glimpse()

# split datasets into retain and discard
observer_data_lobster_retain <- observer_data_lobster |>
  dplyr::filter(landed == 1) |>
  dplyr::glimpse()
observer_data_lobster_discard <- observer_data_lobster |>
  dplyr::filter(landed == 0) |>
  dplyr::glimpse()


# exploratory plotting
# select a dataset
observer_data_lobster_no.na <- observer_data_lobster |> 
  dplyr::filter(!is.na(sex)) |>
  dplyr::filter(!is.na(year)) |>
  dplyr::glimpse()
sex.label <- c("male", "female")
names(sex.label) <- c(0, 1)
(plot1 <- ggplot2::ggplot(observer_data_lobster_no.na, ggplot2::aes(x = carapace_length_width, y = as.factor(year))) +
    ggridges::geom_density_ridges(scale = 2.5, alpha = 0.3, quantile_lines = TRUE, 
                                  quantiles = c(0.05, 0.5, 0.95), ggplot2::aes(fill = as.factor(sex))) +
    ggplot2::geom_vline(xintercept = 90, color = "darkgreen", linewidth = 1) +
    ggplot2::xlim(50, 195) +
    ggplot2::xlab("carapace width (mm)") +
    ggplot2::ylab("year") +
    ggplot2::scale_fill_manual(labels = c("male", "female"), values = c("darkblue", "darkred")) +
    ggplot2::theme_classic() + 
    ggplot2::coord_flip() +
    ggplot2::theme( 
      panel.grid.minor = ggplot2::element_blank(), 
      panel.background = ggplot2::element_blank(), 
      axis.line = ggplot2::element_line(colour = "black"),
      axis.title.x = ggplot2::element_text(size=10),
      axis.title.y = ggplot2::element_text(size=10),	
      axis.text.x = ggplot2::element_text(size=8), 
      axis.text.y = ggplot2::element_text(size=8),
      legend.background = ggplot2::element_blank(),
      legend.position = "none",
      legend.title = ggplot2::element_blank(),
      legend.text = ggplot2::element_text(colour="black", size = 8),
      plot.title = ggplot2::element_text(hjust = 0.4, size = 4),
      legend.key = ggplot2::element_blank(),
      strip.background = ggplot2::element_blank(), 
      strip.placement = "outside",
      strip.text.x = ggplot2::element_text(size = 10, colour = "darkblue")) +  
    ggplot2::guides(color = ggplot2::guide_legend(override.aes = list(size = 3)))  +
    ggplot2::facet_wrap(~ sex, labeller = ggplot2::labeller(sex = sex.label), strip.position = "top", ncol = 1))


# reformat length composition input data (for SS)
#_yr month fleet sex part Nsamp datavector(female-male) ***separate males and females*** 
for (part in c(0, 1, 2)) {
  print(part)
  if (part==0) {
    data <- observer_data_lobster
    part_label = "all"
    }
  if (part==1) {
    data <- observer_data_lobster_discard
    part_label = "discard"
    }
  if (part==2) {
    data <- observer_data_lobster_retain
    part_label = "retain"
    }
  print(data)
  cat(part_label)
  
  data <- data |> 
  dplyr::filter(!is.na(sex)) |>
    dplyr::mutate(carapace_length_width = carapace_length_width/10)
  colnames(data)[colnames(data)=="carapace_length_width"] <- "length" # recorded in mm -> convert to cm for ss
  (size.min <- round(min(data$length, na.rm = TRUE))) # 1
  (size.max <- round(max(observer_data_lobster$carapace_length_width, na.rm = TRUE)/10)) # -> based on the complete dataset
  width <- 0.2
  n.size <- length(table(cut(data$length, 
                             breaks = c(size.min, 
                                        seq(size.min+width, size.max-width, by = width), size.max))))
  size.dist_m <- matrix(NA, 1, n.size+7)
  size.dist_f <- matrix(NA, 1, n.size+7)
  size.dist_lobster <- NULL 
  for (i in c(unique(data$month.yr.rect))) {
    print(i)
    subdata <- data[data$month.yr.rect==i,]
    subdata_m <- subdata[subdata$sex==0,]
    subdata_f <- subdata[subdata$sex==1,]
    if (nrow(subdata_m) > 0) {
      size.dist_m[1] <- unique(subdata_m$year)
      size.dist_m[2] <- unique(subdata_m$month)
      size.dist_m[3] <- 1 # fleet
      size.dist_m[4] <- unique(subdata_m$sex)
      size.dist_m[5] <- part
      size.dist_m[6] <- nrow(subdata_m) * sum(unique(subdata_m$nominal.cpue_potset), na.rm = TRUE)
      size.dist_m[7:(n.size+6)] <- table(cut(subdata_m$length, 
                                             breaks = c(size.min, seq(size.min+width, size.max-width, by = width), size.max))) * 
        sum(unique(subdata_m$nominal.cpue_potset), na.rm = TRUE)
      size.dist_m[(n.size+6)+1] <- unique(subdata_m$month.yr)
    }
    if (nrow(subdata_f) > 0) {
      size.dist_f[1] <- unique(subdata_f$year)
      size.dist_f[2] <- unique(subdata_f$month)
      size.dist_f[3] <- 1 # fleet
      size.dist_f[4] <- unique(subdata_f$sex)
      size.dist_f[5] <- part
      size.dist_f[6] <- nrow(subdata_f) * sum(unique(subdata_f$nominal.cpue_potset), na.rm = TRUE)
      size.dist_f[7:(n.size+6)] <- table(cut(subdata_f$length, 
                                             breaks = c(size.min, seq(size.min+width, size.max-width, by = width), size.max))) * 
        sum(unique(subdata_f$nominal.cpue_potset), na.rm = TRUE)
      size.dist_f[(n.size+6)+1] <- unique(subdata_f$month.yr)
    }
    size.dist <- dplyr::bind_rows(as.data.frame(size.dist_m), as.data.frame(size.dist_f))
    size.dist_lobster <- dplyr::bind_rows(as.data.frame(size.dist_lobster), as.data.frame(size.dist))
  }
  
  # aggregate by month
  colnames(size.dist_lobster) <- c("year", "month", "fleet", "sex", "part", "nsample", paste0("s", 1:n.size), "month.yr")
  size.dist_m2 <- matrix(0, 1, n.size+6)
  size.dist_f2 <- matrix(0, 1, n.size+6)
  size.dist_lobster2 <- NULL 
  size.dist_lobster <- size.dist_lobster |> 
    dplyr::filter(is.finite(as.numeric(nsample)))
  for (i in c(unique(data$month.yr))) {
    subdata <- size.dist_lobster[size.dist_lobster$month.yr==i,]
    subdata_m <- subdata[subdata$sex==0,1:ncol(subdata)-1]
    subdata_f <- subdata[subdata$sex==1,1:ncol(subdata)-1]
    if (nrow(subdata_m) > 0) {
      size.dist_m2[1] <- unique(subdata_m$year)
      size.dist_m2[2] <- unique(subdata_m$month)
      size.dist_m2[3] <- unique(subdata_m$fleet)
      size.dist_m2[4] <- unique(subdata_m$sex)
      size.dist_m2[5] <- unique(subdata_m$part)
      size.dist_m2[6] <- round(sum(as.numeric(subdata_m$nsample), na.rm = TRUE))
      if (nrow(subdata_m) > 1) {
        size.dist_m2[7:(n.size+6)] <- round(colSums(as.data.frame(apply(subdata_m[7:ncol(subdata_m)], 2, as.numeric)), na.rm = TRUE), digits=1)
      } else size.dist_m2[7:(n.size+6)] <- round(as.numeric(subdata_m[7:ncol(subdata_m)]), digits = 1)
    }
    if (nrow(subdata_f) > 0) {
      size.dist_f2[1] <- unique(subdata_f$year)
      size.dist_f2[2] <- unique(subdata_f$month)
      size.dist_f2[3] <- unique(subdata_f$fleet)
      size.dist_f2[4] <- unique(subdata_f$sex)
      size.dist_f2[5] <- unique(subdata_f$part)
      size.dist_f2[6] <- round(sum(as.numeric(subdata_f$nsample), na.rm = TRUE))
      if (nrow(subdata_f) > 1) {
        size.dist_f2[7:(n.size+6)] <- round(colSums(as.data.frame(apply(subdata_f[7:ncol(subdata_f)], 2, as.numeric)), na.rm = TRUE), digits=1)
      } else size.dist_f2[7:(n.size+6)] <- round(as.numeric(subdata_f[7:ncol(subdata_f)]), digits = 1)
    }
    size.dist <- dplyr::bind_rows(as.data.frame(size.dist_m2), as.data.frame(size.dist_f2))
    size.dist_lobster2 <- dplyr::bind_rows(as.data.frame(size.dist_lobster2), as.data.frame(size.dist))
  }
  
  # generate monthly dataset
  colnames(size.dist_lobster2) <- c("year", "month", "fleet", "sex", "part", "nsample", paste0("s", 1:n.size))
  size.dist_lobster_month <- size.dist_lobster2 |>
    dplyr::mutate(date = as.Date(paste(year, month, "15", sep="-"))) |> # use mid-month 
    dplyr::glimpse()
  
  # reformat for ss
  size.dist_lobster_m <- size.dist_lobster2 |> 
    dplyr::filter(sex == 0) |> 
    dplyr::mutate(sex = 3) |>
    dplyr::rename(nsample.m = nsample) |>
    dplyr::select(-year, -month, -fleet, -sex, -part)
  size.dist_lobster_f <- size.dist_lobster2 |> 
    dplyr::filter(sex == 1) |> 
    dplyr::mutate(sex = 3) 
  size.dist_lobster <- size.dist_lobster_f |> 
    dplyr::bind_cols(size.dist_lobster_m) |>
    dplyr::mutate(nsample = as.numeric(nsample)+as.numeric(nsample.m)) |>
    dplyr::select(-nsample.m)
  colnames(size.dist_lobster) <- c("year", "month", "fleet", "sex", "part", "nsample", paste0("f", 1:n.size), paste0("m", 1:n.size))
  
  # aggregate by year
  size.dist_lobster_yr <- size.dist_lobster |> 
    tidyr::gather(sizebin, value, f1:colnames(size.dist_lobster)[length(colnames(size.dist_lobster))], factor_key = TRUE) |>
    dplyr::filter(is.finite(nsample)) |>
    dplyr::group_by(year, sizebin) |>
    dplyr::reframe(year = unique(year),
                   month = max(month),
                   fleet = 1,
                   sex = 3,
                   part = unique(part),
                   nsample = sum(nsample, na.rm = TRUE),
                   sizebin = unique(sizebin),
                   value = sum(as.numeric(value), na.rm = TRUE)/nsample) |>
    tidyr::spread(sizebin, value)
  
  #print(size.dist_lobster_yr)
  # export output
  readr::write_csv(size.dist_lobster, file = paste0("observer.size.comp.data_lobster_wales_month_ss_", part_label,".csv")) 
  readr::write_csv(size.dist_lobster_yr, file = paste0("observer.size.comp.data_lobster_all_yr_wales_ss_", part_label ,".csv")) 
}
