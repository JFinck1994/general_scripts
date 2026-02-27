## This script aims to merge ASV sequences w/ respective taxonomic assignment
## ! Script requires folder structure from 'qiime2_amplicon-XXX-read-processing'
## ! Script requires output from 'qiime2_amplicon-XXX-read-processing'
conda activate qiime2-amplicon-2024.10

## (1) Export feature-table.biom and tax-table.tsv from .qza files 
qiime tools export \
--input-path analysis/seqs/table_min10.qza \
--output-path merged_asv_taxa
qiime tools export \
--input-path output-files/tax_assignment_classifier_rep_seqs_min10.qza \
--output-path merged_asv_taxa 

## (2) Make a copy of taxonomy.tsv (cp <INPUT_FILE> <OUTPUT_FILE>)
cp merged_asv_taxa/taxonomy.tsv merged_asv_taxa/biom-taxonomy.tsv
head merged_asv_taxa/biom-taxonomy.tsv

## (3) Manually edit header & check if biom-taxonomy.tsv is tab-separated
## - change from "Feature ID / Taxon / Confidence" to "#OTUID / taxonomy / confidence"  
head merged_asv_taxa/biom-taxonomy.tsv | od -c

## (4) Add metadata to taxonomy 
biom add-metadata \
-i merged_asv_taxa/feature-table.biom \
-o merged_asv_taxa/table-with-taxonomy.biom \
--observation-metadata-fp merged_asv_taxa/biom-taxonomy.tsv \
--sc-separated taxonomy

## (5) Convert to .tsv 
## - "--header-key" command is CRUCIAL to carry-over taxonomy from .biom as new column
biom convert \
-i merged_asv_taxa/table-with-taxonomy.biom \
-o merged_asv_taxa/table-with-taxonomy.tsv \
--to-tsv \
--header-key taxonomy
