# dowload from here 

# https://portal.opentopography.org/raster?opentopoID=OTSDEM.032021.4326.3

# https://mapcarta.com/es/W435020166


library(terra)
library(sf)

# Load polygon (sf) and DEM raster
area_of_interest <- readRDS("clean_data/manabi_area_simple.RDS")
dem30 <- rast("crude_data/rasters_COP30/output_hh.tif")
dem90 <- rast("crude_data/rasters_COP90/output_hh.tif")

# Convert sf polygon to terra SpatVector
aoi_vect <- vect(area_of_interest)

# Crop DEM to bounding box, then mask to polygon
dem30_mask <- mask(crop(dem30, aoi_vect), aoi_vect)
dem90_mask <- mask(crop(dem90, aoi_vect), aoi_vect)

# Save clipped raster
writeRaster(dem30_mask, "crude_data/dem30_manabi.tif", overwrite = TRUE)
writeRaster(dem90_mask, "clean_data/dem90_manabi.tif", overwrite = TRUE)

# mapview(dem90_mask, col.regions = terrain.colors(100), maxpixels = 4767480)


# Define elevation ranges (lower, upper, class_id)
rcl <- matrix(c(
  0,   50,  1,
  50, 150,  2,
  150, 250,  3,
  250, 350,  4,
  350, 450,  5,
  450, 750,  6,
  750, Inf,  7
), ncol = 3, byrow = TRUE)

# Reclassify DEM into categories
dem_classes <- classify(dem30_mask, rcl)

# Convert classified raster into polygons
polygons <- as.polygons(dem_classes, dissolve = TRUE, values = TRUE)

# Convert to sf for easier handling
polygons_sf <- st_as_sf(polygons)

# Relabel class IDs with elevation ranges
labels <- data.frame(
  output_hh = 0:7,   # include 0 since it's present in your polygons
  elevation_range = c("0: NoData/Below 0", "1: 0--50", "2: 50--150", "3: 150--250",
                      "4: 250--350", "5: 350--450", "6: 450--750", "7: 750 and above")
)

# Join on output_hh instead of lyr.1
polygons_sf <- polygons_sf %>%
  filter(output_hh >= 0) %>%
  left_join(labels, by = "output_hh") %>% 
  dplyr::select(-output_hh)

saveRDS(polygons_sf, "clean_data/dem_polygons_manabi.RDS")

# mapview(polygons_sf, zcol = "elevation_range", alpha.regions = 0.5)
