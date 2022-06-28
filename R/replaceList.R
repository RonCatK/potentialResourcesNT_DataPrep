replaceList <- function(harmonizedList,
                        potentialOil,
                        potentialMining){
  # Oil and Gas
  harmonizedList$oilGas[names(harmonizedList$oilGas) == "potentialOilGas"] <- NULL
  harmonizedList$oilGas[["potentialOilGas"]] <- potentialOil
  
  # Mining
  harmonizedList$mining[names(harmonizedList$mining) == "potentialMining"] <- NULL
  harmonizedList$mining[["potentialMining"]] <- potentialMining
  
  return(harmonizedList)
}