makePotentialCutblocks <- function(disturbanceList, 
                                   currentYear,
                                   historicalFires){
  
  # To recreate the potential cutblocks ENR (James Hodson) developed for the
  # NWT, we need to follow his recipe, sent by Kathleen Groenewegen 
  # (sft@gov.nt.ca):
  
  # The FVI data in the Wek'eezhii region was
  # originally created in 2011 and stand ages were updated by overlaying recent
  # fires in the region, and recalculating stand ages current to 2021. To
  # characterize forestry potential, forest stands were first broken down into
  # 'productive' and 'unproductive' forests. 'Productive' forest stands were
  # defined as those with a minimum Site Index (SI_50) value of 8 (which means 
  # stands have a height of at least 8 m at 50 years) and a minimum crown 
  # closure (CROWNCLOS) of 30%. Productive forest stands were then
  # broken down into three age categories: Recently burned (<=10 years old,
  # currently suitable for salvage harvesting); 11‐49 years old (will be 
  # suitable for timber harvesting in the future); and >=50 years old (currently 
  # suitable for timber harvesting). Unproductive forest stands and non‐forested 
  # polygons within the FVI were assumed to have little potential for commercial 
  # forestry.
  # 
  # NOTES ~TM: 
  # 1. In the current case, the layers will be updated up to the currentYear
  # 2. The age layer is not defined in the explanation, but I believe is this: 
  
  fireToUse <- historicalFires[historicalFires[["fireYear"]] > currentYear,]
  if (class(fireToUse) != "SpatVector")
    fireToUse <- vect(fireToUse) 
  # Select forestry potential layer
  forestPotential <- disturbanceList[["forestry"]][["potentialCutblocks"]]
  # Overlay with fire and update age
  browser()
  
  whichClaim[["Potential"]] <- 1
  whichClaim <- whichClaim[, "Potential"] #remove all names except potential
  newPotentialOil <- rbind(whichPotential, whichClaim)
  return(newPotentialOil)
}
