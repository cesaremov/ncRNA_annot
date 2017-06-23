library(R.utils)
library(Biobase)
#library(gplots)

setwd("~/LangebioWork/Amy_Projects/hPoly_ncRNA/")

inPath = "07.00.Reaper"
inPatt = ".+.report.clean.len"
outFile = "08.00.length_plot/raw.length.pdf"
skipPatt = "P2B"

# Figure params
figRow = 1
figCol = 1
paperWidth = 10
paperHeight = 6
cex = 1
font = 2

# Config (for length)
lenCols = c("darkblue","skyblue","orange")  # Distinct, Repeated, LowComplexity
ymax = 1.5e06

dir.create(dirname(outFile), showWarnings = FALSE)

# Files to process
inFiles = list.files(inPath, pattern = inPatt, full.names = TRUE)
names(inFiles) = gsub("^.+\\/|.lane.+", "", inFiles)

# Image plotting
pdf(outFile, width = paperWidth, height = paperHeight)

par(mfrow = c(figRow, figCol), cex = cex, omi = c(0, 0, 0, 0), font = font, mfrow = c(1, 1))

# Do for each barcode/lane
SummaryCounts = data.frame(row.names = inFiles, "lib" = basename(sub(".report.clean.len", "", inFiles)))
for (lenFile in inFiles) {
  
  print(lenFile)
  
  # Get freqFile from my list
  print(paste("Reading ", lenFile))
  
  # Read the matrix from file
  lenMat = as.matrix(read.table(file = lenFile, row.names=1, header=TRUE, sep="\t", check.names=FALSE))
  
  # Take the totals line, to obtain total reads
  totals = sum(lenMat[,"count"])
  totalReads = sum(totals[!is.na(totals)])
  totalReadsMill = signif(totalReads / 1e6, 2)
  
  # Get totalReads and selected reads to tab
  SummaryCounts[lenFile, paste("total.", paste(range(as.numeric(row.names(lenMat))), collapse = "_"), sep = "")] = sum(lenMat)
  selLenTab = lenMat[as.numeric(row.names(lenMat)) >= 16,]
  SummaryCounts[lenFile, paste("total.", paste(range(as.numeric(names(selLenTab))), collapse = "_"), sep = "")] = sum(selLenTab)
  
  # Remove, to avoid plotting extra
  lenMat = lenMat[!rownames(lenMat) %in% "Total",,drop=FALSE]
  if (ymax == 0) {
    ymaxTemp = max(totals)
  } else {
    ymaxTemp = ymax
  }
  
  bp = barplot(t(lenMat), #[as.numeric(row.names(lenMat)) >= 20 & as.numeric(row.names(lenMat)) <= 80,]), 
          las = 3, xlab = "Read-length", ylab = "Number of reads", border = NA,
          ylim = c(0,ymaxTemp*1.1), cex.axis = 1, cex.names = .75, 
          main = paste(gsub("Reaper/+|.lane.+$", "", lenFile), ":\n", totalReadsMill," raw total million reads\n", sep = ""), 
          col = lenCols[2], font = font)
  abline(h = 0, lty = 1, lwd = 1.5, col = "black")
  abline(h = seq(0, ymaxTemp, 2.5e+05), lty = 3, lwd=0.5, col="grey")
  abline(v = bp[c(19, 37)], col="red")
  
}

dev.off()

# Write SummaryCounts to file
write.table(x = SummaryCounts, file = "SummaryCounts.base.tab", sep = "\t", row.names = FALSE, quote = FALSE)
