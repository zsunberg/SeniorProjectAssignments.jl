using SeniorProjectAssignments
using Random

rng = MersenneTwister(3)
roles = Set([:hardware, :software, :electronics])

n_students = 100
n_projects = 10

projects = [ProjectData(Symbol(string("project_", j)), (hardware = 2, software = 2, electronics = 2), 9, 12) for j in 1:n_projects]
pnames = [p.id for p in projects]

students = StudentData[]
for i in 1:n_students
    specialty = rand(rng, roles)
    secondary = rand(rng, delete!(copy(roles), specialty))
    sd = StudentData(string(i), (;specialty=>0.7, secondary=>0.3), pnames[randperm(rng, length(pnames))])
    push!(students, sd)
end

group3(i) = [string(j) for j in (i-1)*3+1:i*3]
groups = [group3(i) for i in 1:floor(Int, n_students/3)]

matching = SeniorProjectAssignments.match(students, projects, groups)
