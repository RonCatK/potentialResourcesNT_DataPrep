# CALCULATE TOTAL CURRENT DISTURBANCE (ALREADY BUFFERED TO 500m WITH 2015 30m LAYER-- NEEDS TO CLOSE TO 9.5% -- VALUE FROM GNWT/ENR)
# AND THE RATE OF CHANGE USING 2010 and 2015 ECCC DISTURBANCE LAYERS AT 30m 

# openProject(path = "/home/tmichele/projects/potentialResourcesNT_DataPrep/potentialResourcesNT_DataPrep.Rproj", 
#             newSession = TRUE)

library("Require")
Require("reproducible")
Require("SpaDES.core")
Require("terra")
Require("data.table")

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

dist2015Filename <- file.path(Paths$inputPath, 
                              "totalDisturbance_2015", "totalDisturbance_2015.shp")
dist2010Filename <- file.path(Paths$inputPath, 
                              "totalDisturbance_2010", "totalDisturbance_2010.shp")

if (any(!file.exists(dist2015Filename),
        !file.exists(dist2010Filename))) {
  # 2015
  lineURL <- "https://drive.google.com/file/d/14j9lvuE-Y6VnYdeERF8kLs_9gTkZKT3n/view?usp=sharing"
  AD_2015_Lines <- prepInputs(url = lineURL,
                              archive = "NorthwestTerritories_30m_Disturb_Perturb_Line.zip",
                              alsoExtract = "similar",
                              targetFile = "NorthwestTerritories_30m_Disturb_Perturb_Line.shp",
                              destinationPath = Paths$inputPath)
  AD_2015_Lines <- vect(AD_2015_Lines)
  
  polyURL <- "https://drive.google.com/file/d/1bbgRZjLXZzo-jJgdMccqwIwFd5dp1LDt/view?usp=sharing"
  AD_2015_Polys <- prepInputs(url = polyURL,
                              alsoExtract = "similar",
                              targetFile = "NorthwestTerritories_30m_Disturb_Perturb_Poly.shp",
                              destinationPath = Paths$inputPath)
  AD_2015_Polys <- vect(AD_2015_Polys)
  
  # 2010
  url_2010 <- "https://www.ec.gc.ca/data_donnees/STB-DGST/003/Boreal-ecosystem-anthropogenic-disturbance-vector-data-2008-2010.zip"
  AD_2010_Lines <- prepInputs(url = url_2010,
                              archive = "Boreal-ecosystem-anthropogenic-disturbance-vector-data-2008-2010.zip",
                              alsoExtract = "similar",
                              targetFile = "EC_borealdisturbance_linear_2008_2010_FINAL_ALBERS.shp",
                              destinationPath = Paths$inputPath)
  AD_2010_Lines <- vect(AD_2010_Lines)
  
  AD_2010_Polys <- prepInputs(url = url_2010,
                              archive = "Boreal-ecosystem-anthropogenic-disturbance-vector-data-2008-2010.zip",
                              alsoExtract = "similar",
                              targetFile = "EC_borealdisturbance_polygonal_2008_2010_FINAL_ALBERS.shp",
                              destinationPath = Paths$inputPath)
  AD_2010_Polys <- vect(AD_2010_Polys)
}


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
# 2015 --> NOPE.
# As it turns out, this process is highly time consuming and the classification ends up being impossible
# We decided instead to just:
# 1. Clip out (mask with inverse = TRUE to keep what does NOT intersect) the polygons from the buffered lines

AD_2015 <- mask(AD_2015_Lines_clipBuff, mask = AD_2015_Polys_clip, inverse = TRUE)
AD_2010 <- mask(AD_2010_Lines_clipBuff, mask = AD_2010_Polys_clip, inverse = TRUE)

# 2. Simply rbind the two shapefiles (polys + buffered lines with polys cropped out). Do the same for 2010.
AD_2015_all <- rbind(AD_2015, AD_2015_Polys_clip)
AD_2010_all <- rbind(AD_2010, AD_2010_Polys_clip)

# 3. Calculate the rate of growth for each of the 12 different classes
# 3.1. Calculate the area for each individual form:
AD_2015_all$Area_sqKm <- expanse(AD_2015_all) / 1000000
AD_2010_all$Area_sqKm <- expanse(AD_2010_all) / 1000000

# 3.2. Bring all to a data.table and summarize
AD_2015_DT <- as.data.table(as.data.frame(AD_2015_all[, c("Class", "Area_sqKm")]))
AD_2010_DT <- as.data.table(as.data.frame(AD_2010_all[, c("Class", "Area_sqKm")]))
# Make sure all classes match from 2010 to 2015
testthat::expect_true(all(sort(unique(AD_2015_DT$Class)) == sort(unique(AD_2010_DT$Class))))
AD_2015_DT_summ <- AD_2015_DT[, totalArea_sqKm := sum(Area_sqKm), by = "Class"]
AD_2015_DT_summ <- unique(AD_2015_DT_summ[, Area_sqKm := NULL])
AD_2010_DT_summ <- AD_2010_DT[, totalArea_sqKm := sum(Area_sqKm), by = "Class"]
AD_2010_DT_summ <- unique(AD_2010_DT_summ[, Area_sqKm := NULL])

# 3.3. Now I can see how much the disturbances changed from 2010 to 2015 in sq Km
AD_2015_DT_summ[, Year := "year2015"]
AD_2010_DT_summ[, Year := "year2010"]
AD_change <- rbind(AD_2015_DT_summ, AD_2010_DT_summ)
AD_changed <- dcast(data = AD_change, formula = Class ~ Year, value.var = "totalArea_sqKm")
AD_changed[, areaSqKmChangedPerYear := (year2015-year2010)/5]
AD_changed[, rateChangedPerYear := ((year2015-year2010)/year2010)/5]

if (checkChangeInDisturbance){
  # EXTRA: Quick calculation of the % disturbance change per year over the entire NT1 area:
  totAreaChangedPerYearSqKm <- sum(AD_changed$areaSqKmChangedPerYear)
  totalNT1AreaSqKm <- expanse(NT1) / 1000000
  print(paste0("Percentage of area changed per year averaged across 2010 to 2015 across ",
               "the total area: ", 
               round((totAreaChangedPerYearSqKm/totalNT1AreaSqKm)*100, 3), "%"))
}

if (checkDisturbance2015){
  # EXTRA: Quick calculation of the % 500m buffered disturbance over the entire NT1 area:
  AD_2015_L_500m <- buffer(x = AD_2015_Lines_clip, width = 500)
  AD_2015_P_500m <- buffer(x = AD_2015_Polys_clip, width = 500)
  AD_2015_L_500m <- mask(AD_2015_L_500m, mask = AD_2015_P_500m, inverse = TRUE)
  AD_2015_500m_all <- rbind(AD_2015_L_500m, AD_2015_P_500m)
  AD_2015_500m_all$Area_sqKm <- expanse(AD_2015_500m_all) / 1000000
  AD_2015_500m_DT <- as.data.table(as.data.frame(AD_2015_500m_all[, c("Class", "Area_sqKm")]))
  totDistKm2 <- sum(AD_2015_500m_DT$Area_sqKm)
  print(paste0("Percentage of 500m buffered human disturbance in the area based on 2015 data ",
               " is: ", 
               round((totDistKm2/totalNT1AreaSqKm)*100, 3), "%"))
}

# 4. Aggregate disturbances that need to be aggregated (based on the table I have)


# 5. Modify the table, which should be an Input.
# This process ensures we are not double counting disturbances, and that we can calculate the change 
# in disturbance per class, which we need to simulate the new disturbances coming.

