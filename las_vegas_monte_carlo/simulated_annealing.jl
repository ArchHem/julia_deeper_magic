module Annealing
using StaticArrays, Random

function exp_temp_decay(τ::T; α::T = 0.05, cutoff::T = 1e-4)::T where T<:AbstractFloat
    val =  exp(-α*τ)
    @assert α > zero(T)
    #maybe cond ? outp1 : outp2 is faster
    if val < cutoff
        return zero(T)
    else
        return val
    end
end

function geometric_temp_decay(τ::T; α::T = 0.05, γ::T = 1.5, cutoff::T = 1e-4)::T where T<:AbstractFloat
    @fastmath val = α * τ^(-γ)
    if val < cutoff
        return zero(T)
    else 
        return val
    end
end

#implicitly use dispatch
function Gaussian_perturbator(x; σ, NDim::Int)
    T = eltype(x)
    new_sol = @. x + σ * randn(T,NDim) #will yield and SVector
    return new_sol
end

function generate_random_sample(low_dom,up_dom, NDims::Int)
    T = eltype(low_dom)
    sample = SVector{NDims, T}(@. rand(T, NDims) * (up_dom - low_dom) + low_dom)
    return sample
end

#module end
export exp_temp_decay, geometric_temp_decay, SimulatedAnnealing, Gaussian_perturbator, Gaussian_perturbator_1D
end
using StaticArrays, .Annealing