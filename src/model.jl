function create_model!(prb::Problem)
    prb.model = Model(prb.data.solver)

    add_variables!(prb)
    add_constraints!(prb)
    add_objective!(prb)
end

function add_variables!(prb::Problem)
    
    add_energy_storage!(prb)
    add_energy_sold_battery!(prb)
    add_energy_sold_vehicle!(prb)
    add_energy_bought_grid!(prb)
    add_charging_battery!(prb)
    add_swapping_battery!(prb)
    add_energy_charger!(prb)
    add_pv_generation_bat!(prb)
    add_pv_generation_grid!(prb)
    add_assignment!(prb)
    add_trick_C_B!(prb)
    add_trick_B_B!(prb)
    nothing
end

function add_constraints!(prb::Problem)
    
    add_battery_balance!(prb)
    add_linear_Cont_Bin1!(prb)
    add_linear_Cont_Bin2!(prb)
    add_bound_energy_sold!(prb)
    add_energy_sold_balance!(prb)
    add_final_storage!(prb)
    add_assignment_con_1!(prb)
    add_assignment_con_2!(prb)
    add_choose_action!(prb)
    add_min_swap!(prb)
    add_swap_battery!(prb)
    add_max_charges!(prb)
    add_max_charger!(prb)
    add_disponible_converter_energy!(prb)
    add_pv_balance!(prb)
    add_energy_balance!(prb)
    nothing
end

function add_objective!(prb::Problem)
    
    add_max_profit!(prb)
    nothing
end

function solve_model!(prb::Problem)
    
    optimize!(prb.model)
end