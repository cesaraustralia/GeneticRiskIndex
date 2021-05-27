# Prefiltering

# categorizes risk where distance/resistance are not needed
precategorize_risk <- function(taxa) {
   taxa %>% add_count_cols() %>%
            add_risk_col() %>%
            label_high_count() %>%
            label_low_count() %>%
            # label_low_regional_relevance() %>%
            label_data_deficient()
}

label_high_count <- function(taxa) {
  taxa$risk[taxa$state_count > MAXCOUNT] <- "abundant"
  return(taxa)
}

label_low_count <- function(taxa) {
  taxa$risk[taxa$state_count < MINCOUNT] <- "rare"
  return(taxa)
}

label_low_regional_relevance <- function(taxa) {
  # TODO: is the proportion enough?
  taxa$risk[(taxa$state_count / taxa$count) < MINPROPINSTATE] <- paste0("more common outside", STATE) 
}

label_data_deficient <- function(taxa) {
  # TODO: add something here
  # not sure what data deficient means in practice
  return(taxa)
}

add_risk_col <- function(taxa) {
  taxa$risk <- rep("unknown", length(taxa$ALA.taxon))
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
    filters = select_filters(
      year = TIMESPAN,
      basis_of_record = BASIS,
      stateProvince = STATE
    ),
    group_by = "species",
    type = "record",
    limit = 5000
  )
}

get_all_counts <- function(taxa) {
  ala_counts(
    taxa = select_taxa(taxa$ALA.taxon), 
    filters = select_filters(
      year = TIMESPAN,
      basis_of_record = BASIS
    ),
    group_by = "species",
    type = "record",
    limit = 5000
  )
}
