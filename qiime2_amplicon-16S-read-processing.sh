## This script is run on the linux terminal and used for AMPLICON 16S PAIRED-END SEQs
## Qiime2 version: 2024.10 (problems may occurr w/ different version)
## For fungal ITS paired-end seqs you only need to remove the Picrust2 section, and cp ITS primer seqs
## For fungal ITS single-end seqs check the separate script that replaces the 'Trim, denoise, filter' section (rest stays the same)

## first set your folder path
cd ~/PATH/TO/DIR

## This folder should contain
## - rawdata folder: paired-end seq read files as fastq.gz
## - prereq folder: metadata.tsv, samples.txt 
## - classifier folder (eg. silva-138.2-release) (check other scripts f/ how to train classifier)

## - metadata.tsv:
## - row 1: sample-id  md-variable1  md-variable2 ... (md-var could be site, season, biomass..)
## - row 2: #q2:types  var-type1  var-type2 ... (var-type can be categorical, numeric) 
## - ! sample-id's = sample names w/o seq read identifier (eg. sample1_07_L001_R1_001.fastq.gz -> identifier: _07_L001_R1_001.fastq.gz)

## - samples.txt: An enumeration (row-wise) of samples
## - ! names = sample-id's from metadata.tsv
## - ! make sure #rows = #samples

## create processing folders
mkdir output-files
mkdir output-vis
mkdir output-data
mkdir analysis
mkdir analysis/seqs
mkdir analysis/phylogeny

## activate conda qiime2 environment
## if not yet installed: 
## conda update conda
## conda env create -n qiime2-amplicon-2024.10 --file https://data.qiime2.org/distro/amplicon/qiime2-amplicon-2024.10-py310-linux-conda.yml
conda activate qiime2-amplicon-2024.10
qiime --help ## test if installation is working

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##       Trim, denoise, filter (abundances >10 ASV count)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Import data 
## - Format 'CasavaOneEightSingleLanePerSampleDirFmt' requires paired end reads
## - these reads are identifiable by a shared sample name & identifier w/ variable tail 
## - eg. sample1_07_L001_R1_001.fastq.gz & sample1_07_L001_R2_001.fastq.gz

qiime tools import   \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path rawdata \
--input-format CasavaOneEightSingleLanePerSampleDirFmt \
--output-path analysis/seqs/combined_demux.qza

## Pre-requisites: Trimming, Denoising (DADA2 workflow within qiime2) 
## - check your <FORW-PRIMER-SEQ> & <REV-PRIMER-SEQ>
## - replace placeholder w/ primer-seq used for seq IF primers haven't been removed by facility
qiime cutadapt trim-paired \
--i-demultiplexed-sequences analysis/seqs/combined_demux.qza \
--p-front-f <FORW-PRIMER-SEQ> \
--p-front-r <REV-PRIMER-SEQ> \
--o-trimmed-sequences analysis/seqs/combined_demux_trimmed.qza \
--verbose \
&> primer_trimming.log 

# check quality scrores aka TRUNCATE LENGTH
# - checking combined_demux.qzv with qiime2view (web application) will let you see the seq read quality graph
# - use the graph to determine truncate lenf <NUM>
qiime demux summarize \
--i-data analysis/seqs/combined_demux_trimmed.qza \
--o-visualization analysis/seqs/combined_demux_trimmed.qzv
qiime demux summarize \
--i-data analysis/seqs/combined_demux.qza \
--o-visualization analysis/seqs/combined_demux.qzv
  
# check for trimming length 
qiime dada2 denoise-paired \
--i-demultiplexed-seqs analysis/seqs/combined_demux_trimmed.qza \
--p-trunc-len-f <NUM> \
--p-trunc-len-r <NUM> \
--o-table analysis/seqs/table.qza \
--o-representative-sequences analysis/seqs/rep-seqs-dada2.qza \
--o-denoising-stats analysis/seqs/denoising-stats-dada2.qza

### (optional) visualizing denoise stats, table, representative sequences 
qiime metadata tabulate \
--m-input-file analysis/seqs/denoising-stats-dada2.qza \
--o-visualization analysis/seqs/denoising-stats-dada2.qzv
qiime feature-table summarize \
--i-table analysis/seqs/table.qza \
--o-visualization analysis/seqs/table.qzv \
--m-sample-metadata-file prereq/metadata.tsv   
qiime feature-table tabulate-seqs \
--i-data analysis/seqs/rep-seqs-dada2.qza \
--o-visualization analysis/seqs/rep-seqs-dada2.qzv         

### (optional) convert denoising stats to tsv
qiime tools export \
--input-path analysis/seqs/denoising-stats-dada2.qza \
--output-path analysis/seqs/dada2-denoising-output

### (optional) summarize & check feature table (filtered)
qiime feature-table summarize \
--i-table analysis/seqs/table.qza \
--o-visualization output-vis/table_filtered.qzv

### Filter feature table, remove low abundant ASVs (< 10 seqs)
qiime feature-table filter-features \
--i-table analysis/seqs/table.qza \
--p-min-frequency 10 \
--o-filtered-table analysis/seqs/table_min10.qza
qiime feature-table filter-seqs \
--i-data analysis/seqs/rep-seqs-dada2.qza \
--i-table analysis/seqs/table_min10.qza \
--o-filtered-data output-files/rep-seqs-table_min10.qza
qiime feature-table summarize \
--i-table analysis/seqs/table_min10.qza \
--o-visualization output-vis/table_min10.qzv

## Check 'table_min10.qzv' in qiime2viewer web app to identify seq depth (f/ rarefy)

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##       Build phylogenetic tree w/ MAFFT/FASTTREE
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### SINGLE COMMAND tree creation
qiime phylogeny align-to-tree-mafft-fasttree \
--i-sequences output-files/rep-seqs-table_min10.qza \
--o-alignment analysis/phylogeny/aligned-rep-seqs-dada2_min10.qza \
--o-masked-alignment analysis/phylogeny/masked-aligned-rep-seqs-dada2_min10.qza \
--o-tree analysis/phylogeny/unrooted-tree-dada2_min10.qza \
--o-rooted-tree analysis/phylogeny/rooted-tree-dada2_min10.qza

### export trees (qiime2 does NOT support tree visualization) 
qiime tools export \
--input-path analysis/phylogeny/unrooted-tree-dada2_min10.qza \
--output-path output-data/exported-unrooted-tree/
qiime tools export \
--input-path analysis/phylogeny/rooted-tree-dada2_min10.qza \
--output-path output-data/exported-rooted-tree/
 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                 Rarefaction curves 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## - key quality control step
## - to determine sufficient sequencing depth for diversity 
## - uses filtered feature table-min10.qza
## - p-max-depth: <NUM> based on table-min10.qzv, max. sampling depth
## - p-sampling-depth: <NUM> based on rarefaction_curves.qzv/rarefaction_exported, sampling depth where lines plateau
 
qiime diversity alpha-rarefaction \
--i-table analysis/seqs/table_min10.qza \
--p-max-depth <NUM> \
--p-steps 20 \
--i-phylogeny analysis/phylogeny/rooted-tree-dada2_min10.qza \
--m-metadata-file prereq/metadata.tsv \
--o-visualization analysis/rarefaction_curves.qzv

## - the previous command gives NO option to check RF curves individually
## - to do so, you have to re-run the command and omit the metadata
qiime diversity alpha-rarefaction \
--i-table analysis/seqs/table_min10.qza \
--p-max-depth <NUM> \
--p-steps 20 \
--i-phylogeny analysis/phylogeny/rooted-tree-dada2_min10.qza \
--m-metadata-file prereq/metadata.tsv \
--o-visualization analysis/rarefaction_curves_individually.qzv

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                 Assign taxonomy
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## - classify with a trained classifier
## - qiime2 ready-to-use classifiers under https://docs.qiime2.org/2024.10/data-resources/

qiime feature-classifier classify-sklearn \
--i-classifier <CLASSIF-FOLDER>/classifier.qza \
--i-reads output-files/rep-seqs-table_min10.qza \
--o-classification output-files/tax_assignment_classifier_rep_seqs_min10.qza

qiime metadata tabulate \
--m-input-file output-files/tax_assignment_classifier_rep_seqs_min10.qza \
--o-visualization output-files/tax_assignment_classifier_rep_seqs_min10.qzv

## Plot taxa barplot (exploratory)
qiime taxa barplot \
--i-table analysis/seqs/table_min10.qza \
--i-taxonomy output-files/tax_assignment_classifier_rep_seqs_min10.qza \
--o-visualization output-vis/taxa_barplot.qzv \
--m-metadata-file prereq/metadata.tsv

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##      Export files & lvl abundances for usage in R
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### Export OTU/ASV table
mkdir analysis/phyloseq
qiime tools export \
--input-path analysis/seqs/table_min10.qza \
--output-path analysis/phyloseq

# Convert biom format to tsv format
biom convert \
-i analysis/phyloseq/feature-table.biom \
-o analysis/phyloseq/asv_table_min10.tsv \
--to-tsv
cd analysis/phyloseq
sed -i '1d' asv_table_min10.tsv
sed -i 's/#OTU ID//' asv_table_min10.tsv
cd ../
cd ../

### Export merged taxa table (is saved as "taxonomy.tsv")
qiime tools export \
 --input-path output-files/tax_assignment_silva138.2_classifier_rep_seqs_min10.qza \
 --output-path analysis/phyloseq

### Export representative sequences
## will be named 'dna-sequences.fasta'
qiime tools export \
--input-path output-files/rep-seqs-table_min10.qza \
--output-path analysis/phyloseq

### Export tree files
qiime tools export \
--input-path analysis/phylogeny/unrooted-tree-dada2_min10.qza \
--output-path analysis/phyloseq
cd analysis/phyloseq
# rename file (structure: mv old-file-name.file-type new-file-name.file-type)
mv tree.nwk unrooted_tree_dada2.nwk
cd ../
cd ../

qiime tools export \
--input-path analysis/phylogeny/rooted-tree-dada2_min10.qza \
--output-path analysis/phyloseq
cd analysis/phyloseq
mv tree.nwk rooted_tree_dada2.nwk
cd ../
cd ../

### Export Lvl2 abundances (p-level 2, Phylum)
qiime taxa collapse \
--i-table analysis/seqs/table_min10.qza \
--i-taxonomy output-files/tax_assignment_classifier_rep_seqs_min10.qza \
--p-level 2 \
--o-collapsed-table analysis/seqs/table_min10_lvl2.qza
qiime feature-table relative-frequency \
--i-table analysis/seqs/table_min10_lvl2.qza \
--o-relative-frequency-table analysis/seqs/frequency_lvl2.qza
qiime tools export \
--input-path analysis/seqs/frequency_lvl2.qza \
--output-path phyloseq   
biom convert \
-i phyloseq/feature-table.biom \
-o phyloseq/asv_table_min10-lvl2.tsv \
--to-tsv

### Export Lvl3 abundances (p-level 3, Class)
qiime taxa collapse \
--i-table analysis/seqs/table_min10.qza \
--i-taxonomy output-files/tax_assignment_classifier_rep_seqs_min10.qza \
--p-level 3 \
--o-collapsed-table analysis/seqs/table_min10_lvl3.qza
qiime feature-table relative-frequency \
--i-table analysis/seqs/table_min10_lvl3.qza \
--o-relative-frequency-table analysis/seqs/frequency_lvl3.qza
qiime tools export \
--input-path analysis/seqs/frequency_lvl3.qza \
--output-path phyloseq 
biom convert \
-i phyloseq/feature-table.biom \
-o phyloseq/asv_table_min10-lvl3.tsv \
--to-tsv
  
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                 Diversity Testing 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
### compute alpha/beta diversity metrics
qiime diversity core-metrics-phylogenetic \
--i-phylogeny analysis/phylogeny/rooted-tree-dada2_min10.qza \
--i-table analysis/seqs/truncate4/table_min10.qza \
--p-sampling-depth <NUM> \
--m-metadata-file prereq/metadata.tsv \
--output-dir analysis/diversity
  
### compute additional alpha diversity indices (e.g. Simpson, Chao1)
### indice commands: https://forum.qiime2.org/t/alpha-and-beta-diversity-explanations-and-commands/2282
qiime diversity alpha \
--i-table analysis/seqs/truncate4/table_min10.qza \
--p-metric chao1 \
--o-alpha-diversity analysis/diversity/chao1_vector.qza
qiime diversity alpha \
--i-table analysis/seqs/truncate4/table_min10.qza \
--p-metric simpson \
--o-alpha-diversity analysis/diversity/simpson_vector.qza

### Export alpha diversity metrics as .tsv (mv for renaming exported files to target names) 
mkdir analysis/phyloseq/alpha-div

qiime tools export \
 --input-path analysis/diversity/observed_features_vector.qza \
 --output-path analysis/phyloseq/alpha-div  
mv analysis/phyloseq/alpha-div/alpha-diversity.tsv analysis/phyloseq/alpha-div/richness.tsv
 
qiime tools export \
 --input-path analysis/diversity/shannon_vector.qza \
 --output-path analysis/phyloseq/alpha-div  
mv analysis/phyloseq/alpha-div/alpha-diversity.tsv analysis/phyloseq/alpha-div/shannon.tsv

qiime tools export \
 --input-path analysis/diversity/evenness_vector.qza \
 --output-path analysis/phyloseq/alpha-div  
mv analysis/phyloseq/alpha-div/alpha-diversity.tsv analysis/phyloseq/alpha-div/evenness.tsv
  
qiime tools export \
 --input-path analysis/diversity/chao1_vector.qza \
 --output-path analysis/phyloseq/alpha-div  
mv analysis/phyloseq/alpha-div/alpha-diversity.tsv analysis/phyloseq/alpha-div/chao1.tsv
    
qiime tools export \
 --input-path analysis/diversity/simpson_vector.qza \
 --output-path analysis/phyloseq/alpha-div  
mv analysis/phyloseq/alpha-div/alpha-diversity.tsv analysis/phyloseq/alpha-div/simpson.tsv

### Alpha-Div Boxplots 
mkdir output-vis/alpha-div
qiime diversity alpha-group-significance \
--i-alpha-diversity analysis/diversity/observed_features_vector.qza \
--m-metadata-file prereq/metadata.tsv \
--o-visualization output-vis/alpha-div/richness-group-significance.qzv
  
qiime diversity alpha-group-significance \
--i-alpha-diversity analysis/diversity/shannon_vector.qza \
--m-metadata-file prereq/metadata.tsv \
--o-visualization output-vis/alpha-div/shannon_compare_groups.qzv
  
qiime diversity alpha-group-significance \
--i-alpha-diversity analysis/diversity/evenness_vector.qza \
--m-metadata-file prereq/metadata.tsv \
--o-visualization output-vis/alpha-div/evenness_compare_groups.qzv

### ANOVA testing of Alpha Diversity Measures 
### - you must specifc metric (eg. shannon) & metadata-var to test for
### - metric name = file name from file.qza (eg. md-var1 could be season)

qiime longitudinal anova \
--m-metadata-file analysis/diversity/shannon_vector.qza \
--m-metadata-file prereq/metadata.tsv \
--p-formula 'shannon_entropy ~ md-var1' \
--o-visualization output-vis/alpha-div/anova_shannon_md-var1.qzv
  
qiime longitudinal anova \
--m-metadata-file analysis/diversity/observed_features_vector.qza \
--m-metadata-file prereq/metadata.tsv \
--p-formula 'observed_features ~ md-var1' \
--o-visualization output-vis/alpha-div/anova_richness_md-var1.qzv
  
qiime longitudinal anova \
--m-metadata-file analysis/diversity/evenness_vector.qza \
--m-metadata-file prereq/metadata.tsv \
--p-formula 'pielou_evenness ~ md-var1' \
--o-visualization output-vis/alpha-div/anova_evenness_md-var1.qzv

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                 PICRUSt2 functional prediction
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mkdir picrust2

## if not yet installed: 
## conda create -n picrust2 -c bioconda -c conda-forge picrust2=2.6.2
conda activate picrust2

qiime tools export \
--input-path output-files/rep-seqs-table_min10.qza \
--output-path picrust2
picrust2_pipeline.py -s dna-sequences.fasta -i feature-table.biom -o picrust2_out_pipeline -p 1
