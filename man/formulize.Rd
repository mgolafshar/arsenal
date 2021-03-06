% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/formulize.R
\name{formulize}
\alias{formulize}
\title{formulize}
\usage{
formulize(y = "", x = "", ..., data = NULL)
}
\arguments{
\item{y, x, ...}{Character vectors to be collapsed (by \code{"+"}) and put left-to-right in the formula.
If \code{data} is supplied, these can also be numeric, denoting which column name to use. See examples.}

\item{data}{An R object with non-null column names.}
}
\description{
A shortcut to generate one-, two-, or many-sided formulas from vectors of variable names.
}
\examples{
## two-sided formula
formulize("y", c("x1", "x2", "x3"))

## one-sided formula
formulize(x = c("x1", "x2", "x3"))

## multi-sided formula
formulize("y", c("x1", "x2", "x3"), c("z1", "z2"), "w1")

## can use numerics for column names
data(mockstudy)
formulize(y = 1, x = 2:4, data = mockstudy)

## mix and match
formulize(1, c("x1", "x2", "x3"), data = mockstudy)

## get an interaction
formulize("y", c("x1*x2", "x3"))

## use in an lm
form <- formulize(2, 3:4, data = mockstudy)
summary(lm(form, data = mockstudy))

}
\seealso{
\code{\link[stats]{reformulate}}
}
\author{
Ethan Heinzen
}
