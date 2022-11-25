function create_sddip(prb::Problem, ub = 50)

    data = prb.data
    options = prb.options

    model = SDDP.LinearPolicyGraph(
        stages = data.T,
        sense = :Max,
        upper_bound = ub,
        optimizer = options.solver,
    ) do subproblem, node
        
        # #state variables
        @variable(subproblem, data.store_min <= energy_storage[b = 1:data.B] <= data.store_max, SDDP.State, initial_value = data.store_init[b])

        # # #control variables
        @variable(subproblem, 0.0 <= energy_sold[1:data.B] <= data.store_max - data.store_min)
        @variable(subproblem, 0.0 <= energy_sold_vehicle[1:data.vehicles_arrived[node], 1:data.B] <= data.store_max)
        @variable(subproblem, 0.0 <= energy_bought_grid)
        @variable(subproblem, K[1:data.B], Bin)
        @variable(subproblem, S[1:data.B], Bin)
        @variable(subproblem, 0 <= energy_charger[1:data.B] <= data.ramp_max)
        @variable(subproblem, A[1:data.vehicles_arrived[node], 1:data.B], Bin)
        @variable(subproblem, Y_C_B[1:data.B])
        @variable(subproblem, pv_generation)
        @variable(subproblem, 0.0 <= pv_generation_bat)
        @variable(subproblem, 0.0 <= pv_generation_grid)

        # # #constraints
        @constraint(subproblem, pv_generation_bat <= pv_generation)
        @constraint(subproblem, pv_generation_grid <= pv_generation)
        @constraint(subproblem, battery_balance[b = 1:data.B], energy_storage[b].out == energy_storage[b].in + energy_charger[b]*data.D*data.charger_efficiency - energy_sold[b]) 
        @constraint(subproblem, aux_Y_C_B_1[b = 1:data.B], Y_C_B[b] <= data.store_max*S[b])
        @constraint(subproblem, aux_Y_C_B_2[b = 1:data.B], Y_C_B[b] <= energy_storage[b].in)
        @constraint(subproblem, aux_Y_C_B_3[b = 1:data.B], Y_C_B[b] >= energy_storage[b].in - data.store_max*(1-S[b])) 
        @constraint(subproblem, aux_Y_C_B_4[b = 1:data.B], Y_C_B[b] >= data.store_min*S[b])
        @constraint(subproblem, aux_1[v = 1:data.vehicles_arrived[node], b = 1:data.B], energy_sold_vehicle[v, b] <= data.store_max*A[v,b])
        @constraint(subproblem, aux_2[v = 1:data.vehicles_arrived[node], b = 1:data.B], energy_sold_vehicle[v, b] <= energy_sold[b])
        @constraint(subproblem, aux_3[v = 1:data.vehicles_arrived[node], b = 1:data.B], energy_sold_vehicle[v, b] >= energy_sold[b] - data.store_max*(1-A[v,b])) 
        @constraint(subproblem, lala1[v = 1:data.vehicles_arrived[node], b = 1:data.B], energy_sold_vehicle[v, b] <= data.max_arrived[node][v]*A[v,b])
        @constraint(subproblem, lala2[v = 1:data.vehicles_arrived[node], b = 1:data.B], data.min_arrived[node][v]*A[v,b] <= energy_sold_vehicle[v,b])
        @constraint(subproblem, energy_sold_balance[b = 1:data.B], energy_sold[b] == (Y_C_B[b] - sum(A[v,b]*data.energy_arrived[node][v] for v in 1:data.vehicles_arrived[node])))
        if node == data.T
            @constraint(subproblem, final_storage[b = 1:data.B], energy_storage[b].out >= data.rho*data.store_max ) 
        end
        @constraint(subproblem, con_1[b = 1:data.B], sum(A[v,b] for v in 1:data.vehicles_arrived[node]) == S[b])
        @constraint(subproblem, con_2[v = 1:data.vehicles_arrived[node]], sum(A[v,b] for b in 1:data.B) <= 1)
        @constraint(subproblem, choose_action[b = 1:data.B], K[b] + S[b] <= 1) 
        @constraint(subproblem, swap_battery, sum(S[:]) <= min(data.vehicles_arrived[node], data.N_s)) 
        @constraint(subproblem, max_charges, sum(K[:]) <= data.N_k) 
        @constraint(subproblem, max_charger[b in 1:data.B], energy_charger[b] <= data.ramp_max*K[b]) 
        @constraint(subproblem, disponible_converter_energy, sum(energy_charger[:]) <= data.converter_max) 
        @constraint(subproblem, pv_balance, pv_generation >= pv_generation_bat + pv_generation_grid) 
        @constraint(subproblem, energy_balance, sum(energy_charger[:]) == pv_generation_bat + energy_bought_grid) 

        # # #objective
        @stageobjective(subproblem, sum(data.battery_energy_price*energy_sold + data.swap_price*S)
        + sum( pv_generation_grid*data.grid_sell_price*data.con_efficiency*data.D)
        - sum( energy_bought_grid*data.grid_buy_price*data.D)
        - sum( data.pv_price*pv_generation*data.D)
        ) 

        #random variable
        pv_generation_data = data.pv_generation_distribution[node,:]
        S_scen = length(pv_generation_data)
        P = (1/S_scen)*ones(S_scen)
        SDDP.parameterize(subproblem, pv_generation_data, P) do ω
            return JuMP.fix(pv_generation, ω)
        end

    end
    return model
end 

function solve_sddip(model, iteration_limit = 10)
    SDDP.train(
        model;
        iteration_limit = iteration_limit,
        duality_handler = SDDP.ContinuousConicDuality(),
    )
    return model
end