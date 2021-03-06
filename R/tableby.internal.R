
get_attr <- function(x, which, default)
{
  x <- attr(x, which, exact = TRUE)
  if(is.null(x)) default else x
}

#' @export
format.tbstat <- function(x, digits = NULL, ...)
{
  x <- x[] # to remove classes
  if(is.numeric(x)) x <- trimws(formatC(x, digits = digits, format = "f"))
  if(length(x) == 1) return(paste0(x))

  parens <- get_attr(x, "parens", c("", ""))
  sep <- get_attr(x, "sep", " ")
  sep2 <- get_attr(x, "sep2", " ")
  pct <- get_attr(x, "pct", "")
  if(length(x) == 2)
  {
    paste0(x[1], sep, parens[1], x[2], pct, parens[2])
  } else paste0(x[1], sep, parens[1], x[2], sep2, x[3], parens[2])
}

#' @export
format.tbstat_countpct <- function(x, digits.count = NULL, digits.pct = NULL, ...)
{
  att <- attributes(x)
  x <- if(length(x) == 2)
  {
    c(formatC(x[1], digits = digits.count, format = "f"), formatC(x[2], digits = digits.pct, format = "f"))
  } else formatC(x[1], digits = digits.count, format = "f")
  attributes(x) <- att
  NextMethod("format")
}

#' Internal \code{tableby} functions
#'
#' A collection of functions that may help users create custom functions that are formatted correctly.
#' @param x Usually a vector.
#' @param oldClass class(es) to add to the resulting object.
#' @param sep The separator between \code{x[1]} and the rest of the vector.
#' @param parens A length-2 vector denoting parentheses to use around \code{x[2]} and \code{x[3]}.
#' @param sep2 The separator between \code{x[2]} and \code{x[3]}.
#' @param pct The symbol to use after percents.
#' @param ... arguments to pass to \code{as.tbstat}.
#' @details
#'   \code{as.tbstat} defines a tableby statistic with its appropriate formatting.
#'
#'   \code{as.countpct} adds another class to \code{as.tbstat} to use different "digits" arguments. See \code{\link{tableby.control}}.
#'
#'   \code{as.tbstat_multirow} marks an object (usually a list) for multiple-row printing.
#' @name tableby.stats.internal
NULL
#> NULL

#' @rdname tableby.stats.internal
#' @export
as.tbstat <- function(x, oldClass = NULL, sep = NULL, parens = NULL, sep2 = NULL, pct = NULL)
{
  structure(x, class = c("tbstat", oldClass),
            sep = sep, parens = parens, sep2 = sep2, pct = pct)
}

#' @rdname tableby.stats.internal
#' @export
as.countpct <- function(x, ...)
{
  tmp <- as.tbstat(x, ...)
  class(tmp) <- c("tbstat_countpct", class(tmp))
  tmp
}

#' @rdname tableby.stats.internal
#' @export
as.tbstat_multirow <- function(x)
{
  class(x) <- c("tbstat_multirow", class(x))
  x
}

extract_tbstat <- function(x, ...)
{
  x <- NextMethod("[")
  class(x) <- class(x)[class(x) %nin% c("tbstat", "tbstat_countpct", "tbstat_multirow")]
  x
}

extract2_tbstat <- function(x, ...)
{
  x <- NextMethod("[[")
  class(x) <- class(x)[class(x) %nin% c("tbstat", "tbstat_countpct", "tbstat_multirow")]
  x
}

#' @export
`[.tbstat` <- extract_tbstat
#' @export
`[.tbstat_countpct` <- extract_tbstat
#' @export
`[.tbstat_multirow` <- extract_tbstat
#' @export
`[[.tbstat` <- extract2_tbstat
#' @export
`[[.tbstat_countpct` <- extract2_tbstat
#' @export
`[[.tbsta_multirowt` <- extract2_tbstat


## merge two tableby objects
## both must have same "by" variable and levels
## if some RHS variables have same names, keep both, the one in y add ".y"

#' Helper functions for tableby
#'
#' A set of helper functions for \code{\link{tableby}}.
#'
#' @param object A \code{data.frame} resulting from evaluating a \code{tableby} formula.
#' @param ... Other arguments, or a vector of indices for extracting.
#' @param x,y A \code{tableby} object.
#' @param i A vector to index \code{x} with: either names of variables, a numeric vector, or a logical vector of appropriate length.
#' @param value A list of new labels.
#' @param pdata A named data.frame where the first column is the x variable names matched by name, the second is the
#'   p-values (or some test stat), and the third column is the method name (optional)
#' @param e1,e2 \code{\link{tableby}} objects, or numbers to compare them to.
#' @param use.pname Logical, denoting whether the column name in \code{pdata} corresponding to the p-values should be used
#'   in the output of the object.
#' @return \code{na.tableby} returns a subsetted version of \code{object} (with attributes). \code{Ops.tableby} returns
#'   a logical vector. \code{xtfrm.tableby} returns the p-values (which are ordered by \code{\link{order}} to \code{\link{sort}}).
#' @details
#' Logical comparisons are implemented for \code{Ops.tableby}.
#'
#' \code{xtfrm.tableby} also allows the use of \code{\link{order}} and \code{\link{sort}}.
#'
#' \code{length.tableby} also allows for the use of \code{\link[utils]{head}} and \code{\link[utils]{tail}}.
#' @name tableby.internal
NULL
#> NULL

#' @rdname tableby.internal
#' @export
merge.tableby <- function(x, y, ...) {

  if(names(x$y) != names(y$y)) {
    stop("tableby objects cannot be merged unless same 'by' variable name).\n")
  }
  if(!all(names(x$y[[1]]$stats) == names(y$y[[1]]$stats))){
    stop("tableby objects cannot be merged unless same 'by' variable categories.\n")
  }
  newobj <- x
  y$y[[1]]$label <- paste0(y$y[[1]]$label, ".2")
  newobj$y[[paste0(names(y$y)[[1]],".2")]] <- y$y[[1]]
  for(xname in names(y$x)) {
    thisname <- xname
    ## if name already present, add "2" to name and add on
    if(xname %in% names(newobj$x)) {
      thisname <- paste0(xname, ".2")
      y$x[[xname]]$label <- paste0(y$x[[xname]]$label, ".2")
    }
    newobj$x[[thisname]] <- y$x[[xname]]
  }

  ## add on call and control from y
  newobj$Call2 <- y$Call
  newobj$control2 <- y$control

  return(newobj)
}

## pdata is a named data.frame where the first column is the x variable names matched by name,
## p-values (or some test stat) are numbers and the name is matched
## method name is the third column (optional)
## to the x variable in the tableby object (x)

#' @rdname tableby.internal
#' @export
modpval.tableby <- function(x, pdata, use.pname=FALSE) {
  ## set control$test to TRUE
  if(any(pdata[,1] %in% names(x$x))) {
    x$control$test <- TRUE

    ## change test results
    for(k in 1:nrow(pdata)) {
      xname <- pdata[k,1]
      idx <- which(names(x$x)==xname)
      if(length(idx)==1) {
        x$x[[idx]]$test$p.value <- pdata[k,2]
        if(ncol(pdata)>2) {
          x$x[[idx]]$test$method <- pdata[k,3]
        } else {
          x$x[[idx]]$test$method <- "modified by user"
        }
      }
    }
    if(use.pname & nchar(names(pdata)[2])>0) {
      ## put different test column name in control
      x$control$test.pname <- names(pdata)[2]
    }
  }
  return(x)
}

## Get the labels from the tableby object's elements in the order they appear in the fomula/Call
## including the y and x variables
# labels <- function(x) {
#   UseMethod("labels")
# }

## retrieve variable labels (y, x-vec) from tableby object

#' @rdname tableby.internal
#' @export
labels.tableby <- function(object, ...) {
  ##  get the formal labels from a tableby object's data variables
  allLabels <- c(sapply(object$y, function(obj) obj$label), sapply(object$x, function(obj) obj$label))
  names(allLabels) <- c(names(object$y), names(object$x))
  return(allLabels)
}

## define generic function for tests, so tests(tbObj) will work

#' @rdname tableby.internal
#' @export
tests <- function(x) {
  UseMethod("tests")
}

## retrieve the names of the tests performed per variable

#' @rdname tableby.internal
#' @export
tests.tableby <- function(x) {
  if(x$control$test) {
    testdf <- data.frame(
      Variable = labels(x)[-1],
      p.value = vapply(x$x, function(z) z$test$p.value, NA_real_),
      Method = vapply(x$x, function(z) z$test$method, NA_character_),
      stringsAsFactors = FALSE
    )
    if(!is.null(x$control$test.pname)) {
      names(testdf)[2] <- x$control$test.pname
    }
  } else {
    testdf <- cat("No tests run on tableby object\n")
  }
  return(testdf)
}


## assign labels to tableby object

#' @rdname tableby.internal
#' @export
'labels<-.tableby' <- function(x, value) {
  ## if the value vector is named, then assign the labels to
  ## those names that match those in x and y
  if(is.list(value)) value <- unlist(value)
  if(is.null(value))
  {
    x$y[[1]]$label <- x$y[[1]]$name
    for(k in seq_along(x$x)) x$x[[k]]$label <- x$x[[k]]$name
  } else if(!is.null(names(value))) {
    vNames <- names(value)
    objNames <- c(names(x$y), names(x$x))
    v2objIndex <- match(vNames, objNames)
    if(anyNA(v2objIndex))
    {
      idx <- is.na(v2objIndex)
      warning("Named value(s) not matched in x: ", paste(vNames[idx],collapse=","), "\n")
      value <- value[!idx]
      v2objIndex <- v2objIndex[!idx]
    }

    ## handle y label first, then remove it
    if(any(v2objIndex == 1)) {
      x$y[[1]]$label <- value[v2objIndex == 1]
      value <- value[v2objIndex != 1]
      v2objIndex <- v2objIndex[v2objIndex != 1]
    }
    if(length(v2objIndex) > 0) {
      ## prepare to iterate over the rest for x, if there are any
      v2objIndex <- v2objIndex - 1
      for(k in seq_along(v2objIndex)) x$x[[v2objIndex[k]]]$label <- value[k]
    }
  } else  {

    ## Otherwise, assign in the order of how variables appear in formula, starting with y
    ## check that length of value matches what is expected for x
    ## for each of the RHS vars of x (1:length(x)-3),
    ##assign strings in value to the 'label' element of the list for each RHS variable

    if(length(value) != length(x$y) + length(x$x)) {
      stop("Length of new labels is not the same length as there are variables in the formula.\n")
    }
    x$y[[1]]$label <- value[1]
    for(k in seq_along(x$x)) {
      x$x[[k]]$label <- value[k+1]
    }
  }
  return(x)
}

## subset a tableby object;
## syntax of usage: newtb <- tbObj[1:2]
## x here is the tableby object
## index is in '...', and allows only 1 vector of integer indices
## in future, maybe allow subsetting by names

#' @rdname tableby.internal
#' @export
"[.tableby" <- function(x, i) {
  if(missing(i)) return(x)
  newx <- x

  if(is.character(i) && any(i %nin% names(x$x)))
  {
    tmp <- paste0(i[i %nin% names(x$x)], collapse = ", ")
    warning(paste0("Some indices not found in tableby object: ", tmp))
    i <- i[i %in% names(x$x)]
  } else if(is.numeric(i) && any(i %nin% seq_along(x$x)))
  {
    tmp <- paste0(i[i %nin% seq_along(x$x)], collapse = ", ")
    warning(paste0("Some indices not found in tableby object: ", tmp))
    i <- i[i %in% seq_along(x$x)]
  } else if(is.logical(i) && length(i) != length(x$x))
  {
    stop("Logical vector index not the right length.")
  }

  if(length(i) == 0 || anyNA(i)) stop("Indices must have nonzero length and no NAs.")

  newx$x <- x$x[i]
  return(newx)
}



## function to handle na.action for tableby formula, data.frame

#' @rdname tableby.internal
#' @export
na.tableby <- function(object, ...) {
    omit <- is.na(object[[1]])
    xx <- object[!omit, , drop = FALSE]
    if(any(omit)) {
        temp <- stats::setNames(seq_along(omit)[omit], attr(object, "row.names")[omit])
        attr(temp, "class") <- "omit"
        attr(xx, "na.action") <- temp
    }
    xx
}


#' @rdname tableby.internal
#' @export
xtfrm.tableby <- function(x)
{
  if(!x$control$test) stop("Can't extract p-values from a tableby object created with test=FALSE.")
  vapply(x$x, function(lst) lst$test$p.value, NA_real_)
}

#' @rdname tableby.internal
#' @export
Ops.tableby <- function(e1, e2)
{
  ok <- switch(.Generic, `<` = , `>` = , `<=` = , `>=` = , `==` = , `!=` = TRUE, FALSE)
  if(!ok) stop("'", .Generic, "' is not meaningful for tableby objects")

  if(inherits(e1, "tableby")) e1 <- xtfrm(e1)
  if(inherits(e2, "tableby")) e2 <- xtfrm(e2)
  get(.Generic, mode = "function")(e1, e2)
}

#' @rdname tableby.internal
#' @export
length.tableby <- function(x) length(x$x)
