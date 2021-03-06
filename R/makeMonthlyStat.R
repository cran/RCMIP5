#' Compute monthly statistic of a variable
#' 
#' We frequently want to summarize CMIP5 data by month, e.g. to understand how
#' air temperature varies over the year for a particular data range. This function 
#' does that for monthly data. The default statistic is \link{mean}, but any 
#' summary function that returns a numeric result can be used.
#'
#' @param x A \code{\link{cmip5data}} object
#' @param verbose logical. Print info as we go?
#' @param sortData logical. Sort \code{x} and \code{area} before computing?
#' @param FUN function. Function to apply across months of year
#' @param ... Other arguments passed on to \code{FUN}
#' @return A \code{\link{cmip5data}} object, whose \code{val} field is the monthly
#' mean of the variable. A \code{numYears} field is also added
#' recording the number of years averaged for each month.
#' @details The stat function is calculated for all combinations of lon,
#' lat, and Z (if present).
#' @note If \code{x} is not in a needed order (for example, \code{FUN} uses
#' weights in a different order), be sure to specify \code{sortData=TRUE}.
#' @seealso \code{\link{makeAnnualStat}} \code{\link{makeZStat}} \code{\link{makeGlobalStat}}
#' @examples
#' d <- cmip5data(1970:1975)   # sample data
#' makeMonthlyStat(d)
#' summary(makeMonthlyStat(d))
#' summary(makeMonthlyStat(d, FUN=sd))
#' @export
makeMonthlyStat <- function(x, verbose=FALSE, sortData=FALSE, FUN=mean, ...) {
    
    # Sanity checks
    assert_that(class(x)=="cmip5data")
    assert_that(is.null(x$numYears))
    assert_that(x$debug$timeFreqStr=="mon")
    assert_that(is.flag(verbose))
    assert_that(is.flag(sortData))
    assert_that(is.function(FUN))
    
    # Main computation code
    timer <- system.time({ # time the main computation, below
        if(is.array(x$val)) {
            
            monthNum <- floor((x$time-floor(x$time)) * 12) + 1
            newDim <- dim(x$val)
            newDim[4] <- length(unique(monthNum))
            #aggFUN <- FUN
            x$time <- sort(unique(monthNum))
            x$numYears <- as.data.frame(table(monthNum))$Freq
            x$val <- vapply(x$time, FUN=function(monthIndex, ...) {
                newDim <- dim(x$val)
                temp <- x$val[,,,monthNum==monthIndex]
                newDim[4] <- sum(monthNum == monthIndex)
                dim(temp) <- newDim
                return(apply(temp, c(1,2,3), FUN, ...))
            }, FUN.VALUE=x$val[,,,1], ...)
            dim(x$val) <- newDim
        } else {
            # Suppress stupid NOTEs from R CMD CHECK
            lon <- lat <- Z <- time <- month <- value <- `.` <- NULL
            
            # Put data in consistent order BEFORE overwriting time
            if(sortData) {
                if(verbose) cat("Sorting data...\n")    
                x$val <- group_by(x$val, lon, lat, Z, time) %>%
                    arrange()
            }
            
            monthIndex <- floor((x$val$time %% 1) * 12 + 1)
            x$val$month <- monthIndex  
            
            # Instead of "summarise(value=FUN(value, ...))", we use the do()
            # call below, because the former doesn't work (as of dplyr 0.3.0.9000):
            # the ellipses cause big problems. This solution thanks to Dennis
            # Murphy on the manipulatr listesrv.
            x$val <- x$val %>%
                # start by taking spatial mean, in case there are multiple data per spatial point
                # looking at you, IPSL-CM5A-MR
                group_by(lon, lat, Z, time, month) %>%
                summarise(value=mean(value, na.rm=TRUE)) %>% 
                # now move on to year summary
                group_by(lon, lat, Z, month) %>%
                do(data.frame(value = FUN(.$value, ...))) %>%
                ungroup()
            x$val$time <- x$val$month
            x$val$month <- NULL
            
            # dplyr doesn't (yet) have a 'drop=FALSE' option, and the summarise
            # command above may have removed some lon/lat combinations
            if(length(unique(x$val$lon)) < length(unique(as.numeric(x$lon))) |
                   length(unique(x$val$lat)) < length(unique(as.numeric(x$lat)))) {
                if(verbose) cat("Replacing missing lon/lat combinations\n")
                
                # Fix this by generating all lon/lat pairs and combining with answer
                full_data <- tbl_df(data.frame(lon=as.vector(x$lon), lat=as.vector(x$lat)))
                x$val <- left_join(full_data, x$val, by=c("lon", "lat"))
            }
            x$time <- 1:12
            x$numYears <- as.data.frame(table(floor(monthIndex)))$Freq
        } #if(array) else
    }) # system.time
    
    if(verbose) cat('\nTook', timer[3], 's\n')
    
    # Finish up
    x$timeUnit <- "months (summarized)"
    
    addProvenance(x, paste("Calculated", 
                           paste(deparse(substitute(FUN)), collapse="; "),
                           "for months", min(x$time), "-", max(x$time)))
} # makeMonthlyStat
