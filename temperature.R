library(geodata)
library(terra)
library(sf)
library(mapview)

# Download WorldClim temperature data for Ecuador
ecuador_avg_temp <- worldclim_country(country = "Ecuador", var = "tavg", res = 0.5,
                  path = "~/Desktop/manabi/crude_data")
ecuador_min_temp <- worldclim_country(country = "Ecuador", var = "tmin", res = 0.5,
                  path = "~/Desktop/manabi/crude_data")
ecuador_max_temp <- worldclim_country(country = "Ecuador", var = "tmax", res = 0.5,
                  path = "~/Desktop/manabi/crude_data")

# After downloading, I copy the .tiff files to clean_data folder

# Now load the rasters from clean_data. 

ecuador_avg_temp <- rast("clean_data/ECU_wc2.1_30s_tavg.tif")
ecuador_min_temp <- rast("clean_data/ECU_wc2.1_30s_tmin.tif")
ecuador_max_temp <- rast("clean_data/ECU_wc2.1_30s_tmax.tif")

# Each object above contains 12 GeoTiff (.tif) files, one for each month of the year


# 1. Mean across 12 layers (average climatology)
ecuador_avg_temp_mean <- terra::app(ecuador_avg_temp, mean, na.rm = TRUE)

# 2. Min across 12 layers (coldest month per pixel)
ecuador_min_temp_min <- terra::app(ecuador_min_temp, min, na.rm = TRUE)

# 3. Max across 12 layers (hottest month per pixel)
ecuador_max_temp_max <- terra::app(ecuador_max_temp, max, na.rm = TRUE)


area_of_interest <- readRDS("clean_data/manabi_area_simple.RDS")

# Convert sf polygon to terra SpatVector
aoi_vect <- vect(area_of_interest)

# Crop to bounding box, then mask to polygon
manabi_avg_temp <- mask(crop(ecuador_avg_temp_mean, aoi_vect), aoi_vect)
manabi_min_temp <- mask(crop(ecuador_min_temp_min, aoi_vect), aoi_vect)
manabi_max_temp <- mask(crop(ecuador_max_temp_max, aoi_vect), aoi_vect)

# Save clipped raster
writeRaster(manabi_avg_temp, "clean_data/manabi_avg_temp.tif", overwrite = TRUE)
writeRaster(manabi_min_temp, "clean_data/manabi_min_temp.tif", overwrite = TRUE)
writeRaster(manabi_max_temp, "clean_data/manabi_max_temp.tif", overwrite = TRUE)

# terra::plot(manabi_avg_temp)
# terra::plot(manabi_min_temp)
# terra::plot(manabi_max_temp)

# mapview(manabi_avg_temp, layer.name = "Avg Temp (°C)")


# condition: Tmin >= 18 and Tmax <= 30
suitable_area <- (manabi_min_temp >= 19.5) & (manabi_max_temp <= 30)

suitable_min <- mask(manabi_min_temp, suitable_area, maskvalues = 0)
suitable_max <- mask(manabi_max_temp, suitable_area, maskvalues = 0)






