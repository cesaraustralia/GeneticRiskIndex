# Prefiltering #############################################################

# Main function called from scripts
# Categorizes risk where distance/resistance are not needed
# This has to be done in chunks as ALA database dies somewhere 
# around 1000 rows
precategorize_risk <- function(taxa) {
    n <- nrow(taxa)
    r <- rep(1:ceiling(n/GALAH_MAXROWS), each=GALAH_MAXROWS)[1:n]
    s <- lapply(split(taxa, r), precategorize_chunk)
    # Split apply combine chunks
    do.call(rbind, s)
}

# Precategorise risk for a chunk of the dataframe.
# This filters out high and low count values, regionally
# irrelevant species and data deficient species.
precategorize_chunk <- function(taxa) {
   taxa %>% 
     add_count_cols() %>%
     add_risk_col() %>%
     label_many_observations() %>%
     label_few_observations() %>%
     label_not_assessed() %>%
     label_isolation_by_resistance() %>%
     label_isolation_by_distance() %>%
     label_low_regional_relevance() %>%
     identity
}

# ALA queries #############################################################

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
    limit = NULL
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
    limit = NULL
  )
}


# Filtering #############################################################

# Add a column that classifies risk. Initially "unknown".
add_risk_col <- function(taxa) {
  taxa$risk <- rep(NA, length(taxa$ala_search_term))
  return(taxa)
}

# Add columns for each taxon of statewide and national observation counts
add_count_cols <- function(taxa) {
  state_counts <- get_state_counts(taxa) %>% rename(state_count = count, ala_search_term = species)
  all_counts <- get_all_counts(taxa) %>% rename(ala_search_term = species)
  taxa <- merge(taxa, state_counts, by = "ala_search_term", all.x=TRUE)
  taxa <- merge(taxa, all_counts, by = "ala_search_term", all.x=TRUE)
  return(taxa)
}

# Label very common species as "abundant"
label_many_observations <- function(taxa) {
  ids <- taxa$state_count > MAXCOUNT
  taxa$risk[ids] <- "abundant"
  taxa$filter_category[ids] <- "many_observations"
  return(taxa)
}

# Label very rare species as "rare"
label_few_observations <- function(taxa) {
  ids <- taxa$state_count < MINCOUNT
  taxa$risk[ids] <- "rare"
  taxa$filter_category[ids] <- "few_observations"
  return(taxa)
}

# Label species not relevent to STATE e.g. Victoria
label_low_regional_relevance <- function(taxa) {
  # TODO: is the proportion enough?
  ids <- (taxa$state_count / taxa$count) < MINPROPINSTATE
  taxa$risk[ids] <- "widespread"
  taxa$filter_category[ids] <- "low_proportion_in_state"
  return(taxa)
}

label_not_assessed <- function(taxa) {
  ids <- taxa$assess != "ALA"
  taxa$risk[ids] <- "not_assessed"
  taxa$filter_category[ids] <- "not_ALA_taxon"
  return(taxa)
}

label_isolation_by_distance <- function(taxa) {
  taxa$filter_category[is.na(taxa$filter_category) & taxa$disperse_model == "Distance"] <- "isolation_by_distance"
  return(taxa)
}

label_isolation_by_resistance <- function(taxa) {
  taxa$filter_category[is.na(taxa$filter_category) & taxa$disperse_model == "Habitat"] <- "isolation_by_resistance"
  return(taxa)
}

# Label species for which there is not enough data.
label_data_deficient <- function(taxa) {
  # TODO: add something here
  # not sure what data deficient means in practice
  return(taxa)
}
