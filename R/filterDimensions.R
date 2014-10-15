#' Filter dimensions, limiting to arbitrary lon/lat/Z/time
#'
#' We frequently want to filter CMIP5 data according to some predetermined
#' criteria: only high-latitude cells, for example, or certain years, months,
#' Zs, etc. This function provides convenient one-stop service
#' for such filtering.
#' 
#' @param x A \code{\link{cmip5data}} object
#' @param lons numeric vector. Longitudes to filter
#' @param lats numeric vector. Latitudes to filter
#' @param Zs numeric vector. Z values to filter
#' @param years numeric vector
#' @param months numeric vector
#' @param verbose logical. Print info as we go?
#' @return The filtered \code{\link{cmip5data}} object.
#' @note If a filter is requested but no relevant data are present,
#' a \code{\link{warning}} will be produced.
#' @examples
#' d <- cmip5data(1970:2014)   # sample data
#' filterDimensions(d, years=1980:1985)
#' filterDimensions(d, months=6:8)  # summer
#' filterDimensions(d, lats=d$lat[abs(d$lat)<20])  # the tropics
#' @export
filterDimensions <- function(x, lons=NULL, lats=NULL, Zs=NULL,
                             years=NULL, months=NULL, verbose=FALSE) {
    
    # Sanity checks
    stopifnot(class(x)=="cmip5data")
    stopifnot(length(verbose)==1 & is.logical(verbose))
    
    # The ordering of x$val dimensions is lon-lat-Z?-time?
    # Anything else is not valid.
    timeIndex <- length(dim(x$val))
    stopifnot(timeIndex == 4) # that's all we know
    
    x <- filterDimensionLon(x, lons, verbose)
    x <- filterDimensionLat(x, lats, verbose)
    x <- filterDimensionZ(x, Zs, verbose)
    x <- filterDimensionTimeYears(x, years, verbose)
    x <- filterDimensionTimeMonths(x, months, verbose)
    
    if(timeIndex != length(dim(x$val)) | 0 %in% dim(x$val)) {
        warning("Dropped one or more dimensions (i.e. no data matched criteria). This is probably not what you want.")    
    }
    
    x
} # filterDimensions

#' Filter longitude dimension.
#'
#' @param x cmip5data A \code{\link{cmip5data}} object.
#' @param lons numeric vector. Longitudes to filter (in).
#' @param verbose logical. Print info as we go?
#' @return A \code{\link{cmip5data}} object.
#' @note This is an internal RCMIP5 function and not exported.
#' @keywords internal
filterDimensionLon <- function(x, lons=NULL, verbose=FALSE) {
    
    # Sanity check
    stopifnot(is.null(lons) | class(lons) %in% c("numeric", "integer", "array"))
    
    # Filter longitude dimension
    if(!is.null(lons)) {
        if(is.null(x[["lon"]])) {
            warning("No lon data found")
        } else {
            x$val <- asub(x$val, x$lon %in% lons, 1, drop=F)
            x$lon <- x$lon[x$lon %in% lons]
            x <- addProvenance(x, paste("Filtered for lons in range [",
                                        paste(range(lons), collapse=', '), "]"))
            x$filtered <- TRUE
            if(verbose) cat("Filtered by lon, dim =", dim(x$val), "\n")
        }
    }
    x
} # filterDimensionLon

#' Filter latitude dimension.
#'
#' @param x cmip5data A \code{\link{cmip5data}} object.
#' @param lats numeric vector. Latitudes to filter (in).
#' @param verbose logical. Print info as we go?
#' @return A \code{\link{cmip5data}} object.
#' @note This is an internal RCMIP5 function and not exported.
#' @keywords internal
filterDimensionLat <- function(x, lats=NULL, verbose=FALSE) {
    
    # Sanity check
    stopifnot(is.null(lats) | class(lats) %in% c("numeric", "integer", "array"))
    
    # Filter latitude dimension
    if(!is.null(lats)) {
        if(is.null(x[["lat"]])) {
            warning("No lat data found")
        } else {
            x$val <- asub(x$val, x$lat %in% lats, 2, drop=F)
            x$lat <- x$lat[x$lat %in% lats]
            x <- addProvenance(x, paste("Filtered for lats in range [",
                                        paste(range(lats), collapse=', '), "]"))
            x$filtered <- TRUE
            if(verbose) cat("Filtered by lat, dim =", dim(x$val), "\n")
        }
    }
    x
} # filterDimensionLat

#' Filter Z dimension.
#'
#' @param x cmip5data A \code{\link{cmip5data}} object.
#' @param Zs numeric vector. Z values to filter.
#' @param verbose logical. Print info as we go?
#' @return A \code{\link{cmip5data}} object.
#' @note This is an internal RCMIP5 function and not exported.
#' @keywords internal
filterDimensionZ <- function(x, Zs=NULL, verbose=FALSE) {
    
    # Sanity checks
    stopifnot(is.null(Zs) | class(Zs) %in% c("numeric", "integer", "array"))
    
    # Filter Z dimension
    ndim <- length(dim(x$val))
    if(!is.null(Zs)) {
        if(is.null(x[["Z"]])) {
            warning("No Z data found")
        } else {
            stopifnot(length(x$Z) == dim(x$val)[3]) # Sanity check
            
            x$val <- asub(x$val, x$Z %in% Zs, ndim-1, drop=F)
            x$Z <- x$Z[x$Z %in% Zs]
            x <- addProvenance(x, paste("Filtered for Zs in range [",
                                        paste(range(Zs), collapse=', '), "]"))
            x$filtered <- TRUE
            if(verbose) cat("Filtered by Z, dim =", dim(x$val), "\n")
        }
    }
    x
} # filterDimensionZ

#' Filter time (years) dimension.
#'
#' @param x cmip5data A \code{\link{cmip5data}} object.
#' @param years numeric vector
#' @param verbose logical. Print info as we go?
#' @return A \code{\link{cmip5data}} object.
#' @note This is an internal RCMIP5 function and not exported.
#' @keywords internal
filterDimensionTimeYears <- function(x, years=NULL, verbose=FALSE) {
    
    # Sanity checks
    stopifnot(is.null(years) | class(years) %in% c("numeric", "integer", "array"))
    
    # Filter time (years) dimension
    ndim <- length(dim(x$val))
    if(!is.null(years)) {
        if(is.null(x[["time"]])) {
            warning("No time data found")
        } else {
            years <- unique(floor(years)) # no fractional or duplicate years allowed
            x$val <- asub(x$val, floor(x$time) %in% years, ndim, drop=F)
            x$time <- x$time[floor(x$time) %in% years]
            x <- addProvenance(x, paste("Filtered for years in range [",
                                        paste(range(years), collapse=', '), "]"))
            x$filtered <- TRUE
            if(verbose) cat("Filtered by year, dim =", dim(x$val), "\n")
        }
    }
    x
} # filterDimensionTimeYears

#' Filter time (months) dimension.
#'
#' @param x cmip5data A \code{\link{cmip5data}} object.
#' @param months numeric vector
#' @param verbose logical. Print info as we go?
#' @return A \code{\link{cmip5data}} object.
#' @note This is an internal RCMIP5 function and not exported.
#' @keywords internal
filterDimensionTimeMonths <- function(x, months=NULL, verbose=FALSE) {
    
    # Sanity checks
    stopifnot(is.null(months) | class(months) %in% c("numeric", "integer", "array"))
    stopifnot(months %in% 1:12)
    
    # Filter time (months) dimension
    ndim <- length(dim(x$val))
    if(!is.null(months)) {
        if(is.null(x[["time"]])) {
            warning("No time data found")
        } else if(x$debug$timeFreqStr != "mon") {
            warning("A monthly filter can only be applied to monthly data")            
        }
        else {
            fracmonths <- round((months-0.5) / 12, 2) # From Jan=1, Feb=2 to Jan 15=0.042, Feb15=0.123, etc.
            monthfilter <- round(x$time %% 1, 2) %in% fracmonths
            x$val <- asub(x$val, monthfilter, ndim, drop=F)
            x$time <- x$time[monthfilter]
            x <- addProvenance(x, paste("Filtered for months in range [",
                                        paste(range(months), collapse=', '), "]"))
            x$filtered <- TRUE
            if(verbose) cat("Filtered by month, dim =", dim(x$val), "\n")
        }
    }
    x
} # filterDimensionTimeMonths