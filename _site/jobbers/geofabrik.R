library(osmextract)
library(sf)
library(mapview)

source("jobbers/custom_bounding_box.R")


# downloaded from https://download.geofabrik.de/south-america/ecuador.html
# translate to gpkg
pbf_path <- "crude_data/ecuador-latest.osm.pbf"
# its_gpkg <- oe_vectortranslate(pbf_path)

#ecu_pbf <-  st_read(pbf_path)
st_layers(pbf_path)
# ecu_pbf_points <- st_read(pbf_path, layer = "points")
# ecu_pbf_lines <- st_read(pbf_path, layer = "lines")
# ecu_pbf_multilinestrings <- st_read(pbf_path, layer = "multilinestrings")
# ecu_pbf_multipolygons <- st_read(pbf_path, layer = "multipolygons")
# ecu_pbf_other_relations <- st_read(pbf_path, layer = "other_relations")


# ecu_gpkg <- st_read("crude_data/ecuador-latest.gpkg", layer = "lines")
# st_layers("crude_data/ecuador-latest.gpkg")

# Build polygon (close ring by repeating first point)
coords <- rbind(NE, SE, SW, NW, NE) # from source("jobbers/custom_bounding_box.R")
bbox_poly <- st_sfc(st_polygon(list(coords)), crs = 4326)



roads <- oe_read(
  pbf_path,
  layer = "lines",
  query = "SELECT * FROM lines WHERE highway IS NOT NULL",
  boundary = bbox_poly   # <-- spatial filter
)

mapviewOptions(basemaps = c("OpenStreetMap",
                            "Esri.WorldImagery",
                            "OpenTopoMap"))
aux <- roads[roads$waterway == "stream", ] # filter for z_order == 3)
mapview(aux)

rivers <- oe_read(
  pbf_path,
  layer = "lines",
  query = "SELECT * FROM lines WHERE waterway IS NOT NULL",
  boundary = bbox_poly
)
water_natural <- oe_read(
  pbf_path,
  layer = "multipolygons",
  query = "SELECT * FROM multipolygons WHERE natural='water'",
  boundary = bbox_poly
)

water_tagged <- oe_read(
  pbf_path,
  layer = "multipolygons",
  query = "SELECT * FROM multipolygons WHERE water IS NOT NULL",
  boundary = bbox_poly
)



mapview(rivers) + mapview(water_natural) + mapview(water_tagged)
