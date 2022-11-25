using ElectricVehicles
using HiGHS
using JuMP
using SDDP

function create_data()
    
    prb = ElectricVehicles.Problem()
    data = prb.data
    options = prb.options

    data.B = 2
    data.T = 3 
    data.N_s = 2
    data.N_k = 2
    data.store_max = 1.0
    data.store_min = 0.0
    data.ramp_max = 0.3
    data.converter_max = 0.6
    data.battery_energy_price = 5.0
    data.swap_price = 5.0
    data.grid_sell_price = -5.0
    data.grid_buy_price = 1000.0
    data.pv_price = 0.0
    data.con_efficiency = 0.95
    data.charger_efficiency = 0.99
    data.pv_generation = ones(3)
    data.pv_generation_distribution = [0.6 1.0; 0.6 1.0; 0.6 1.0]
    # data.pv_generation_distribution = [0.0 0.0; 0.0 0.0; 0.0 0.0]

    data.D = 1.0
    data.energy_arrived = [[0.6, 0.6], [0.5], [0.5]]
    data.max_arrived = [[0.9, 0.9], [1], [1]]
    data.min_arrived = [[0, 0], [0.0], [0]]
    data.vehicles_arrived = [2,1,1]
    data.store_init = [1.0, 1.0]
    data.rho = 0.0

    options.solver = HiGHS.Optimizer
    options.forward_number = 1
    options.backward_number = 2
    options.simul_ub_number = 1
    options.simul_lb_number = 1
    return prb
end

##########################################
prb = create_data()
ElectricVehicles.create_model!(prb)
ElectricVehicles.solve_model!(prb)
objective_value(prb.model)
##########################################
prb = create_data()
ElectricVehicles.create_model!(prb)
ElectricVehicles.solve_model!(prb, true)
objective_value(prb.model)
##########################################
prb = create_data()
ElectricVehicles.create_model!(prb, true)
ElectricVehicles.solve_model!(prb)
objective_value(prb.model)
##########################################
prb = create_data()
model = ElectricVehicles.create_sddip(prb)
model = ElectricVehicles.solve_sddip(model)
##########################################
prb = create_data()
ElectricVehicles.sddp(prb, maxiter = 100)


value.(prb.model[:S])
value.(prb.model[:K])
value.(prb.model[:energy_storage])

