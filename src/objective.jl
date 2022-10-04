
function add_max_profit!(prb::Problem)
    model = prb.model
    swap_price = prb.data.swap_price
    battery_energy_price = prb.data.battery_energy_price
    grid_sell_price = prb.data.grid_sell_price
    pv_price = prb.data.pv_price
    con_efficiency = prb.data.con_efficiency
    D = prb.data.D
    grid_buy_price = prb.data.grid_buy_price
    pv_generation = prb.data.pv_generation #TODO !!!!!!

    energy_sold = model[:energy_sold]
    S = model[:S]
    pv_generation_grid = model[:pv_generation_grid]
    energy_bought_grid = model[:energy_bought_grid]

    @objective(model, Max, sum(battery_energy_price*energy_sold + swap_price*S)
                            + sum( pv_generation_grid*grid_sell_price*con_efficiency*D)
                            - sum( energy_bought_grid*grid_buy_price*D)
                            - sum( pv_price*pv_generation*D)
                            ) 
    
end