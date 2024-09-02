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


function execute_mh(log_prob_func, model::MHBinder, x0::AbstractArray{T}; max_steps::N) where {T<:AbstractFloat,N<:Integer}
    ref = zero(T)
    val0 = log_prob_func(x0)

    for i in ProgressBar(1:max_steps)

        new_x0 = model.proposal_func(x0)
        new_val0 = log_prob_func(new_x0)

        dval = new_val0 - val0
        if dval > ref || rand(T) < exp(dval)
            x0 = new_x0
            val0 = new_val0
        end
    end
    return x0, val0
end

# Execute Metropolis-Hastings with tracking
function execute_mh_tracked(log_prob_func, model::MHBinder, x0::AbstractArray{T}; max_steps::N) where {T<:AbstractFloat,N<:Integer}
    ref = zero(T)
    val0 = log_prob_func(x0)
    tracker_x0= Vector{typeof(x0)}(undef,max_steps)
    tracker_val0 = Vector{T}(undef,max_steps)

    for i in ProgressBar(1:max_steps)
        tracker_x0[i] = x0
        tracker_val0[i] = val0

        new_x0 = model.proposal_func(x0)
        new_val0 = log_prob_func(new_x0)

        dval = new_val0 - val0
        if dval > ref || rand(T) < exp(dval)
            x0 = new_x0
            val0 = new_val0
        end
    end
    return x0, val0, tracker_x0, tracker_val0
end

# Module export
export Gaussian_perturbator, MHBinder, execute_mh, execute_mh_tracked

end

using Test
using StaticArrays
using .MetropolisHastings


log_prob(x) = -0.5 * sum(x .^ 2)


@testset "Gaussian Perturbator" begin
    x0 = SA[0.0]
    σ = SA[1.0]
    NDim = 1
    perturbed_x = Gaussian_perturbator(x0; σ=σ, NDim=NDim)
    @test length(perturbed_x) == 1
end


@testset "Metropolis-Hastings" begin
    x0 = SA[0.0]
    σ = SA[1.0]
    var_params = (σ=σ, NDim=1)
    model = MHBinder(Gaussian_perturbator, var_params)

    xf, valf = execute_mh(log_prob, model, x0, max_steps=1000)
    @test isfinite(valf)
end

@testset "Metropolis-Hastings Tracking" begin
    x0 = SA[0.0]
    σ = SA[1.0]
    var_params = (σ=σ, NDim=1)
    model = MHBinder(Gaussian_perturbator, var_params)

    xf, valf, x0_p, val_p = execute_mh_tracked(log_prob, model, x0, max_steps=1000)
    @test length(x0_p) <= 1000
    @test all(isfinite, val_p)
end