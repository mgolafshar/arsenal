% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/write2specific.R
\name{write2specific}
\alias{write2specific}
\alias{write2word}
\alias{write2pdf}
\alias{write2html}
\title{write2word, write2html, write2pdf}
\usage{
write2word(object, file, ...)

write2pdf(object, file, ...)

write2html(object, file, ...)
}
\arguments{
\item{object}{An object.}

\item{file}{A single character string denoting the filename for the output document.}

\item{...}{Additional arguments to be passed to \code{FUN}, \code{rmarkdown::render}, etc.
One popular option is to use \code{quiet = TRUE} to suppress the command line output.}
}
\value{
\code{object} is returned invisibly, and \code{file} is written.
}
\description{
Functions to output tables to a single Word, HTML, or PDF document.
}
\details{
To generate the appropriate file type, the \code{write2*} functions use one of \code{rmarkdown::word_document}, \code{rmarkdown::html_document},
   and \code{rmarkdown::pdf_document} to get the job done. \code{"..."} arguments are passed to these functions, too.
}
\examples{
\dontrun{
data(mockstudy)
# tableby example
tab1 <- tableby(arm ~ sex + age, data=mockstudy)
write2html(tab1, "~/trash.html")

# freqlist example
tab.ex <- table(mockstudy[, c("arm", "sex", "mdquality.s")], useNA = "ifany")
noby <- freqlist(tab.ex, na.options = "include")
write2pdf(noby, "~/trash2.pdf")

# A more complicated example
write2word(tab1, "~/trash.doc",
  keep.md = TRUE,
  reference_docx = mystyles.docx, # passed to rmarkdown::word_document
  quiet = TRUE, # passed to rmarkdown::render
  title = "My cool new title") # passed to summary.tableby
}
}
\seealso{
\code{\link{write2}}
}
\author{
Ethan Heinzen, adapted from code from Krista Goergen
}
