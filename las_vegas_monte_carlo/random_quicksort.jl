module RSort

using Random

@inline function swap!(v, i::Int, j::Int)
    #easier than pointer magic.
    v[i], v[j] = v[j], v[i]
    return Nothing
end

#https://rosettacode.org/wiki/Sorting_algorithms/Quicksort
function quicksort_det!(X)

    if length(X) > 1
        pivot = X[1]
        left, right = 1, length(X)
        while left <= right
            while X[left] < pivot
                left += 1
            end
            while X[right] > pivot
                right -= 1
            end

            if left <= right
                swap!(X,left,right)
                left += 1
                right -= 1
            end
        end
        #avoid copying via using @views
        quicksort_det!(@views X[1:right])
        quicksort_det!(@views X[left:end])
    end
    return X
end

function quicksort_ran!(X)

    if length(X) > 1
        pivot = X[rand((1:length(X)))]
        left, right = 1, length(X)
        while left <= right
            while X[left] < pivot
                left += 1
            end
            while X[right] > pivot
                right -= 1
            end

            if left <= right
                swap!(X,left,right)
                left += 1
                right -= 1
            end
        end
        quicksort_det!(@views X[1:right])
        quicksort_det!(@views X[left:end])
    end
    return X
end

export quicksort_det!, quicksort_ran!, swap!
#end module
end

using BenchmarkTools, Plots

#set up text cases

#random cases

using .RSort



function compare_methods_randn(low::Int64 = 10,high::Int64 = 100,step::Int64=2)
    iter = collect(low:step:high)

    mtimes_det = zeros(length(iter))
    mtimes_ran = zeros(length(iter))

    for (index, N) in enumerate(iter)
        
        #dont interpolate!
        results_det = (@benchmark quicksort_det!(randn($N)) )
        results_ran = (@benchmark quicksort_ran!(randn($N)) )

        mtimes_det[index] = mean(results_det.times::Vector{Float64})/1e9
        mtimes_ran[index] = mean(results_ran.times::Vector{Float64})/1e9
    end

    return mtimes_det, mtimes_ran, iter
end

function gns(N::Int64; to_swap::Int64 = convert(Int64,floor(N/20)))
    rn = collect(1:N)
    for j in to_swap

        swap!(rn,rand(1:N),rand(1:N))
    end
    return rn
end

function compare_methods_near_sorted(low::Int64 = 10,high::Int64 = 100,step::Int64=2)
    iter = collect(low:step:high)

    mtimes_det = zeros(length(iter))
    mtimes_ran = zeros(length(iter))

    for (index, N) in enumerate(iter)
        
        #dont interpolate!
        results_det = (@benchmark quicksort_det!(gns($N)) )
        results_ran = (@benchmark quicksort_ran!(gns($N)) )

        mtimes_det[index] = mean(results_det.times::Vector{Float64})/1e9
        mtimes_ran[index] = mean(results_ran.times::Vector{Float64})/1e9
    end

    return mtimes_det, mtimes_ran, iter
end

#change after prototyping!

#=
t1, t2, Ns = @time compare_methods_randn(2,100,4)

p1 = plot(Ns,t1, xlabel = "Array size", 
ylabel = "post-JIT execution time (s)", 
title = "Quicksort!() on randn() arrays", grid = true,
color =:red, label = "1-Pivot Quicksort", dpi = 1200)
plot!(p1, Ns,t2,color =:green, label = "Random-Pivot Quicksort")
=#

#=
t1, t2, Ns = @time compare_methods_near_sorted(2,100,4)

p1 = plot(Ns,t1, xlabel = "Array size", 
ylabel = "post-JIT execution time (s)", 
title = "Quicksort!() on nearly-sorted arrays", grid = true,
color =:red, label = "1-Pivot Quicksort", dpi = 1200)
plot!(p1, Ns,t2,color =:green, label = "Random-Pivot Quicksort")
=#









