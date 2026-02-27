## ! Script requires qiime2 env
conda activate qiime2-amplicon-2024.10

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##              Train SILVA classifier (16S)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
mkdir /PATH/TO/DIR/silva-release
cd /PATH/TO/DIR/silva-release

## (1) Download SILVA v (eg. SILVA-138.2) dependencies 
## - you can check which version and its corresponding p-target
qiime rescript get-silva-data \
--p-version '138.2' \
--p-target 'SSURef_NR99' \
--o-silva-sequences silva-138.2-ssu-nr99-rna-seqs.qza \
--o-silva-taxonomy silva-138.2-ssu-nr99-tax.qza

## (2) Convert RNA-ref-seqs to DNA-ref-seqs
qiime rescript reverse-transcribe \
--i-rna-sequences silva-138.2-ssu-nr99-rna-seqs.qza \
--o-dna-sequences silva-138.2-ssu-nr99-seqs.qza

## (3) Train SILVA classifier
qiime feature-classifier fit-classifier-naive-bayes \
--i-reference-reads silva-138.2-ssu-nr99-seqs.qza \
--i-reference-taxonomy silva-138.2-ssu-nr99-tax.qza \
--o-classifier silva-138.2-classifier.qza

##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
##              Train UNITE classifier (ITS)
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
## Download UNITE files: https://unite.ut.ee/repository.php (should contain rep-seqs.fasta & tax.txt)
mkdir /PATH/TO/DIR/unite-release
cd /PATH/TO/DIR/unite-release (eg. unite10-release -> the folder you download)

## (1) Import rep-seqs into qiime and create .qza
qiime tools import \
--type FeatureData[Sequence] \
--input-path unite10-release/developer/sh_refs_qiime_ver10_99_19.02.2025_dev.fasta \
--output-path unite10-release/unite-ver10-seqs_99.qza

## (2) Import taxonomy and create .qza
qiime tools import \
--type FeatureData[Taxonomy] \
--input-path unite10-release/developer/sh_taxonomy_qiime_ver10_99_19.02.2025_dev.txt \
--output-path unite10-release/unite-ver10-taxonomy_99.qza \
--input-format HeaderlessTSVTaxonomyFormat

## (3) Train UNITE classifier with .qza files 
qiime feature-classifier fit-classifier-naive-bayes \
--i-reference-reads unite10-release/unite-ver10-seqs_99.qza \
--i-reference-taxonomy unite10-release/unite-ver10-taxonomy_99.qza \
--o-classifier unite9-release/unite-ver10-99-classifier.qza
