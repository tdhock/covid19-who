works_with_R(
  "3.6.3",
  nc="2020.3.25")

prefix <- "https://www.who.int"
reports.url <- paste0(
  prefix,
  "/emergencies/diseases/novel-coronavirus-2019/situation-reports")
dir.create("list-pages", showWarnings = FALSE)
local.html <- file.path("list-pages", format(Sys.time(), "%Y-%m-%d.html"))
if(!file.exists(local.html)){
  download.file(reports.url, local.html)
}

## test subject.
two.html <- "<p><a href=\"/docs/default-source/coronaviruse/situation-reports/20200122-sitrep-2-2019-ncov.pdf?sfvrsn=4d5bcbca_2\" target=\"_blank\"><strong>Situation report - 2</strong></a><br />Novel Coronavirus (2019-nCoV)<br />22 January 2020</p><p><a href=\"/docs/default-source/coronaviruse/situation-reports/20200121-sitrep-1-2019-ncov.pdf?sfvrsn=20a99c10_4\" target=\"_blank\"><strong>Situation report - 1</strong></a><br />Novel Coronavirus (2019-nCoV)<br />21 January 2020</p><p>&nbsp;</p></div>"

href.dt <- nc::capture_all_str(
  local.html,
  nc::field("href", '="', ".*?pdf"),
  rest='[?].*?',
  '".*?>',
  text=".*?",
  "</a>")

only.hrefs <- unique(href.dt[, .(href)])
dir.create("reports", showWarnings=FALSE)
only.hrefs[, file.pdf := file.path("reports", basename(href))]
new.dt <- only.hrefs[!file.exists(file.pdf)]
if(nrow(new.dt)){
  new.dt[, {
    u <- paste0(prefix, href)
    print(u)
    download.file(u, file.pdf)
  }, by=href]
}
