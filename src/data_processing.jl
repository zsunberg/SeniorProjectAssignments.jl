# takes in clean dataframes, outputs students, projects, groups
function process_projects(projects::DataFrame; min=9, max=12)
    pdata = ProjectData[]
    for p in eachrow(projects)
        name = p["Sponsor"]*": "*p["Title"]

        minroles = (hardware = p["Min # of Hardware"],
                    software = p["Min # of Software"],
                    electronics = p["Min # of Electrical"])

        project = ProjectData(name, minroles, min, max)

        push!(pdata, project)
    end

    return pdata
end

function process_survey(survey, pnames; manual_singles=String[], map_roles=default_map_roles)
    sdata = StudentData[]
    teammates = Dict{String, Vector{String}}()
    for s in eachrow(survey)
        name = string(s["RecipientFirstName"], ' ', filter(!isspace, s["RecipientLastName"]))

        tms = collect(map(teammate_to_name, skipmissing([s["Q1_1"], s["Q3_1"]])))
        # filter out strange numbers that appeared in the 011 survey
        teammates[name] = filter(tms) do tmname
            if isnothing(tryparse(Int, tmname)) && tmname != name
                return true
            else
                @warn ("Ignoring teammate name $tmname for $name")
                return false
            end
        end

        pm = !ismissing(s["Q6"])

        # roles
        roles = (electronics = s["Q4_3"],
                 hardware = s["Q4_1"],
                 software = s["Q4_2"])
        roles = map_roles(roles)

        @assert length(pnames) <= 9 # can only handle single digit numbers
        prefs = Vector{Union{Missing, String}}(missing, length(pnames))
        multiples = PriorityQueue()
        for (i, p) in enumerate(pnames)
            rank = passmissing(x->parse(Int, first(x)))(s[string("Q9_", i)])
            if ismissing(rank)
                @info("$name gave no rank for project $p")
            else
                if !ismissing(prefs[rank])
                    @info("Double entry for rank $rank ($name, $p). Moving!")
                    multiples[p] = rank
                else
                    prefs[rank] = p
                end
            end
        end
        for r in 1:length(prefs)
            if ismissing(prefs[r])
                if !isempty(multiples)
                    prefs[r] = dequeue!(multiples)
                end
            end
        end
        @assert isempty(multiples)

        push!(sdata, StudentData(name, roles, pm, prefs, s["Q10"]))
    end

    groups = Vector{String}[]
    gmap = Dict{String, Int}()
    for (n, mates) in teammates
        if haskey(gmap, n) || isempty(mates)
            continue
        end
        valid = true
        for tm in mates
            if !haskey(teammates, tm)
                @warn("Could not find teammates entry for $tm. Ignoring")
                valid = false
            # elseif !(n in teammates[tm]) || haskey(gmap, tm)
            elseif !(n in teammates[tm])
                @warn("Invalid group: $n => $tm was not reciprocated.")
                valid = false
            end
        end
        if valid
            group = [n, teammates[n]...]
            push!(groups, group)
            for s in group
                gmap[s] = length(groups)
            end
        end
    end

    # force same prefs
    for g in groups
        selected = first(shuffle(g))
        # selected = first(g)
        # selected = last(g)
        prefs = copy(only(filter(s->s.id==selected, sdata)).prefs)
        for n in g
            otherprefs = only(filter(s->s.id==n, sdata)).prefs
            if any(skipmissing(otherprefs .!= prefs))
                @info("Preferences for $n don't match $selected in group $g.")
            end
            otherprefs[:] = prefs
        end
    end

    return sdata, groups
end

function default_map_roles(roles)
    # specialty = argmax(roles)
    # roles = merge((;), [specialty=>1.0]) # roundabout way
    # floor anything <= 3
    roles = map(roles) do frac
        if ismissing(frac) || frac <= 3
            return 0
        else
            return frac
        end
    end

    if sum(roles) == 0.0
        return roles
    else
        # normalize
        return map(frac->frac/sum(roles), roles)
    end
end

teammate_to_name(teammate) = join(reverse(split(teammate, '_')), ' ')

function Base.convert(::Type{DataFrame}, sd::Vector{StudentData})
    pairs = [:id => [s.id for s in sd],
             :hardware => [get(s.roles, :hardware, 0.0) for s in sd],
             :software => [get(s.roles, :software, 0.0) for s in sd],
             :electronics => [get(s.roles, :electronics, 0.0) for s in sd],
             :pm => [s.pm for s in sd]
            ]

    for j in 1:length(first(sd).prefs)
        push!(pairs, Symbol(string("pref_", j)) => [s.prefs[j] for s in sd])
    end
    return DataFrame(pairs)
end
