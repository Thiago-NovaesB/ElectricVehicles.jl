function sddp(prb::Problem; maxiter = 10, ub = 50)
    iter = 1
    data = prb.data
    options = prb.options
    data.T = 1
    stages, _ = size(data.pv_generation_distribution)
    FCFs = FCF[FCF(Cut[Cut(zeros(data.B), ub, zeros(data.B))],t) for t = 1:stages]
    
    LB = 0
    UB = 0
    while iter <= maxiter
        for _ in 1:options.forward_number
            _, storages = forward(prb, FCFs)
            FCFs = backward(prb, FCFs, storages)

            LB = update_lb(prb, FCFs)
            UB = update_ub(prb, FCFs)
        end
        if LB ≈ UB
            return LB, UB
        end
        iter += 1
    end
    return LB, UB
end

function update_lb(prb::Problem, FCFs::Vector{FCF})
    options = prb.options
    E_LB = 0
    for _ in 1:options.simul_lb_number
        LB, _ = forward(prb, FCFs)
        E_LB += LB/options.simul_lb_number
    end
    return E_LB
end

function update_ub(prb::Problem, FCFs::Vector{FCF})
    data = prb.data
    options = prb.options
    E_UB = 0
    for _ in 1:options.simul_ub_number
        solar = rand(data.pv_generation_distribution[1,:])
        initial_storage = data.store_init
        _create_sub_model!(prb, initial_storage, FCFs[1], solar)
        solve_model!(prb, false)
        model = prb.model
        E_UB += objective_value(model)/options.simul_ub_number
    end
    return E_UB

end

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
        LB += objective_value(model) - value(variable_by_name(model, "omega_$(t)"))
    end

    return LB, storages
end

function backward(prb::Problem, FCFs::Vector{FCF}, storages)
    data = prb.data
    options = prb.options
    stages, _ = size(data.pv_generation_distribution)


    for t = stages:-1:2
        Q = 0
        pi = zeros(data.B)
        initial_storage = storages[t-1]
        for _ in 1:options.backward_number
            solar = rand(data.pv_generation_distribution[t,:])
            _create_sub_model!(prb, initial_storage, FCFs[t], solar)
            solve_model!(prb, false)
            model = prb.model
            pi += dual.(model[:dual_fisher])/options.backward_number
            Q += objective_value(model)/options.backward_number
        end
        cut = Cut(pi, Q, initial_storage)
        push!(FCFs[t-1].cuts, cut)
    end
    
    return FCFs
end

function apply_cuts!(prb::Problem, FCF::FCF)
    model= prb.model

    x = model[:energy_storage]
    model[:omega_t] = omega_t = @variable(model, base_name = "omega_"*string(FCF.stage))
    for cut in FCF.cuts
        @constraint(model, omega_t <= sum(cut.π .* (x .- cut.x)) + cut.Q)
    end
    objective = objective_function(model)
    objective += omega_t
    set_objective_function(model, objective)
end