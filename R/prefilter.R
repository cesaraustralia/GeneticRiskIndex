# Prefiltering

# prefilter_taxa cleans up the table of taxa by removing
# groups for various reasons
prefilter_taxa <- function(taxa) {
   add_count_cols(taxa) %>%
     remove_high_count() %>%
     remove_low_count() %>%
     remove_low_regional_relevance() %>%
     remove_data_deficient()
}

remove_high_count <- function(taxa) {
  filter(taxa, state_count < MAXCOUNT)
}

remove_low_count <- function(taxa) {
  filter(taxa, state_count > MINCOUNT)
}

remove_low_regional_relevance <- function(taxa) {
  # TODO: is the proportion enough?
  filter(taxa, state_count / count > MINPROPINSTATE )
}

remove_data_deficient <- function(taxa) {
  # TODO: add something here
  # not sure what data deficient means in practice
  return(taxa)
}

add_count_cols <- function(taxa) {
  # TODO: renaming the species to ALA.taxon here is incorrect. 
  # But it gets things working for now. We need to work out how to 
  # count each specific taxon and what the logic should be.
  state_counts <- get_state_counts(taxa) %>% rename(state_count = count, ALA.taxon = species)
  all_counts <- get_all_counts(taxa) %>% rename(ALA.taxon = species)
  taxa <- merge(taxa, state_counts, by = "ALA.taxon")
  taxa <- merge(taxa, all_counts, by = "ALA.taxon")
  return(taxa)
}

get_state_counts <- function(taxa) {
  ala_counts(
    taxa = select_taxa(taxa$ALA.taxon), 
    filters = FILTERS,
    group_by = "species",
    type = "record",
    limit = 5000
  )
}

get_all_counts <- function(taxa) {
  ala_counts(
    taxa = select_taxa(taxa$ALA.taxon), 
    filters = select_filters(
      year = c(1960:2021), 
      basis_of_record = "HumanObservation"
    ),
    group_by = "species",
    type = "record",
    limit = 5000
  )
}
