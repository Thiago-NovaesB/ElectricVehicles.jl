function sddp(prb::Problem; maxiter = 10)
    iter = 1
    data = prb.data
    data.T = 1
    B = data.B
    stages = length(data.pv_generation_distribution)
    FCFs = FCF[FCF(Cut[Cut(zeros(3)...)],t) for t = 1:stages]
    
    while iter <= maxiter
        vs = [[] for _ = 1:stages]
        pis = [[] for _ = 1:stages]
        Qs = [[] for _ = 1:stages]
        us = [[] for _ = 1:stages]
        for t = 1:stages, (k,St) in enumerate(data.pv_generation_distribution[t])
            pi = zeros(B)
            Q = 0.0
            u = 0.0
            for solar in St
                initial_storage = (t == 1 ? data.store_init : vs[t-1][k])
                _create_sub_model!(prb, initial_storage, FCFs[t], solar)
                solve_model!(prb, false)
                model = prb.model
                push!(vs[t], value.(model[:energy_storage])[:,end])
                pi += dual.(model[:dual_fisher])
                Q += objective_value(model)
                u += objective_value(model) - value(variable_by_name(model, "omega_$(t)"))
            end
            push!(pis[t], pi/length(St))
            push!(Qs[t],Q/length(St))
            push!(us[t],u/length(St))
        end
        global UB = sum(mean.(us))

        for t = stages:-1:2, (k,St) in enumerate(data.pv_generation_distribution[t])
            cut = Cut(pis[t][k],Qs[t][k],vs[t-1][k])
            push!(FCFs[t-1].cuts,cut)
        end
        temp = 0.0
        for i in 1:length(data.pv_generation_distribution[1][1])
            solar = data.pv_generation_distribution[1][1][i]
            _create_sub_model!(prb, data.store_init, FCFs[1], solar)
            solve_model!(prb, false)
            temp += objective_value(prb.model)
        end

        global LB = temp/length(data.pv_generation_distribution[1][1])

        iter = iter + 1
    end
    return LB, UB
end