module ElectricVehicles

using JuMP
using HiGHS

include("utils.jl")
include("types.jl")
include("variables.jl")
include("constraints.jl")
include("objective.jl")
include("model.jl")

end # module ElectricVehicles
