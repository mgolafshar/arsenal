#' Helper functions for \code{write2}
#' 
#' Helper functions for \code{\link{write2}}.
#' 
#' @param x An R object to coerce to class \code{"threeticks"} or such an object to print.
#' @param ... Other arguments passed to \code{print}.
#' @name write2.internal
NULL
#> NULL

#' @rdname write2.internal
#' @export
print.threeticks <- function(x, ...)
{
  cat("```\n")
  NextMethod()
  cat("\n```\n\n")
}

#' @rdname write2.internal
#' @export
as.threeticks <- function(x)
{
  class(x) <- c("threeticks", class(x))
  x
}