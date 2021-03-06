% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/makeZStat.R
\name{makeZStat}
\alias{makeZStat}
\title{Compute Z-dimension statistic of a variable}
\usage{
makeZStat(x, verbose = FALSE, sortData = FALSE, FUN = mean, ...)
}
\arguments{
\item{x}{A \code{\link{cmip5data}} object}

\item{verbose}{logical. Print info as we go?}

\item{sortData}{logical. Sort \code{x} and \code{area} before computing?}

\item{FUN}{function. Function to apply across Zs}

\item{...}{Other arguments passed on to \code{FUN}}
}
\value{
A \code{\link{cmip5data}} object, whose \code{val} field is the mean of the
variable across Zs A \code{numZs} field is also added
recording the number of Z values averaged for each year, and x's original
Z field is removed.
}
\description{
Some CMIP5 data are four-dimensional: in addition to longitude, latitude,
and time, they include a Z dimension (typically encoded in the NetCDF file as
'depth' or 'lev'). This function computes a summary statistic for all Z values.
The default statistic is \link{mean}, but any summary
function that returns a numeric result (including weighted.mean, if you
want to apply weights) can be used.
}
\note{
If \code{x} is not in a needed order (for example, \code{FUN} uses
weights in a different order), be sure to specify \code{sortData=TRUE}.
}
\examples{
d <- cmip5data(1970:1975, Z=TRUE)   # sample data
makeZStat(d)
summary(makeZStat(d, FUN=sd))
}
\seealso{
\code{\link{makeAnnualStat}} \code{\link{makeGlobalStat}} \code{\link{makeMonthlyStat}}
}

