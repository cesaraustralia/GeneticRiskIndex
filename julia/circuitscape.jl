using Circuitscape, Pkg

# Use command line argumentsa for job_taxon and datadir
datadir = joinpath(homedir(), "data")

# Get job from the AWS batch array, or use the first one
job_number = parse(Int, get(ENV, "AWS_BATCH_JOB_ARRAY_INDEX", "0")) + 1

# Get the ala_search_term (the taxon name) that identifies the job folder
job_list = readlines(joinpath(datadir, "batch_jobs.txt"))
if job_number > length(job_list)
    @warn "job number $job_number larger than length of job list $(length(job_list))"
    exit()
end
job = job_list[job_number]
println("Job taxon: $job")

# Set the project directory to the one this file is in
projectdir = dirname(Pkg.project().path)

# Link the taxon directory here for circuitscape.ini to save to
taxondir = joinpath(datadir, "taxa", job)
localdir = joinpath(projectdir, "data")
# Set up directories
isdir(taxondir) || error("taxon directory $taxondir does not exist")
isdir(localdir) && rm(localdir)
# Symlink taxon data folder to this directory
symlink(taxondir, localdir, dir_target=true)

# Run the model, and time it
seconds_elapsed = @elapsed compute(joinpath(projectdir, "circuitscape_model.ini"))

# Store the time taken to run it
open("data/job_stats.csv", "w") do io
    println(io, "threads, seconds_elapsed")
    println(io, string(Threads.nthreads(), ", ", seconds_elapsed))
end
