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

saveRDS(gadm41_ECU_country_level_filtered, "clean_data/gadm41_ECU_country_level_filtered.RDS")
saveRDS(gadm41_ECU_province_level_filtered, "clean_data/gadm41_ECU_province_level_filtered.RDS")
saveRDS(gadm41_ECU_canton_level_filtered, "clean_data/gadm41_ECU_canton_level_filtered.RDS")
saveRDS(gadm41_ECU_parish_level_filtered, "clean_data/gadm41_ECU_parish_level_filtered.RDS")

# p <- ggplot(gadm41_ECU_province_level_filtered) +
#   geom_sf(aes(fill = NAME_1, text = NAME_1), color = "black", size = 0.2) +
#   geom_sf_text(aes(label = NAME_1), size = 2) +
#   theme_minimal() +
#   theme(legend.position = "none")
# 
# ggplotly(p)
# mapview::mapview(gadm41_ECU_province_level_filtered)
# tmap_mode("view")   
# tm_shape(gadm41_ECU_province_level_filtered) +
#   tm_polygons("NAME_1")

# Now I want the bounding box of Manabi
# Extract the Manabí bounding box
manabi_bbox <- gadm41_ECU_province_level_filtered %>% 
  filter(NAME_1 == "Manabi") %>% 
  st_bbox()

# Expand the bbox a bit (e.g., by 0.1 degrees)
expand_amount <- 0.01
manabi_bbox_expanded <- manabi_bbox
manabi_bbox_expanded["xmin"] <- manabi_bbox["xmin"] - expand_amount
manabi_bbox_expanded["xmax"] <- manabi_bbox["xmax"] + expand_amount
manabi_bbox_expanded["ymin"] <- manabi_bbox["ymin"] - expand_amount
manabi_bbox_expanded["ymax"] <- manabi_bbox["ymax"] + expand_amount

saveRDS(manabi_bbox_expanded, "clean_data/manabi_bbox_expanded.RDS")

# Crop using the expanded bbox
gadm41_ECU_country_cropped <- st_crop(gadm41_ECU_country_level_filtered, manabi_bbox_expanded)
gadm41_ECU_province_cropped <- st_crop(gadm41_ECU_province_level_filtered, manabi_bbox_expanded)
gadm41_ECU_canton_cropped <- st_crop(gadm41_ECU_canton_level_filtered, manabi_bbox_expanded)
gadm41_ECU_parish_cropped <- st_crop(gadm41_ECU_parish_level_filtered, manabi_bbox_expanded)

# Save cropped layers
saveRDS(gadm41_ECU_country_cropped, "clean_data/gadm41_ECU_country_cropped.RDS")
saveRDS(gadm41_ECU_province_cropped, "clean_data/gadm41_ECU_province_cropped.RDS")
saveRDS(gadm41_ECU_canton_cropped, "clean_data/gadm41_ECU_canton_cropped.RDS")
saveRDS(gadm41_ECU_parish_cropped, "clean_data/gadm41_ECU_parish_cropped.RDS")


# Use st_crop() if your study area is rectangular and you just need a quick crop.
# Use st_intersection() if you need to respect the exact shape of the study polygon.


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


# Optional: visualize
# tmap_mode("view")
# tmap_options(basemaps = c("OpenStreetMap", "Esri.WorldGrayCanvas", "Esri.WorldTopoMap"))
# tm_shape(gadm41_ECU_province_cropped) + tm_polygons("NAME_1", alpha = 0.4, border.col = "black", border.alpha = 0.8)
# mapview::mapviewOptions(basemaps = c("OpenStreetMap",
#                             "Esri.WorldImagery",
#                             "OpenTopoMap"))
# mapview::mapview(
#   gadm41_ECU_province_cropped,
#   zcol = "NAME_1",        # attribute used for fill
#   alpha.regions = 0.4,    # fill transparency
#   color = "black",        # border color
#   alpha = 0.8,             # border transparency
#   legend = FALSE          # show legend
# )

