#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

library(rtracklayer)

# Paths
bit = "./ncRNA"
inPath = bit
outPath = paste(bit, "/Annotation", sep = "")

dir.create(outPath, showWarnings = FALSE)

# Set base
base = "o.v"
base = sub("\\.", "_", base)

# Genomer path
genomePath = paste(bit, "/Genome", sep = "")

# Chr lengths
print("Loading chr lentgths")
chrlensTab = read.table(paste(genomePath, "/", base, ".chrlens", sep = ""), sep = "\t")
colnames(chrlensTab) = c("Chr", "length")
row.names(chrlensTab) = chrlensTab$Chr
chrlens = chrlensTab$length
names(chrlens) = row.names(chrlensTab)







# MapMi results ------------------------------------------------------
# tryCatch({
  
print("Loading MapMi results")
mapmiTabAll = read.table(paste(genomePath, "/", base, ".mapmi.dust", sep = ""), sep = "\t")
threshold = 20
mapmiTabAll = mapmiTabAll[mapmiTabAll$V16 >= threshold,]
mapmiTabAll = mapmiTabAll[order(mapmiTabAll$V16, decreasing = TRUE),]
mapmiTabAll = mapmiTabAll[!grepl("yRNA_secretion", mapmiTabAll$V6),]
mapmiTabAll = mapmiTabAll[!grepl("NA", mapmiTabAll$V1, ignore.case = FALSE),]
mapmiTabAll$V1 = sub("\\s.+$", "", mapmiTabAll$V1)
# mapmiTabAll$V1 = sub("^...-", "", mapmiTabAll$V1)

# Process MapMi results
print("MapMi")
mapmiTab = mapmiTabAll[grepl("nHp", mapmiTabAll$V3), ]

# Convert mapmiTab to GRanges
mapmiGR0 = GRanges(seqnames = Rle(mapmiTab$V6), 
                   ranges = IRanges(start = mapmiTab$V8, end = mapmiTab$V9), 
                   strand = Rle(mapmiTab$V7), 
                   type =  mapmiTab$V1, 
                   seq = mapmiTab$V21, 
                   seqlengths = chrlens[!grepl("yRNA_secretion", names(chrlens))])
mapmiGR0 = mapmiGR0[order(width(mapmiGR0), decreasing = TRUE)]
mapmiGR0 = mapmiGR0[!duplicated(values(mapmiGR0)$type)]

# Reduce mapmi redundancy
reduceMapMi = reduce(mapmiGR0)
redundancyMapMi = findOverlaps(mapmiGR0, reduceMapMi)
values(redundancyMapMi) = values(mapmiGR0[queryHits(redundancyMapMi)][, "type"])
redundancyMapMiTab = data.frame(redundancyMapMi, stringsAsFactors = FALSE)

# Re-order MapMiTabAll by hpo prefferency
redundancyMapMiTab = redundancyMapMiTab[c(grep("hpo", (redundancyMapMiTab)$type),
                                          grep("prd", (redundancyMapMiTab)$type), 
                                          grep("cbn", (redundancyMapMiTab)$type), 
                                          grep("cbr", (redundancyMapMiTab)$type), 
                                          grep("cel", (redundancyMapMiTab)$type), 
                                          grep("crm", (redundancyMapMiTab)$type), 
                                          grep("hco", (redundancyMapMiTab)$type), 
                                          grep("asu", (redundancyMapMiTab)$type),
                                          grep("bma", (redundancyMapMiTab)$type), 
                                          grep("ppc", (redundancyMapMiTab)$type), 
                                          setdiff(c(1:nrow(redundancyMapMiTab)), grep("hpo|prd|cbn|cbr|cel|crm|hco|asu|bma|ppc", (redundancyMapMiTab)$type))),]

# Unique reduced id 
x = redundancyMapMiTab[!duplicated((redundancyMapMiTab$subjectHits)),]
row.names(x) = x$subjectHits
values(reduceMapMi)$type = sub("_MIMAT.+$", "", x[as.character(1:nrow(x)), "type"])
mapmiGR = reduceMapMi
mapmiGR$Name = "MapMi"
seqlengths(mapmiGR) = chrlens[levels(seqnames(mapmiGR))]

# Save MapMi track
export(mapmiGR, paste(outPath, "/mapmi.gff3", sep =""))
# }, finally = next)



# ShortStack results ------------------------------------------------------
print("Loading ShortStack results")
shortstackFile = paste(inPath, "/shortstack/ShortStack_All.gff3", sep = "")

# Process ShortStack results
print("ShortStack")
shortstackGR0 = import.gff3(shortstackFile)
names(shortstackGR0) = shortstackGR0$ID
ssTab = read.table(sub("ShortStack_All.gff3", "Results.txt", shortstackFile), sep = "\t", header = TRUE, as.is = TRUE, quote = "", comment.char = "")
row.names(ssTab) = ssTab$Name

# Process ShortStack results
ssTab$Strand = ifelse(as.numeric(ssTab$FracTop) > 0.5, "+", ifelse(as.numeric(ssTab$FracTop) < 0.5, "-", "*"))
strand(shortstackGR0) = ssTab$Strand

# Re-define ShortStack types
shortstackGR0$bioTypeI = paste(ifelse(shortstackGR0$DicerCall == "N", "clust", ifelse(shortstackGR0$MIRNA == "N", "DCR", "miRNA")), 
                               "_", shortstackGR0$ID, sep = "")
shortstackGR0$type0 = sub("\\_.+$", "", shortstackGR0$bioTypeI)
shortstackGR0$count = ssTab[names(shortstackGR0), "Reads"]

# Summarize ss regions
# print("Plot ShortStack results")
# pdf(paste(outPath, "/ShortStack_summary.pdf", sep = ""), width = 12)
# par(mfrow = c(1, 1))
# ssClusters = table( shortstackGR0$type0)
# ssClusters = sort(ssClusters, decreasing = TRUE)
# barplot(ssClusters, log = "y", ylab = "count", 
#         main = "Number of ncRNA regions predicted\nby ShortStack")
# legend("right", legend = paste(names(table(shortstackGR0$type0)), " = ", table(shortstackGR0$type0), sep = ""),
#        box.col = "white")
# # countSStab = aggregate(shortstackGR0$count, by = list(sub("_.+$", "", shortstackGR0$bioTypeI)), sum)
# # barplot(countSStab$x, log = "y", ylab = "count", names.arg = countSStab$Group.1,
# #         main = "Number of reads produced by ncRNA regions predicted\nby ShortStack")
# # legend("right", legend = paste(countSStab$Group.1, " = ", round(countSStab$x/1e6), " million", sep = ""),
# #        box.col = "white")
# dev.off()

# Create ShortStack GRange's object to work with
shortstackGR = shortstackGR0

# Resume Dicer call information
values(shortstackGR) = values(shortstackGR[, c("type0", "source")])
colnames(values(shortstackGR)) = c("type", "Name")

# Filter out ShortStack results
shortstackGR = shortstackGR[width(shortstackGR) >= 18]

# Save ShortStack track
export(shortstackGR, paste(outPath, "/shorstack.gff3", sep =""))



break



# Rfam results ------------------------------------------------------
print("Load Rfam results")
rfamFile = list.files(path = genomePath, patter = "rfam", full.names = TRUE, recursive = TRUE)

# Process RFam results
print("Rfam")
rfamTab = NULL
for (x in rfamFile) {
  tryCatch({
    rfamTab0 = read.table(x, sep = "", comment.char = "#", quote = "", as.is = TRUE, header = FALSE)
    cnames = c("targetName", "accession", "queryName", "accessionRfam", "mdl", "mdlFrom", "mdlTo", "seqFrom", "seqTo",
               "strand", "trunc", "pass", "gc", "bias", "score", "E.val", "inc", "description")
    colnames(rfamTab0) = cnames
    
    rfamTab0 = rfamTab0[rfamTab0$E.val <= 0.1,]
    
    rfamTab = rbind(rfamTab, rfamTab0)
  }, finally = next)
}

# rfam table to genomic ranges
rfamGR = GRanges(seqnames = Rle(rfamTab$targetName), 
                 ranges = IRanges(start = ifelse(rfamTab$seqFrom < rfamTab$seqTo, rfamTab$seqFrom, rfamTab$seqTo), 
                                  width = abs(rfamTab$seqFrom-rfamTab$seqTo) + 1), 
                 strand = rfamTab$strand,
                 type = paste(rfamTab$queryName), #, "_", rfamTab$accessionRfam, sep = ""),
                 Name = "Rfam")
seqlengths(rfamGR) = chrlens[levels(seqnames(rfamGR))]

# Save Rfam track
export(rfamGR, paste(outPath, "/rfam.gff3", sep =""))





# RNAmmer results ------------------------------------------------------
print("Load RNAmmer results")
rrnaFile = list.files(path = genomePath, patter = "rnammer.gff", full.names = TRUE, recursive = TRUE)

# Process RNAmmer results
print("RNAmmer")
gff = GRanges()
for (x in rrnaFile) {
  tryCatch( {
    gff0 = import.gff(x, format = "gff2")
    gff = c(gff, gff0)
  }, finally = next)
}
rnammerGR = gff
values(rnammerGR) = values(rnammerGR)$type
colnames(values(rnammerGR)) = "type"
values(rnammerGR)$type = paste(values(rnammerGR)$type, sep = "")
rnammerGR$Name = "RNAmmer"
seqlengths(rnammerGR) = chrlens[levels(seqnames(rnammerGR))]

# Save RNAmmer track
export(rnammerGR, paste(outPath, "/rnammer.gff3", sep =""))






# tRNAscan-SE results ------------------------------------------------------
print("Load tRNAscan results")
trnaFiles = list.files(path = genomePath, patter = "trnas", full.names = TRUE, recursive = TRUE)

# Process tRNAscan results
print("tRNAscan")
gff = GRanges()
for (x in trnaFiles) {
  tryCatch( {
    tab = read.table(x, header = FALSE, sep = "\t", comment.char = "", quote = "", as.is = TRUE, skip = 3)
    cond = ifelse(tab$V4 - tab$V3 > 0, TRUE, FALSE)
    gff0 = GRanges(seqnames = Rle(gsub("\\s", "", tab$V1)), ranges = IRanges(start = ifelse(cond, tab$V3, tab$V4), 
                                                                             width =  abs(tab$V4-tab$V3+1)), 
                   strand = Rle(ifelse(cond, "+", "-")), 
                   "type" = tab$V5, 
                   "AntiCodon" = tab$V6, "IntroBegin" = tab$V7, "IntronEnd" = tab$V8, "CoveScore" = tab$V9)
    gff = c(gff, gff0)
  }, finally = next)
}

# Select only type information
trnaGR = gff
values(trnaGR) = values(trnaGR)$type
colnames(values(trnaGR)) = "type"
values(trnaGR)$type = paste("tRNA", "_", values(trnaGR)$type, sep = "")
trnaGR$Name = "tRNAscan-SE"
seqlengths(trnaGR) = chrlens[levels(seqnames(trnaGR))]

# Save tRNAscan track
export(trnaGR, paste(outPath, "/trnascan.gff3", sep =""))






# miRDeep2 results ------------------------------------------------------
print("Load miRDeep2 results")
mirdeepFile = paste(inPath, "/miRDeep2/Results.txt", sep = "")

# Process miRDeep2 results
print("miRDeep2")
mirdeepTab = read.table("miRDeep/Results.txt", sep = "\t", header = TRUE, as.is = TRUE, comment.char = "#")
row.names(mirdeepTab) = mirdeepTab$provisional.id
mirdeepGR = import.bed("miRDeep/miRDeep.bed")
mirdeepGR = mirdeepGR[mirdeepGR$score > 1]
names(mirdeepGR) = sub("^.+:", "", mirdeepGR$name)
mirdeepTab = mirdeepTab[names(mirdeepGR),]
values(mirdeepGR) = paste("miRNA_", values(mirdeepGR)$name, sep = "")
colnames(values(mirdeepGR)) = "Name"
# values(mirdeepGR)$type = paste(values(mirdeepGR)$type, sep = "")
mirdeepGR$type = sub("\\_MIMAT.+", "", mirdeepTab[names(mirdeepGR), "example.miRBase.miRNA.with.the.same.seed"])
# mirdeepGR$premirSeq = mirdeepTab[names(mirdeepGR), "consensus.precursor.sequence"]
# mirdeepGR$type = ifelse(mirdeepGR$type == "-", , mirdeepGR$type)
values(mirdeepGR) = values(mirdeepGR)[, c("type", "Name")]
seqlengths(mirdeepGR) = chrlens[levels(seqnames(mirdeepGR))]

# Save miRDeep2 track
export(mirdeepGR, paste(outPath, "/mirdeep2.gff3", sep =""))

### Get yRNA regions
# yTab = read.table("00.ProcGenome/nHp_2_0_yRNA.tab", sep = "\t", header = FALSE, quote = "", as.is = TRUE)
# colnames(yTab) = c("qname", "sname","Identity", "Algn_length", "mm", "gaps", "qstart", "qend", "sstart", "send", "eval", "bitScore")
# 
# # Process yRNA results
# print("yRNA, blast")
# yTab = yTab[yTab$Identity > 80 & yTab$eval <= 0.1,]
# yGR = reduce(GRanges(seqnames = yTab$sname, ranges = IRanges(start = ifelse(yTab$sstart < yTab$send, yTab$sstart, yTab$send), width = abs(yTab$send-yTab$sstart+1)), strand = ifelse(yTab$sstart < yTab$send, "+", "-")))
# yGR$type = "yRNA"
# yGR$Name = "yRNA" 
# seqlengths(yGR) = chrlens[levels(seqnames(yGR))]
# 
# # Save yRNA track
# export(yGR, paste(outPath, "/yrna.gff3", sep =""))


# Gather all annotation results,ShortStack cluster as basis ------------------------------------------------------
print("Gather annotation results")

grList = list("Rfam" = rfamGR, "tRNAscan-SE" = trnaGR, "RNAmmer" = rnammerGR, "MapMi" = mapmiGR, "miRDeep2" = mirdeepGR)
gr0 = shortstackGR
ncrnasTab = data.frame(row.names = names(gr0), "ShortStack" = shortstackGR$type)
for (type in names(grList)) {
  
  print(type)
  
  # Where does gr overlap?
  gr = grList[[type]]
  ov = findOverlaps(query = gr, subject = gr0, minoverlap = 18)
  
  # Add info to overlaps
  values(ov)$ShorStack = values(gr0[subjectHits(ov)])[, c("type")]
  values(ov)$ID = names(gr0[subjectHits(ov)])
  values(ov)$type = values(gr[queryHits(ov)])[, c("type")]
  
  # Split by cluster and process
  splitOV = split(values(ov), f = values(ov)$ID)
  typeIDs = sapply(splitOV, function(x) paste(x$type, collapse = ","))
  
  # Add to ncrnasTab
  ncrnasTab[, type] = NA 
  ncrnasTab[names(typeIDs), type] = typeIDs
}

# Add description
ncrnasTab$Description = apply(ncrnasTab, 1, function(x) paste(x[!is.na(x)], collapse = "_"))

### Define ncRNA clusters (ordered by seqname and position)
print("Define ncRNAs clusters")
ncrnasGR = granges(gr0)
values(ncrnasGR) = ncrnasTab[names(ncrnasGR),]
ncrnasGR$source = "R"
ncrnasGR$type = paste("ncRNA_", 1:length(ncrnasGR), sep = "")
# colnames(values(ncrnasGR)) = sub("type0", "Description", colnames(values(ncrnasGR)))

# Get major read and get first nucleotide-width type
ncrnasGR$MajorRNA = ssTab[names(ncrnasGR), "MajorRNA"]
ncrnasGR$widthLetter = paste(nchar(ncrnasGR$MajorRNA), "_", substr(ncrnasGR$MajorRNA, 1, 1), sep = "")

#  Quantify genomic regions by strand
# typesGenomic = ifelse(!grepl("Genomic=(exon|intron)", types), "", sub("^.+Genomic=", "", types))
# ncrnasGR$genomicRegion = typesGenomic

# Quantify regions genomic/ncRNAs
print("Types")
types = as.character(ncrnasGR$Description)

# Set simple ids ------------------------------------------------------
print("Define family ids")
# types = ifelse(grepl("intergenic", types) & (grepl("intron", types) | grepl("exon", types)), 
#                sub("intergenic", "", types), types)
types = ifelse(!grepl("yRNA", types), types, "yRNA")
types = ifelse(!grepl("Y_RNA|RF01619|RF01623|RF01643|RF01656|RF01663", types), types, "yRNA")
types = ifelse(grepl("microR|mir|miR|miRNA|let|lin|bantam|MIR", types, ignore.case = TRUE), "miR", types)
# types = ifelse(grepl("yRNA_secretion", types), "yRNA", types)
types = ifelse(grepl("trna|tRNA", types), "tRNA", types)
types = ifelse(grepl("rRNA|rrna|ribos|Ribos", types), "rRNA", types)
types = ifelse(grepl("clust", types), "clust", types)
types = ifelse(grepl("DCR", types), "DCR", types)
types = ifelse(grepl("intergenic", types), "Inter", types)
# types = sub(";exon|;intron|;intergenic|;yRNA_secretion", "", types)
types = ifelse(grepl("microR|mir|miR|miRNA|let|lin|bantam|MIR|trna|tRNA|rRNA|rrna|D_N.N|D_C.N|D_C.Y|yRNA|clust|DCR|Inter", types), 
               types, "Other")

# Add biotypes to ncrnasGR, first layer 
ncrnasGR$bioTypeI = types

# Add width and first nucleotide info, second layer
typesII = ifelse(grepl("2[123]_G", ncrnasGR$widthLetter), paste(ncrnasGR$bioTypeI, "-", ncrnasGR$widthLetter, sep = ""), 
                 ifelse(grepl("2[567]_G", ncrnasGR$widthLetter), paste(ncrnasGR$bioTypeI, "-", ncrnasGR$widthLetter, sep = ""),  paste(ncrnasGR$bioTypeI, "-Unch", sep = "")))

ncrnasGR$bioTypeII = typesII

# Add names
print("Adding names")
ncrnasGR$Cluster = names(ncrnasGR)
names(ncrnasGR) = ncrnasGR$type
ncrnasGR$Name = ncrnasGR$type

# Export ncRNA annotation ------------------------------------------------------
print("Exporting tracks")
export(ncrnasGR, paste(outPath, "/ncRNAs.gff3", sep =""))
# export(ncrnasGR0, paste(outPath, "/ncRNAs0.gff3", sep =""))
save(ncrnasGR, file = paste(outPath, "/ncRNAs.RData", sep =""))

# Define bioType colors
colsBioTypes = c("clust" = "#FFFFB3", "DCR" = "#80B1D3", "miR" = "#FB8072", "rRNA" = "#FDB462", "tRNA" = "#BEBADA", "yRNA" = "#8DD3C7", "Unmap" = "gray")

# Save bioType colors
save(colsBioTypes, file = paste(outPath, "/colsBioTypesI.RData", sep = ""))

# Summarize 
totalTypes  = table(types)
totalTypes = sort(totalTypes, decreasing = TRUE)



# Generate ncRNA's plots
# pdf(paste(outPath, "/ncRNAs_raw_numbers.pdf", sep = ""))
# 
# # Plot regions genomic/ncRNAs numbers 
# par(omi = c(0.35, 0, 0, 0), mfrow = c(1, 1))
# colsTypes = colorRampPalette(brewer.pal(10, "Paired"))(length(totalTypes))
# barplot(totalTypes, las = 3, border = FALSE, cex.names = 0.8, log = "y", col = colsBioTypes[names(totalTypes)], main = "# Clusters")
# legend("topright", legend = paste(names(totalTypes), " = ", (totalTypes), sep = ""), title = "", bty = "n")
# grid()
# # colsGenomic = brewer.pal(length(totalGenomic), "Set3")
# # barplot(totalGenomic, las = 3, border = FALSE, cex.names = 0.8, log = "y", col = colsGenomic, main = "# ncRNA regions\n mapping to genome regions")
# # grid()

# dev.off()




