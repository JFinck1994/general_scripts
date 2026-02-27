## ! Script requires outout files from 'qiime2_amplicon-XXX-read-processing'
conda activate qiime2-amplicon-2024.10

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
  
