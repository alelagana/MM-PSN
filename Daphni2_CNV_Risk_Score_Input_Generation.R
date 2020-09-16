#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
library(GenomicRanges)
allDuplicated <- function(vec){
  front <- duplicated(vec)
  back <- duplicated(vec, fromLast = TRUE)
  all_dup <- front + back > 0
  return(all_dup)
}


if (length(args)==0) {
  stop("At least one argument must be supplied.", call.=FALSE)
} else if (length(args) > 0) {
  parse_cnv <- args[1]
  cytoband <- args[2]
  samplename <- args[3]
  predicted_trans_input <- args[4]
  expression_vector <- args[5]
  expression_features <- args[6]
  cnv_features <- args[7]

    # parse_cnv <- "/data1/users/dmelnekoff/parsed_cnvs.txt"
    # cytoband <- "/data1/users/dmelnekoff/cytoBand_hg38.txt"
    # samplename <- "MM_0092_T2"
    # predicted_trans_input <- "~/predicted_translocations.csv"
    # expression_vector <- "~/vst_normalized_counts_noqs.csv"
    # expression_features <- "~/expression_features_rem.tsv"
    #  cnv_features <- "~/CNV_features.tsv"

  #### read in tables and set up columns

  parsed_cnv_tab <- read.table(parse_cnv, sep = "\t", header = T)
  cytoband_tab <- read.table(cytoband, sep = "\t", header = F)

  cytoband_tab$tag <- paste0(gsub("chr","",cytoband_tab$V1),cytoband_tab$V4)
  cytoband_tab$rawchr <- gsub("chr","",cytoband_tab$V1)

  #### generate real CNV by takign into account cellularity####

  parsed_cnv_tab$real_cnv <- (parsed_cnv_tab$cellular_prevalence*parsed_cnv_tab$copy_number) + ((1-parsed_cnv_tab$cellular_prevalence)*2)

  ##generate Granges Objects ######

  cytoband_GR <-  GRanges(seqnames = cytoband_tab$rawchr,
              ranges = IRanges(start = cytoband_tab$V2,
                               end = cytoband_tab$V3,
                               band = cytoband_tab$tag))


  parse_cnv_GR <- GRanges(seqnames = parsed_cnv_tab$chromosome,
                          ranges = IRanges(start = parsed_cnv_tab$start,
                                           end = parsed_cnv_tab$end,
                                           cnv = parsed_cnv_tab$real_cnv))


  ###find overlapping regions between objects #####

  Overlaps <- findOverlaps(parse_cnv_GR,cytoband_GR)

  #### make band x cnv table #####

  CNV <- parsed_cnv_tab$real_cnv[Overlaps@from]
  bands <- cytoband_tab$tag[Overlaps@to]
  names(CNV) <- bands
  cnv_band_table <- t(as.matrix(CNV))


  ###filter bands for input #####

  bands_of_int <- c("1p36.33","1q21.1","1q21.3","1q22","1q44","2p14","2p13.3","2q22.1",
                    "3p21.31","3p21.1","3q23","3q26.2","4q31.3","4q35.1","5p15.33","5q11.2",
                    "5q31.2","5q33.3","5q35.3","6p24.3","6p24.2","6p21.33","6q21","7p21.3",
                    "7p15.2","7q34","8q13.1","8q24.21","9p13.2","9q22.2","9q34.13","10p14",
                    "10q22.3","10q25.2","11q13.3","11q23.1","11q23.3","12p13.32","12q24.31",
                    "14q11.2","14q32.33","15q15.1","15q23","15q24.2","16p13.13","16p11.1","17p13.2",
                    "17p11.2","17q22","18q23","19p13.3","19p13.11","20q11.22","20q13.12","20q13.33",
                    "21q22.11","22q11.22","22q13.1","1p32.3","1p22.1","1p13.1","2p23.3","2q31.1",
                    "2q37.1","3q26.32","4p16.3","4q22.1","5q21.1","6q25.2","7p22.3","8p23.2","8q24.13",
                    "8q24.3","9p21.3","10q24.32","11q22.2","12p13.1","12q23.3","12q24.33","13q12.11",
                    "13q14.2","14q23.3","16p13.3","16q12.1","16q23.1","16q24.3","17p13.1","17q21.2","17q25.3",
                    "18q12.2","20p13","22q13.33")




  cnv_band_table_int <- t(as.matrix(cnv_band_table[,which(colnames(cnv_band_table) %in% bands_of_int)]))
  rownames(cnv_band_table_int) <- samplename


  #### look for duplicate band information (when CNV splits bands) ######


  bands_to_check <- unique(names(cnv_band_table_int[,allDuplicated(colnames(cnv_band_table_int))]))


  ###find which CNV segment if larger proportion of band and take that value ######

  isect <- pintersect(parse_cnv_GR[queryHits(Overlaps)], cytoband_GR[subjectHits(Overlaps)])

  overlap_df <- data.frame(query=queryHits(Overlaps), subject=subjectHits(Overlaps),
             olap_width=width(isect),
             subject_width=width(cytoband_GR)[subjectHits(Overlaps)],
             band=cytoband_GR$band[subjectHits(Overlaps)],
             CNV=parse_cnv_GR$cnv[queryHits(Overlaps)])

  overlap_df_dup <- overlap_df[which(overlap_df$band %in% bands_to_check),]
  new_cnvs <- c()
  for(band in bands_to_check){
    band_mat <- overlap_df_dup[which(overlap_df_dup$band == band),]
    cnv_to_keep <- band_mat$CNV[which(band_mat$olap_width == max(band_mat$olap_width))]
    new_cnvs <- c(new_cnvs,cnv_to_keep)
  }

  cnv_band_table_int <-  t(as.matrix(cnv_band_table_int[,-which(duplicated(colnames(cnv_band_table_int)))]))

  cnv_band_table_int[,bands_to_check] <- new_cnvs



  CNV_features_tab <- read.table(cnv_features, sep = "\t", header = F)

  cnv_band_table_int <- t(as.matrix(cnv_band_table_int[,as.character(CNV_features_tab$V1)]))

  rownames(cnv_band_table_int) <- samplename

  write.csv(cnv_band_table_int,"CNV_risk_score_input.csv", col.names = NA, row.names = T, quote = F)


  ##### Translocations#####

  trans_input <- read.table(predicted_trans_input, sep = ",", header = T)
  rownames(trans_input) <- trans_input$X
  trans_input <- trans_input[,-1]
  trans_input <- cbind(trans_input,0,0,0,0,0)
  trans_feature_names <- c("SeqWGS_WHSC1_CALL","SeqWGS_CCND1_CALL","SeqWGS_MAF_CALL","SeqWGS_CCND3_CALL","SeqWGS_MYC_CALL","SeqWGS_CCND2_CALL","SeqWGS_MAFA_CALL","SeqWGS_MAFB_CALL")
  colnames(trans_input) <- trans_feature_names
  trans_input <- trans_input[,c("SeqWGS_WHSC1_CALL","SeqWGS_CCND3_CALL","SeqWGS_MYC_CALL","SeqWGS_MAFA_CALL","SeqWGS_CCND1_CALL","SeqWGS_CCND2_CALL","SeqWGS_MAF_CALL","SeqWGS_MAFB_CALL")]
  write.table(trans_input,"predicted_trans_final.csv", sep = ",", col.names = T, row.names = T, quote = F)



  ##### Expressions ######

  expression_vector_tab <- read.table(expression_vector, sep = ",", header = T)
  rownames(expression_vector_tab) <- expression_vector_tab$X
  expression_vector_tab <- expression_vector_tab[,-1]
  expression_features_tab <- read.table(expression_features, sep = "\t", header = F)
  expression_vector_tab_final <- expression_vector_tab[,as.character(expression_features_tab$V1)]
  write.csv(expression_vector_tab_final,"vst_normalized_counts_noqs_final.csv", row.names = T, col.names = NA)
  }