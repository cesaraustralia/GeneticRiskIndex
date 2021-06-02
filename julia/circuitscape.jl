using Circuitscape

# Symlink taxon data folder to this directory
symlink(joinpath(homedir(), "taxon_data"), "data")

# Run the model
seconds_elapsed = @elapsed compute("circuitscape_model.ini")

# Store the time taken to run it
open("data/seconds_elapsed.txt", "a") do io
   println(io, seconds_elapsed)
end
