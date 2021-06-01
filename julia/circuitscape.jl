using Circuitscape

# Symlin taxon data folder to this directory
symlink(joinpath(homedir(), "taxon_data"), "data")

# Run the model
compute("circuitscape_model.ini")
