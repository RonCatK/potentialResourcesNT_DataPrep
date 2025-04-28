makePotentialSeismicLines <- function(disturbanceList, 
                                whatToCombine){
  # We use the same potential layers for seismic lines than for oilGas. Here we have an extra
  # function only for organizational purposes!
  laysToWork <- disturbanceList[["oilGas"]][names(disturbanceList[["oilGas"]]) %in% 
                                              whatToCombine[datasetName == "oilGas", 
                                                            dataClasses]]
  if (is.null(laysToWork)){
    message("No potential for seismic lines in the study area. Returning NULL")
    return(NULL)
  } 
  
  whichClaim <- laysToWork[unlist(lapply(laysToWork, function(L){
    return(any(grepl(pattern = "OBJECTID", x = names(L))))
  }))][[1]]
  whichPotential <- laysToWork[unlist(lapply(laysToWork, function(L){
    return(any(grepl(pattern = "Band_1", x = names(L)))) 
  }))][[1]] # This used to be the layer C2H4_BCR6_NT1. I have no idea why terra/reproducible changed 
  # the name to Band_1. No time to find out... 
  whichPotential[["Potential"]] <- as.numeric(whichPotential[["Band_1"]][[1]])+1
  whichPotential <- whichPotential[, "Potential"] #remove all names except potential
  
  whichClaim[["Potential"]] <- as.numeric(max(whichPotential))+1 # Maximum potential is in already claimed areas
  whichClaim <- whichClaim[, "Potential"] #remove all names except potential
  newPotentialOil <- rbind(whichPotential, whichClaim)
  return(newPotentialOil)
}