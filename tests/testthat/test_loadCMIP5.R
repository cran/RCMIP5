# Testing code for the RCMIP5 'loadCMIP5.R' script

# Uses the testthat package
# See http://journal.r-project.org/archive/2011-1/RJournal_2011-1_Wickham.pdf

# To run this code:
#   source("loadCMIP5.R")
#   library(testthat)
#   test_file("tests/testthat/test_loadCMIP5.R")

context("loadCMIP5")

implementations <- c("data.frame", "array")

test_that("loadCMIP5 handles bad input", {
    expect_error(loadCMIP5("",,"",path="does_not_exist"))  # path does not exist
    expect_error(loadCMIP5("","","",path=c("path1","path2")))       # multi-value path
    expect_error(loadCMIP5("","","",path=1))                  # non-character path
    expect_error(loadCMIP5(1,"",""))                          # non-character
    expect_error(loadCMIP5("",1,""))                          # non-character
    expect_error(loadCMIP5("","",1))                          # non-character
    expect_error(loadCMIP5("","","",domain=1))                # non-character
    expect_error(loadCMIP5(c("",""),"",""))                   # multi-value
    expect_error(loadCMIP5("",c("",""),""))                   # multi-value
    expect_error(loadCMIP5("","",c("","")))                   # multi-value
    expect_error(loadCMIP5("","","",domain=c("","")))         # multi-value
    expect_error(loadCMIP5("","","",verbose=1))               # non-logical verbose
    expect_error(loadCMIP5("","","",recursive=1))             # non-logical recursive
    expect_error(loadCMIP5("","","",force.ncdf=1))             # non-logical force.ncdf
    expect_error(loadCMIP5("","","",yearRange=T))             # non-numeric yearRange
    expect_error(loadCMIP5("","","",yearRange=1))             # yearRange wrong length
    expect_error(loadCMIP5("","","",ZRange=T))             # non-numeric ZRange
    expect_error(loadCMIP5("","","",ZRange=1))             # ZRange wrong length
    expect_error(loadCMIP5("","","",loadAs=1))             # bad loadAs
})

test_that("loadCMIP5 handles no files found", {            # no NetCDF files found
    w <- getOption('warn')
    options(warn=-1)
    expect_warning(loadCMIP5("","","",path=("testdata_none")))
    options(warn=w)
})

test_that("loadCMIP5 loads monthly data", {
    skip_on_cran()
    
    for(i in implementations) {
        path <- "../../sampledata/monthly"
        if(!file.exists(path)) skip("Path doesn't exist")
        
        d <- loadCMIP5('nbp', 'HadGEM2-ES', 'rcp85', path=path, verbose=F, 
                       yearRange=c(2029, 2030), loadAs=i)     # test data set
        expect_is(d, "cmip5data")
        expect_equal(length(d$files), 4) # should be four files
        expect_is(d$val, i)  # val correct class
    }
})

test_that("loadCMIP5 loads global data", {
    skip_on_cran()
    for(i in implementations) {
        path <- "../../sampledata/monthly"
        if(!file.exists(path)) skip("Path doesn't exist")
        
        d <- loadCMIP5('co2mass', 'bcc-csm1-1-m', 'historical', path=path, verbose=F, 
                       loadAs=i)     # test data set
        expect_is(d, "cmip5data")
        expect_is(d$val, i)  # val correct class
    }
})

test_that("loadCMIP5 loads annual data", {
    skip_on_cran()
    path <- "../../sampledata/annual"
    if(!file.exists(path)) skip("Path doesn't exist")
    
    for(i in implementations) {
        d <- loadCMIP5('co3', 'HadGEM2-ES', 'rcp85', path=path, verbose=F, loadAs=i)
        expect_is(d,"cmip5data")
        # There is a csv file with the same base name that load should ignore
        expect_equal(length(d$files), 1)                # should be one file
        expect_is(d$val, i)  # val correct class
    }
})

test_that("loadEnsemble checks unique domain", {
    
    for(i in implementations) {
        expect_error(loadCMIP5("co3", "fakemodel1-ES", "rcp85", 
                               path='testdata_twodomains/',verbose=F, loadAs=i))
    }
})

test_that("loadCMIP5 handles spatial mismatches between ensembles", {
    path <- "testdata_mismatch"
    
    # Test data created by
    # d1 <- cmip5data(1850,lonsize=10,latsize=10)
    # d2 <- cmip5data(1851,lonsize=10,latsize=8)
    # d2$ensemble <- "dummyensemble2"
    # saveNetCDF(d1) and then d2
    # Rename files to avoid R CMD CHECK warning
    for(i in implementations) {
        expect_warning(loadCMIP5("dummyvar", "b", "c", domain="d", path=path, verbose=F))
    }
})

test_that("loadCMIP5 can load area files", {
    path <- "../../sampledata/fx"
    if(!file.exists(path)) skip("Path doesn't exist")
    
    # areacella_fx_GFDL-CM3_historical_r0i0p0.nc
    for(i in implementations) {
        d <- loadCMIP5('areacella', 'GFDL-CM3', 'historical', path=path, verbose=F, loadAs=i)
        expect_is(d, "cmip5data")
        expect_null(d$Z)
        expect_null(d$time)
        expect_is(d$val, i)
    }
})

test_that("Converts to and reads arrays formats agree", {
    skip_on_cran()
    path <- "../../sampledata"
    if(!file.exists(path)) skip("Path doesn't exist")
    
    d <- loadCMIP5(path=path, variable='nbp', model='HadGEM2-ES', experiment='historical', ensemble='r3i1p1')
    darray <- loadCMIP5(path=path, variable='nbp', model='HadGEM2-ES', experiment='historical', ensemble='r3i1p1', loadAs='array')
    
    expect_equal(as.array(d, drop=FALSE), darray$val)
})

test_that("loadCMIP5 correctly extracts start year", {
    skip_on_cran()
    path <- "../../sampledata/monthly"
    if(!file.exists(path)) skip("Path doesn't exist")
    
    for(i in implementations) {
        d <- loadCMIP5('nbp', 'HadGEM2-ES', 'rcp85', ensemble='r3i1p1', 
                       yearRange=c(1, 2007), path=path, verbose=F, loadAs=i)
        expect_equal(d$debug$startYr, 1859+11/12)
    }
})

test_that("loadCMIP5 handles YearRange", {
    skip_on_cran()
    path <- "../../sampledata/monthly"
    if(!file.exists(path)) skip("Path doesn't exist")
    
    # These ../../sample data are 200512-203011 and 203012-205511 (with 2 ensembles)
    # yearRange in first file only
    d <- loadCMIP5('nbp', 'HadGEM2-ES', 'rcp85', ensemble='r3i1p1', path=path, verbose=F, yearRange=c(2006, 2007))
    expect_equal(length(d$time), 24)
    d <- loadCMIP5('nbp', 'HadGEM2-ES', 'rcp85', ensemble='r3i1p1', path=path, verbose=F, yearRange=c(1, 2007))
    expect_equal(length(d$time), 25)
    
    # yearRange in second file only
    d <- loadCMIP5('nbp', 'HadGEM2-ES', 'rcp85', ensemble='r3i1p1', path=path, verbose=F, yearRange=c(2036, 2037))
    expect_equal(length(d$time), 24)
    d <- loadCMIP5('nbp', 'HadGEM2-ES', 'rcp85', ensemble='r3i1p1', path=path, verbose=F, yearRange=c(2054, 9999))
    expect_equal(length(d$time), 23)
    
    # yearRange spans files
    d <- loadCMIP5('nbp', 'HadGEM2-ES', 'rcp85', ensemble='r3i1p1', path=path, verbose=F, yearRange=c(2030, 2031))
    expect_equal(length(d$time), 24)
    
    # yearRange doesn't overlap with files
    expect_warning(loadCMIP5('nbp', 'HadGEM2-ES', 'rcp85', ensemble='r3i1p1', path=path, verbose=F, 
                             yearRange=c(1999, 2000)))
})

test_that("loadCMIP5 handles ZRange", {
    skip_on_cran()
    path <- "../../sampledata/annual"
    if(!file.exists(path)) skip("Path doesn't exist")
    
    for(i in implementations) {
        d <- loadCMIP5('ph', 'MPI-ESM-LR', 'historical', path=path, verbose=F, ZRange=c(30, 50), loadAs=i)
        expect_equal(length(d$Z), 2)
        
        # ZRange doesn't overlap with data
        expect_warning(loadCMIP5('ph', 'MPI-ESM-LR', 'historical', 
                                 path=path, verbose=F, ZRange=c(-10, -20)))
    }
})

test_that("loadCMIP5 handles FUN correctly", {
    path <- "testdata_twoensembles"
    # These two files (saved by saveNetCDF) have all 1's and 2's,
    # respectively, in their data
    if(!file.exists(path)) skip("Path doesn't exist")
    for(i in implementations) {        
        d_mean <- loadCMIP5('var', 'm', 'ex', path=path, verbose=F, loadAs=i)
        d_min <- loadCMIP5('var', 'm', 'ex', path=path, verbose=F, FUN=min, loadAs=i)
        d_max <- loadCMIP5('var', 'm', 'ex', path=path, verbose=F, FUN=max, loadAs=i)
        d_sum <- loadCMIP5('var', 'm', 'ex', path=path, verbose=F, FUN=sum, loadAs=i)
        expect_error(loadCMIP5('var', 'm', 'ex', path=path, verbose=F, FUN=sd, loadAs=i))
        
        expect_equal(mean(RCMIP5:::vals(d_mean)), 1.5, info=i)
        expect_equal(mean(RCMIP5:::vals(d_min)), 1, info=i)
        expect_equal(mean(RCMIP5:::vals(d_max)), 2, info=i)
        expect_equal(mean(RCMIP5:::vals(d_sum)), 3, info=i)
    }
})
