function create_model!(prb::Problem, relaxed::Bool = false)
    prb.model = Model(prb.options.solver)
    set_silent(prb.model)
    prb.options.relaxed = relaxed
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
    prb.model = Model(prb.options.solver)
    set_silent(prb.model)
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
    model[:omega_t] = omega_t = @variable(model, base_name = "omega_"*string(FCF.stage))
    for cut in FCF.cuts
        @constraint(model, omega_t <= sum(cut.π .* (x .- cut.x)) + cut.Q)
    end
    objective = objective_function(model)
    objective += omega_t
    set_objective_function(model, objective)
end