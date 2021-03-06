# -------------------------------------------------------------------
ls
# Takes 'gribdata' object and deaccumulates
# -------------------------------------------------------------------
dR <- function(x,deaccumulate=24) {
   # Create unique hashes
   hashes <- sprintf("%8d_%02d_%03d",x[,'initdate'],x[,'inithour'],x[,'member'])

   hold <- attributes(x)
   # Deaccumulate
   steps <- attr(x,'steps')
   for ( hash in hashes ) {
      ###cat(sprintf(" - Deccumulate: %s\n",hash))
      for ( st in sort(steps[which(steps-deaccumulate > 0)],decreasing=T) ) {
         idx <- c( which(hashes == hash & x[,'step'] ==  st    ),
                   which(hashes == hash & x[,'step'] == (st-deaccumulate)) )
         #cat(sprintf("   step %3d (is %3d)\n",st,st-24))
         # This step is       =   this step        minus    previous step
         x[idx[1L],5:ncol(x)] <- pmax(0,x[idx[1L],5:ncol(x)] - x[idx[2L],5:ncol(x)])
      }
   }

   for ( nam in names(hold) ) attr(x,nam) <- hold[[nam]]
   return(x)
}

# -----------------------------------------------------------------
# -----------------------------------------------------------------
## -----------------------------------------------------------------
library('getgrib')
file <- '/home/retos/Downloads/operational_hindcasts/SnowSafeHindcast_tp_20161010_2007101000.grib'
shortName <- 'tp'
scale <- '* 1000'

   gd <- getdata(file,shortName,scale)

# -------------------------------------------------------------------
# -------------------------------------------------------------------
# -------------------------------------------------------------------
#deaccumulate <- function(x,deaccumulation=24,setzero=FALSE,zeroval=0.0001) {
#
#   # Loading shared library
#   library.dynam('getgrib',package='getgrib',lib.loc=.libPaths())
#
#   # Rearange the data
#   meta <- matrix(as.integer(x[,1:4]),ncol=4)
#   data <- x[,5:ncol(x)]
#
#   Fresult <- .Fortran('deaccumulate',meta,data,
#                       as.integer(nrow(data)),as.integer(ncol(data)), # data dimension (and meta rows)
#                       as.integer(deaccumulation), # hours to deaccumulate
#                       as.integer(setzero), # setzero: set values below 0 to 0
#                       as.numeric(zeroval), # values smaller set to this value (if setzero>0)
#                       PACKAGE='getgrib')
#
#   hold <- attributes(x)
#   x <- cbind(Fresult[[1]],Fresult[[2]])
#   for ( nam in names(hold) ) attr(x,nam) <- hold[[nam]]
#   return(x)
#}



# -------------------------------------------------------------------
# -------------------------------------------------------------------
t1 <- system.time( d1 <- deaccumulate(gd,24,setzero=TRUE) )
t2 <- system.time( d2 <- dR(gd,24)           )


print(t1)
print(t2)

print(dim(d1))
print(dim(d2))

stop()

print(tail(gd[20:25,1:6]))
print(tail(d1[20:25,1:6]))
print(tail(d2[20:25,1:6]))

library('colorspace')

pp <- gribdata2raster(d1)
idx <- which(grepl("_m05",names(pp)))
zlim <- c(0,max(cellStats(pp[[idx]],max)))
plot(pp[[idx]],zlim=zlim,col=diverge_hcl(100))

X11()
pp <- gribdata2raster(gd)
idx <- which(grepl("_m05",names(pp)))
zlim <- c(0,max(cellStats(pp[[idx]],max)))
plot(pp[[idx]],zlim=zlim,col=diverge_hcl(100))


stop()


#
#   # Loading fortran library
#   library.dynam('getgrib',package='getgrib',lib.loc=.libPaths())
#
#   # ---------------------------------------------
#   # Getting number of messages in the grib file. Needed to allocate
#   # the corresponding results matrizes and vectors.
#   nmessages <- .Fortran('messagecount',file,as.integer(0),PACKAGE='getgrib')[[2]][1]
#
#   # ---------------------------------------------
#   # First we have to get the dimension of the grid. Note
#   # that this function stops the script if not all grids
#   # inside the grib file do have the same specification!
#   Freturn <- .Fortran('getgridinfo',file,as.integer(rep(0,6)),PACKAGE='getgrib')
#   # Estracting required information
#   dimension      <- Freturn[[2]][1:2]
#
#   # ---------------------------------------------
#   # Getting data
#   Freturn <- .Fortran('getgriddataByMessageNumber',file,as.integer(10),
#                    paste(rep(" ",20),collapse=""),
#                    rep(as.integer(-999),4), # meta information
#                    rep(as.numeric(-999.),prod(dimension)), # data (values)
#                    rep(as.numeric(-999.),prod(dimension)), # lats
#                    rep(as.numeric(-999.),prod(dimension)), # lons
#                    as.integer(prod(dimension)), # number of grid points (col dimension)
#                    PACKAGE='getgrib')
#
#   # ---------------------------------------------
#   # Create "gribdata" object
#   # First combine meta information and data
#   data <- t(c(Freturn[[4]],Freturn[[5]]))
#   # Adding class and labels
#   colnames(data) <- c("initdate","inithour","step","member",paste("gp",1:(ncol(data) - 4),sep = ""))
#   class(data) <- c("gribdata","matrix")
#
#   # ---------------------------------------------
#   # Create vector of unique dates, hours, steps, and members
#   shortName <- trim(Freturn[[3]])
#   lats      <- as.numeric(Freturn[[6]])
#   lons      <- as.numeric(Freturn[[7]])
#   steps     <- data[1,'step'];     nsteps     <- 1
#   initdates <- data[1,'initdate']; ninitdates <- 1
#   inithours <- data[1,'inithour']; ninithours <- 1
#   members   <- data[1,'member'];   nmembers   <- 1
#
#   # ---------------------------------------------
#   # Create final object
#   class(data) <- c('gribdata','matrix')
#   keys <- c('shortName','dimension','lats','lons','file','initdates','ninitdates',
#             'inithours','ninithours','steps','nsteps','members','nmembers')
#   for ( key in keys ) eval(parse(text=sprintf("attr(data,'%s') <- %s",key,key)))
#   
#   print(Freturn[[3]])
#   print(head(Freturn[[5]]))
#   stop("x")


#file <- 'data/hc.grib'
#shortName <- 'tp'

#grib_ls <- function(file,parameters,where) {
#
#   if ( ! file.exists(file) ) stop(sprintf("Sorry, file %s does not exist",file))
#   # Base command
#   cmd <- sprintf("grib_ls %s",file)
#   # Adding selectors if rquired
#   # Reto's defaults
#   if ( missing(parameters) ) parameters <- "centre,dataDate,dataTime,perturbationNumber,shortName,step"
#   if ( ! missing(parameters) ) {
#      if ( is.character(parameters)) cmd <- sprintf("%s -p %s",cmd,paste(parameters,collapse=","))
#   }
#   if ( ! missing(where) ) {
#      if ( is.list(where) ) cmd <- sprintf("%s -w %s",cmd,paste(names(where),where,sep="=",collapse=","))
#      if ( is.character(where) ) cmd <- sprintf("%s -w %s",cmd,where)
#   }
#   # Show command
#   cat(sprintf(" Calling: %s\n",cmd))
#   tcon <- system(cmd,intern=TRUE)
#   data <- read.table(textConnection(tcon),skip=1,nrows=length(tcon)-5,header=TRUE)
#
#}

#u1 <- grib_ls(file)
#u2 <- grib_ls(file,parameters="dataDate,dataTime,shortName,step")
#u3 <- grib_ls(file,parameters=c("dataDate","dataTime","shortName","step"))
#
#u4 <- grib_ls(file,where="shortName=2t,step=12")
#u5 <- grib_ls(file,where=list("shortName"="cp","step"=12))
#
#for ( i in 1:5 ) eval(parse(text=sprintf('print(head(u%d))',i)))



