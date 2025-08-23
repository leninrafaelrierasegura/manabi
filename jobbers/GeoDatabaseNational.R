# this was to extract the layers 
library(sf)
library(mapview)
LAYERS <- st_layers("crude_data/GEODATABASE_NACIONAL_2021/GEODATABASE_NACIONAL_2021.gpkg")
for (layer in LAYERS$name) {
  assign(layer, st_read("crude_data/GEODATABASE_NACIONAL_2021/GEODATABASE_NACIONAL_2021.gpkg", layer = layer))
  
}

for (layer in LAYERS$name) {
  saveRDS(get(layer), file = paste0("crude_data/GEODATABASE_NACIONAL_2021/", layer, ".RDS"))
}

aream_a <- st_read("crude_data/GEODATABASE_NACIONAL_2021/GEODATABASE_NACIONAL_2021.gpkg", layer = "aream_a")
mapview(aream_a, zcol = "tipo_aream")

# this is to cut only within the study area
library(sf)
library(mapview)
library(dplyr)
library(tmap)
LAYERS <- st_layers("crude_data/GEODATABASE_NACIONAL_2021/GEODATABASE_NACIONAL_2021.gpkg")


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

LAYERS_name <- c("viv_p", "ejes_l", "zon_a", "sec_a", "loc_p", "ingresos_l", "ca04_a", "aream_a", "man_a")
obj <- readRDS(paste0("crude_data/GEODATABASE_NACIONAL_2021/", LAYERS_name[7], "_cropped_to_manabi.RDS"))
View(obj)
#filtered <- filter(obj, cod_otros == "EDIFICIO EDUCACIONAL")
mapview::mapview(obj)
tmap_mode("view")
tm_shape(filtered)

# aream_a tiene las cabeceras a todos los niveles
# loc_p son como cabeceras de pueblitos
# ca04_a tiene esto
# > unique(obj$cod_otros)
# [1] NA                         "EDIFICIO EDUCACIONAL"     "TEMPLO RELIGIOSO"         "CASA COMUNAL"             "EDIFICIO IMPORTANTE"      "EDIFICIO DE REFERENCIA"  
# [7] "CAMPO DEPORTIVO"          "CEMENTERIO"               "GASOLINERA"               "ESTABLECIMIENTO DE SALUD" "PARQUE"                   "PLAZA"                   
# [13] "TANQUE DE AGUA"           "EDIFICIO REFERENCIA" 