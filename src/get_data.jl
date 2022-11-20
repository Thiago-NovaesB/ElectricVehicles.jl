function get_cars_electric_demand(filename::String, mean::Bool=true)

    js_data = JSON.parsefile(filename)

    arrivals = DateTime[]
    for js in js_data["_items"]
        push!(arrivals, DateTime(js["connectionTime"][1:end-4], dateformat"eee, dd uuu yyyy HH:MM:SS")-Hour(7))
    end
    energy_requested = Float64[]
    for js in js_data["_items"]
        if js["userInputs"] !== nothing
            push!(energy_requested, js["userInputs"][1]["kWhRequested"])
        else
            push!(energy_requested,0.0)
        end
    end
    
    df_arrivals = DataFrame(time = arrivals, energyRequested = energy_requested);
    df_arrivals_hourly = df_arrivals |>
        @groupby(Dates.format(_.time, "dd-mm-yyyy HH")) |>
        @map({Key=key(_), Count=length(_)}) |>
        DataFrame

    if mean
        df_arrivals_hourly_mean = df_arrivals |>
        @groupby(Dates.format(_.time, "HH")) |>
        @map({Key=key(_), Count=round(length(_)/365), EQ = _.energyRequested[1:min(Int(round(length(_)/365)),length(_.energyRequested))]}) |>
        DataFrame

        df_arrivals_hourly_mean = sort(df_arrivals_hourly_mean)
        return df_arrivals_hourly_mean
    else
        start = Date(js_data["_meta"]["start"][1:end-4], dateformat"eee, dd uuu yyyy HH:MM:SS")
        final = Date(js_data["_meta"]["end"][1:end-4], dateformat"eee, dd uuu yyyy HH:MM:SS")

        all_hours = collect(DateTime(start):Hour(1):DateTime(final))
        all_hours = Dates.format.(all_hours, "dd-mm-yyyy HH")
        df_all_hours = DataFrame(Time = all_hours)
        df_new = DataFrame(Time = all_hours, Arrivals_full = 0)

        df = sort(leftjoin(df_all_hours, df_arrivals_hourly , on = :Time => :Time))
        df_new[.!ismissing.(df.Arrivals), :Arrivals_full]  = df[.!ismissing.(df.Arrivals), :Arrivals]
        rename!(df_new, "Arrivals_full" => "Arrivals")
        return df_new
    end
end

    