module Annealing
using StaticArrays, Random, ProgressBars

@inline function exp_temp_decay(τ::T; α::T = 0.05, cutoff::T = 1e-4)::T where T<:AbstractFloat
    val =  exp(-α*τ)
    @assert α > zero(T)
    #maybe cond ? outp1 : outp2 is faster
    if val < cutoff
        return zero(T)
    else
        return val
    end
end

@inline function geometric_temp_decay(τ::T; α::T = 0.05, γ::T = 1.5, cutoff::T = 1e-4)::T where T<:AbstractFloat
    @fastmath val = α * τ^(-γ)
    if val < cutoff
        return zero(T)
    else 
        return val
    end
end

#try to deal with boilerplate!!!
@inline function Gaussian_perturbator(x::AbstractArray{T}; σ::AbstractArray{T}, NDim::Int)::AbstractArray{T} where T<:AbstractFloat
    #outputs vectors for SVectors - look for fix!
    U = typeof(x)
    #boilerplate
    rand_norm = U(randn(T,NDim))
    noise = σ .* rand_norm
    new_sol = x + noise
    return new_sol
end

struct AnnealingBinder{F,U}
    temp_func::F
    evolve_func::U
    function AnnealingBinder(temp_evol, T_args::NamedTuple, sol_evol, sol_args::NamedTuple)
        #the only constraint on these functions is that sol_args last element must be NDinms
        local_temp_func(x) = temp_evol(x;T_args...)
        local_evol(x) = sol_evol(x;sol_args...)
        F0 = typeof(local_temp_func)
        U0 = typeof(local_evol)
        new{F0,U0}(local_temp_func,local_evol)
    end
end

function execute_anneal(cost_func, model::AnnealingBinder, dτ::T, x0::AbstractArray{T}; max_steps::N) where {T<:AbstractFloat,N<:Integer}
    #wont track results and has no domain - pretty simple
    τ = zero(T)
    ref = zero(T)
    Temp = model.temp_func(τ)
    val0 = cost_func(x0)


    for i in ProgressBar(1:max_steps)

        new_x0 = model.evolve_func(x0)

        new_val0 = cost_func(new_x0)

        dval = new_val0 - val0

        if dval < ref #moving towards minima
            #we could add domain based rejection here.
            x0 = new_x0
            val0 = new_val0
        else
            accept_prob = exp(-dval/Temp)
            comp_prob = rand(T)
            condition = accept_prob > comp_prob
            x0 = condition ? new_x0 : x0
            val0 = condition ? new_val0 : val0
        end

        τ += dτ
        Temp = model.temp_func(τ)
        if Temp <= ref
            break
        end
    end
    return x0, val0
end

function execute_anneal_tracked(cost_func, model::AnnealingBinder, dτ::T, x0::AbstractArray{T}; max_steps::N) where {T<:AbstractFloat,N<:Integer}
    #wont track results and has no domain - pretty simple
    τ = zero(T)
    ref = zero(T)
    Temp = model.temp_func(τ)
    val0 = cost_func(x0)
    tracker_x0= Vector{typeof(x0)}(undef,max_steps)
    tracker_val0 = Vector{T}(undef,max_steps)


    for i in ProgressBar(1:max_steps)
        tracker_x0[i] = x0
        tracker_val0[i] = val0
        new_x0 = model.evolve_func(x0)

        new_val0 = cost_func(new_x0)

        dval = new_val0 - val0

        if dval < ref #moving towards minima
            #we could add domain based rejection here.
            x0 = new_x0
            val0 = new_val0
        else
            accept_prob = exp(-dval/Temp)
            comp_prob = rand(T)
            condition = accept_prob > comp_prob
            x0 = condition ? new_x0 : x0
            val0 = condition ? new_val0 : val0
        end
        

        τ += dτ
        Temp = model.temp_func(τ)
        if Temp <= ref
            tracker_x0 = @views tracker_x0[1:i]
            tracker_val0 = @views tracker_val0[1:i]
            break
        end
    end
    return x0, val0, tracker_x0, tracker_val0
end



#module end
export exp_temp_decay, geometric_temp_decay, Gaussian_perturbator, AnnealingBinder, execute_anneal, execute_anneal_tracked
end
using StaticArrays, .Annealing, Plots


f(x) =  begin 
    A = 5
    z =  @. A + x*x - A*cos(2*π*x)
    return z[1]
end

f(x::Float64) =  begin 
    A = 5
    z =  @. A + x*x - A*cos(2*π*x)
    return z
end

x0 = SA[10.0]
NDims = 1

cool_params = (α = 0.01, cutoff = 1e-4)
var_params = (σ = SA[0.7], NDim = 1)
dτ = 0.025

model = AnnealingBinder(exp_temp_decay,cool_params,Gaussian_perturbator,var_params)

xf, valf, x0_p, val_p = execute_anneal_tracked(f,model,dτ,x0, max_steps = 100000)

x0_p = [(x0_p...)...]

N = length(x0_p)

plotscolors = [RGB(0.1,1 - n/N,n/N) for n in 1:N]

plotx = LinRange(-2,10,2000)
ploty = f.(plotx)
plot1 = plot(plotx, ploty, ls = :dash, color = :green, label = "f(x) = A + x^2 - A cos(2πx)", dpi = 1600)
scatter!(x0_p, val_p, c = plotscolors, label = "Path of annealer" , ms = 1.0)