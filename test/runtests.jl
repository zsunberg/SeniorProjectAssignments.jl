using SeniorProjectAssignments
using Test
using DataFrames
using CSV

using SeniorProjectAssignments: match

@testset "SeniorProjectAssignments.jl" begin

students = [
    StudentData("Alice",
                (software=0.9, hardware=0.1, electronics=0.0),
                false,
                ["Airplane", "Rocket"]
               ),
    StudentData("Bob",
                (software=0.1, hardware=0.9, electronics=0.0),
                true,
                ["Rocket", "Airplane"]
               ),
    StudentData("Charlie",
                (hardware=0.9, software=0.1, electronics=0.0),
                true,
                ["Airplane", missing]
               )
]

projects = [
            ProjectData("Airplane", (hardware=1.0, software=1.0), 2, 3),
            ProjectData("Rocket", (hardware=0.8,), 1, 2)
]

@show match(students, projects, [])

groups = [["Alice", "Bob"]]
@show match(students, projects, groups)

survey_dataframe = CSV.read("../data/Senior Projects Survey 011_August 24, 2020_19.09.csv", DataFrame, header=1, datarow=4)
project_dataframe = CSV.read("../data/projects_011.csv", DataFrame)

projects = process_projects(project_dataframe)
@show pnames = [p.id for p in projects]
students, groups = process_survey(survey_dataframe, pnames)

end
