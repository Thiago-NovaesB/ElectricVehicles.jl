using ElectricVehicles
using HiGHS
using JuMP

prb = ElectricVehicles.Problem()
data = prb.data

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
data.D = 1.0
data.swap_min = 0.7
data.energy_arrived = [[0.5, 0.5], [0.5], [0.5]]
data.vehicles_arrived = [2,1,1]
data.store_init = [1.0, 1.0]
data.rho = 0.0

data.solver = HiGHS.Optimizer

ElectricVehicles.create_model!(prb)
ElectricVehicles.solve_model!(prb)

value.(prb.model[:S])
value.(prb.model[:Y_C_B])
value.(prb.model[:energy_storage])
value.(prb.model[:energy_sold])


value.(prb.model[:Y_B_B])

