using Revise
using SeniorProjectAssignments
using DataFrames
using CSV

using SeniorProjectAssignments: match

survey_dataframe = CSV.read("../data/section012.csv", DataFrame, header=1, datarow=4)
project_dataframe = CSV.read("../data/projects_012.csv", DataFrame)

projects = process_projects(project_dataframe)
@show pnames = [p.id for p in projects]

# manual_singles = ["Alex Lowry", "Sam D'Souza", "William Watkins", "Buck Guthrie", "Dawson Weis", "Reade Warner", "Ponder Stine", "Hugo Stetz", "Riley Swift"]
# students, groups = process_survey(survey_dataframe, pnames, manual_singles=manual_singles)
students, groups = process_survey(survey_dataframe, pnames)

sdf = convert(DataFrame, students)

m = match(students, projects, groups)
