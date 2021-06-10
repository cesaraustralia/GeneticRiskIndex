using Circuitscape, Pkg

projectdir = dirname(Pkg.project().path)
datadir = joinpath(homedir(), "data")

job_taxon = first(readlines(joinpath(datadir, "job.txt")))

taxondir = joinpath(datadir, "taxa", job_taxon) 
localdir = joinpath(projectdir, "data")

isdir(taxondir) || error("taxon directory $taxondir does not exist")

# Symlink taxon data folder to this directory
if !isdir(joinpath(projectdir, "data"))
    symlink(taxondir, localdir, dir_target=true)
end

# Run the model
seconds_elapsed = @elapsed compute(joinpath(projectdir, "circuitscape_model.ini"))

# Store the time taken to run it
open("data/run_stats.csv", "w") do io
    println(io, "threads, seconds_elapsed")
    println(io, string(Threads.nthreads() * ", " seconds_elapsed))
end
