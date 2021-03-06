% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/worldPlot.R
\name{worldPlot}
\alias{worldPlot}
\title{Plot global data}
\usage{
worldPlot(x, dates = unique(x$time), splitPacific = TRUE,
  capMinMax = TRUE, verbose = FALSE)
}
\arguments{
\item{x}{A \code{\link{cmip5data}} object}

\item{dates}{numeric. Which date value(s) should we plot?}

\item{splitPacific}{logical. Try to split image in the Pacific?}

\item{capMinMax}{logical. Cap data min and max by quantile? This may produce better coloring.}

\item{verbose}{logical. Print info as we go?}
}
\value{
A \code{ggplot} object.
}
\description{
Plot a quick world map with reasonable coloring.
}
\details{
Uses \code{ggplot2::geom_raster}.
}
\examples{
d <- cmip5data(1970:1975)   # sample data
worldPlot(d)
}

