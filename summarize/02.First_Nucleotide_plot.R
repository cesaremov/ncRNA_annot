library(R.utils)
library(Biobase)
library(ShortRead)
library(reshape2)
library(gplots)

setwd("~/LangebioWork/Amy_Projects/hPoly_ncRNA/")
Sys.setlocale(locale = "C")  # possibly give more consistent file sortings?
rm(list = ls())
gc()

options("scipen" = 10)

# Paths
inPath   <- "07.01.Tally/"
inPatt   <- ".fa.gz"
outFile  <- "08.01.First_Nucleotide/raw.nt.pdf"
skipPatt <- "P2B"

# pData 
pdata = read.table("pData", sep = "\t", header = TRUE, as.is = TRUE)
pdata$id = sub(".sanfastq.gz", "", pdata$sanfastq.gz)
row.names(pdata) = pdata$ReplicateName
pdata$ReplicateName = gsub("\\.", "_", pdata$ReplicateName)

# Figure params
figRow <- 1
figCol <- 1
paperWidth <- 18
paperHeight <- 16
cex <- 1
font <- 2

# Define nuvleotide colors
colsACGT = c(rich.colors(5))[-1]
names(colsACGT) = c("A", "C", "G", "U")

# Load ids names table
# idsNameTab = read.table("idsNames.txt", sep = "\t", header = TRUE)
# row.names(idsNameTab) = idsNameTab$ID

# Config (for length)
lenCols <- c("darkblue","skyblue","orange")  # Distinct, Repeated, LowComplexity
ymax <- 1.5e06

# Arguments from command line, if present:
args <- R.utils::commandArgs(asValues=TRUE)
if (is.null(args$inPath) | is.null(args$inPatt) | is.null(args$outFile)) {
  #stop("I need these arguments: --inPath=path --inPatt=pattern and --outFile=outfile")
} else {
  inPath   <- args$inPath
  inPatt   <- args$inPatt
  outFile  <- args$outFile
}
if (!is.null(args$ymax)) {
  ymax <- as.numeric(args$ymax)
}
if (!is.null(args$figRow)) {
  figRow <- as.numeric(args$figRow)
}
if (!is.null(args$figCol)) {
  figCol <- as.numeric(args$figCol)
}
if (!is.null(args$paperWidth)) {
  paperWidth <- as.numeric(args$paperWidth)
}
if (!is.null(args$paperHeight)) {
  paperHeight <- as.numeric(args$paperHeight)
}
if (!is.null(args$cex)) {
  cex <- as.numeric(args$cex)
}


dir.create(dirname(outFile), showWarnings = FALSE)
inFiles <- list.files(inPath, pattern = inPatt, full.names = TRUE)
names(inFiles) = gsub("^.+\\/|.lane.+", "", inFiles)

# Image plotting
pdf(outFile, width = paperWidth, height = paperHeight)
par(mfrow = c(figRow, figCol), cex = cex, omi = c(0, 0, 0, 0), font = font, mfrow = c(2, 2))


# Do for each barcode/lane
fnList = list()
for (inFile in inFiles) {
  
  # Get freqFile from my list
  print(paste("Reading ", inFile))
  
  # Read fast file
  fa = readBStringSet(inFile)
  
  # Create table
  fnTab = data.frame("width" = gsub("^.+w|.x.+$", "", names(fa)), 
                     "times" = as.numeric(sub("^.+x", "", names(fa))),
                     "FirstNucleoide" = substr(as.character(fa), 1, 1))
  fnTab = fnTab[!fnTab$FirstNucleoide == "N",]
  fnTab = aggregate(fnTab$times, by = list(fnTab$width, fnTab$FirstNucleoide), sum)
  colnames(fnTab) = c("width", "FirstNucleotide", "count")
  
  # Add fnTab to list
  fnList[[sub(inPatt, "", basename(inFile))]] = fnTab
  
  # Long to wide table format
  fnTab2plot = acast(fnTab, width ~ FirstNucleotide, fun.aggregate = sum, value.var = "count")
  colnames(fnTab2plot) = sub("T", "U", colnames(fnTab2plot))
  
  # Take the totals line, to obtain total reads
  totals <- sum(fnTab2plot)
  totalReads <- sum(totals[!is.na(totals)])
  totalReadsMill <- signif(totalReads / 1e6, 2)
  
  # Remove, to avoid plotting extra
  fnTab2plot <- fnTab2plot[!rownames(fnTab2plot) %in% "Total",,drop=FALSE]
  if (ymax == 0) {
    ymaxTemp <- max(totals)
  } else {
    ymaxTemp <- ymax
  }
  
  barplot(t(fnTab2plot), 
          las = 3, xlab = "Read-length", ylab = "Number of reads", border = NA,
          main = paste(gsub(inPatt, "", basename(inFile)), ":\n", totalReadsMill," raw total million reads\n", sep = ""), 
          col = colsACGT[colnames(fnTab2plot)], font = font)
  grid()
  legend("topright", legend = c("First nucleotide", colnames(fnTab2plot)), fill = c("white",  colsACGT[colnames(fnTab2plot)]), box.col = "white", border = "white")
  
  
  #par(xpd=TRUE)
  #legend("top", horiz=TRUE, legend=gsub("ity","",rownames(lenMat)), col=lenCols, bty="n", pch=15, x.intersp=0.5)
  #par(xpd=FALSE)
}

dev.off()

# Type of libraries
typeLibs = list("monophosphate" = c("HES_exosome_HpWAGO", "HES_sup_HpWAGO"), "polyphosphate" = c("HES_exosome_HpWAGO_P", "HES_sup_HpWAGO_P"))

#
pdf(paste(dirname(outFile), "/first_nt_distributions.pdf", sep = ""), width = 14, height = 8)
par(mfrow = c(2, 2))

options("scipen" = -10)
for (typeId in names(typeLibs)) {
  
  print(typeId)
  
  typeLib = typeLibs[[typeId]]
  
  pdataSel = pdata[pdata$BiologicalOrigin %in% typeLib,]
  
  biolorigs = unique(pdataSel$BiologicalOrigin)
  tab = data.frame()
  tabList = list()
  
  for (biolorig in biolorigs) {
    
    print(biolorig)
    
    # Concat data
    print("Concat data")
    tab0 = do.call(cbind, lapply(fnList[pdataSel[pdataSel$BiologicalOrigin %in% biolorig, "ReplicateName"]], function(x) melt(x)))
    tab0$biotype = tab0[, 1]
    tab0$len = tab0[, 2]
    tab0$biolorig = biolorig
    tab0 = cbind(tab0, "cpm" = apply(tab0[, grepl("value", colnames(tab0))], 2, function(x) x/sum(x) * 1e6))
    
    tab0$meanCPM = rowMeans(tab0[, grepl("cpm", colnames(tab0))])
    tab0$sumCPM = rowSums(tab0[, grepl("cpm", colnames(tab0))])
    tab0$varCPM = apply(tab0[, grepl("cpm", colnames(tab0))], 1, var)
    
    libsByOrigs = names(tab0[, grepl("cpm", colnames(tab0))])
    cpmAllList = list()
    for (libByOrig in libsByOrigs) {
      print(libByOrig)
      cpmTab = acast(tab0[, c("biotype", "len", libByOrig)], biotype ~ len, fun.aggregate = sum, value.var = libByOrig)
      cpmAllList[[libByOrig]] = t(cpmTab)
    }
    
    # Concat tables
    allTab = do.call(rbind, cpmAllList)

    # Sum tables
    sumTab = do.call(rbind, lapply(split(as.data.frame(allTab), f = row.names(allTab)), function(x) {
      apply(x, 2, function(x) {x[is.na(x)] = 0; x = x[x > 0]; mean(x, na.rm = TRUE)})}))
    sumTab[is.na(sumTab)] = 0
    
    # Plot stacked bars
    barplot(sumTab,  las = 3, xlab = "Read-length", ylab = "cpm", border = NA,
            # main = paste(gsub(inPatt, "", basename(inFile)), ":\n", totalReadsMill," raw total million reads\n", sep = ""), 
            col = colsACGT[colnames(fnTab2plot)], font = font, cex.axis = 1.5, cex.names = 1.5, cex.lab = 1.5)
    grid()
    legend("topright", legend = c(colnames(fnTab2plot)), fill = c(colsACGT[colnames(fnTab2plot)]), 
           box.col = "white", border = "white", cex = 1.5, title = "First nucleotide")
    
  }
}

dev.off()


