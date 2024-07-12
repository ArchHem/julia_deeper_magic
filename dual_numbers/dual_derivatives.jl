include("./base_dual_numbers.jl")
using .DualNumbers, Plots, LaTeXStrings

#let us try to evalue some derivates in a number of ways!

function fancy_function(x)
    y = cos(exp(x)*cos(x)-x^(2.3-log(sin(x)+5.0)) / 5) 
    return y
end

function fancy_function_deriv(x)
    dy = (1/5 * x^(2.3 - log(sin(x) + 5)) * ((2.3 - log(sin(x) + 5))/x - (log(x) * cos(x))/(sin(x) + 5)) 
    + exp(x) * sin(x) - exp(x) * cos(x)) * sin(exp(x) * cos(x) - 1/5 * x^(2.3 - log(5 + sin(x))))
    return dy
end

x = LinRange(0.5,4.0,500)
eps = ones(length(x))

#finite difference
dx = 1e-6

x_n = x .-dx
x_p = x .+dx

y_p = fancy_function.(x_p)
y_n = fancy_function.(x_n)

derivs_finite = @. (y_p - y_n) / (2*dx)

duals = DualNumber.(x,eps)
derivs_dual = hyperpart.(fancy_function.(duals))
exact_derivs = fancy_function_deriv.(x)

#=
plot(x,derivs_finite,color = "green", label = L"Finite difference derivative with $\Delta x = 10^{-6}$", dpi = 1500,
xlabel = "x", ylabel = L"$\approx \frac{dy}{dx}$")
plot!(x,derivs_dual,color = "red", label = "Dual-Number based derivative")
scatter!(x,exact_derivs,color = "blue", label = "Exact Derivative", ms = 0.9, markershape = :x)
=#

plot(x,exact_derivs .- derivs_finite,color = "green", label = L" $\frac{dy}{dx} - F_{\Delta}(x,\Delta x = 10^{-6})$", dpi = 1500,
xlabel = "x", ylabel = L"$\frac{dy}{dx} - F$")

plot!(x,exact_derivs .- derivs_dual, color = "red", label = L" $\frac{dy}{dx} - F_{ϵ}(x)$", dpi = 1500,
)
