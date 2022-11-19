function add_energy_storage!(prb::Problem)
    model = prb.model
    store_max = prb.data.store_max
    store_min = prb.data.store_min
    B = prb.data.B
    T = prb.data.T

    @variable(model, store_min <= energy_storage[1:B, 1:T] <= store_max)
end

function add_energy_sold_battery!(prb::Problem)
    model = prb.model
    store_max = prb.data.store_max
    B = prb.data.B
    T = prb.data.T

    @variable(model, 0.0 <= energy_sold[1:B, 1:T] <= store_max)
end

function add_energy_sold_vehicle!(prb::Problem)
    model = prb.model
    store_max = prb.data.store_max
    vehicles_arrived = prb.data.vehicles_arrived
    B = prb.data.B
    T = prb.data.T

    @variable(model, 0.0 <= energy_sold_vehicle[t in 1:T, 1:vehicles_arrived[t], 1:B] <= store_max)
end

function add_energy_bought_grid!(prb::Problem)
    model = prb.model
    T = prb.data.T

    @variable(model, 0.0 <= energy_bought_grid[1:T])
end

function add_charging_battery!(prb::Problem)
    model = prb.model
    B = prb.data.B
    T = prb.data.T

    @variable(model, K[1:B, 1:T], Bin)
end

function add_swapping_battery!(prb::Problem)
    model = prb.model
    B = prb.data.B
    T = prb.data.T

    @variable(model, S[1:B, 1:T], Bin)
end

function add_energy_charger!(prb::Problem)
    model = prb.model
    store_max = prb.data.store_max
    store_min = prb.data.store_min
    B = prb.data.B
    T = prb.data.T

    @variable(model, store_min <= energy_charger[1:B, 1:T] <= store_max)
end

function add_pv_generation_bat!(prb::Problem)
    model = prb.model
    pv_generation = prb.data.pv_generation
    T = prb.data.T

    @variable(model, 0.0 <= pv_generation_bat[t = 1:T] <= pv_generation[t])
end

function add_pv_generation_grid!(prb::Problem)
    model = prb.model
    pv_generation = prb.data.pv_generation
    T = prb.data.T

    @variable(model, 0.0 <= pv_generation_grid[t = 1:T] <= pv_generation[t])
end

function add_assignment!(prb::Problem)
    model = prb.model
    vehicles_arrived = prb.data.vehicles_arrived
    T = prb.data.T
    B = prb.data.B
    if true #TODO
        @variable(model, A[t in 1:T, 1:vehicles_arrived[t], 1:B], Bin)
    else
        @variable(model, 0 <= A[t in 1:T, 1:vehicles_arrived[t], 1:B] <= 1)
    end
end

function add_trick_C_B!(prb::Problem)
    model = prb.model
    T = prb.data.T
    B = prb.data.B

    @variable(model, Y_C_B[1:T-1, 1:B])
end

function add_trick_B_B!(prb::Problem)
    model = prb.model
    vehicles_arrived = prb.data.vehicles_arrived
    T = prb.data.T
    B = prb.data.B

    @variable(model,Y_B_B[t in 1:T, 1:vehicles_arrived[t], 1:B], Bin)
end