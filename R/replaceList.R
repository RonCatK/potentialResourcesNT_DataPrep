replaceList <- function(disturbanceList,
                        potentialOil,
                        potentialMining,
                        potentialCutblocks){
  # Oil and Gas
  disturbanceList$oilGas[names(disturbanceList$oilGas) == "potentialOilGas"] <- NULL
  disturbanceList$oilGas[["potentialOilGas"]] <- potentialOil
  
  # Mining
  disturbanceList$mining[names(disturbanceList$mining) == "potentialMining"] <- NULL
  disturbanceList$mining[["potentialMining"]] <- potentialMining
  
  # Cutblocks/Forestry
  disturbanceList$forestry[names(disturbanceList$forestry) == "potentialCutblocks"] <- NULL
  disturbanceList$forestry[["potentialCutblocks"]] <- potentialCutblocks
  
  return(disturbanceList)
}