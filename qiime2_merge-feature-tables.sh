## This script performs dataset merging, eg. f/ when you want to merge feature tables:
## - from different seq runs
## - from different primer sets

conda activate qiime2-amplicon-2024.10

## (1) Merge Feature tables
qiime feature-table merge \
--i-tables /PATH/TO/DIR_1/table_min10.qza /PATH/TO/DIR_2/table_min10.qza \
--o-merged-table PATH/TO/DIR_MERGE/table_min10_merged.qza

## (2) Merge corresponding rep seqs 
qiime feature-table merge-seqs \
--i-data /PATH/TO/DIR_1/rep-seqs.qza /PATH/TO/DIR_2/rep-seqs.qza \
--o-merged-data /PATH/TO/DIR_MERGE/rep-seqs_merged.qza

## Past this step script resumes as in 'qiime2_amplicon-XXX-read-processing.sh' 
## You can simply run rarefaction, taxonomoy assignment, exp2phyloseq, picrust2 as previously done
