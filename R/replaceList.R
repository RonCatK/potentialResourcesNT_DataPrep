replaceList <- function(disturbanceList,
                        potentialOil,
                        potentialMining){
  # Oil and Gas
  disturbanceList$oilGas[names(disturbanceList$oilGas) == "potentialOilGas"] <- NULL
  disturbanceList$oilGas[["potentialOilGas"]] <- potentialOil
  
  # Mining
  disturbanceList$mining[names(disturbanceList$mining) == "potentialMining"] <- NULL
  disturbanceList$mining[["potentialMining"]] <- potentialMining
  
  return(disturbanceList)
}