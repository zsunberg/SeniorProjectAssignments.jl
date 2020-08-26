# takes in clean dataframes, outputs students, projects, groups
function process_projects(projects::DataFrame, min=9, max=12)
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

function process_survey(survey, pnames; manual_singles=String[])
    groups = Vector{String}[]
    gmap = Dict{String, Int}()
    sdata = StudentData[]
    for s in eachrow(survey)
        name = string(s["RecipientFirstName"], ' ', s["RecipientLastName"])

        if name in manual_singles
            push!(groups, [name])
        else
            group = [name]
            for tm in skipmissing([s["Q1_1"], s["Q3_1"]])
                push!(group, teammate_to_name(tm))
            end

            if haskey(gmap, name)
                for n in group
                    if !haskey(gmap, n)
                        @warn("group disagreement: $name wanted group $(group), but $n was not assigned to $(groups[gmap[name]]).")
                    elseif gmap[n] != gmap[name]
                        @warn("group disagreement: $name wanted group $(group), but $n was already assigned to $(groups[gmap[n]]).")
                    end
                end
            else
                push!(groups, group)
                for n in group
                    gmap[n] = length(groups)
                end
            end
        end

        pm = !ismissing(s["Q6"])

        # roles
        roles = (hardware = s["Q4_1"],
                 software = s["Q4_2"],
                 electronics = s["Q4_3"])
        # floor anything <= 3
        roles = map(roles) do frac
            if ismissing(frac) || frac <= 3
                return 0
            else
                return frac
            end
        end
        # normalize
        roles = map(frac->frac/sum(roles), roles)

        @assert length(pnames) <= 9 # can only handle single digit numbers
        prefs = Vector{Union{Missing, String}}(missing, length(pnames))
        for (i, p) in enumerate(pnames)
            rank = passmissing(x->parse(Int, first(x)))(s[string("Q9_", i)])
            if !ismissing(rank)
                if !ismissing(prefs[rank])
                    @warn("Double entry for rank $rank ($name, $p). Ignoring!")
                else
                    prefs[rank] = p
                end
            end
        end

        push!(sdata, StudentData(name, roles, pm, prefs))
    end

    return sdata, groups
end

teammate_to_name(teammate) = join(reverse(split(teammate, '_')), ' ')
