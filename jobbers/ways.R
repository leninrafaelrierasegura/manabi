library(sf)
library(tmap)
library(mapview)
library(dplyr)
library(osmextract)
# set mapview options
mapviewOptions(basemaps = c("CartoDB.Positron",
                            "OpenStreetMap",
                            "Esri.WorldImagery",
                            "OpenTopoMap"))

source("jobbers/custom_bounding_box.R")

# plot the area of interest
area_of_interest <- readRDS("clean_data/manabi_area_simple.RDS")
mapview(
  area_of_interest,
  zcol = "geometry",        # attribute used for fill
  alpha.regions = 0,    # fill transparency
  color = "black",        # border color
  alpha = 0.4,            # border transparency
  legend = FALSE           # remove legend
)

# check the layers
pbf_path <- "crude_data/ecuador-latest.osm.pbf"
st_layers(pbf_path)

# create bounding box polygon
coords <- rbind(NE, SE, SW, NW, NE) # from source("jobbers/custom_bounding_box.R")
bbox_poly <- st_sfc(st_polygon(list(coords)), crs = 4326)

# get rivers on the box
rivers <- oe_read(
  pbf_path,
  layer = "lines",
  query = "SELECT * FROM lines WHERE waterway IS NOT NULL",
  boundary = bbox_poly
)
# get roads in the box
roads <- oe_read(
  pbf_path,
  layer = "lines",
  query = "SELECT * FROM lines WHERE highway IS NOT NULL",
  boundary = bbox_poly   # <-- spatial filter
)

# Clip rivers
rivers_in_aoi <- st_intersection(rivers, area_of_interest)

# Clip roads
roads_in_aoi <- st_intersection(roads, area_of_interest)


mapview(
  rivers_in_aoi,       # attribute used for fill
  zcol = "waterway",
  legend = TRUE           # remove legend
)

mapview(
  roads_in_aoi,       # attribute used for fill
  zcol = "highway",
  legend = TRUE           # remove legend
)


saveRDS(rivers_in_aoi, "clean_data/rivers_in_aoi.RDS")
saveRDS(roads_in_aoi, "clean_data/roads_in_aoi.RDS")

# Just for the record the below code does not work well as the previous did

# bbox <- st_bbox(area_of_interest)
# osm_lines <- st_read(pbf_path, layer = "lines", wkt_filter = st_as_text(st_as_sfc(bbox)))
# mapview(
#   osm_lines,       # attribute used for fill
#   zcol = "waterway",
#   alpha.regions = 0,    # fill transparency
#   color = "black",        # border color
#   alpha = 0.4,            # border transparency
#   legend = TRUE           # remove legend
# )

