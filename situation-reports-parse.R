works_with_R(
  "3.6.3",
  pdftools="2.3")

report.pdf.vec <- Sys.glob("reports/*.pdf")

for(report.i in seq_along(report.pdf.vec)){
  report.pdf <- report.pdf.vec[[report.i]]
  print(report.pdf)
  ## character vector, one element per page.
  txt <- pdftools::pdf_text(report.pdf)
  report.txt <- sub("pdf$", "txt", report.pdf)
  writeLines(txt, report.txt)
  ## list of data frames, one element per page. each data frame has
  ## one row per text element.
  if(FALSE){
    dfs <- pdftools::pdf_data(report.pdf)
  }
}
