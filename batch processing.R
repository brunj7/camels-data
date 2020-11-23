
library(tidyverse)
library(ggplot2)
library(lubridate) # for dates
library(janitor) # clean column names
# remotes::install_github("brunj7/CamelsQuery")
library(CamelsQuery)  


# Paths
main_dir <- "/home/shares/camels/"
my_basin_dir <- file.path(main_dir, "basin_dataset_public_v1p2")
my_attr_dir <- file.path(main_dir, "camels_attributes_v2.0")

# Get the list of all HUC2 present in CAMELS
huc2_list <- dir(file.path(my_basin_dir,"basin_mean_forcing","daymet"), full.names = FALSE)
huc2_path <- dir(file.path(my_basin_dir,"basin_mean_forcing","daymet"), full.names = TRUE)

# loop 
# for (h in 1:length(huc2_list)) {
h=15

  message(paste0("processing HUC # ",huc2_list[h]))
  
  ### get the site list ----
  sites <- list.files(huc2_path[h]) %>% str_split("_", simplify = TRUE)
  site_ids <- sites[,1]
  
  # Chunk ids by 10
  site_ids_chunks <- split(site_ids, ceiling(seq_along(site_ids)/10))

  
  ### Get the CAMELS data ----
  # message("<---- Getting CAMELS forcing and attributes ---->")
  
  camels_data <- extract_huc_data(basin_dir = my_basin_dir, 
                                  attr_dir = my_attr_dir, 
                                  huc8_names = site_ids)

  ### Get the USGS data for those sites----
  # message("<---- Getting USGS flow and chemistry ---->")
  
  usgs_data <- get_sample_data(site_ids) # takes some time
  

  ### Write the csv files ----
  # message("<---- Writing files ---->")
  
  # Discharge
  # write_csv(camels_q, "data/camels_discharge_test_sites.csv")
  write_csv(usgs_data$discharge, file.path(main_dir, sprintf("output/usgs_discharge_huc%s_sites.csv", huc2_list[h])))
  
  # Water Quality
  # removing the stream flow since it was added to the main stream flow file
  usgs_chem <- usgs_data$water_ %>%
    filter(!str_detect(CharacteristicName,"flow"))
  
  # Write the file
  write_csv(usgs_chem, file.path(main_dir, sprintf("output/usgs_waterq_huc%s_sites.csv", huc2_list[h])))
  
  # Sites info
  write_csv(usgs_data$sites, file.path(main_dir, sprintf("output/usgs_huc%s_sites.csv", huc2_list[h])))
  
  # Camels forcing
  write_csv(camels_data$mean_forcing_daymet, file.path(main_dir, sprintf("output/camels_forcing_huc%s_sites.csv", huc2_list[h])))
  
  # Camels attributes
  write_csv(camels_data$camels_clim, file.path(main_dir, sprintf("output/camels_att_clim_huc%s_sites.csv", huc2_list[h])))
  write_csv(camels_data$camels_geol, file.path(main_dir, sprintf("output/camels_att_geol_huc%s_sites.csv", huc2_list[h])))
  write_csv(camels_data$camels_hydro, file.path(main_dir, sprintf("output/camels_att_hydro_huc%s_sites.csv", huc2_list[h])))
  write_csv(camels_data$camels_soil, file.path(main_dir, sprintf("output/camels_att_soil_huc%s_sites.csv", huc2_list[h])))
  write_csv(camels_data$camels_topo, file.path(main_dir, sprintf("output/camels_att_topo_huc%s_sites.csv", huc2_list[h])))
  write_csv(camels_data$camels_vege, file.path(main_dir, sprintf("output/camels_att_vege_huc%s_sites.csv", huc2_list[h])))
  
# }