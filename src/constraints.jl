# function add_dual_fisher!(prb::Problem)
#     model = prb.model
#     data = prb.data
#     B = prb.data.B
#     energy_storage_inital = model[:energy_storage_inital]

#     @constraint(model, dual_fisher[b in 1:B], energy_storage_inital[b] == data.store_init[b])
# end

function add_battery_balance!(prb::Problem)
    model = prb.model
    B = prb.data.B
    T = prb.data.T
    D = prb.data.D
    charger_efficiency = prb.data.charger_efficiency
    store_init = prb.data.store_init

    energy_storage = model[:energy_storage]
    energy_charger = model[:energy_charger]
    energy_sold = model[:energy_sold]

    @constraint(model, battery_balance_0[b = 1:B], energy_storage[b, 1] == store_init[b] + energy_charger[b, 1]*D*charger_efficiency - energy_sold[b, 1]) 
    @constraint(model, battery_balance[b = 1:B, t = 2:T], energy_storage[b, t] == energy_storage[b, t-1] + energy_charger[b, t]*D*charger_efficiency - energy_sold[b, t]) 
end

function add_linear_Cont_Bin1!(prb::Problem)
    model = prb.model
    B = prb.data.B
    T = prb.data.T
    store_max = prb.data.store_max
    store_min = prb.data.store_min

    S = model[:S]
    energy_storage = model[:energy_storage]
    Y_C_B = model[:Y_C_B]
    
    @constraint(model, aux_Y_C_B_1[t = 1:T-1, b = 1:B], Y_C_B[b, t] <= store_max*S[b,t+1])
    @constraint(model, aux_Y_C_B_2[t = 1:T-1, b = 1:B], Y_C_B[b, t] <= energy_storage[b, t])
    @constraint(model, aux_Y_C_B_3[t = 1:T-1, b = 1:B], Y_C_B[b, t] >= energy_storage[b, t] - store_max*(1-S[b,t+1])) 
    @constraint(model, aux_Y_C_B_4[t = 1:T-1, b = 1:B], Y_C_B[b, t] >= store_min*S[b,t+1])
    
end

function add_linear_Cont_Bin2!(prb::Problem)
    model = prb.model
    B = prb.data.B
    T = prb.data.T
    store_max = prb.data.store_max
    vehicles_arrived = prb.data.vehicles_arrived

    A = model[:A]
    energy_sold_vehicle = model[:energy_sold_vehicle]
    energy_sold = model[:energy_sold]
    
    @constraint(model, aux_1[t = 1:T, v = 1:vehicles_arrived[t], b = 1:B], energy_sold_vehicle[t, v, b] <= store_max*A[t,v,b])
    @constraint(model, aux_2[t = 1:T, v = 1:vehicles_arrived[t], b = 1:B], energy_sold_vehicle[t, v, b] <= energy_sold[b, t])
    @constraint(model, aux_3[t = 1:T, v = 1:vehicles_arrived[t], b = 1:B], energy_sold_vehicle[t, v, b] >= energy_sold[b, t] - store_max*(1-A[t,v,b])) 
    
end

function add_bound_energy_sold!(prb::Problem)
    model = prb.model
    B = prb.data.B
    T = prb.data.T
    max_arrived = prb.data.max_arrived
    min_arrived = prb.data.min_arrived
    vehicles_arrived = prb.data.vehicles_arrived

    A = model[:A]
    energy_sold_vehicle = model[:energy_sold_vehicle]
    
    @constraint(model, lala1[t = 1:T, v = 1:vehicles_arrived[t], b = 1:B], energy_sold_vehicle[t,v,b] <= max_arrived[t][v]*A[t,v,b])
    @constraint(model, lala2[t = 1:T, v = 1:vehicles_arrived[t], b = 1:B], min_arrived[t][v]*A[t,v,b] <= energy_sold_vehicle[t,v,b])
end

function add_energy_sold_balance!(prb::Problem)
    model = prb.model
    B = prb.data.B
    T = prb.data.T
    store_init = prb.data.store_init
    energy_arrived = prb.data.energy_arrived
    vehicles_arrived = prb.data.vehicles_arrived

    energy_sold = model[:energy_sold]
    S = model[:S]
    A = model[:A]
    Y_C_B = model[:Y_C_B]

    @constraint(model, energy_sold_balance_0[b = 1:B], energy_sold[b, 1] == (store_init[b]*S[b,1] - sum(A[1,v,b]*energy_arrived[1][v] for v in 1:vehicles_arrived[1])))
    @constraint(model, energy_sold_balance[b = 1:B, t = 2:T], energy_sold[b, t] == (Y_C_B[b, t-1] - sum(A[t,v,b]*energy_arrived[t][v] for v in 1:vehicles_arrived[t])))
end

function add_final_storage!(prb::Problem)
    model = prb.model
    B = prb.data.B
    T = prb.data.T
    store_max = prb.data.store_max
    rho = prb.data.rho
    
    energy_storage = model[:energy_storage]

    @constraint(model, final_storage[b = 1:B], energy_storage[b, T] >= rho*store_max ) 
end

function add_assignment_con_1!(prb::Problem)
    model = prb.model
    B = prb.data.B
    T = prb.data.T
    vehicles_arrived = prb.data.vehicles_arrived
    A = model[:A]
    S = model[:S]

    @constraint(model, con_1[b = 1:B, t = 1:T], sum(A[t,v,b] for v in 1:vehicles_arrived[t]) == S[b,t]) #TODO
end

function add_assignment_con_2!(prb::Problem)
    model = prb.model
    B = prb.data.B
    T = prb.data.T
    vehicles_arrived = prb.data.vehicles_arrived
    A = model[:A]

    @constraint(model, con_2[t = 1:T, v = 1:vehicles_arrived[t]], sum(A[t,v,b] for b in 1:B) <= 1) #TODO
end

function add_choose_action!(prb::Problem)
    model = prb.model
    B = prb.data.B
    T = prb.data.T

    S = model[:S]
    K = model[:K]

    @constraint(model, choose_action[b = 1:B, t = 1:T], K[b, t] + S[b, t] <= 1) 
end

function add_swap_battery!(prb::Problem)
    model = prb.model
    T = prb.data.T
    N_s = prb.data.N_s
    vehicles_arrived = prb.data.vehicles_arrived

    S = model[:S]

    @constraint(model, swap_battery[t in 1:T], sum(S[:,t]) <= min(vehicles_arrived[t], N_s)) 
end

function add_max_charges!(prb::Problem)
    model = prb.model
    N_k = prb.data.N_k
    T = prb.data.T

    K = model[:K]

    @constraint(model, max_charges[t in 1:T], sum(K[:,t]) <= N_k) 
end

function add_max_charger!(prb::Problem)
    model = prb.model
    ramp_max = prb.data.ramp_max
    T = prb.data.T
    B = prb.data.B

    K = model[:K]
    energy_charger = model[:energy_charger]

    @constraint(model, max_charger[b in 1:B, t in 1:T], energy_charger[b,t] <= ramp_max*K[b,t]) 
end

function add_disponible_converter_energy!(prb::Problem)
    model = prb.model
    converter_max = prb.data.converter_max
    T = prb.data.T
    
    energy_charger = model[:energy_charger]

    @constraint(model, disponible_converter_energy[t in 1:T], sum(energy_charger[:,t]) <= converter_max) 
end

function add_pv_balance!(prb::Problem)
    model = prb.model
    T = prb.data.T
    pv_generation = prb.data.pv_generation
    
    pv_generation_bat = model[:pv_generation_bat]
    pv_generation_grid = model[:pv_generation_grid]

    @constraint(model, pv_balance[t in 1:T], pv_generation[t] >= pv_generation_bat[t] + pv_generation_grid[t]) 
end

function add_energy_balance!(prb::Problem)
    model = prb.model
    T = prb.data.T
    
    energy_charger = model[:energy_charger]
    energy_bought_grid = model[:energy_bought_grid]
    pv_generation_bat = model[:pv_generation_bat]

    @constraint(model, energy_balance[t in 1:T], sum(energy_charger[:,t]) == pv_generation_bat[t] + energy_bought_grid[t]) 
end