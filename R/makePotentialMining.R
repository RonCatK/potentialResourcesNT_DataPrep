makePotentialMining <- function(harmonizedList, 
                                whatToCombine){
  laysToWork <- harmonizedList[["mining"]][names(harmonizedList[["mining"]]) %in% 
                                             whatToCombine[datasetName == "mining", 
                                                           dataClasses]]
  # Get the layers with needed fields
  lays <- lapply(1:length(laysToWork), function(index){
    L <- laysToWork[index][[1]]
    Lf <- subset(L, L[[whatToCombine[datasetName == "mining", 
                                     activeProcess][index]]] == "ACTIVE")
    return(Lf)
  })
  whichClaim <- lays[unlist(lapply(lays, function(L){
    return(any(grepl(pattern = "CLAIM", x = names(L))))
  }))][[1]]
  whichPermit <- lays[unlist(lapply(lays, function(L){
    return(any(grepl(pattern = "PERMIT", x = names(L))))
  }))][[1]]
  whichClaim[["Potential"]] <- 1
  whichClaim <- whichClaim[, "Potential"] #remove all names except potential
  whichPermit[["Potential"]] <- 2
  whichPermit <- whichPermit[, "Potential"] #remove all names except potential
  newPotentialMining <- rbind(whichPermit, whichClaim)
  return(newPotentialMining)
}