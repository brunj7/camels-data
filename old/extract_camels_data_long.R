library(tools)
library(readr)
library(stringr)
library(fs)
library(dplyr)



#' Extract data from CAMELS
#' 
#' This function takes a list of watershed Huc 8s and extracts daily mean forcing dayment data as well as relevant climate, geology, hyrdology, area, soil, topography and vegetation data
#'
#' @param daymet_dir directory path to basin data should look something like: "~/basin_dataset_public_v1p2/" this directory pathway MUST end with the daymet/ folder 
#' -- within this folder there should more directories (labeled '01', '02', '03' etc) representing different huc2 watersheds
#' @param attr_dir directory path for attributes data (e.g: "~/camels_attributes_v2.0")
#' @param huc8_names vector of huc8 watershed IDs
#'
#' @return named list for each huc8 with 8 nested named lists, one for each attribut of interest
#' @export
#'
#' @examples 
#' \dontrun{
#' daymet_dir <- "~/CAMELS/basin_dataset_public_v1p2"
#' attr_dir <- "~/CAMELS/camels_attributes_v2.0"
#' huc8_names <- c("01013500", "08269000")
#' 
#' data <- extract_data(daymet_dir = daymet_dir, attr_dir = attr_dir, huc8_names = huc8_names)
#' 
#' ## list of hucs queried
#' > names(data)
#' [1] "01013500" "08269000"
#' 
#' ## names of dataframes within first list item
#' > names(data[[1]])
#' [1] "daymet"       "camels_clim"  "camels_geol"  "camels_hydro"
#' [5] "camels_name"  "camels_soil"  "camels_topo"  "camels_vege" 
#' 
#' ## same results using the huc ID for first ID in entered vector
#' > names(data[["01013500"]])
#' [1] "daymet"       "camels_clim"  "camels_geol"  "camels_hydro"
#' [5] "camels_name"  "camels_soil"  "camels_topo"  "camels_vege" 
#' 
#' ## getting data for specific attribute from huc 01013500
#' > data[["01013500"]]$camels_name
#   A tibble: 1 x 3
#' gauge_id huc_02 gauge_name                      
#'    <chr>    <chr>  <chr>                           
#'  1 01013500 01     Fish River near Fort Kent, Maine
#'  
#' ## similarly using the $ syntax:
#' > data$`08269000`$camels_name
#' A tibble: 1 x 3
#' gauge_id huc_02 gauge_name                      
#'    <chr>    <chr>  <chr>                           
#'  1 08269000 13     RIO PUEBLO DE TAOS NEAR TAOS, NM
#'}
extract_huc_data <- function(basin_dir, attr_dir, huc8_names) {
  
  ### assuming a consistent file structure these should yield the correct filepaths to daymet forcing and streamflow data
  daymet_dir <- file.path(basin_dir, "basin_mean_forcing/daymet")
  flow_dir <- file.path(basin_dir, "usgs_streamflow")
  
  
  ### check that these filepaths exist
  if(!dir_exists(daymet_dir)) stop("daymet directory does not exist, please check file path")
  if(!dir_exists(flow_dir)) stop("streamflow directory does not exist, please check file path")
  if(str_sub(daymet_dir, start = -6) != "daymet") stop("daymet directory is incorrect, please check file path")
  if(!dir_exists(attr_dir)) stop("attribute directory does not exist, please check file path")

  

  ## loop through each of the huc8 that were entered
  ## there are 2 steps in this loop
  ##~ step 1: get daymet (a) and steamflow (b) data and add as items 1 and 2 w/in attribute list
  ##~ step 2: get attribute data and add as items 3:9 in list
    
    #create empty attribute/data list
    attr_list <- list()
    
    #### STEP 1a ####
    ## get file path for the Huc8's daymet data
    daymet_file <- data.frame(files = list.files(daymet_dir,
                                                 recursive = T)) %>% 
      dplyr::filter(str_detect(files, paste(huc8_names, collapse = "|")))
    


    ### read each of the met files in
    daymet_data <- list()
    ids <- vector()
    for(i in 1:nrow(daymet_file)) {
      
      daymet_data[[i]] <- read_table2(
        file.path(daymet_dir, as.character(daymet_file[i,1])), 
        skip = 3,
        col_types = cols())
        
      ### get huc names from file path (we cant reliably use the orginal huc8 vector incase one wasn't found)
      ##~ will use this to name each list item, which will then be turned into an ID when turning list into df
      ##~~~ the below line of code pastes row i from the df, and cleanes the file path to just the huc by subtracting the first 8 chacters from the textfile name (basename)
      ids[i] <- str_sub(basename(paste(daymet_file[i,1])), end = 8)
      
    }
    
    ## name each list item with huc
    names(daymet_data) <- ids
    ## bind list into df, adding a column with huc as id
    all_daymet <- bind_rows(daymet_data, .id = "ID")
    
    
    ## if one of the entered hucs isn't present, let user know
    if (length(ids) < length(huc8_names)) {
      # turn huc8_names into df to filter out names that dont match the id's from above
      missing <- data.frame(name = huc8_names) %>% 
        dplyr::filter(!name %in% ids)
      
      message(sprintf("daymet mean forcing data not found for the following huc(s): \n %s \n please check that these IDs are correct",
                      paste(missing$name, collapse = "  ")))
    }
    
    
    # add this as first item within this huc's list
    attr_list[[1]] <- all_daymet
    
    ##### Step 1b #####
    ### Repeating above workflow for streamgauge data
    flow_file <- data.frame(files = list.files(flow_dir,
                                                 recursive = T)) %>% 
      dplyr::filter(str_detect(files, paste(huc8_names, collapse = "|")))
    
    
    ### read each of the met files in
    flow_data <- list()
    flow_ids <- vector()
    for(i in 1:nrow(flow_file)) {
      
      df <- read.table(file.path(flow_dir, as.character(flow_file[i,1])), 
                       sep = '',
                       header = F)
      names(df) <- c("ID", "Year", "Mnth", "Day", "discharge_cfs", "QC_flag")
      
      flow_data[[i]] <- df

      flow_ids[i] <- str_sub(basename(paste(flow_file[i,1])), end = 8)
      
    }
    
    if (length(flow_ids) < length(huc8_names)) {
      # turn huc8_names into df to filter out names that dont match the id's from above
      missing <- data.frame(name = huc8_names) %>% 
        dplyr::filter(!name %in% flow_ids)
      
      message(sprintf("flow data not found for the following huc(s): \n %s \n please check that these IDs are correct",
                      paste(missing$name, collapse = "  ")))
    }
    
    ## name each list item with huc
    names(flow_data) <- ids
    ## bind list into df, adding a column with huc as id
    ##~ suppress warning about coercing to character
    suppressWarnings(
      all_flow <- bind_rows(flow_data)
    )
    
    
    
    
    # add this as first item within this huc's list
    attr_list[[2]] <- all_flow
    
    
    #### STEP 2 ####
    ### get file paths for each file in attribute directory
    att_files <- list.files(file.path(attr_dir),
                            pattern = "^camels_[^a]", # remove the xls too; will be better with the extension instead
                            full.names = TRUE)
    
    ### loop through each attribute, adding each as a new nested list item
    for (j in 1:length(att_files)) {
      
      attr_list[[j+2]] <- read_delim(att_files[j], 
                                     delim = ";",
                                     col_types = cols()) %>% 
        dplyr::filter(gauge_id %in% huc8_names)
      
    }
    
    ## name these nested lists
    #~ first is daymet, the following are named based on the name of the text file
    list_names <- c("mean_forcing_daymet", "usgs_streamflow", file_path_sans_ext(basename(att_files)))
    names(attr_list) <- list_names
    
    return(attr_list)
    
    
}


##### test function #######


# Constant
daymet_dir <- "~/Data/CAMELS/basin_timeseries_v1p2_metForcing_obsFlow/basin_dataset_public_v1p2/basin_mean_forcing/daymet/"
attr_dir <- "~/Data/CAMELS/camels_attributes_v2.0"

# To become a variable
huc8_names <- c("01013500", "08269000", "test", "10259200")



data <- extract_huc_data(daymet_dir = daymet_dir, attr_dir = attr_dir, huc8_names = huc8_names)

