# Install packages
if (!require("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install(version = "3.17")
BiocManager::install(c("biomaRt", "Biostrings"))
install.packages(c('rentrez', 'dplyr', 'readr', 'seqinr', 'stringr'))

# Load packages 
library(biomaRt)
library(Biostrings)
library(rentrez)
library(dplyr)
library(readr)
library(seqinr)
library(stringr)

# Sets directory location 
setwd("~/R")

# Finds all possible marts
mart_finder <- function(file_name_1) {
  # Mart list is made and saved to file
  list_1 = listMarts(host='https://www.ensembl.org')
  write.csv(list_1, file_name_1, row.names=FALSE)
}

# Finds all BioMart Ensembl databases based on specified mart
# A database represents a species
database_finder <- function(mart_name, file_name_2) {
  list_2 = useMart(biomart=mart_name, host='https://www.ensembl.org')
  # Database list is made and saved to file
  list_2_new = listDatasets(list_2)
  write.csv(list_2_new, file_name_2, row.names=FALSE)
}

# Filters are found for specified species
# This function is called twice (1 per different species)
dataset_filters <- function(type, species, file_1) {
  species_dataset = useEnsembl(biomart=type, dataset=species)
  # List is made for species filters
  list_1 = listFilters(species_dataset)
  # List is made for filters and saved to file
  write.csv(list_1, file_1, row.names=FALSE)
}

# Attributes are found for specified species
# This function is called twice (1 per different species)
dataset_attributes <- function(type, species, file_2) {
  species_dataset = useEnsembl(biomart=type, dataset=species)
  # List is made for species attributes
  list_2 =listAttributes(species_dataset)
  # List is made for attributes and saved to file
  write.csv(list_2, file_2, row.names=FALSE)
}

# Data from BioMart is queried for a specified species
# This function is called twice (1 per different species)
dataset_retrieve <- function(type, species, chrom, file_name) {
  species_dataset = useEnsembl(biomart=type, dataset=species)
  # Attributes are specified
  species_query <- getBM(attributes=c('refseq_mrna', 'refseq_peptide', 'ensembl_gene_id',   
                                      'external_gene_name', 'description', 'start_position', 'end_position', 'strand',
                                      # Filters are specified
                                      'chromosome_name', 'name_1006'), filters =
                           'chromosome_name', values =chrom, mart = species_dataset)
  # Dataset saved to file and reopened for blank removal 
  write.csv(species_query, file_name, row.names=FALSE)
  # Blanks are replaced with NA
  species_csv = read.csv(file_name, na.strings = c("", "NA"))
  # NAs are removed from the dataset
  species_csv = species_csv %>% na.omit()
  # Dataset saved to file
  write.csv(species_csv, file_name, row.names=FALSE)
}

# Genes are found for a particular species and its corresponding homologs to another specified species
gene_list <- function(species, chrom, species_2_id, species_2_gene_name, file_name) {
  # Species 1 is specified
  species_dataset = useEnsembl(biomart="ensembl", dataset=species)
  # Attributes include gene name and ID for species_1, and ID and gene name for   
  # corresponding homolog species
  gene_list_query <- getBM(attributes=c('ensembl_gene_id','external_gene_name',
                                        # Genes filtered by chromosomal location                                     
                                        species_2_id, species_2_gene_name), filters =
                             'chromosome_name', values =chrom, mart = species_dataset)
  # Dataset saved to file and reopened for blank removal 
  write.csv(gene_list_query, file_name, row.names=FALSE)
  # Blanks are replaced with NA
  genes_csv = read.csv(file_name, na.strings = c("", "NA"))
  # NAs are removed from the dataset
  genes_csv = genes_csv %>% na.omit()
  # Dataset saved to file
  write.csv(genes_csv, file_name, row.names=FALSE)
}

# Queries are filtered out if they don't appear on the gene list for the first species dataset
gene_list_dataset_1_filter <- function(species, gene_list, species_filter, filter_gene) {
  # Species_1 dataset selected
  dataset = read.csv(species)
  # Uses gene list made from gene_list function
  genes = read.csv(gene_list)
  # Selects all values for external_gene_name column
  list_1 = genes %>% select(external_gene_name)
  # Removes duplicate names from list_1
  list_1_column = unique(list_1)
  # List_1 is converted to a vector 
  list_1_vector = unlist(list_1_column)
  # Removes genes from species 1 dataset that aren't in list_1_vector and saves to file
  query_1 = dataset[dataset$external_gene_name %in% list_1_vector, ]
  write.csv(query_1, species_filter, row.names=FALSE)
  # Selects all values for external_gene_name column from filtered species_1 dataset
  list_2 =  query_1 %>% select(external_gene_name)
  # Removes duplicate names from list_2
  list_2_column = unique(list_2)
  # List_2 is converted to a vector 
  list_2_vector = unlist(list_2_column)
  # Removes genes from filtered species_1 dataset that aren't in list_2 and saves to file
  query_2 = genes[genes$external_gene_name %in% list_2_vector, ]
  write.csv(query_2, filter_gene, row.names=FALSE)
}

# Queries are filtered out if they don't appear on the gene list for the second species dataset
gene_list_dataset_2_filter <- function(species, gene_list, column_name, file_name_1, file_name_2) {
  # Species_2 dataset is selected
  dataset = read.csv(species)
  # Uses gene list made from gene_list_dataset_1_filter function
  genes = read.csv(gene_list)
  # Selects all values from specified column from filtered gene list
  list_1 = genes %>% select(column_name)
  # Removes duplicates from list_1
  list_1_column = unique(list_1)
  # List_1 is converted to a vector
  list_1_vector = unlist(list_1_column)
  # Removes genes from species 2 dataset that aren't in list_1_vector and saves to file
  query_1 = dataset[dataset$ensembl_gene_id %in% list_1_vector, ]
  write.csv(query_1, file_name_1, row.names=FALSE)
  # Selects all values from ensembl_gene_id column in filtered species_2 dataset
  list_2 =  query_1 %>% select(ensembl_gene_id)
  # From duplicates from list_2
  list_2_column = unique(list_2)
  # Converts list_2 to a vector
  list_2_vector = unlist(list_2_column)
  # Removes genes from filtered species_2 dataset that aren't in list_2 and saves to file
  query_2 = genes[genes[, column_name] %in% list_2_vector, ]
  write.csv(query_2, file_name_2, row.names=FALSE)
}

# First species dataset is updated to reflect filtered second species dataset
dataset_1_final_filter<- function(species, gene_list, file_name) {
  # Use species_1_filter from gene_list_dataset_1_filter function
  dataset = read.csv(species)
  # Uses filter_gene_final from gene_list_dataset_2_filter function
  genes = read.csv(gene_list)
  # Selects all values from external_gene_name column final filtered gene list
  list_1 = genes %>% select(external_gene_name)
  # Removes duplicates from list_1
  list_1_column = unique(list_1)
  # Converts list_1 to a vector
  list_1_vector = unlist(list_1_column)
  # Removes genes from filter species_1 dataset that aren't list_1 and saves to file
  query_1 = dataset[dataset$external_gene_name %in% list_1_vector, ]
  write.csv(query_1, file_name, row.names=FALSE)
}  

# Finds queries that have a specific gene ontology name
# This function is called twice (1 per different species)
gene_ontology_filter <- function(file, go_term, go_name_filter) {
  # Uses final filter datasets from gene_list_dataset_2_filter and dataset_1_final_filter functions
  filtered_species = read.csv(file)
  # Return dataset entries that have specified GO term and saved to file
  query = filtered_species[filtered_species$name_1006 == go_term,]
  write.csv(query, go_name_filter, row.names=FALSE)
}

# Returns RefSeqs for a particular gene
# This function is called twice (1 per different species)
ref_seq_list <- function(file_name, column_name, gene_name, name) {
  # Uses files created from gene_ontology_filter
  file = read.csv(file_name)
  selected = file[, c(column_name, 'external_gene_name')]
  # Duplicate RefSeqs are removed
  new_list = unique(selected)
  query = new_list[new_list$external_gene_name %in% c(gene_name),]
  write.csv(query, name, row.names=FALSE)
}

# Outputs RefSeq based on ID 
# This function is called twice (1 per different species)
ref_seq_sequence <- function(db_type, id, file_name) {
  # Specified RefSeq is retrieved
  # db can be nucleotide or protein and rettype can be fasta or gb
  net_handle <- entrez_fetch(db=db_type, id=id, rettype="fasta", retmode='text')
  # RefSeq is saved and written to file
  write(net_handle, file = file_name)
}

# Creates pairwise alignment from two specie sequences
pairwise_alignment <- function(file_1, file_2, matrix, open_gap, extend_gap, file_name) {
  # Uses selected fatsa file
  species_1 <- read.fasta(file_1)
  # Species_1 is converted to a vector
  species_1_character <- unlist(species_1)
  # All values in vector are converted to uppercase
  species_1_upper <- lapply(species_1_character, toupper)
  # Species_1_upper converted to vector
  species_1_unlist <- unlist(species_1_upper)
  # Species_1_unlist converted to string
  species_1_string <- toString(species_1_unlist)
  # Commas in species_1_string removed
  species_1_comma = str_replace_all(species_1_string,",","")
  # Spaces removed from species_1_comma
  species_1_space = str_replace_all(species_1_comma," ","")
  species_2 <- read.fasta(file_2)
  species_2_character <- unlist(species_2)
  species_2_upper <- lapply(species_2_character, toupper)
  species_2_unlist <- unlist(species_2_upper)
  species_2_string <- toString(species_2_unlist)
  species_2_comma = str_replace_all(species_2_string,",","")
  species_2_space = str_replace_all(species_2_comma," ","")
  alignment <- pairwiseAlignment(species_1_space, species_2_space, type="global",
                                 # Substitution matrix is selected
                                 # BLOSUM62, BLOSUM45, BLOSUM50, BLOSUM80, 
                                 # BLOSUM100, PAM30, PAM40, PAM70, PAM120, and PAM250
                                 substitutionMatrix = matrix,
                                 # Values for open and extended gaps are set
                                 # Values should be entered as negative integers
                                 gapOpening = open_gap,
                                 gapExtension = extend_gap,
                                 scoreOnly = FALSE)
  writePairwiseAlignments(alignment, file=file_name, Matrix = matrix, block.width=60)
}

# Functions are called
mart_finder('mart_list_R.csv') 
database_finder('ENSEMBL_MART_ENSEMBL', 'database_list_R.csv')
dataset_filters('ENSEMBL_MART_ENSEMBL', 'mmusculus_gene_ensembl', 'm_filter_R.csv')
dataset_filters('ENSEMBL_MART_ENSEMBL', 'mmusculus_gene_ensembl', 'm_filter_R.csv')
dataset_attributes('ENSEMBL_MART_ENSEMBL', 'hsapiens_gene_ensembl', 'h_attrib_R.csv')
dataset_attributes('ENSEMBL_MART_ENSEMBL', 'mmusculus_gene_ensembl', 'm_attrib_R.csv')
dataset_retrieve('ENSEMBL_MART_ENSEMBL', 'hsapiens_gene_ensembl', '5', 'species_1_R.csv')
dataset_retrieve('ENSEMBL_MART_ENSEMBL','mmusculus_gene_ensembl', '18', 'species_2_R.csv')
gene_list('hsapiens_gene_ensembl', '5', 'mmusculus_homolog_ensembl_gene', 'mmusculus_homolog_associated_gene_name', 'genes_R.csv')
gene_list_dataset_1_filter('species_1_R.csv',  'genes_R.csv','species_1_filter_R.csv',
                           'filtered_gene_R.csv') 
gene_list_dataset_2_filter('species_2_R.csv', 'filtered_gene_R.csv', 'mmusculus_homolog_ensembl_gene',  
                           'species_2_filter_final_R.csv', 'filtered_gene_final_R.csv')
dataset_1_final_filter('species_1_filter_R.csv', 'filtered_gene_final_R.csv', 'species_1_filter_final_R.csv')
gene_ontology_filter('species_1_filter_final_R.csv', 'plasma membrane', 'species_1_go_R.csv')
gene_ontology_filter('species_2_filter_final_R.csv', 'plasma membrane', 'species_2_go_R.csv')
ref_seq_list('species_1_go_R.csv', 'refseq_peptide', 'APC', 'species_1_ref_R.csv')
ref_seq_list('species_2_go_R.csv', 'refseq_peptide', 'Apc', 'species_2_ref_R.csv')
ref_seq_sequence('protein', 'NP_001394379', 'H_APC_ref_seq_R.fasta')
ref_seq_sequence('protein', 'NP_001347909', 'M_Apc_ref_seq_R.fasta')
pairwise_alignment('H_APC_ref_seq_R.fasta', 'M_Apc_ref_seq_R.fasta', 'BLOSUM62', -10, -0.5, 'alignment_R.txt')
