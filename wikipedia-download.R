source("packages.R")
Sys.setlocale(locale="C")

u <- "https://en.wikipedia.org/wiki/2019%E2%80%9320_coronavirus_pandemic_deaths"
local.html <- file.path(
  "wikipedia", format(Sys.time(), "%Y-%m-%d.html"))
dir.create("wikipedia", showWarnings=FALSE)
if(!file.exists(local.html)){
  download.file(u, local.html)
}

webpage <- xml2::read_html(local.html)
tbls <- rvest::html_nodes(webpage, "table")
tbl.list <- rvest::html_table(tbls, fill=TRUE)

not.countries <- c(
  "", "World", "Territories", "Days to double", "References",
  "Countries and territories", "Notes.*")
bad.pattern <- paste0(
  "^(?:",
  paste(not.countries, collapse="|"),
  ")$")
count.dt.list <- list()
for(tbl.i in seq_along(tbl.list)){
  df <- tbl.list[[tbl.i]]
  if(names(df)[[1]] == "Date"){
    is.country <- !grepl(bad.pattern, df$Date)
    country.dt <- data.table(df[is.country,])
    country.tall <- melt(
      country.dt,
      id.vars=1,
      measure.vars=3:ncol(country.dt))
    count.dt.list[[paste(tbl.i)]] <- country.tall
  }
}

count.dt <- do.call(rbind, count.dt.list)
strftime(Sys.time(), "%b_%d")
count.dt[, date.str := paste0(
  "2020 ", sub("[^A-Za-z0-9]", " ", variable))]
count.dt[, date.POSIXct := suppressWarnings(strptime(date.str, "%Y %b %d"))]
count.dt[, value.num := as.numeric(gsub(",", "", value))]
count.dt[is.na(value.num), .(count=.N), by=.(value, value.num)]
count.out <- count.dt[is.finite(value.num), .(
  country=Date, cum.deaths=value.num, date.POSIXct)]
local.csv <- sub("html$", "csv", local.html)
data.table::fwrite(count.out, local.csv)
