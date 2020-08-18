using SeniorProjectAssignments
using Test

using SeniorProjectAssignments: match

@testset "SeniorProjectAssignments.jl" begin

students = [
    StudentData("Alice",
                (software=0.9, hardware=0.1, electronics=0.0),
                [:airplane, :rocket]
               ),
    StudentData("Bob",
                (software=0.1, hardware=0.9, electronics=0.0),
                [:rocket, :airplane]
               ),
    StudentData("Charlie",
                (hardware=0.9, software=0.1, electronics=0.0),
                [:airplane, :rocket]
               )
]

projects = [
            ProjectData(:airplane, (hardware=1.0, software=1.0), 2, 3),
            ProjectData(:rocket, (hardware=0.8,), 1, 2)
]

@show match(students, projects, [])

groups = [["Alice", "Bob"]]
@show match(students, projects, groups)

end
