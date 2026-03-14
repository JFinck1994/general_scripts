## R scripts summary
***full-community-diversity-pipeline.Rmd:** Full script encompassing the 4 scripts detailed below. 

***alpha-diversity.Rmd:** Alpha diversity analysis, based on already-available alpha diversity data in the dataset (derived w/ qiime2, see other scripts). This script plots alpha diversity per individual group & larger group, and runs Wilcoxon tests to evaluate statistical differences. In the plot it will then display significance as letter display. *Core packages: vegan, phyloseq, multcompView*

***beta-diversity.Rmd:** Beta diversity analysis, based on XLSX file containing the feature table (OTUs or ASVs) and taxonomic data. This script plots beta diversity ordinations and explains differences between RDA, PCA, PCoA, and the underlying normalizations and transformations. Significance is determined w/ PERMANOVA. Additionally, the script expains how to plot beta diversity distance as boxplots. *Core packages: vegan, phyloseq*

***beta-dispersion.Rmd:** An extension to beta-diversity analysis to compute and visualize the mean distance to the group centroid, commonly known as beta diversity disperion. *Core packages: vegan*

***beta-NTI.Rmd:** Computes group-wise beta-nearest taxon index to determine whether community assembly in that group is driven primarily deterministically or stochastically. *Core packages: picante* 

## Qiime2 scripts summary
***read-processing.sh:** Amplicon raw read processing for 16S or ITS (single-end) depending on the chosen script. This script will perform trimming, demultiplexing, removing of low-abundant ASVs (<10 reads), taxonomic assignment, and export of feature data, taxonomic data for downstream analysis in R, and (for 16S reads) PICRUSt2 analysis.  

***train-classifier.sh:** This script explains how to train a taxonomic classifier for qiime2 using the SILVA and UNITE reference databases.

***div-stats.sh:** This is a continuation of the previous script, which uses the same objects generated in the above script to calculate and visualize beta and alpha diversity metrics. This script also explains how to export alpha diversity metrics for analysis in R. 

***merge-feature-tables.sh:** This script explains how to merge 2 different feature tables and their corresponding taxonomies into new files. This may be useful, for example, when combining read data from different sequencing runs. 

***merge-feat-tab-taxonomy.sh:** This script explains how to join feature data and its ASVs directly w/ corresponding taxonomy using the feature table and taxonomy table as input. 
