u <- paste0(
  "https://en.wikipedia.org/wiki/",
  "List_of_countries_and_dependencies_by_population")
local.html <- file.path(
  "population", format(Sys.time(), "%Y-%m-%d.html"))
dir.create("population", showWarnings=FALSE)
if(!file.exists(local.html)){
  download.file(u, local.html)
}

webpage <- xml2::read_html(local.html)
tbls <- rvest::html_nodes(webpage, "table")
tbl.list <- rvest::html_table(tbls, fill=TRUE)

country.vec <- c(
  "United States"="USA")
pop.dt <- data.table(tbl.list[[1]])
pop.dt[, country.orig := sub("\\[.*", "", `Country (or dependent territory)`)]
pop.dt[, country := ifelse(
  country.orig %in% names(country.vec),
  country.vec[country.orig],
  country.orig)]
#we need as.numeric because world pop is greater than max int.
pop.dt[, population := as.numeric(gsub(",", "", Population))]
pop.dt[is.na(population)]
country.dt <- data.table(
  country=c("China", "India", "USA", "France", "Canada", "Japan", "Brazil"))
pop.dt[country.dt, on="country"]

fwrite(pop.dt[, .(country, population)], "population-download.csv")

