# Prefiltering

# Categorizes risk where distance/resistance are not needed
precategorize_risk <- function(taxa) {
   taxa %>% add_count_cols() %>%
            add_risk_col() %>%
            label_high_count() %>%
            label_low_count() # %>%
            # label_low_regional_relevance() %>%
            # label_data_deficient()
}

# Label very common species
label_high_count <- function(taxa) {
  taxa$risk[taxa$state_count > MAXCOUNT] <- "abundant"
  return(taxa)
}

# Label very rare species
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

# Add a column that classifies risk. Initially "unknown".
add_risk_col <- function(taxa) {
  taxa$risk <- rep("unknown", length(taxa$ala_search_term))
  return(taxa)
}

# Add columns for each taxon of statewide and national observation counts
add_count_cols <- function(taxa) {
  state_counts <- get_state_counts(taxa) %>% rename(state_count = count, ala_search_term = species)
  all_counts <- get_all_counts(taxa) %>% rename(ala_search_term = species)
  taxa <- merge(taxa, state_counts, by = "ala_search_term")
  taxa <- merge(taxa, all_counts, by = "ala_search_term")
  return(taxa)
}

# Retreive state counts from ALA
get_state_counts <- function(taxa) {
  ala_counts(
    taxa = select_taxa(taxa$ala_search_term), 
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

# Retreive national counts from ALA
get_all_counts <- function(taxa) {
  ala_counts(
    taxa = select_taxa(taxa$ala_search_term), 
    filters = select_filters(
      year = TIMESPAN,
      basis_of_record = BASIS
    ),
    group_by = "species",
    type = "record",
    limit = 5000
  )
}
