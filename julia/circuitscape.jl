using Circuitscape, Pkg

projectdir = dirname(Pkg.project().path)

# Symlink taxon data folder to this directory
if !isdir(joinpath(projectdir, "data"))
    symlink(joinpath(homedir(), "taxon_data"), joinpath(projectdir, "data"))
end

# Run the model
seconds_elapsed = @elapsed compute(joinpath(projectdir, "circuitscape_model.ini"))

# Store the time taken to run it
open("data/seconds_elapsed.txt", "w") do io
   println(io, seconds_elapsed)
end
