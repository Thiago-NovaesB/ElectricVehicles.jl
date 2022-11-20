module ElectricVehicles

    using Statistics
    using JuMP
    using HiGHS
    using JSON
    using Dates
    using DataFrames
    using Query
    using Plots

    include("get_data.jl")
    include("utils.jl")
    include("types.jl")
    include("variables.jl")
    include("constraints.jl")
    include("objective.jl")
    include("model.jl")
    include("interface.jl")

    export get_cars_electric_demand

end # module ElectricVehicles
