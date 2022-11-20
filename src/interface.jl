function create_model!(prb::Problem, relaxed::Bool = false)
    prb.model = Model(prb.data.solver)
    prb.data.relaxed = relaxed
    choose_stage!(prb::Problem)
    add_variables!(prb)
    add_constraints!(prb)
    add_objective!(prb)
end

function solve_model!(prb::Problem, fixed::Bool = false)

    optimize!(prb.model)
    if fixed
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

        optimize!(prb.model)
    end
end

function choose_stage!(prb::Problem)
    data = prb.data

    if data.stage == 0
        data.energy_arrived_temp = data.energy_arrived
        data.max_arrived_temp = data.max_arrived
        data.min_arrived_temp = data.min_arrived
        data.vehicles_arrived_temp = data.vehicles_arrived
        data.store_init_temp = data.store_init
    else
        data.energy_arrived_temp = data.energy_arrived[data.stage:data.stage]
        data.max_arrived_temp = data.max_arrived[data.stage:data.stage]
        data.min_arrived_temp = data.min_arrived[data.stage:data.stage]
        data.vehicles_arrived_temp = data.vehicles_arrived[data.stage:data.stage]
    end
end

function _create_sub_model!(prb::Problem, initial_storage::Vector{Float64}, FCF::FCF, solar::Float64)
    prb.model = Model(prb.data.solver)

    # prb.data.relaxed = false
    prb.data.stage = FCF.stage
    prb.data.pv_generation = [solar]
    prb.data.store_init_temp = initial_storage

    choose_stage!(prb::Problem)
    add_variables!(prb)
    add_constraints!(prb)
    add_objective!(prb)
    apply_cuts!(prb, FCF)
end

function apply_cuts!(prb::Problem, FCF::FCF)
    model= prb.model

    x = model[:energy_storage]
    model[:omega_t] = omega_t = @variable(model, base_name = "omega_"*string(FCF.stage), lower_bound = 0.0)
    for cut in FCF.cuts
        @constraint(model, omega_t >= sum(cut.π .* (x .- cut.x)) + cut.Q)
    end
    objective = objective_function(model)
    objective -= omega_t
    set_objective_function(model, objective)
end


function sddp_rb(prb::Problem; maxiter = 10)
    iter = 1
    data = prb.data
    data.T = 1
    B = data.B
    stages = length(data.pv_generation_distribution)
    FCFs = FCF[FCF(Cut[Cut(zeros(3)...)],t) for t = 1:stages]
    
    while iter <= maxiter
        vs = [[] for _ = 1:stages]
        pis = [[] for _ = 1:stages]
        Qs = [[] for _ = 1:stages]
        us = [[] for _ = 1:stages]
        for t = 1:stages, (k,St) in enumerate(data.pv_generation_distribution[t])
            pi = zeros(B)
            Q = 0.0
            u = 0.0
            for solar in St
                initial_storage = (t == 1 ? data.store_init : vs[t-1][k])
                _create_sub_model!(prb, initial_storage, FCFs[t], solar)
                solve_model!(prb, false)
                model = prb.model
                push!(vs[t], value.(model[:energy_storage])[:,1])
                pi += dual.(model[:dual_fisher])
                Q += objective_value(model)
                u += objective_value(model) - value(variable_by_name(model, "omega_$(t)"))
            end
            push!(pis[t], pi/length(St))
            push!(Qs[t],Q/length(St))
            push!(us[t],u/length(St))
        end
        global UB = sum(mean.(us))

        for t = stages:-1:2, (k,St) in enumerate(data.pv_generation_distribution[t])
            cut = Cut(pis[t][k],Qs[t][k],vs[t-1][k])
            push!(FCFs[t-1].cuts,cut)
        end
        temp = 0.0
        for i in 1:length(data.pv_generation_distribution[1][1])
            solar = data.pv_generation_distribution[1][1][i]
            _create_sub_model!(prb, data.store_init, FCFs[1], solar)
            solve_model!(prb, false)
            temp += objective_value(prb.model)
        end

        global LB = temp/length(data.pv_generation_distribution[1][1])

        iter = iter + 1
    end
    return LB, UB
end