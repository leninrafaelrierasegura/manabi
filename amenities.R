library(sf)
library(mapview)
library(dplyr)

# this was to extract the layers 
LAYERS <- st_layers("crude_data/GEODATABASE_NACIONAL_2021/GEODATABASE_NACIONAL_2021.gpkg")
for (layer in LAYERS$name) {
  aux_layer <-  st_read("crude_data/GEODATABASE_NACIONAL_2021/GEODATABASE_NACIONAL_2021.gpkg", layer = layer)
  saveRDS(aux_layer, file = paste0("crude_data/GEODATABASE_NACIONAL_2021/", layer, ".RDS"))
}

# this is to cut only within the study area
manabi_area_simple <- readRDS("clean_data/manabi_area_simple.RDS")
for (layer in LAYERS$name) {
  # Read the layer
  layer_obj <- readRDS(file = paste0("crude_data/GEODATABASE_NACIONAL_2021/", layer, ".RDS"))
  
  # Transform study polygon to match this layer
  manabi_area_proj <- st_transform(manabi_area_simple, st_crs(layer_obj))
  
  # Intersect
  cropped <- st_intersection(layer_obj, manabi_area_proj)
  
  # Save
  saveRDS(cropped, file = paste0("crude_data/GEODATABASE_NACIONAL_2021/", layer, "_cropped_to_manabi.RDS"))
}
# get the amenities from the ca04_a layer
ca04_a <- readRDS("clean_data/ca04_a_cropped_to_manabi.RDS")
amn <- unique(ca04_a$cod_otros) # check the unique values of the cod_otros column

for (i in 2:length(amn)) {
  aux <- filter(ca04_a, cod_otros == amn[i])
  saveRDS(aux, paste0("clean_data/amn_", gsub(" ", "_", amn[i]), ".RDS"))
}