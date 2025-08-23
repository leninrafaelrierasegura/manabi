library(sf)
library(ggplot2)
library(plotly)
library(tmap)
library(dplyr)

source("jobbers/custom_bounding_box.R")

# Read layers
gadm41_ECU_country_level <- st_read("crude_data/gadm41_ECU.gpkg", layer = "ADM_ADM_0")
gadm41_ECU_province_level <- st_read("crude_data/gadm41_ECU.gpkg", layer = "ADM_ADM_1")
gadm41_ECU_canton_level <- st_read("crude_data/gadm41_ECU.gpkg", layer = "ADM_ADM_2")
gadm41_ECU_parish_level <- st_read("crude_data/gadm41_ECU.gpkg", layer = "ADM_ADM_3")

# Get mainland polygon
ECU_mainland <- gadm41_ECU_country_level %>% 
  st_cast("POLYGON") %>% 
  mutate(area = st_area(geom)) %>% 
  filter(area == max(area)) #%>% st_union() # merge into single polygon

# Function to keep only features inside mainland
filter_inside_mainland <- function(layer, mainland) {
  layer %>% 
    st_cast("POLYGON") %>% 
    filter(st_intersects(., mainland, sparse = FALSE)) %>% 
    group_by(across(-geom)) %>%
    summarise(geom = st_combine(geom), .groups = "drop") %>%
    st_cast("MULTIPOLYGON")
}

# Apply to all layers
gadm41_ECU_country_level_filtered <- filter_inside_mainland(gadm41_ECU_country_level, ECU_mainland)
gadm41_ECU_province_level_filtered <- filter_inside_mainland(gadm41_ECU_province_level, ECU_mainland)
gadm41_ECU_canton_level_filtered <- filter_inside_mainland(gadm41_ECU_canton_level, ECU_mainland)
gadm41_ECU_parish_level_filtered <- filter_inside_mainland(gadm41_ECU_parish_level, ECU_mainland)

# Now i want a custom polygon to crop the data
coords <- rbind(NE, SE, SW, NW, NE) # from source("jobbers/custom_bounding_box.R")
# Convert to an sf polygon
crop_polygon <- st_polygon(list(coords)) %>% 
  st_sfc(crs = st_crs(gadm41_ECU_country_level_filtered)) # match CRS of your data

# Optional: convert to sf object
crop_polygon_sf <- st_sf(geometry = crop_polygon)
mapview::mapview(crop_polygon_sf)

saveRDS(crop_polygon_sf, "clean_data/manabi_bbox_custom.RDS")

# Crop using st_intersection
gadm41_ECU_country_custom <- st_intersection(gadm41_ECU_country_level_filtered, crop_polygon_sf)
gadm41_ECU_province_custom <- st_intersection(gadm41_ECU_province_level_filtered, crop_polygon_sf)
gadm41_ECU_canton_custom <- st_intersection(gadm41_ECU_canton_level_filtered, crop_polygon_sf)
gadm41_ECU_parish_custom <- st_intersection(gadm41_ECU_parish_level_filtered, crop_polygon_sf)


# Save the custom cropped layers
saveRDS(gadm41_ECU_country_custom, "clean_data/gadm41_ECU_country_custom.RDS")
saveRDS(gadm41_ECU_province_custom, "clean_data/gadm41_ECU_province_custom.RDS")
saveRDS(gadm41_ECU_canton_custom, "clean_data/gadm41_ECU_canton_custom.RDS")
saveRDS(gadm41_ECU_parish_custom, "clean_data/gadm41_ECU_parish_custom.RDS")

manabi_area_simple <- st_as_sf(data.frame(geometry = st_geometry(gadm41_ECU_country_custom)))
saveRDS(manabi_area_simple, "clean_data/manabi_area_simple.RDS")