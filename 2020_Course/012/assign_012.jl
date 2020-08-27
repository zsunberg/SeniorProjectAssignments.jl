using Revise
using SeniorProjectAssignments
using DataFrames
using CSV

using SeniorProjectAssignments: match

using Random
# Random.seed(146)

survey_dataframe = CSV.read("survey_012.csv", DataFrame, header=1, datarow=4)
project_dataframe = CSV.read("projects_012.csv", DataFrame)

projects = process_projects(project_dataframe, min=10, max=12)
@show pnames = [p.id for p in projects]

# Random.seed!(146)
# function map_roles(roles)
#     map(roles) do rating
#         round(rating/10.0)
#     end
# end

Random.seed!(147)
map_roles(roles) = map(rating->1.0, roles)
# 
students, groups = process_survey(survey_dataframe, pnames, map_roles=map_roles)

# Random.seed!(147)
# students, groups = process_survey(survey_dataframe, pnames)

CSV.write("processed_students.csv", convert(DataFrame, students))

@show groups

sdf = convert(DataFrame, students)

force = ["Andy Benham"=>"Prof. Nerem: Drone Bathymetry"]

m = match(students, projects, groups, force=force)
sort!(m, :project)
CSV.write("output_012.csv", m)
display(m)
display([r=>sum(skipmissing(m[:,:rank]).==r) for r in sort(unique(m[:,:rank]))])
