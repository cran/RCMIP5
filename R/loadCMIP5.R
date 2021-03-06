#' Load CMIP5 data
#'
#' Loads CMIP5 data from disk. \code{loadCMIP5} will return a unique model ensemble,
#' or will apply a function across all ensemble members of a
#' specified experiment-variable-model combination.
#'
#' @param variable CMIP5 variable to load (required)
#' @param model CMIP5 model to load (required)
#' @param experiment CMIP5 experiment to load (required)
#' @param ensemble optional CMIP5 ensemble to load
#' @param domain optional CMIP5 domain to load
#' @param path root of directory tree
#' @param recursive logical. Should we recurse into directories?
#' @param verbose logical. Print info as we go?
#' @param force.ncdf Force use of the less-desirable ncdf package for testing?
#' @param FUN function. Function (mean, min, max, or sum) to apply across ensembles
#' @param yearRange numeric of length 2. If supplied, load only years of data in this range
#' @param ZRange numeric of length 2. If supplied, load only Z data within this range.
#' @param loadAs a string identifying possible structures for values. Currently: 'data.frame' and 'array' the only valid options.
#' @return A \code{\link{cmip5data}} object, or \code{NULL} if nothing loaded
#' @note The \code{yearRange} parameter is intended to help users deal with large
#' CMIP5 data files on memory-limited machines, e.g. by allowing them to process
#' smaller chunks of such files.
#' @note FUN is limited to min, max, sum, and mean (the default), because the
#' memory costs of keeping all ensembles in memory is too high. Be warned that
#' min and max are quite slow!
#' @examples
#' \dontrun{
#' loadCMIP5(experiment='rcp85', variable='prc', model='GFDL-CM3', ensemble='r1i1p1')
#' }
#' @export
loadCMIP5 <- function(variable, model, experiment, ensemble='[^_]+', domain='[^_]+',
                      path='.', recursive=TRUE, verbose=FALSE, force.ncdf=FALSE,
                      FUN=mean, yearRange=NULL, ZRange=NULL, loadAs='data.frame') {
    
    # Sanity checks - parameters are correct type and length
    assert_that(length(variable)==1 & is.character(variable))
    assert_that(length(model)==1 & is.character(model))
    assert_that(length(experiment)==1 & is.character(experiment))
    assert_that(length(ensemble)==1 & is.character(ensemble) | is.null(ensemble))
    assert_that(length(domain)==1 & is.character(domain))
    assert_that(is.dir(path))
    assert_that(is.readable(path))
    assert_that(is.flag(recursive))
    assert_that(is.flag(verbose))
    assert_that(is.flag(force.ncdf))
    assert_that(is.function(FUN))
    assert_that(is.null(yearRange) | length(yearRange)==2 & is.numeric(yearRange))
    assert_that(is.null(ZRange) | length(ZRange)==2 & is.numeric(ZRange))
    FUNstr <- as.character(substitute(FUN))
    assert_that(FUNstr %in% c("mean", "min", "max", "sum"))
    assert_that(loadAs %in% c("data.frame", "array"))
    
    # List all files that match specifications
    fileList <- list.files(path=path, full.names=TRUE, recursive=recursive)
    
    # Only pull the files which are specified by the id strings
    fileList <- fileList[grepl(pattern=sprintf('^%s_%s_%s_%s_%s.*\\.nc$',
                                               variable, domain, model, experiment, ensemble),
                               basename(fileList))]
    
    #cat(fileList)
    if(length(fileList) == 0) {
        warning("Could not find any matching files")
        return(NULL)
    }
    
    # Strip the .nc out of the file list
    fileList <- gsub('\\.nc$', '', fileList)
    
    # Parse out the ensemble strings according to CMIP5 specifications for
    # ...file naming conventions
    ensembleArr <- unique(unlist(lapply(strsplit(basename(fileList), '_'),
                                        function(x) {x[5]})))
    
    # -----------------------------------------------------------------------------------------------
    # Loop through ensembles, loading each and adding to data
    
    if(verbose) cat('Averaging ensembles:', ensembleArr, '\n') 
    modelTemp <- NULL              # Initalize the return data structure
    for(ensemble in ensembleArr) { # for each ensemble...
        
        # load the entire ensemble
        temp <- loadEnsemble(variable, model, experiment, ensemble, domain,
                             path=path, verbose=verbose, recursive=recursive,
                             force.ncdf=force.ncdf, yearRange=yearRange, ZRange=ZRange)
        
        # If nothing loaded, skip and go on to next ensemble
        if(is.null(temp)) next
        
        if(is.null(modelTemp)) {         # If first model, just copy
            modelTemp <- temp
        } else {
            # Make sure lat-lon-Z-time match
            if(all(identical(temp$lat, modelTemp$lat) &
                       identical(temp$lon, modelTemp$lon) &
                       identical(temp$Z, modelTemp$Z) &
                       identical(temp$time, modelTemp$time))) {
                
                # Add this ensemble's data and record file and ensemble loaded
                if(FUNstr %in% c("min", "max")) { # for min and max, compute as we go
                    if(verbose) cat("Computing", FUNstr)
                    combined <- array(c(modelTemp$val, temp$val), dim=c(dim(modelTemp$val), 2))
                    modelTemp$val <- apply(combined,
                                           MARGIN=1:length(dim(modelTemp$val)),
                                           FUN=FUN)
                    
                    #                     modelTemp$val <- plyr::aaply(combined,
                    #                                                  .margins=1:length(dim(modelTemp$val)),
                    #                                                  .fun=FUN,
                    #                                                  .progress=ifelse(verbose, "text", "none"))
                } else { # mean and sum are easier, and much faster
                    modelTemp$val <- modelTemp$val + temp$val
                }
                
                modelTemp$files <- c( modelTemp$files, temp$files )
                modelTemp$ensembles <- c(modelTemp$ensembles, ensemble)
                modelTemp <- addProvenance(modelTemp, temp)
                modelTemp <- addProvenance(modelTemp, paste("Added ensemble", ensemble))
            } else { # ...if dimensions don't match, don't load
                warning(ensemble, paste(
                    "Did not load", ensemble, "- data dimensions do not match those of previous ensemble(s)"))
            }
        } # is.null(modelTemp)
    } # for

    # -----------------------------------------------------------------------------------------------
    # All done loading. Sanity checks and final calculations

    # Make sure at least one ensemble was actually loaded
    if(is.null(modelTemp) | length(modelTemp$ensembles) == 0) {
        warning(paste("No ensembles were loaded:", variable, model, experiment))
        return(NULL)
    }
    
    # If taking the mean, calculate over all ensembles
    if(FUNstr == "mean") {
        modelTemp$val <- unname(modelTemp$val / length(modelTemp$ensembles))
    }

    assert_that(length(modelTemp$lon) == length(modelTemp$lat))
    assert_that(length(dim(modelTemp$lon)) == 2 | is.null(modelTemp$lon))
    assert_that(length(dim(modelTemp$lat)) == 2 | is.null(modelTemp$lat))
    
    # -----------------------------------------------------------------------------------------------
    # At this point we're all done with loading. Put data into final format and return
    
    if(identical(loadAs, 'data.frame')) {
        modelTemp$val <- convert_array_to_df(modelTemp, verbose)
    } else if(identical(loadAs, 'array')) {
        # Do nothing
    } else {
        stop('loadAs is not recognized')
    }
    
    # Update provenance and return
    addProvenance(modelTemp, c(paste("Computed", FUNstr, "of ensembles:",
                                     paste(ensembleArr, collapse=' '))))
} # loadCMIP5

#' Convert array format cmip5data to data frame format
#'
#' @param x A \code{\link{cmip5data}} object
#' @param verbose logical. Print info as we go?
#' @details Convert array format cmip5data to data frame format, for use with dplyr.
#' @note This is an internal RCMIP5 function and not exported.
#' @keywords internal
convert_array_to_df <- function(x, verbose=FALSE) {
    
    # Sanity checks
    assert_that(class(x) == "cmip5data")
    assert_that(is.flag(verbose))
    assert_that(is.array(x$val))
    
    if(verbose) cat("Converting to data frame\n")
    lon <- lat <- Z <- time <- NA
    if(!is.null(x$lon)) lon <- as.vector(x$lon)
    if(!is.null(x$lat)) lat <- as.vector(x$lat)
    if(!is.null(x$Z)) Z <- x$Z
    if(!is.null(x$time)) time <- x$time
    # R uses "column major order" - the first subscript moves fastest
    # Prepare out data frame in this order too
    df <- data.frame('lon'=rep(lon, times=length(Z) * length(time)),
                     'lat'=rep(lat, times=length(Z) * length(time)),
                     'Z'=rep(Z, each=length(lon)),
                     'time'=rep(time, each=length(Z) * length(lon)))
    
    assert_that(nrow(df) == length(x$val)) # right?
    
    df$value <- as.numeric(x$val)
    tbl_df(df) # wrap as a dplyr tbl and return
} # convert_array_to_df
