using Lux, ComponentArrays
using Turing
using Random, Statistics, Distributions, LinearAlgebra
using Plots


Turing.setprogress!(true)
#generate some random data

μ1 = 10.0
μ2 = 22.0
σ1 = 2.0
σ2 = 2.5

rng = Random.default_rng()
Random.seed!(rng, 1234)

#radial distr.
d1 = Normal(μ1, σ1)
d2 = Normal(μ2, σ2)

scaler = 10.
N_samples = 100
r1 = rand(d1,N_samples)
r2 = rand(d2,N_samples)

θ1 = 2pi*rand(N_samples)
θ2 = 2pi*rand(N_samples)

x1, y1 = @. r1*cos(θ1) , r1*sin(θ1)

x2, y2 = @. r2*cos(θ2) , r2*sin(θ2)

x1, y1, x2, y2 = x1 ./scaler, y1 ./ scaler, x2 ./ scaler, y2 ./ scaler

data_1 = hcat(x1,y1)
data_2 = hcat(x2,y2)

alldata = vcat(data_1,data_2)

alldata = collect(transpose(alldata))
alldata = alldata

T = eltype(data_1)
#ensure type stability
labs = [ones(T,N_samples); zeros(T,N_samples)]


#

ms = 2
p1 = scatter(x1,y1,color="red",label = "μ = $(round(μ1, digits = 1)), σ = $(round(σ1, digits = 1))", ms = ms, dpi = 1200, aspect_ratio = 1.0)
scatter!(x2,y2,color="green",label = "μ = $(round(μ2, digits = 1)), σ = $(round(σ2, digits = 1))", ms = ms)

#bi-classifier
network_struct = Chain(Dense(2 => 4, tanh), Dense(4 => 3, tanh), Dense(3=>2, tanh), Dense(2 => 1, sigmoid))
ps, st = Lux.setup(rng, network_struct)

function vec_to_param(vec,p_in)
    res = ComponentArray(vec,getaxes(ComponentArray(p_in)))
    return res
end

alpha = 0.1
sig = sqrt(1.0 / alpha)
param_len = Lux.parameterlength(network_struct)

x = vec_to_param(zeros(param_len),ps)

#lets freeze the network's state variables.

const model = StatefulLuxLayer(network_struct, st)

@model function bayes_nn(xs, ts)
    # Initiate parameters as normally distributed variables (IID)
    nparameters = Lux.parameterlength(network_struct)
    parameters ~ MvNormal(zeros(nparameters), Diagonal(abs2.(sig .* ones(nparameters))))

    # apply the underlying frozen model
    preds = Lux.apply(model, xs, vec_to_param(parameters, ps))

    # draw our samples, as store them in ts
    for i in eachindex(ts)
        #binary choice
        ts[i] ~ Bernoulli(preds[i])
    end
end

#arams = vec_to_param(ones(Float64,param_len),ps)
#
#example: by default 'apply' will work along columns (constituent memory layout perhaps?)
#Lux.apply(model, alldata, params)

N = 10000
ch = sample(bayes_nn(alldata, labs), HMC(0.05, 4; adtype=AutoTracker()), N)

#reclaim network params

param_samples = MCMCChains.group(ch, :parameters).value
#these are essentialy samples from the MCMC integrator

val, i = findmax(ch[:lp])
#index of most likely log-likelyhood param 'snapshot'

i = i.I[1]
N_res = 100
x_rang = LinRange(-20,20,N_res)
y_rang = LinRange(-20,20,N_res)

x_range = x_rang' .* ones(N_res)
y_range = y_rang .* ones(N_res)'

x_range = reshape(x_range,N_res^2)
y_range = reshape(y_range,N_res^2)

combined_data = collect(hcat(x_range,y_range)')
ll_params = param_samples[i,:]

z_predict = Lux.apply(model,combined_data,vec_to_param(ll_params,ps))

z_predict = reshape(z_predict,(N_res,N_res))

contour!(x_rang,y_rang,z_predict, xlim = (-5,5), ylim = (-5,5), colormap = :cork)


