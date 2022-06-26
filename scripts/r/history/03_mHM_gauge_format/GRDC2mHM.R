## Preprocessing tool to create mHM compatible Q observed files
## Oldrich Rakovec oldrich.rakovec@ufz.de
## 22 March 2016
## corr. 06.11.2017
## ==> Abstraction of the GRDC stations globally;

## Modified: Pallav Kumar Shrestha [incomplete]
##    07 June 2018
##    Modified to convert monthly GRDC to mHM input
##    Abstraction of the GRDC stations globally;



rm(list = ls(all = TRUE))
Sys.setenv(TZ="UTC") # 
graphics.off()

library(zoo)
library(xts)

maindir = "/Users/shresthp/pallav/01_work/R/Sawam/01 KhartoumWSP/"
# datadir = "/data/stohyd/data/raw/global_mHM/GRDC/DATA_DAY/"
datadir = "/Users/shresthp/pallav/01_work/R/Sawam/01 KhartoumWSP/input/"
outdir  = "/Users/shresthp/pallav/01_work/R/Sawam/01 KhartoumWSP/output/"

## get GRDC ID's/names of extracted basins:
setwd(datadir)
FILES=list.files(path = ".", pattern = "*txt*", recursive=FALSE)

names=substr(FILES,1,7)
print(names)
print("=================")

## names="6730501"

## because 1 file has a duplicite number, re-run for the rest here !OROROR!
## names=names[5825:length(names)]

## names="6731555"

kk=0

## loop through individual files
for(nn in names){
  
  print(nn) 
  print(paste("remaining number of basins:",length(names)-kk,sep="  ")) 
  kk=kk+1
  
  filename=paste(datadir,nn,"_Q_Day.Cmd.txt",sep="")
  length(readLines)
  
  misval=as.character(scan(filename, skip=4, what = "", nlines = 1)[-1])[6]
  
  ## do check, if data in file exists:
  if ( length( readLines(filename)) == 10 )
  {
    print(paste(nn, "has no data"))
  }else{
    
    ## read discharge:
    tab=read.table(filename, header=TRUE, sep=";",na.strings=c(misval,paste(misval,0,sep="")))
    
    ## read dates (start-end), "unique" needed, as some of the last lines were duplicated...
    date = unique(as.Date(tab[,1],"%Y-%m-%d"))
    
    ldum= length(date)
    ## put the grdc obs data together with the dummy dates:
    qobs     = zoo(tab[1:ldum,3], date)
    
    ## another check to eliminate negative values:
    qobs[qobs<0.0] = NA
    
    ## define target dates, for which the observed discharge files are written:
    datestarget=seq(as.Date("1951/1/1"), as.Date("2017/12/31"), "day")
    dummy_day = rep(NA,length(datestarget))
    dummy_day = zoo(dummy_day,datestarget)
    
    qobs=cbind(qobs,dummy_day)[,1]
    datesFULL=time(qobs)
    
    ## index of the Start and End:
    iS=which(datesFULL==datestarget[1])
    iE=which(datesFULL==datestarget[length(datestarget)])
    
    dateS=datesFULL[iS]
    dateE=datesFULL[iE]
    
    yyS=substr(dateS,1,4)
    mmS=sprintf("%02s",substr(dateS,6,7))
    ddS=sprintf("%02s",substr(dateS,9,10))
    
    yyE=substr(dateE,1,4)
    mmE=sprintf("%02s",substr(dateE,6,7))
    ddE=sprintf("%02s",substr(dateE,9,10))
    
    yy =substr(datestarget,1,4)
    mm =substr(datestarget,6,7)
    dd =substr(datestarget,9,10)
    hh=ss=rep("00",length(dd))
    
    new_vec=as.vector(qobs[iS:iE])
    new_vec[which(is.na(new_vec)==TRUE)]=-9999.000
    
    setwd(outdir)
    
    file1=file(paste(nn,".day",sep=""), "w")  # open log file
    cat(paste(nn, "ID from GRDC discharge database; (Abfluss) DAILY", sep="  "), file=file1, '\n',sep="")
    cat("nodata   -9999.000", file=file1, '\n',sep="")
    cat("n       1 measurement per day [1, 1440]", file=file1, '\n',sep="")
    cat(paste("start  ", yyS, mmS, ddS, "00 00 (YYYY MM DD HH MM)",sep=" "), file=file1, '\n',sep="")
    cat(paste("end    ", yyE, mmE, ddE, "00 00 (YYYY MM DD HH MM)",sep=" "), file=file1, '\n',sep="")
    for (i in 1:length(dd))
      cat(cbind(yy[i],mm[i],dd[i],"00","00", sprintf("%11.3f",new_vec[i])), file=file1,'\n')
    close(file1)
    
  }
  
} 

setwd(maindir)


