@kwdef mutable struct Data
    B::Int64
    T::Int64
    N_s::Int64
    N_k::Int64

    store_max::Float64
    store_min::Float64

    ramp_max::Float64
    converter_max::Float64
    battery_energy_price::Float64
    swap_price::Float64
    grid_sell_price::Float64
    grid_buy_price::Float64
    pv_price::Float64
    con_efficiency::Float64
    charger_efficiency::Float64
    pv_generation::Vector{Float64}
    D::Float64
    
    swap_min::Float64
    energy_arrived::Vector{Vector{Float64}}
    max_arrived::Vector{Vector{Float64}}
    min_arrived::Vector{Vector{Float64}}
    vehicles_arrived::Vector{Int}
    store_init::Vector{Float64}
    rho::Float64

    solver::Union{DataType,Nothing} = nothing
end

@kwdef mutable struct Cache

end

@kwdef mutable struct Output

end


@kwdef mutable struct Problem
    data::Data
    cache::Cache
    output::Output
    model::JuMP.Model
end

