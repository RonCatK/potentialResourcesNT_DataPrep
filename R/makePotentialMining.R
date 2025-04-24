makePotentialMining <- function(disturbanceList, 
                                whatToCombine){

  valueType <- data.table(type = c("CLAIM_STAT", "PERMIT_STA", "CLAIM_STAT", "PERMIT_STA"),
                          status = c("ACTIVE","ACTIVE", "CANCELLED", "CANCELLED"),
                          value = c(4, 3, 2, 1)) 
  
  #TODO This is something that could potentially be generalized (i.e., each 
  # type has their own table but the processing is generic. 
  
  laysToWork <- disturbanceList[["mining"]][names(disturbanceList[["mining"]]) %in%
                                              whatToCombine[datasetName == "mining",
                                                            dataClasses]]
  whichLayers <- lapply(1:length(laysToWork), function(index){
    L <- laysToWork[[index]]
    whichTypeIndex <- unique(valueType[["type"]][which(valueType[["type"]] %in% names(L))])
    # Some of the permits have been CANCELLED --> Which we assume mean there is no interest in exploring
    # further, at least at the moment. This doesn't mean they will not eventually be available, are
    # just lower priority.
    Lactive <- subset(L, L[[whatToCombine[datasetName == "mining", activeProcess][index]]] == "ACTIVE")
    Lactive[["Potential"]] <- valueType[type == whichTypeIndex & status == "ACTIVE", value]
    Linactive <- subset(L, L[[whatToCombine[datasetName == "mining", activeProcess][index]]] == "CANCELLED")
    Linactive[["Potential"]] <- valueType[type == whichTypeIndex & status == "CANCELLED", value]    
    proccLays <- rbind(Lactive, Linactive)
    proccLays <- proccLays[, "Potential"] #remove all names except potential
    return(proccLays)
  })
  newPotentialMining <- do.call(rbind, whichLayers)
  if (any(is.null(newPotentialMining),
          length(newPotentialMining) == 0)){
    stop(paste0("No potential in the study area. At least one potential ",
                "layer is necessary for the analysis. If you are supplying ",
                " potential layers, please keep this in mind. If you are ",
                "the deafult in the NT, your study area is outside of",
                "currently supported region for potential resources",
                "creation but this was missed before. Please debug!"))
  }
  return(newPotentialMining)
}