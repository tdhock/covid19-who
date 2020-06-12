u <- "https://data.cdc.gov/api/views/r8kw-7aab/rows.csv?accessType=DOWNLOAD"
local.csv <- file.path(
  "cdc-states", format(Sys.time(), "%Y-%m-%d.csv"))
dir.create("cdc-states", showWarnings=FALSE)
if(!file.exists(local.csv)){
  download.file(u, local.csv)
}


