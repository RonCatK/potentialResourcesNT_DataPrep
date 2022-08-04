# CALCULATE TOTAL CURRENT DISTURBANCE (ALREADY BUFFERED TO 500m WITH 2015 30m LAYER-- NEEDS TO CLOSE TO 9.5% -- VALUE FROM GNWT/ENR)
# AND THE RATE OF CHANGE USING 2010 and 2015 ECCC DISTURBANCE LAYERS AT 30m 

# openProject(path = "/home/tmichele/projects/potentialResourcesNT_DataPrep/potentialResourcesNT_DataPrep.Rproj", 
#             newSession = TRUE)

library("Require")
Require("reproducible")
Require("sf")
Require("SpaDES.core")
Require("terra")
Require("tictoc")

# Pass your email for authentication (used for non-interactive calls)
googledrive::drive_auth(email = "tati.micheletti@gmail.com")
options(reproducible.useTerra = FALSE) # Workaround while reproducible is not yet fully functional with terra

# If you load the project, set the directory where your modules are located 
moduleDir <- dirname(getwd())

setPaths(modulePath = moduleDir,
         # cachePath = checkPath(file.path(getwd(), "cache"), 
         cachePath = checkPath(file.path(moduleDir, "potentialResourcesNT_DataPrep", "cache"), 
                               create = TRUE), 
         outputPath = checkPath(file.path(getwd(), "outputs"), 
                                create = TRUE),
         inputPath = checkPath(file.path(getwd(), "inputs"), 
                               create = TRUE),
         rasterPath = checkPath(file.path(getwd(), "temp_raster"), 
                                create = TRUE))

getPaths() # shows where the 4 relevant paths are

# 1. Get the layers (poly + lines) 2015 30m and 2010 30m

# NOTE: The 2015 layer is a GDB, and it doesn't work with prepInputs. Therefore I had to download,
# open in ArcGIS (NorthwestTerritories_30m.gdb), create a shapefile for lines 
# (NorthwestTerritories_30m_Disturb_Perturb_Line.shp) and one for polygons 
# (NorthwestTerritories_30m_Disturb_Perturb_Poly.shp), zip and upload to Google Drive
 
# Original Layer URL: "https://data-donnees.ec.gc.ca/data/species/developplans/2015-anthropogenic-disturbance-footprint-within-boreal-caribou-ranges-across-canada-as-interpreted-from-2015-landsat-satellite-imagery/Anthro_Disturb_Perturb_30m_2015.zip"

# 2015
lineURL <- "https://drive.google.com/file/d/14j9lvuE-Y6VnYdeERF8kLs_9gTkZKT3n/view?usp=sharing"
AD_2015_Lines <- prepInputs(url = lineURL,
                            archive = "NorthwestTerritories_30m_Disturb_Perturb_Line.zip",
                            alsoExtract = "similar",
                            targetFile = "NorthwestTerritories_30m_Disturb_Perturb_Line.shp",
                            destinationPath = Paths$inputPath)
# AD_2015_Lines <- sf::st_as_sf(AD_2015_Lines) # sf
AD_2015_Lines <- vect(AD_2015_Lines) # terra

polyURL <- "https://drive.google.com/file/d/1bbgRZjLXZzo-jJgdMccqwIwFd5dp1LDt/view?usp=sharing"
AD_2015_Polys <- prepInputs(url = polyURL,
                            alsoExtract = "similar",
                            targetFile = "NorthwestTerritories_30m_Disturb_Perturb_Poly.shp",
                            destinationPath = Paths$inputPath)
# AD_2015_Polys <- sf::st_as_sf(AD_2015_Polys) #sf
AD_2015_Polys <- vect(AD_2015_Polys) #terra

# 2010
url_2010 <- "https://www.ec.gc.ca/data_donnees/STB-DGST/003/Boreal-ecosystem-anthropogenic-disturbance-vector-data-2008-2010.zip"
AD_2010_Lines <- prepInputs(url = url_2010,
                            archive = "Boreal-ecosystem-anthropogenic-disturbance-vector-data-2008-2010.zip",
                            alsoExtract = "similar",
                            targetFile = "EC_borealdisturbance_linear_2008_2010_FINAL_ALBERS.shp",
                            destinationPath = Paths$inputPath)
# AD_2010_Lines <- sf::st_as_sf(AD_2010_Lines)
AD_2010_Lines <- vect(AD_2010_Lines)

AD_2010_Polys <- prepInputs(url = url_2010,
                            archive = "Boreal-ecosystem-anthropogenic-disturbance-vector-data-2008-2010.zip",
                            alsoExtract = "similar",
                            targetFile = "EC_borealdisturbance_polygonal_2008_2010_FINAL_ALBERS.shp",
                            destinationPath = Paths$inputPath)
# AD_2010_Polys <- sf::st_as_sf(AD_2010_Polys)
AD_2010_Polys <- vect(AD_2010_Polys) #terra

# 2. Clip all 4 layers to NT1
# 2.1. Load NT1 shapefile
NT1 <- prepInputs(url = "https://drive.google.com/file/d/1VRSolnXMYPrkdBhNofeR81dCu_NTBSgf/view?usp=sharing",
                            archive = "BIO_ENR_WFE_BorealCaribou_GNWT_NT1_range_2020.zip",
                            alsoExtract = "similar",
                            targetFile = "BIO_ENR_WFE_BorealCaribou_GNWT_NT1_range_2020.shp",
                            destinationPath = Paths$inputPath)
# NT1 <- sf::st_as_sf(NT1)
NT1 <- vect(NT1)

# Although NT1 has the same projection as the rest of the data, sf doesn't think so. So I need to
# reproject it to one of the other polygons (which I tested for compatible crs)
# testthat::expect_true(st_crs(AD_2015_Lines) == st_crs(AD_2015_Polys))
# testthat::expect_true(st_crs(AD_2010_Lines) == st_crs(AD_2010_Polys))
# testthat::expect_true(st_crs(AD_2010_Lines) == st_crs(AD_2015_Polys))
# testthat::expect_true(st_crs(AD_2010_Lines) == st_crs(NT1)) # ~~~~> Returns FALSE
NT1 <- project(x = NT1, y = terra::crs(AD_2015_Polys)) # terra
# testthat::expect_true(crs(AD_2010_Lines) == crs(NT1)) # ~~~~> Now returns TRUE
 
# 2.2. Clip all 4 layers to NT1
AD_2015_Polys_clip <- intersect(x = AD_2015_Polys, y = NT1)
AD_2015_Lines_clip <- intersect(x = AD_2015_Lines, y = NT1)

AD_2010_Polys_clip <- intersect(x = AD_2010_Polys, y = NT1)
AD_2010_Lines_clip <- intersect(x = AD_2010_Lines, y = NT1)

# 3. Buffer both lines to 30m
AD_2015_Lines_clipBuff <- buffer(x = AD_2015_Lines_clip, width = 30)
AD_2010_Lines_clipBuff <- buffer(x = AD_2010_Lines_clip, width = 30)

# 4. Union of polys and buffered lines for both 2015 and 2010, merging overlapping features by class
# 4.1. First, though, we need to simplify the AD_2015_Lines_clipBuff to only the columns in AD_2015_Polys
# 2015
toKeep <- names(AD_2015_Lines_clipBuff)[names(AD_2015_Lines_clipBuff) %in% names(AD_2015_Polys)]
AD_2015_Lines_clipBuff <- AD_2015_Lines_clipBuff[, toKeep]

# TRY RUNNING MICROBENCHMARK: I am relatively sure that sf is faster than terra for union of 
# complex features.
# Require("microbenchmark")
# microbenchmark::microbenchmark({
#   AD_2015_A <- union(AD_2015_Polys, AD_2015_Lines_clipBuff)
# }, {
#   AD_2015_Polyssf <- sf::st_as_sf(AD_2015_Polys)
#   AD_2015_Lines_clipBuffsf <- sf::st_as_sf(AD_2015_Lines_clipBuff)
#   AD_2015_B <- st_union(AD_2015_Polyssf, AD_2015_Lines_clipBuffsf)
# }, times = 1)

AD_2015_Polyssf <- sf::st_as_sf(AD_2015_Polys)
AD_2015_Lines_clipBuffsf <- sf::st_as_sf(AD_2015_Lines_clipBuff)
tic("Time for st_union: ")
AD_2015 <- st_union(AD_2015_Polyssf, AD_2015_Lines_clipBuffsf)
toc()
tic("Time for vect: ")
AD_2015 <- vect(AD_2015)
toc()
tic("Time for aggregate: ")
AD_2015b <- aggregate(AD_2015, by = "Class", dissolve = TRUE)
toc()


# AD_2015sf <- sf::st_as_sf(AD_2015)
# unied2015 <- st_union(AD_2015sf)
# parts <- st_cast(unied2015, "POLYGON")
# clust <- unlist(st_intersects(AD_2015sf, parts))
# 
# diss <- cbind(AD_2015sf, clust)
# diss2 <- vect(diss)
# 
# diss3 <- group_by(.data = diss2, clust)
# AD_2015b <- summarize(.data = diss3)

# 2010


# AD_2010_Lines_clipBuff <- AD_2010_Lines_clipBuff[, names(AD_2010_Lines_clipBuff) %in% names(AD_2010_Polys)]
# AD_2010 <- rbind(AD_2010_Polys, AD_2010_Lines_clipBuff)
# parts <- st_cast(st_union(AD_2010), "POLYGON")
# clust <- unlist(st_intersects(AD_2010, parts))
# diss <- cbind(AD_2010, clust)
# diss2 <- group_by(.data = diss, clust) 
# AD_2010 <- summarize(.data = diss2)

# HERE <~~~~~~~~~~~~~ DID IT WORK? check
AD_2010
AD_2015

# 5. Calculate area of all features


# 6. Extract the tables
# 7. Calculate total area per Class
# 8. Get the total change between 2010 and 2015, and divide by 5 to get yearly rate
# 
# From 3 with 500m buffer to 8 (to check whether there is any difference in the total, there should not!)
# 9. Calculate the total area of disturbance over the entire NT1 --> James' should result in about 9.5%
