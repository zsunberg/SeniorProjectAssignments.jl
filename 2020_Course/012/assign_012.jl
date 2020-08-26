using Revise
using SeniorProjectAssignments
using DataFrames
using CSV

using SeniorProjectAssignments: match

using Random
Random.seed!(146)

survey_dataframe = CSV.read("survey_012.csv", DataFrame, header=1, datarow=4)
project_dataframe = CSV.read("projects_012.csv", DataFrame)

projects = process_projects(project_dataframe, min=10, max=12)
@show pnames = [p.id for p in projects]

# manual_singles = ["Alex Lowry", "Sam D'Souza", "William Watkins", "Buck Guthrie", "Dawson Weis", "Reade Warner", "Ponder Stine", "Hugo Stetz", "Riley Swift"]
# students, groups = process_survey(survey_dataframe, pnames, manual_singles=manual_singles)
students, groups = process_survey(survey_dataframe, pnames)

CSV.write("processed_students.csv", convert(DataFrame, students))

@show groups

sdf = convert(DataFrame, students)

m = match(students, projects, groups)
sort!(m, :project)
CSV.write("output_012.csv", m)
m
