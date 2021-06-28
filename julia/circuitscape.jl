using Circuitscape, Pkg

# Use command line argumentsa for job_taxon and datadir
job_id = ARG[1] 
datadir = joinpath(homedir(), "data")

job_list = readlines(joinpath(datadir, "batch_jobs.txt"))
job = job_list[job_id]
println("Job taxon: $job")

projectdir = dirname(Pkg.project().path)

taxondir = joinpath(datadir, "taxa", job) 
localdir = joinpath(projectdir, "data")

isdir(taxondir) || error("taxon directory $taxondir does not exist")

# Symlink taxon data folder to this directory
if !isdir(joinpath(projectdir, "data"))
    symlink(taxondir, localdir, dir_target=true)
end

# Run the model
seconds_elapsed = @elapsed compute(joinpath(projectdir, "circuitscape_model.ini"))

# Store the time taken to run it
open("data/job_stats.csv", "w") do io
    println(io, "threads, seconds_elapsed")
    println(io, string(Threads.nthreads(), ", ", seconds_elapsed))
end
