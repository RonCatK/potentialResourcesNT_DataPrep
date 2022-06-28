makePotentialOilGas <- function(harmonizedList, 
                                whatToCombine){
  laysToWork <- harmonizedList[["oilGas"]][names(harmonizedList[["oilGas"]]) %in% 
                                             whatToCombine[datasetName == "oilGas", 
                                                           dataClasses]]
  whichClaim <- laysToWork[unlist(lapply(laysToWork, function(L){
    return(any(grepl(pattern = "OBJECTID", x = names(L))))
  }))][[1]]
  whichPotential <- laysToWork[unlist(lapply(laysToWork, function(L){
    return(any(grepl(pattern = "C2H4_BCR6_NT1", x = names(L))))
  }))][[1]]
  whichPotential[["Potential"]] <- as.numeric(whichPotential[["C2H4_BCR6_NT1"]][[1]])+1
  whichPotential <- whichPotential[, "Potential"] #remove all names except potential
  
  whichClaim[["Potential"]] <- 1
  whichClaim <- whichClaim[, "Potential"] #remove all names except potential
  newPotentialOil <- rbind(whichPotential, whichClaim)
  return(newPotentialOil)
}