module SeniorProjectAssignments

import GLPK
using JuMP
using DataFrames
using Random: shuffle
using DataStructures: PriorityQueue, dequeue!

export
    StudentData,
    ProjectData,
    IndexModel,
    match,
    process_survey,
    process_projects

struct StudentData
    id::String
    roles::NamedTuple
    pm::Bool
    prefs::Vector{Union{String,Missing}}
    comment::Union{String, Missing}
end

struct ProjectData
    id::String
    minroles::NamedTuple
    minsize::Int
    maxsize::Int
end

struct IndexModel
    c::Matrix{Float64}            # c[i, j] is the cost for assigning group i to project j
    r::Matrix{Float64}            # r[k, i] is the amount of effort that group i contributes to role k
    pm::Vector{Float64}           # pm[i] indicates the number of potential project managers in group i
    s::Vector{Float64}            # s[i] is the size of group i
    minroles::Matrix{Float64}     # minroles[k, j] is the minimum number of people needed for role k on project j
    minsizes::Vector{Float64}     # minimum sizes for each project
    maxsizes::Vector{Float64}     # maximum sizes for each project
    force::Vector{Pair{Int, Int}} # i => j means we are forcing group i to be assigned to project j
end

function IndexModel(students, projects, groups; force=[])
    c = calculate_costs(students, projects, groups)
    r, pm, s = calculate_role_fractions(students, projects, groups)
    roles = collect_roles(projects)
    minroles = zeros(length(roles), length(projects))
    for (k, role) in enumerate(roles)
        for (j, p) in enumerate(projects)
            minroles[k, j] = get(p.minroles, role, 0.0)
        end
    end
    minsizes = [p.minsize for p in projects]
    maxsizes = [p.maxsize for p in projects]

    ginds = group_index_map(students, groups)
    pinds = Dict(p.id => j for (j,p) in enumerate(projects))
    force_indices = map(force) do pair
        ginds[first(pair)] => pinds[last(pair)]
    end

    return IndexModel(c, r, pm, s, minroles, minsizes, maxsizes, force_indices)
end

function match(students, projects, groups; optimizer=GLPK.Optimizer, force=[])
    opt = create_model(students, projects, groups, force=force)
    set_optimizer(opt, optimizer)
    optimize!(opt)
    if termination_status(opt) != MOI.OPTIMAL
        @show termination_status(opt)
    end
    return interpret(value.(opt[:x]), students, projects, groups)
end

function create_model(students::Vector{StudentData},
                      projects::Vector{ProjectData},
                      groups::Vector;
                      kwargs...
                     )
    return create_model(IndexModel(students, projects, groups; kwargs...))
end

function create_model(m::IndexModel)
    n_groups, n_projects = size(m.c)

    opt = Model()

    # x[i, j] = 1 indicates that group i is in project j
    @variable(opt, x[1:n_groups, 1:n_projects], Bin)

    @objective(opt, Min, sum(m.c.*x))

    for i in 1:n_groups
        @constraint(opt, sum(x[i, :]) == 1)
    end

    for j in 1:n_projects
        # roles
        pr = m.r*x[:, j]
        @constraint(opt, pr .>= m.minroles[:, j])
        # sizes
        ps = m.s'*x[:, j]
        @constraint(opt, m.minsizes[j] <= ps <= m.maxsizes[j])
        # project managers
        pms = m.pm'*x[:, j]
        @constraint(opt, pms >= 1.0)
    end

    for pair in m.force
        @constraint(opt, x[pair...] == 1)
    end

    return opt
end
    
function calculate_costs(students, projects, groups)
    ginds = group_index_map(students, groups)#  id to group index
    n_groups = length(students)
    if !isempty(groups)
        n_groups += length(groups) - sum(length, groups)
    end
    pinds = Dict(p.id => j for (j,p) in enumerate(projects))# id to project index

    # constant for calculating costs
    logn = ceil(Int, log2(length(students)+length(projects)))

    # c[i, j] is the cost of connecting group i to project j
    c = zeros(n_groups, length(projects))

    for (i, sd) in enumerate(students)
        @assert length(sd.prefs) == length(pinds)
        missingcost = nothing
        for (r, p) in enumerate(sd.prefs)
            cost = 2.0^(logn*(r-1))
            if ismissing(p) && isnothing(missingcost)
                missingcost = cost
            elseif !ismissing(p)
                c[ginds[sd.id], pinds[p]] += cost
            end
        end
        row = view(c, ginds[sd.id], :)
        if sum(row.==0.0) > 0
            row[row.==0.0] .= missingcost
        end
    end

    return c
end

function calculate_role_fractions(students, projects, groups)
    ginds = group_index_map(students, groups)
    n_groups = length(students)
    if !isempty(groups)
        n_groups += length(groups) - sum(length, groups)
    end
    roles = collect_roles(projects)
    rinds = Dict(role => k for (k, role) in enumerate(roles))

    r = zeros(length(roles), n_groups)
    pm = zeros(n_groups)
    s = zeros(n_groups)
    
    for sd in students
        for (role, frac) in pairs(sd.roles)
            if frac > 0
                r[rinds[role], ginds[sd.id]] += frac
            end
        end
        pm[ginds[sd.id]] += sd.pm
        s[ginds[sd.id]] += 1
    end

    return r, pm, s
end

function collect_roles(projects)
    roles = Set{Symbol}()
    for p in projects
        union!(roles, keys(p.minroles))
    end
    return collect(roles)
end

function group_index_map(students, groups)
    ginds = Dict{String, Int}()
    for (i, g) in enumerate(groups)
        for s in g
            ginds[s] = i
        end
    end
    nextindex = length(groups) + 1
    for sd in students
        if !haskey(ginds, sd.id)
            ginds[sd.id] = nextindex
            nextindex += 1
        end
    end
    return ginds
end

function interpret(x, students, projects, groups)
    ginds = group_index_map(students, groups)

    assignments = DataFrame(id = String[],
                            project = String[],
                            rank = Union{Int, Missing}[],
                            hardware = Float64[],
                            software = Float64[],
                            electronics = Float64[],
                            pm = Bool[],
                            comment = Union{String,Missing}[]
                           )

    boolx = x .> 0
    for sd in students
        j = findfirst(boolx[ginds[sd.id], :])
        pd = projects[j]
        rank = something(findfirst(isequal(pd.id), sd.prefs), missing)
        flatcomment = ismissing(sd.comment) ? sd.comment : replace(sd.comment, '\n' => "\\n")
        roundedroles = map(frac->round(frac, digits=2), sd.roles)
        line = merge((id=sd.id, project=string(pd.id), rank=rank, pm=sd.pm, comment=flatcomment), roundedroles)
        push!(assignments, line)
    end
    return assignments
end

include("data_processing.jl")

end
