function sddp(prb::Problem; maxiter = 10)
    iter = 1
    data = prb.data
    data.T = 1
    stages, _ = size(data.pv_generation_distribution)
    FCFs = FCF[FCF(Cut[Cut(zeros(3)...)],t) for t = 1:stages]
    
    while iter <= maxiter
        LB, storages = forward(prb, FCFs)
        UB, FCFs = backward(prb, FCFs, storages)
        # LB = update_lb(prb, FCFs)
        # UB = update_ub(prb, FCFs)
        iter += 1
    end
    return nothing
end

# function update_lb(prb::Problem, FCFs::Vector{FCF})

# end

# function update_ub(prb::Problem, FCFs::Vector{FCF})

# end

function forward(prb::Problem, FCFs::Vector{FCF})
    data = prb.data
    stages, _ = size(data.pv_generation_distribution)

    storages = []
    LB = 0.0
    for t = 1:stages
        solar = rand(data.pv_generation_distribution[t,:])
        initial_storage = (t == 1 ? data.store_init : storages[t-1])
        _create_sub_model!(prb, initial_storage, FCFs[t], solar)
        solve_model!(prb, false)
        model = prb.model
        push!(storages, value.(model[:energy_storage])[:,end])
        LB += objective_value(model)
    end

    return LB, storages
end

function backward(prb::Problem, FCFs::Vector{FCF}, storages)
    data = prb.data
    stages, _ = size(data.pv_generation_distribution)

    UB = 0.0
    for t = stages:-1:2
        solar = rand(data.pv_generation_distribution[t,:])
        initial_storage = storages[t-1]
        _create_sub_model!(prb, initial_storage, FCFs[t], solar)
        solve_model!(prb, false)
        model = prb.model
        pi = dual.(model[:dual_fisher])
        u = objective_value(model) - value(variable_by_name(model, "omega_$(t)"))
        UB += objective_value(model)
        cut = Cut(pi, Q, initial_storage)
        push!(FCFs[t-1].cuts, cut)
    end
    
    return UB, FCFs
end