using Revise
using SeniorProjectAssignments
using DataFrames
using CSV

using SeniorProjectAssignments: match

using Random
Random.seed!(146)

survey_dataframe = CSV.read("survey_011.csv", DataFrame, header=1, datarow=4)
project_dataframe = CSV.read("projects_011.csv", DataFrame)

projects = process_projects(project_dataframe, min=10, max=12)
@show pnames = [p.id for p in projects]

students, groups = process_survey(survey_dataframe, pnames)

CSV.write("processed_students.csv", convert(DataFrame, students))

@show groups

sdf = convert(DataFrame, students)

m = match(students, projects, groups)
sort!(m, :project)
CSV.write("output_011.csv", m)
m
