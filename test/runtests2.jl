using ElectricVehicles
using HiGHS
using JuMP

prb = ElectricVehicles.Problem()
data = prb.data

filename = "test/data/acndata_sessions.json"
df_lengths_cars = get_cars_electric_demand(filename)
lengths_cars = Int64.(df_lengths_cars.Count)
# 100 solar panels (KWh)
solar_data = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.39408, 17.11094, 21.53498, 22.33154, 20.40962, 14.99074, 7.6846, 0.92978, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
Max_Baterry_Cap = 60
data.B = 10
data.T = length(lengths_cars)
data.N_s = 10
data.N_k = 10
data.store_max = Max_Baterry_Cap
data.store_min = 0.0
data.ramp_max = 0.3*Max_Baterry_Cap
data.converter_max = 0.6
data.battery_energy_price = 5.0
data.swap_price = 5.0
data.grid_sell_price = -5.0
data.grid_buy_price = 1000.0
data.pv_price = 0.0
data.con_efficiency = 0.95
data.charger_efficiency = 0.99
data.pv_generation = solar_data
data.D = 1.0
data.swap_min = 0.7*Max_Baterry_Cap
data.energy_arrived = df_lengths_cars.EQ
data.vehicles_arrived = lengths_cars
data.store_init = ones(data.B)*Max_Baterry_Cap
data.swap_min = 0.7
data.energy_arrived = [[0.5, 0.5], [0.5], [0.5]]
data.max_arrived = [[1, 1], [1], [1]]
data.min_arrived = [[0, 0], [1], [1]]
data.vehicles_arrived = [2,1,1]
data.store_init = [1.0, 1.0]
data.rho = 0.0

data.solver = HiGHS.Optimizer

ElectricVehicles.create_model!(prb)
ElectricVehicles.solve_model!(prb)

value.(prb.model[:Y_C_B])
value.(prb.model[:energy_storage])
value.(prb.model[:energy_sold])


value.(prb.model[:Y_B_B])

