using Circuitscape

# Symlink taxon data folder to this directory
if !isdir("data")
    symlink(joinpath(homedir(), "taxon_data"), "data")
end

# Run the model
seconds_elapsed = @elapsed compute("circuitscape_model.ini")

# Store the time taken to run it
open("data/seconds_elapsed.txt", "w") do io
   println(io, seconds_elapsed)
end
