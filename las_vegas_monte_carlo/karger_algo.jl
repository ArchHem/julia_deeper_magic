
module karger

#https://stanford-cs161.github.io/winter2021/assets/files/lecture16-notes.pdf
using Graphs, DataStructures, Random, ProgressBars



function simple_karger_optimized(X::Graph)

    vert_num = nv(X)
    num_components = vert_num
    if vert_num == 2
        return [1,2]
    elseif vert_num <2
        return zeros(Int64,vert_num)
    else
        #actual karger
        supersets = DisjointSets{Int64}(1:vert_num)
        for edg in shuffle(collect(edges(X)))
            source = src(edg)
            destination = dst(edg)
            if !in_same_set(supersets, source, destination)
                union!(supersets, source, destination)
                num_components -= 1
                if num_components <= 2
                    break
                end
            end

        end

        return [(in_same_set(supersets, 1, v) ? 1 : 2) for v in 1:vert_num]
    end
    #convert return to readable format^
end

@inline function find_cut_num(X::Graph,V::Vector{Int64})
    func(u) = V[src(u)] != V[dst(u)] #works on edges - yields 1 if the edges' ends are in a different superset
    return count(func, edges(X))

end

function karger_full(X::Graph; N_tries::Int64 = ceil(Int64,binomial(nv(X),2)*log(nv(X))))
    #a simple graph may have at most V(V-1)/2 cuts
    min_num_cut = convert(Int64,nv(X)*(nv(X)-1)/2)
    section = [0,0]
    for _ in ProgressBar(1:N_tries)
        res = simple_karger_optimized(X)
        #count the number of edges that are 'cut' in the supersets
        local_cut_num = find_cut_num(X,res)
        if min_num_cut > local_cut_num
            min_num_cut = local_cut_num
            section = res
        end

    end
    return min_num_cut, section
end


export simple_karger_optimized, karger_full
#end module
end

using Graphs, .karger, GraphRecipes, Plots

n1 = 10
n2 = 8
total_vertices = n1 + n2
g = Graph(total_vertices)

#there gotta be a better way
for u in 1:n1
    for v in (u+1):n1
        add_edge!(g, u, v)
    end
end


for u in (n1+1):(n1+n2)
    for v in (u+1):(n1+n2)
        add_edge!(g, u, v)
    end
end


add_edge!(g, 1, n1 + 1)

G = erdos_renyi(30,90,seed = 1)

M, S = karger_full(g)

c1, c2 = :red, :blue

colors = [S[i] == 1 ? c1 : c2 for i in eachindex(S)]


z = plot(g,markercolor=colors, dpi = 1200, curves = false)



