# une pdfs de portada y de cuerpo

source("libraries.R")
source("functions.R")

pdftools::pdf_combine(
  c("informe/portada.pdf", "informe/valentini_especializacion.pdf")
  ,output="informe/valentini_especializacion_final.pdf"
)