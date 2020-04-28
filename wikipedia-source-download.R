u <- "https://en.wikipedia.org/w/index.php?title=2019%E2%80%9320_coronavirus_pandemic_deaths&action=edit"
local.html <- file.path(
  "wikipedia-source", format(Sys.time(), "%Y-%m-%d.html"))
dir.create("wikipedia-source", showWarnings=FALSE)
if(!file.exists(local.html)){
  download.file(u, local.html)
}

tab.dt <- nc::capture_all_str(
  local.html,
  "<table",
  rest=".*")
