@kwdef mutable struct Data
    B::Int64
    T::Int64
    N_s::Int64
    N_k::Int64
    stage::Int

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
    pv_generation_distribution::Matrix{Float64}
    D::Float64
    
    energy_arrived::Vector{Vector{Float64}}
    max_arrived::Vector{Vector{Float64}}
    min_arrived::Vector{Vector{Float64}}
    vehicles_arrived::Vector{Int}

    energy_arrived_temp::Vector{Vector{Float64}}
    max_arrived_temp::Vector{Vector{Float64}}
    min_arrived_temp::Vector{Vector{Float64}}
    vehicles_arrived_temp::Vector{Int}

    store_init::Vector{Float64}
    store_init_temp::Vector{Float64}
    rho::Float64

end

@kwdef mutable struct Options
    relaxed::Bool
    solver::Union{DataType,Nothing} = nothing
    forward_number::Int
    backward_number::Int
    simul_ub_number::Int
    simul_lb_number::Int
end

@kwdef mutable struct Problem
    data::Data
    options::Options
    model::JuMP.Model
end

struct Cut
    π::Union{Float64,Array{Float64}}
    Q::Float64
    x::Union{Float64,Array{Float64}}
end

struct FCF
    cuts::Array{Cut}
    stage::Int64
end
