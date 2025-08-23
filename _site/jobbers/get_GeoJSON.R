library(sf)
manabi_bbox_expanded <- readRDS("clean_data/manabi_bbox_expanded.rds")
manabi_poly <- st_as_sfc(manabi_bbox_expanded)
st_crs(manabi_poly) <- 4326   # i.e. WGS84, required by TomTom
# Save as GeoJSON
st_write(manabi_poly, "clean_data/manabi_bbox_expanded.geojson", driver = "GeoJSON", delete_dsn = TRUE)
