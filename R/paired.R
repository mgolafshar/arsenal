
#' Make a tableby for paired data
#'
#' @param formula an object of class \code{\link{formula}} of the form \code{time ~ var1 + ...}.
#'   See "Details" for more information.
#' @inheritParams tableby
#' @param id The vector giving IDs to match up data for the same subject across two timepoints.
#' @param na.action a function which indicates what should happen when the data contain \code{NA}s.
#'   The default is \code{na.paired}, which removes any missing time point information, but keeps everything else.
#' @param control control parameters to handle optional settings within \code{paired}.
#'   Two aspects of \code{paired} are controlled with these: test options of RHS variables and x variable summaries.
#'   Arguments for \code{paired.control} can be passed to \code{paired} via the \code{...} argument,
#'   but if a control object and \code{...} arguments are both supplied,
#'   the latter are used. See \code{\link{paired.control}} for more details.
#' @param ... additional arguments to be passed to internal \code{paired} functions or \code{\link{paired.control}}.
#' @return An object with class \code{c("paired", "tableby")}
#' @seealso \code{\link{paired.control}}, \code{\link{tableby}}, \code{\link{formulize}}
#' @author Jason Sinnwell, Beth Atkinson, Ryan Lennon, and Ethan Heinzen
#' @name paired
NULL
#> NULL

#' @rdname paired
#' @export
paired <- function(formula, data, id, na.action = na.paired, subset=NULL, control = NULL, ...) {
  control <- c(list(...), control)
  control <- do.call("paired.control", control[!duplicated(names(control))])

  Call <- match.call()

  ## Tell user if they passed an argument that was not expected, either here or in control
  expectArgs <- c("formula", "data", "na.action", "subset", "control", names(control), "id")
  match.idx <- match(names(Call)[-1], expectArgs)
  if(anyNA(match.idx)) warning("unused arguments: ", paste(names(Call)[1+which(is.na(match.idx))], collapse=", "), "\n")

  indx <- match(c("formula", "data", "subset", "na.action", "id"), names(Call), nomatch = 0)
  if(indx[1] == 0) stop("A formula argument is required")
  if(length(formula) != 3) stop("'formula' must be two-sided.")
  if(indx[5] == 0) stop("An id argument is required")

  temp.call <- Call[c(1, indx)]
  temp.call[[1]] <- as.name("model.frame")

  if(is.null(temp.call$na.action)) temp.call$na.action <- na.paired

  special <- c("paired.t", "mcnemar", "signed.rank", "sign.test")
  if (missing(data)) {
    temp.call$formula <- stats::terms(formula, special)
  } else {
    # instead of call("keep.labels", ...), which breaks when arsenal isn't loaded (Can't find "keep.labels")
    temp.call$data <- as.call(list(keep.labels, temp.call$data))
    temp.call$formula <- stats::terms(formula, special, data = keep.labels(data))
  }
  tabenv <- new.env(parent = environment(formula))
  tmp.fun <- function(x, ...) set_attr(set_attr(x, "name", deparse(substitute(x))), "stats", list(...))
  for(sp in special)
  {
    if(!is.null(attr(temp.call$formula, "specials")[[sp]])) assign(sp, tmp.fun, envir = tabenv)
  }
  environment(temp.call$formula) <- tabenv

  modeldf <- eval.parent(temp.call)
  if (nrow(modeldf) == 0) stop("No (non-missing) observations")
  Terms <- stats::terms(modeldf)

  ## find which columnss of modeldf have specials assigned to known specials
  specialIndices <- unlist(attr(Terms, "specials"))
  specialTests <- rep("", ncol(modeldf))
  ## If a special shows up multiple times, the unlist assigned a number at the end. Strip it off.
  ## This disallows functions with a number at the end
  specialTests[specialIndices] <- gsub("\\d+$", "", names(specialIndices))

  ## list of x variables
  xList <- list()

  ## fix of droplevels on by factor suggested by Ethan Heinzen 4/12/2016
  by.col <- modeldf[[1]]
  if(is.factor(by.col)) {
    by.col <- droplevels(by.col)
    by.levels <- levels(by.col)
  } else by.levels <- sort(unique(by.col))

  if(length(by.levels) != 2) stop("Please specify exactly 2 time points")
  ids <- modeldf$`(id)`
  tab <- table(ids, by.col)
  if(sum(tab > 1) > 0)
    stop("At least one person has multiple observations for at least one time point")
  if(sum(rowSums(tab) == 2) == 0)
    stop("No one appears to have data on both time points")

  ids.both <- intersect(ids[by.col == by.levels[1]], ids[by.col == by.levels[2]])

  TP1 <- modeldf[by.col == by.levels[1], , drop = FALSE]
  TP2 <- modeldf[by.col == by.levels[2], , drop = FALSE]

  cn <- colnames(modeldf)
  cn <- cn[cn != "(id)"]

  TP1 <- TP1[match(ids.both, TP1$`(id)`, nomatch = 0), cn, drop = FALSE]
  TP2 <- TP2[match(ids.both, TP2$`(id)`, nomatch = 0), cn, drop = FALSE]
  modeldf <- modeldf[, cn, drop = FALSE]

  ## fix of droplevels on by factor suggested by Ethan Heinzen 4/12/2016
  by.col <- modeldf[[1]]
  if(is.factor(by.col)) {
    by.col <- droplevels(by.col)
    by.levels <- levels(by.col)
  } else by.levels <- sort(unique(by.col))

  for(eff in 2:ncol(modeldf)) {

    currcol <- modeldf[[eff]]

    ## label
    nameEff <- attributes(currcol)$name
    if(is.null(nameEff))  nameEff <- names(modeldf)[eff]
    labelEff <-  attributes(currcol)$label
    if(is.null(labelEff))  labelEff <- nameEff
    statList <- list()
    bystatlist <- list()

    ############################################################
    if(is.ordered(currcol) || is.logical(currcol) || is.factor(currcol) || is.character(currcol)) {
      ######## ordinal or categorical variable (character or factor) ###############

      ## convert logicals and characters to factor
      if(is.character(currcol))
      {
        lvl <- sort(unique(currcol[!is.na(currcol)]))
        currcol <- factor(currcol, levels = lvl)
        TP1[[eff]] <- factor(TP1[[eff]], levels = lvl)
        TP2[[eff]] <- factor(TP2[[eff]], levels = lvl)
      } else if(is.logical(currcol))
      {
        lvl <- c(FALSE, TRUE)
        currcol <- factor(currcol, levels=lvl)
        TP1[[eff]] <- factor(TP1[[eff]], levels = lvl)
        TP2[[eff]] <- factor(TP2[[eff]], levels = lvl)
      }

      ## to make sure all levels of cat variable are counted, need to pass values along
      xlevels <- levels(currcol)

      if(length(xlevels) == 0)
      {
        warning(paste0("Zero-length levels found for ", nameEff))
        next
      }

      ## get stats funs from either formula  or control
      if(is.ordered(currcol))
      {
        currstats <-  control$ordered.stats
        currtest <- control$ordered.test
        vartype <- "ordinal"
      } else
      {
        currstats <- control$cat.stats
        currtest <- control$cat.test
        vartype <- "categorical"
      }

    } else if(is.Date(currcol)) {
      ######## Date variable ###############
      xlevels <- NULL

      ## get stats funs from either formula  or control
      currstats <- control$date.stats
      currtest <- control$date.test
      vartype <- "Date"

    } else if(survival::is.Surv(currcol)) {
      ##### Survival (time to event) #######
      warning("Sorry, survival objects don't work in this function.")
      next

    } else if(is.numeric(currcol) || inherits(currcol, "difftime")) {
      ######## Continuous variable (numeric) ###############
      xlevels <- NULL

      ## for difftime, convert to numeric
      if(inherits(currcol, "difftime")) currcol <- as.numeric(currcol)

      ## if no missings, and control says not to show missings,
      ## remove Nmiss stat fun
      currstats <- control$numeric.stats
      currtest <- control$numeric.test
      vartype <- "numeric"
    }
    ############################################################

    ## if no missings, and control says not to show missings,
    ## remove Nmiss stat fun
    currstats <- if(length(attributes(currcol)$stats)>0) attributes(currcol)$stats else currstats
    if(!anyNA(currcol) && "Nmiss" %in% currstats) currstats <- currstats[currstats != "Nmiss"]
    for(statfun in currstats) {
      if(statfun == "countrowpct")
      {
        bystatlist <- do.call(statfun, list(currcol, levels = xlevels,
                                            by = by.col, by.levels = by.levels, na.rm = TRUE))
        bystatlist$Total <- NULL
      } else
      {
        for(bylev in by.levels) {
          idx <- by.col == bylev
          bystatlist[[as.character(bylev)]] <- do.call(statfun, list(currcol[idx], levels=xlevels, na.rm=TRUE, ...))
        }
      }
      if(statfun %in% c("countpct", "countrowpct"))
      {
        bystatlist$Difference <- countrowpct(TP1[[eff]], levels = xlevels, by = TP1[[eff]] == TP2[[eff]],
                                             by.levels = c(TRUE, FALSE), na.rm = TRUE)[[1]]
      } else if(statfun == "count")
      {
        bystatlist$Difference <- count(ifelse(TP1[[eff]] == TP2[[eff]], TP1[[eff]], NA), levels = xlevels, na.rm = TRUE)
      } else
      {
        bystatlist$Difference <- do.call(statfun, list(as.numeric(TP2[[eff]]) - as.numeric(TP1[[eff]]),
                                                       levels=xlevels, na.rm=TRUE, ...))
      }
      statList[[statfun]] <- bystatlist
    }

    currtest <- if(nchar(specialTests[eff]) > 0) specialTests[eff] else currtest
    testout <- if(control$test) {
      eval(call(currtest, TP1[[eff]], TP2[[eff]], mcnemar.correct=control$mcnemar.correct,
                signed.rank.exact = control$signed.rank.exact, signed.rank.correct = control$signed.rank.correct))
    } else NULL

    xList[[nameEff]] <- list(stats=statList, test=testout, label=labelEff, name=names(modeldf)[eff], type=vartype)
  }


  if(length(xList) == 0) stop("No x-variables successfully computed.")

  labelBy <- attributes(by.col)$label
  if(is.null(labelBy)) labelBy <- names(modeldf)[1]

  yList <- list()
  yList[[names(modeldf)[1]]] <- list(stats=c(unlist(table(factor(by.col, levels=by.levels), exclude=NA)), Difference=length(ids.both)),
                                     label=labelBy, name=names(modeldf)[1])

  structure(list(y = yList, x = xList, control = control, Call = match.call(), weights=FALSE), class = c("paired", "tableby"))
}

#' @rdname paired
#' @export
print.paired <- function(x, ...)
{
  cat("Paired ")
  NextMethod()
  invisible(x)
}

