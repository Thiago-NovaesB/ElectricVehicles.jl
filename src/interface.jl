function create_model!(prb::Problem)
    prb.model = Model(prb.data.solver)
    prb.data.relaxed = false
    add_variables!(prb)
    add_constraints!(prb)
    add_objective!(prb)
end

function create_model_relaxed!(prb::Problem)
    prb.model = Model(prb.data.solver)
    prb.data.relaxed = true
    add_variables!(prb)
    add_constraints!(prb)
    add_objective!(prb)
end

function solve_model!(prb::Problem)
    optimize!(prb.model)
end

function solve_model_fixed!(prb::Problem)
    
    solve_model!(prb)
    model = prb.model

    K = value.(model[:K])
    S = value.(model[:S])
    A = value.(model[:A])

    @constraint(model, model[:K] .== K)
    @constraint(model, model[:S] .== S)
    @constraint(model, model[:A] .== A)

    unset_binary.(model[:K])
    unset_binary.(model[:S])
    unset_binary.(model[:A])

    solve_model!(prb)
end

