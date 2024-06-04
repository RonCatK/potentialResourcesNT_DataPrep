replaceList <- function(disturbanceList,
                        potentialOil,
                        potentialMining,
                        potentialCutblocks,
                        potentialSeismicLines){
  # Oil and Gas
  disturbanceList$oilGas[names(disturbanceList$oilGas) == "potentialOilGas"] <- NULL
  disturbanceList$oilGas[["potentialOilGas"]] <- potentialOil
  
  # Seismic Lines (belongs to the oil and gas sector!)
  disturbanceList$oilGas[names(disturbanceList$oilGas) == "potentialSeismicLines"] <- NULL
  disturbanceList$oilGas[["potentialSeismicLines"]] <- potentialSeismicLines
  
  # Mining
  disturbanceList$mining[names(disturbanceList$mining) == "potentialMining"] <- NULL
  disturbanceList$mining[["potentialMining"]] <- potentialMining
  
  # Cutblocks/Forestry
  disturbanceList$forestry[names(disturbanceList$forestry) == "potentialCutblocks"] <- NULL
  disturbanceList$forestry[["potentialCutblocks"]] <- potentialCutblocks
  
  return(disturbanceList)
}