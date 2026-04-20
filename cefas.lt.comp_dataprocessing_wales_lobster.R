# script for cleaning the length composition dataset for the Welsh stock of European lobster  (Cefas port sampling)

# ***size comp sampling was not done every month (landings data different from ifish)***

# Check if required packages are installed
required <- c("readr", "dplyr", "lubridate", "tidyr", "janitor")
installed <- rownames(installed.packages())
(not_installed <- required[!required %in% installed])
install.packages(not_installed, dependencies=TRUE)

# subset data
# read in ICES rectangles for wales
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
ices_rec <- readr::read_delim(file = "ices_rectangles_wales.csv")
ices_rec_wales <- ices_rec |> 
  dplyr::filter(proportion != 0)

# lobster
# offshore: "31E4"  "31E5" "31E6"  "37E5" "29E4" "33E3" "35E4" 
# inshore: 32E5" "34E5" "33E5" "35E5" "31E5" "35E6" "35E5" "32E6" "32E4"  

# read in data
port.sampling_lobster <- readr::read_csv("port.sampling_lobster_wales_ices_rec_landings.csv", 
                                         col_types = readr::cols(Rectangle = readr::col_character())) |>
  dplyr::rename(SampleNo = ...1) |> dplyr::glimpse()
colnames(port.sampling_lobster) <- c("sample_no", "date_of_landing", "species", "sex", "length", "total_landed_wgt", "wgt_measured", 
                                     "rectangle", "port_of_landing", "total_at_length")
port.sampling_lobster <- port.sampling_lobster |> janitor::clean_names() 

# data cleaning
size.data_lobster_wales <- port.sampling_lobster |> 
  dplyr::filter(!is.na(date_of_landing)) |>
  dplyr::mutate(year = lubridate::year(date_of_landing), 
                month = lubridate::month(date_of_landing), 
                quarter = lubridate::quarter(date_of_landing)) |>   
  tidyr::unite(month.yr, c(year, month), sep = "-", remove = FALSE) |> 
  tidyr::unite(qrt.yr, c(year, quarter), sep = "-", remove = FALSE) |>
  tidyr::unite(month.yr.rect, c(year, month, rectangle), sep = "-", remove = FALSE) |> 
  dplyr::mutate(sex = dplyr::recode(sex, F=1, M=0, B=1)) |> 
  dplyr::glimpse()

# quick tally on sample sizes
size.data_lobster_wales_nsample <- size.data_lobster_wales |>
  dplyr::group_by(year) |> #month,sex,
  dplyr::reframe(nsample = length(length)) |>
  dplyr::glimpse()
n_sample <- size.data_crab_wales |>
  dplyr::group_by(year) |> #quarter
  dplyr::reframe(n_date_of_landing = length(unique(date_of_landing)), 
                 n_port_of_landing = length(unique(port_of_landing)), 
                 n_sample = dplyr::n()) |>
  dplyr::glimpse()

# export datasets
readr::write_csv(size.data_lobster_wales, file = "cefas_port-sampling_size.data_lobster_wales_clean.csv") 


# minimum landing size
year <- c(1983:2024)
mls <- c(rep(85, 15), rep(87, 17), rep(90, 10)) 
mls <- data.frame(year, mls)
mls <- mls |> 
  dplyr::filter(!(year %in% c(1986, 2010:2013, 2021:2024)))

# plotting
# select a dataset
data_no.na <- size.data_lobster_wales |> 
  dplyr::filter(!is.na(sex))
sex.label <- c("male", "female")
names(sex.label) <- c(0, 1)
(plot <- ggplot2::ggplot(data_no.na, ggplot2::aes(x = length, y = as.factor(year))) +
    ggridges::geom_density_ridges(scale = 2.5, alpha = 0.3, quantile_lines = TRUE, 
                                  quantiles = c(0.05, 0.5, 0.95), ggplot2::aes(fill = as.factor(sex))) +
         ggplot2::geom_point(data = mls, ggplot2::aes(mls, as.factor(year)), shape = 17, size = 3, color = "darkgreen") +   
    
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


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# reformat length composition input data for SS
# set up population length bin structure (note - irrelevant if not using size data and using empirical wtatage
#_N_LengthBins; then enter lower edge of each length bin
#_yr month fleet sex part Nsamp datavector(female-male) ***separate males and females*** 
# select a data set
data <- size.data_lobster_wales
data$length <- data$length/10 # recorded in mm -> convert to cm for ss
size.min <- 1
size.max <- 20
width <- 0.2 
n.size <- length(table(cut(data$length, 
                           breaks = c(size.min, seq(size.min+width, size.max-width, by = width), size.max))))
size.dist_m <- matrix(NA, 1, n.size+7)
size.dist_f <- matrix(NA, 1, n.size+7)
size.dist_lobster <- NULL 
for (i in c(unique(data$month.yr.rect))) {
  subdata <- data[data$month.yr.rect==i,]
  subdata_m <- subdata[subdata$sex==0,]
  subdata_f <- subdata[subdata$sex==1,]
  if (nrow(subdata_m) > 0) {
    size.dist_m[1] <- unique(subdata_m$year)
    size.dist_m[2] <- unique(subdata_m$month)
    size.dist_m[3] <- 1 # fleet
    size.dist_m[4] <- unique(subdata_m$sex)
    size.dist_m[5] <- 0 #part
    size.dist_m[6] <- nrow(subdata_m) * sum(unique(subdata_m$total_landed_wgt/subdata_m$wgt_measured))
    size.dist_m[7:(n.size+6)] <- table(cut(subdata_m$length, 
                                           breaks = c(size.min, seq(size.min+width, size.max-width, by = width), size.max))) * 
      sum(unique(subdata_m$total_landed_wgt/subdata_m$wgt_measured))
    size.dist_m[(n.size+6)+1] <- unique(subdata_m$qrt.yr)
  }
  if (nrow(subdata_f) > 0) {
    size.dist_f[1] <- unique(subdata_f$year)
    size.dist_f[2] <- unique(subdata_f$month)
    size.dist_f[3] <- 1 # fleet
    size.dist_f[4] <- unique(subdata_f$sex)
    size.dist_f[5] <- 0 #part
    size.dist_f[6] <- nrow(subdata_f) * sum(unique(subdata_f$total_landed_wgt/subdata_f$wgt_measured))
    size.dist_f[7:(n.size+6)] <- table(cut(subdata_f$length, 
                                           breaks = c(size.min, seq(size.min+width, size.max-width, by = width), size.max))) * 
      sum(unique(subdata_f$total_landed_wgt/subdata_f$wgt_measured))
    size.dist_f[(n.size+6)+1] <- unique(subdata_f$qrt.yr)
  }
  size.dist <- dplyr::bind_rows(as.data.frame(size.dist_m), as.data.frame(size.dist_f))
  size.dist_lobster <- dplyr::bind_rows(as.data.frame(size.dist_lobster), as.data.frame(size.dist))
}

# aggregate by quarter
colnames(size.dist_lobster) <- c("year", "month", "fleet", "sex", "part", "nsample", paste0("s", 1:n.size), "qrt.yr")
size.dist_m2 <- matrix(0, 1, n.size+6)
size.dist_f2 <- matrix(0, 1, n.size+6)
size.dist_lobster2 <- NULL 
for (i in c(unique(data$qrt.yr))) {
  subdata <- size.dist_lobster[size.dist_lobster$qrt.yr==i,]
  subdata_m <- subdata[subdata$sex==0,1:ncol(subdata)-1]
  subdata_f <- subdata[subdata$sex==1,1:ncol(subdata)-1]
  if (nrow(subdata_m) > 0) {
  size.dist_m2[1] <- unique(subdata_m$year)
  size.dist_m2[2] <- max(subdata_m$month)
  size.dist_m2[3] <- unique(subdata_m$fleet)
  size.dist_m2[4] <- unique(subdata_m$sex)
  size.dist_m2[5] <- unique(subdata_m$part)
  size.dist_m2[6] <- round(sum(as.numeric(subdata_m$nsample)))
    if (nrow(subdata_m) > 1) {
    size.dist_m2[7:(n.size+6)] <- round(colSums(as.data.frame(apply(subdata_m[7:ncol(subdata_m)], 2, as.numeric))), digits=1)
    } else size.dist_m2[7:(n.size+6)] <- round(as.numeric(subdata_m[7:ncol(subdata_m)]), digits = 1)
  
  #barplot(as.numeric(size.dist_m2[7:(n.size+6)]), main = paste0(size.dist_m2[c(1,2,4,6)]))
  
  }
  if (nrow(subdata_f) > 0) {
  size.dist_f2[1] <- unique(subdata_f$year)
  size.dist_f2[2] <- max(subdata_f$month)
  size.dist_f2[3] <- unique(subdata_f$fleet)
  size.dist_f2[4] <- unique(subdata_f$sex)
  size.dist_f2[5] <- unique(subdata_f$part)
  size.dist_f2[6] <- round(sum(as.numeric(subdata_f$nsample)))
  if (nrow(subdata_f) > 1) {
    size.dist_f2[7:(n.size+6)] <- round(colSums(as.data.frame(apply(subdata_f[7:ncol(subdata_f)], 2, as.numeric))), digits=1)
    } else size.dist_f2[7:(n.size+6)] <- round(as.numeric(subdata_f[7:ncol(subdata_f)]), digits = 1)
  
  #barplot(as.numeric(size.dist_f2[7:(n.size+6)]), main = paste0(size.dist_f2[c(1,2,4,6)]))
  
  }
  size.dist <- dplyr::bind_rows(as.data.frame(size.dist_m2), as.data.frame(size.dist_f2))
  size.dist_lobster2 <- dplyr::bind_rows(as.data.frame(size.dist_lobster2), as.data.frame(size.dist))
}


# reformat for ss
colnames(size.dist_lobster2) <- c("year", "month", "fleet", "sex", "part", "nsample", paste0("s", 1:n.size))
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
  tidyr::gather(sizebin, value, f1:m95, factor_key = TRUE) |>
  dplyr::group_by(year, sizebin) |>
  dplyr::reframe(year = unique(year),
                 month = max(month),
                 fleet = 2,
                 sex = 3,
                 part = 0,
                 nsample = sum(nsample),
                 sizebin = unique(sizebin),
                 value = sum(as.numeric(value))/nsample) |>
  tidyr::spread(sizebin, value) |>
  dplyr::glimpse()

# export dataset
readr::write_csv(size.dist_lobster, file = "size.comp.data_lobster_wales_ss.csv") 
readr::write_csv(size.dist_lobster_yr, file = "size.comp.data_lobster_wales_yr_ss.csv") 
