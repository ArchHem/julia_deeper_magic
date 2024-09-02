module MetropolisHastings
using StaticArrays, Random, ProgressBars

@inline function Gaussian_perturbator(x::AbstractArray{T}; σ::AbstractArray{T}, NDim::Int)::AbstractArray{T} where T<:AbstractFloat
    U = typeof(x)
    rand_norm = U(randn(T,NDim))
    noise = σ .* rand_norm
    new_sol = x + noise
    return new_sol
end


struct MHBinder{U}
    proposal_func::U
    function MHBinder(proposal, prop_args::NamedTuple)
        local_proposal(x) = proposal(x; prop_args...)
        U0 = typeof(local_proposal)
        new{U0}(local_proposal)
    end
end


function execute_mh(prob_func, model::MHBinder, x0::AbstractArray{T}; max_steps::N) where {T<:AbstractFloat,N<:Integer}
    ref = zero(T)
    val0 = prob_func(x0)
    tracker_x0 = Vector{typeof(x0)}(undef,max_steps)
    index = 1

    while index < max_steps

        new_x0 = model.proposal_func(x0)
        new_val0 = prob_func(new_x0)

        dval = new_val0/val0
        if rand(T) < dval
            x0 = new_x0
            val0 = new_val0
            index += 1
            tracker_x0[index] = x0
        end
    end
    return tracker_x0
end



# Module export
export Gaussian_perturbator, MHBinder, execute_mh

end

using Plots, BenchmarkTools
using Distributions, Statistics
using StaticArrays
using .MetropolisHastings

function prob_(x)
    dist = sum(x.^2)
    prob = exp(-dist) * abs(sin(dist))
    return prob
end

x0 = @SVector [0.0,]

proposal = Gaussian_perturbator
ndims = 1
sigma = @SVector [0.6]
params = (σ = sigma, NDim = ndims )
object_ = MHBinder(proposal,params)


x0s = execute_mh(prob_,object_,x0,max_steps=1000000)
x0s = Vector.(x0s)
x0s = vcat(x0s...)

histogram(x0s, normalization = :pdf, xlabel = "x", ylabel = "∝ P(x)", label = "MH samples", color = :green, dpi = 1500)