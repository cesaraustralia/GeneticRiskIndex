using Circuitscape

dir = dirname(@__FILE__)
# Symlink taxon data folder to this directory
if !isdir(joinpath(dir, "data"))
    symlink(joinpath(homedir(), "taxon_data"), joinpath(dir, "data"))
end

# Run the model
seconds_elapsed = @elapsed compute(joinpath(dir, "circuitscape_model.ini"))

# Store the time taken to run it
open("data/seconds_elapsed.txt", "w") do io
   println(io, seconds_elapsed)
end
