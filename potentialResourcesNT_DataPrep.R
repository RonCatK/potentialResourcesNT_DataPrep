## Everything in this file and any files in the R directory are sourced during `simInit()`;
## all functions and objects are put into the `simList`.
## To use objects, use `sim$xxx` (they are globally available to all modules).
## Functions can be used inside any function that was sourced in this module;
## they are namespaced to the module, just like functions in R packages.
## If exact location is required, functions will be: `sim$.mods$<moduleName>$FunctionName`.
defineModule(sim, list(
  name = "potentialResourcesNT_DataPrep",
  description =  paste0("This is a data preparation module to harmonize different",
                        " athropogenic disturbance datasets, more specifically, ",
                        "mining and oil/gas. It's intended for the Northwest ",
                        "Territories region (default) and is idyossyncratic.",
                        "This means this module is NOT generalizable, but can ",
                        "be used as basis for other types of development. The ",
                        "objective is to create one standardized layer for each",
                        " of the potential resources that has increasing values ",
                        "for most prioritized places (i.e., higher values, more",
                        " likely structures will appear)."),
  keywords = "",
  authors = structure(list(list(given = "Tati", 
                                family = "Micheletti", role = c("aut", "cre"), 
                                email = "tati.micheletti@gmail.com", 
                                comment = NULL)), 
                      class = "person"),  
  childModules = character(0),
  version = list(potentialResourcesNT_DataPrep = "0.0.0.9000"),
  timeframe = as.POSIXlt(c(NA, NA)),
  timeunit = "year",
  citation = list("citation.bib"),
  documentation = list("README.md", "potentialResourcesNT_DataPrep.Rmd"), ## same file
  reqdPkgs = list("SpaDES.core (>=1.0.10)", "ggplot2", 
                  "PredictiveEcology/reproducible@development",
                  "raster", "terra", "crayon", "data.table"),
  parameters = rbind(
    #defineParameter("paramName", "paramClass", value, min, max, "parameter description"),
    defineParameter("whatToCombine", "data.table", 
                    data.table(datasetName = c("oilGas", "oilGas", "mining", "mining"),
                               dataClasses = c("potentialOilGas", "potentialOilGas", 
                                               "potentialMining", "potentialMining"),
                               toDifferentiate = c(NA, "C2H4_BCR6_NT1", "CLAIM_STAT", "PERMIT_STA"),
                               activeProcess = c(NA, NA, "CLAIM_STAT", "PERMIT_STA")), 
                    NA, NA,
                    paste0("Here the user should specify a data.table with the ",
                           "dataName and dataClasses from the object `disturbanceList` ",
                           "anthroDisturbance_DataPrep, first and (input from ",
                           "second levels) to be combined. The table also contains a ",
                           "column identifying which to be used to filter",
                           " active processes for mining (CLAIM_STAT and PERMIT_STA) ",
                           "For Oil/Gas (it needs to identify which layer ",
                           "is the potential one (C2H4_BCR6_NT1) and which is used ",
                           " to constrain where oil and gas will be added. For oil ",
                           "and gas, the other potential layer (exploration permits)",
                           " is used as a starting point to add structures, followed",
                           " by randomly placing them in the highest values of C2H4_BCR6_NT1",
                           "and going down until the total amount is reached. For mining, ",
                           "CLAIM_STAT is the potential exploration, while PERMIT_STA ",
                           "are the ones that might become CLAIMS. The most likely ",
                           "values are CLAIMS and followed by PERMITS. ")),
    defineParameter(".plots", "character", "screen", NA, NA,
                    "Used by Plots function, which can be optionally used here"),
    defineParameter(".plotInitialTime", "numeric", start(sim), NA, NA,
                    "Describes the simulation time at which the first plot event should occur."),
    defineParameter(".plotInterval", "numeric", NA, NA, NA,
                    "Describes the simulation time interval between plot events."),
    defineParameter(".saveInitialTime", "numeric", NA, NA, NA,
                    "Describes the simulation time at which the first save event should occur."),
    defineParameter(".saveInterval", "numeric", NA, NA, NA,
                    "This describes the simulation time interval between save events."),
    ## .seed is optional: `list('init' = 123)` will `set.seed(123)` for the `init` event only.
    defineParameter(".seed", "list", list(), NA, NA,
                    "Named list of seeds to use for each event (names)."),
    defineParameter(".useCache", "logical", FALSE, NA, NA,
                    "Should caching of events or module be used?")
  ),
  inputObjects = bindrows(
    #expectsInput("objectName", "objectClass", "input object description", sourceURL, ...),
    expectsInput(objectName = "disturbanceList", objectClass = "list",
                 desc = paste0("List (general category) of lists (specific ",
                               "class) needed for generating ",
                               "disturbances. This last list contains: ",
                               "Outter list names: dataName from disturbanceDT",
                               "Inner list names: dataClass from disturbanceDT, ",
                               "which is a unique class after harmozining, except ",
                               "for any potential resources that need idiosyncratic",
                               " processing. This  means that each combination ",
                               "of dataName and dataClass (except for 'potential')",
                               " will only have only one element. Another module",
                               "can deal with the potential layers. For the ",
                               "current defaults, this is the potentialResourcesNT_DataPrep",
                               "If none of the potential layers needs to be modified ",
                               "or combines, you might skip this idiosyncratic module",
                               " and directly use the anthroDisturbance_Generator ",
                               "module."), 
                 sourceURL = NA), # <~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ADD HERE SOMEHOW THE OBJECT!
    expectsInput(objectName = "historicalFires", objectClass = "list",
                 desc = paste0("List per YEAR of burned polygons. It needs to ",
                               "contain at least the following columns: YEAR or DECADE.",
                               "The default layer was created by ENR for the NWT"), 
                 sourceURL = "https://drive.google.com/file/d/1FpaOl5QZ2YWbO6KdEQayip8yqsHWtGV-/view?usp=sharing")
  ),
  outputObjects = bindrows(
    #createsOutput("objectName", "objectClass", "output object description", ...),
    createsOutput(objectName = "disturbanceList", objectClass = "list",
                  desc = paste0("List (general category) of lists (specific ",
                                "class) needed for generating ",
                                "disturbances. This is a modified input, where we ",
                                "replace multiple potential layers (i.e., mining",
                                " and oilGas) by only one layer, with the highest",
                                "values being the ones that need to be filled ",
                                "with new developments first."))
  )
))

## event types
#   - type `init` is required for initialization

doEvent.potentialResourcesNT_DataPrep = function(sim, eventTime, eventType) {
  switch(
    eventType,
    init = {
      # If the simulations start before 2011, it shouldn't work because of the data
      if (start(sim) < 2011) stop(paste0("Please revisit your starting year for",
                                         " the simulations. Simulations shouldn't ",
                                         "start before 2011."))
      # schedule future event(s)
      sim <- scheduleEvent(sim, start(sim), "potentialResourcesNT_DataPrep", "createPotentialMining")
      sim <- scheduleEvent(sim, start(sim), "potentialResourcesNT_DataPrep", "createPotentialOilGas")
      sim <- scheduleEvent(sim, start(sim), "potentialResourcesNT_DataPrep", "createPotentialCutblocks")
      sim <- scheduleEvent(sim, start(sim), "potentialResourcesNT_DataPrep", "replaceInDisturbanceList")
    },
    createPotentialMining = {
      sim$potentialMining <- makePotentialMining(disturbanceList = sim$disturbanceList, 
                                                 whatToCombine = P(sim)$whatToCombine)
    },
    createPotentialOilGas = {
      sim$potentialOilGas <- makePotentialOilGas(disturbanceList = sim$disturbanceList, 
                                                 whatToCombine = P(sim)$whatToCombine)
    },
    createPotentialCutblocks = {
      sim$potentialCutblocks <- makePotentialCutblocks(disturbanceList = sim$disturbanceList,
                                                       currentYear = time(sim),
                                                       historicalFires = sim$historicalFires)
    },
    replaceInDisturbanceList = {
      sim$disturbanceList <- replaceList(disturbanceList = sim$disturbanceList,
                                         potentialOil = sim$potentialOilGas,
                                         potentialMining = sim$potentialMining,
                                         potentialCutblocks = sim$potentialCutblocks)
    },
    warning(paste("Undefined event type: \'", current(sim)[1, "eventType", with = FALSE],
                  "\' in module \'", current(sim)[1, "moduleName", with = FALSE], "\'", sep = ""))
  )
  return(invisible(sim))
}

.inputObjects <- function(sim) {
  #cacheTags <- c(currentModule(sim), "function:.inputObjects") ## uncomment this if Cache is being used
  dPath <- asPath(getOption("reproducible.destinationPath", dataPath(sim)), 1)
  message(currentModule(sim), ": using dataPath '", dPath, "'.")
  
  if (!suppliedElsewhere(object = "disturbanceList", sim = sim)) {
    sim$disturbanceList <- prepInputs(url = extractURL("disturbanceList"),
                                      destinationPath = dPath,
                                      fun = "qs::qread",
                                      header = TRUE, 
                                      userTags = "disturbanceListTest")
    
    warning(paste0("disturbanceList was not supplied. The current should only ",
                   " be used for module testing purposes! Please run the module ",
                   "`anthroDisturbance_DataPrep`"), 
            immediate. = TRUE)
  }
  if (!suppliedElsewhere(object = "historicalFires", sim = sim)) {
    
    message(crayon::red(paste0("historicalFires was not provided. The function will try ",
                               "to use a layer created by ENR-NT. If your study ",
                               "area is NOT in the NWT, please provide historicalFires")))
    
    sim$historicalFires <- prepInputs(url = extractURL("historicalFires"),
                                      destinationPath = dPath,
                                      studyArea = sim$studyArea,
                                      alsoExtract = "similar",
                                      header = TRUE, 
                                      userTags = "historicalFiresENR")
    
    sim$historicalFires <- projectInputs(sim$historicalFires, 
                                         targetCRS = crs(sim$rasterToMatch))
    
    # simplifying
    historicalFiresS <- sim$historicalFires[, names(sim$historicalFires) %in% c("YEAR", 
                                                                                "DECADE")]
    historicalFiresDT <- data.table(historicalFiresS@data)
    historicalFiresDT[, decadeYear := 5 + (as.numeric(unlist(lapply(
      strsplit(historicalFiresDT$DECADE, split = "-"), `[[`, 1
    ))))]
    historicalFiresDT[, fireYear := fifelse(YEAR == -9999, decadeYear, YEAR)]
    historicalFiresS$fireYear <- historicalFiresDT$fireYear
    sim$historicalFires <- historicalFiresS[, "fireYear"]
    
    # Discard fires with more than 60 from starting time
    olderstFireYear <- start(sim) - 60
    sim$historicalFires <- sim$historicalFires[sim$historicalFires$fireYear >= olderstFireYear, ]
  }
  
  return(invisible(sim))
}
