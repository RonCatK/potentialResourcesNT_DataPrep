makePotentialOilGas <- function(disturbanceList, 
                                whatToCombine){
  laysToWork <- disturbanceList[["oilGas"]][names(disturbanceList[["oilGas"]]) %in% 
                                              whatToCombine[datasetName == "oilGas", 
                                                            dataClasses]]
  
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