## ! Script requires outout files from 'qiime2_amplicon-XXX-read-processing'
conda activate qiime2-amplicon-2024.10

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
##                 Diversity metric creation 
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

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                 Diversity metric export  
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                 Diversity metric boxplot 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##                 Diversity metric anova 
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
