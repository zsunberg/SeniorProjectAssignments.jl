using Revise
using SeniorProjectAssignments
using DataFrames
using CSV

using SeniorProjectAssignments: match

using Random
Random.seed!(151)

survey_dataframe = CSV.read("survey_011.csv", DataFrame, header=1, datarow=4)
project_dataframe = CSV.read("projects_011.csv", DataFrame)

projects = process_projects(project_dataframe, min=10, max=12)
@show pnames = [p.id for p in projects]

students, groups = process_survey(survey_dataframe, pnames)

CSV.write("processed_students.csv", convert(DataFrame, students))

@show groups

sdf = convert(DataFrame, students)

force = ["Stephen Peng"=>"Avalanche Drone: Snowpack Measurement"]

# push!(force, ["Michelle

m = match(students, projects, groups, force=force)
sort!(m, :project)
CSV.write("output_011.csv", m)
display(m)
display([r=>sum(skipmissing(m[:,:rank]).==r) for r in sort(unique(m[:,:rank]))])
