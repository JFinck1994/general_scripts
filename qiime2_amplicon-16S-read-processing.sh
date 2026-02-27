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
