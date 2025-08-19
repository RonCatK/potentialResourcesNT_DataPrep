# test-makePotentialSeismicLines.R
# Tests for makePotentialSeismicLines()

library(testthat)
library(terra)
library(data.table)

mk_sq <- function(x0, y0, size = 1, crs = "EPSG:3857") {
  vect(matrix(c(x0,y0, x0+size,y0, x0+size,y0+size, x0,y0+size, x0,y0),
              ncol = 2, byrow = TRUE), type = "polygons", crs = crs)
}

test_that("No oilGas sector -> returns NULL with message", {
  skip_on_cran()
  
  disturbanceList <- list(oilGas = NULL)
  wtc <- data.table(datasetName = "oilGas", dataClasses = c("claims", "potentialOilGas"))
  
  expect_message(
    out <- makePotentialSeismicLines(disturbanceList, wtc),
    regexp = "No potential for seismic lines in the study area", ignore.case = TRUE
  )
  expect_null(out)
})

test_that("Builds Potential from Band_1 + 1 and prioritizes claims as max+1", {
  skip_on_cran()
  
  crs_str <- "EPSG:3857"
  # potential layer with Band_1 field (two polys, Band_1 values differ)
  pot <- rbind(mk_sq(0,0, crs = crs_str), mk_sq(2,0, crs = crs_str))
  pot$Band_1 <- c(5, 9)  # NOTE: function uses [[1]], i.e., the first value only

  # claims layer with OBJECTID field (one poly elsewhere)
  clm <- mk_sq(10,10, crs = crs_str); clm$OBJECTID <- 1L
  
  disturbanceList <- list(oilGas = list(
    potentialOilGas = pot,
    claims          = clm
  ))
  wtc <- data.table(datasetName = "oilGas",
                    dataClasses = c("potentialOilGas","claims"))
  
  out <- makePotentialSeismicLines(disturbanceList, wtc)
  
  # Basic shape
  expect_s4_class(out, "SpatVector")
  expect_equal(geomtype(out), "polygons")
  expect_equal(crs(out), crs(pot))
  expect_identical(names(out), "Potential")
  
  # Current behavior: Potential is (first Band_1 + 1) for all potential polys
  # and claims get max(potential) + 1
  pot_base <- pot$Band_1[1] + 1       # 5 -> 6
  claim_val <- pot_base + 1           # 7
  
  vals <- sort(out$Potential)
  expect_true(all(vals %in% c(pot_base, claim_val)))
  expect_equal(sum(vals == claim_val), nrow(clm))  # claims count at the top value
  expect_equal(sum(vals == pot_base), nrow(pot))   # all potentials flattened to first value
})

test_that("Output contains only 'Potential' column (attributes are dropped)", {
  skip_on_cran()
  
  crs_str <- "EPSG:3857"
  pot <- mk_sq(0,0, crs = crs_str); pot$Band_1 <- 3; pot$Other <- 99
  clm <- mk_sq(2,0, crs = crs_str); clm$OBJECTID <- 1L; clm$Foo <- "bar"
  
  disturbanceList <- list(oilGas = list(potentialOilGas = pot, claims = clm))
  wtc <- data.table(datasetName = "oilGas", dataClasses = c("potentialOilGas","claims"))
  
  out <- makePotentialSeismicLines(disturbanceList, wtc)
  expect_identical(names(out), "Potential")
})

test_that("Missing Band_1 or OBJECTID causes subscript error (documents current behavior)", {
  skip_on_cran()
  
  crs_str <- "EPSG:3857"
  # potential without Band_1
  pot_no_band <- mk_sq(0,0, crs = crs_str); pot_no_band$X <- 1
  # claims without OBJECTID
  clm_no_id <- mk_sq(2,0, crs = crs_str); clm_no_id$Y <- 1
  
  disturbanceList <- list(oilGas = list(potentialOilGas = pot_no_band, claims = clm_no_id))
  wtc <- data.table(datasetName = "oilGas", dataClasses = c("potentialOilGas","claims"))
  
  expect_error(
    makePotentialSeismicLines(disturbanceList, wtc),
    regexp = "subscript|out of bounds", ignore.case = TRUE
  )
})

test_that("When multiple Band_1 candidates exist, the first in list order is used", {
  skip_on_cran()
  
  crs_str <- "EPSG:3857"
  pot1 <- mk_sq(0,0, crs = crs_str); pot1$Band_1 <- 2   # should be the one used
  pot2 <- mk_sq(4,0, crs = crs_str); pot2$Band_1 <- 10  # should be ignored
  clm  <- mk_sq(8,0, crs = crs_str); clm$OBJECTID <- 1L
  
  # List order puts pot1 before pot2
  disturbanceList <- list(oilGas = list(
    potentialOilGas  = pot1,
    potentialOilGas2 = pot2,
    claims           = clm
  ))
  wtc <- data.table(datasetName = "oilGas",
                    dataClasses = c("potentialOilGas","potentialOilGas2","claims"))
  
  out <- makePotentialSeismicLines(disturbanceList, wtc)
  
  # Potential should be (pot1$Band_1[1] + 1) and claim is +1 above that
  expect_equal(min(out$Potential), pot1$Band_1[1] + 1)
  expect_equal(max(out$Potential), pot1$Band_1[1] + 2)
})
