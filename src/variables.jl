function add_energy_storage!(prb::Problem)
    model = prb.model
    store_max = prb.data.store_max
    store_min = prb.data.store_min
    B = prb.data.B
    T = prb.data.T

    @variable(model, store_min <= energy_storage[1:B, 1:T+1] <= store_max)
end

function add_energy_sold_battery!(prb::Problem)
    model = prb.model
    store_max = prb.data.store_max
    store_min = prb.data.store_min
    B = prb.data.B
    T = prb.data.T

    @variable(model, 0.0 <= energy_sold[1:B, 1:T] <= store_max - store_min)
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
    relaxed = prb.data.relaxed
    B = prb.data.B
    T = prb.data.T

    if relaxed
        @variable(model, 0 <= K[1:B, 1:T] <= 1)
    else
        @variable(model, K[1:B, 1:T], Bin)
    end
end

function add_swapping_battery!(prb::Problem)
    model = prb.model
    relaxed = prb.data.relaxed
    B = prb.data.B
    T = prb.data.T

    if relaxed
        @variable(model, 0 <= S[1:B, 1:T] <= 1)
    else
        @variable(model, S[1:B, 1:T], Bin)
    end
end

function add_energy_charger!(prb::Problem)
    model = prb.model
    ramp_max = prb.data.ramp_max

    B = prb.data.B
    T = prb.data.T

    @variable(model, 0 <= energy_charger[1:B, 1:T] <= ramp_max)
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
    relaxed = prb.data.relaxed
    T = prb.data.T
    B = prb.data.B
    
    if relaxed
        @variable(model, 0 <= A[t in 1:T, 1:vehicles_arrived[t], 1:B] <= 1)
    else
        @variable(model, A[t in 1:T, 1:vehicles_arrived[t], 1:B], Bin)
    end
end

function add_trick_C_B!(prb::Problem)
    model = prb.model
    T = prb.data.T
    B = prb.data.B

    @variable(model, Y_C_B[1:B, 1:T])
end