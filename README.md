# julia_deeper_magic
This is a reposetory where I implement interesting concepts I came across throughout the years or mess around with 'lower level' programming. Not all these problems are particularly useful but still offer valuable insight. 

## Dual Numbers

Dual numbers are an extension of the reals, of the form:

$D = a + b \epsilon$ subject to $\epsilon^2 = 0$ 

Seasoned physicists, even without dwelling into the algebra and arithemtic that these numbers _imply_, realise a _very_ useful application for analytic functions.

Let a smooth function $f(x)$ be analytic in some region of radi $\Delta$ around $x_0$: then near point $\delta < \Delta $,  $x_0$, we have that $f(x_0+\delta) = f(x_0) + f'(x_0)\delta + O(\delta^2)$. Conviently, if we interpret $x_0 + y_0 \delta$ as _dual_ number $x_0 + \epsilon y_0$, then we end up exactly with $f(x_0+y_0\delta) = f(x_0) + f'(x_0) y_0 \epsilon$ as $\epsilon^2 = 0$. 

I.e. as long as we can represent a function's value when taking a dual number, which result we denote $x_0^1 + \epsilon y_0^1$, we can calculate the analytic derivative _exactly_. This already has immense benefits over using finite-difference methods, but the true power lies in its applications of the chain rule. If we have a process that can not be represented in a single function for one reason or another (typically memory or other limits) but is instead decomposed into a number of nested functions $f_1(f_2(f_3(...f_n(x))))$, to use a finite difference based differention, we would need to manually apply our finite difference scheme at every step, store it for a later use in the chain rule, all while stacking up errors resulting from discretization _and_ floating point errors.

With dual numbers, this became almost trivial. By defining how every function and its constituent parts apply to dual numbers, we can evalute each part of the derivative via prppegating a simple dual number thrugh while only stacking up floating - point based errors, but _no_ discretization based ones. This is in fact very similar to if we applied symbolic differentitation to every step, except way faster and scalable.

![Dual_vs_finite](https://github.com/ArchHem/julia_deeper_magic/blob/main/project_images/dual_vs_finite_deriv_02.png)

The above plot was produced on the relative difference from the 'true' derivative using a second order discretization method (midpoint) on a function that involved some minor (4-5 layers) nesting of basic functions (arithmetic operators, $\log{}, \cos{}, \sin{}, \exp{}$ etc.) 

Dual numbers have an obvious use case in gradient-descent based ML algorithms, where they can be used to evalute the loss and activation function's (whatever they might be) derivatives to artbitrary precision, which helps a lot if discretization based methods run into problems (read: the function is no longer analytic within the discretization distance $\delta x$).

Another use case lies in financial risk analysis, where such powerful differentiation can be used to evaluate the so called 'greeks' associated with a particular portfolio/option. However, some of these quantities are second or third order derivatives, meaning that we either need to iteratively apply dual numbers together with discrete differentiation (discarding a large part of their advantage) or use other kinds of hyperreal numbers. Such implementations do exists, but are harder to implement 'by hand' and typically require metaprogramming.

## Probabilistic algorithms

# Monte Carlo algorithms

Monte Carlo algorithms refer to algorithms which have bound runtime but may produce incorrect results (within certain error bounds). The simplest example would be Monte-Carlo integrators that are particularly useful for evaluating high-dimensional ($N>>>5$) dimensional integrals and scale much better than a grid-based (quad) integrators. Some more obscure examples are the Karger min-cut finder algorithm and 'global' minimizers like simulated annealing. 

# Las Vegas algorithms

Las Vegas algorithms are algorithms that do not have a 'fixed' runtime but _always_ procude correct results. An example would be _naive_ rejection sampling which may never finish running for certain random seeds (especially for poor choice of a 'ceiling') but will always produce samples from the exact underlying distribution. 

Most Las Vegas algorithms can be converted to Monte Carlo methods by terminating the algorithm after a certain time.

# Atlantic City algorithms

Atlantic city algorithms refer to polynomial-time algorithms that answer a binary problem correctly with probability $p>0.5$. Repeated runnings of an Atlantic City algorithm thus can be used to construct binary Monte-Carlo algorithms.

## Examples 

# Karger's Algorithm

Karger's Algorithm (probably) finds the minimum cut of a simple graph, that is the, 'splitting' of the graph into two sub-graphs such that the number of edges between them is minimal. It works by repeatedly 'contracting/merging' vertices along existing edges until there is only two meta-vertices left. The number of cuts between these two meta-vertices is thus a possible 'cut's cost of the original graph. Karger's algorithm beats deterministic approaches in expected scaling: intuitively, by contracting vertices along edges at random, vertices that have larger number of connections/part of more edges (i.e. part of a 'cluster') will be contracted with a larger probability than vertices that form the periphery of such a cluster. 

By repeatedly running the algorithm and always updating the best, found cut, we can ensure that with high probability we will find the global minimum cut. 

Real-life implementations (eg. Karger-Stein) of min-cut finder use more sophisticated methods, though: they typically terminate at a certain meta-vertex count and switch to some slower, but deterministic algorithm at the end, drastically improving the chance of success and thus reduce the number of runs needed to find a minimum cut with an acceptable probability. 

For actual implementation, we need an efficient way of representing the gradual contraction of the graph, known a 'union-find' datastructure, which was provided by `DataStructures.jl`. Union-find datastructures provide efficient ways of taking the union between disjoint sets and keeping track of which element belong in which sets (most notably, they allow for extremely slowly-scaling time complexity for finding elements). 

A toy implemnetation can be found `karger_algo.jl` file. Interestingly, the 'kernel' function I came up after toying with the `DisJointSet` datatstructure very closely resembles the `Graphs.jl` implementation (which uses superior control flow but functionally is _very_ similar).

![Karger's algorithm performed on 2 cirques](https://github.com/ArchHem/julia_deeper_magic/blob/main/project_images/Karger_2_cirques.png)

The results of the 'cut' can be visualized rather easily using a `Plots.jl` backend with vertex coloring. Above is an example of a (succesfull) Karger run. We have performed further runs on some easily-generated graphs, like Erdős-Rényi and Barabási graphs (the later being an example where as small subset of the vertices have most of the edges). Bellow is an image of a (post-critical) Erdős graph. 

![Algo run on a Erdős graph](https://github.com/ArchHem/julia_deeper_magic/blob/main/project_images/Karger_erdos_renyi.png)

# 'Practical' quicksort

Quicksort is _the_ divide-and-conquer sorting algorithm (alongside mergesort). What is less known that its most common implementation is technically a Las Vegas algorithm.

In quicksort, the array is divided into gradually smaller and smaller portions where we choose a _pivot_ element around which we re-order the array (smaller elements than the pivot go to the left of the pivot, larger the other way). This happens in-place, via swap operations and does not need to allocate thus. 

A _naive_ implementations either uses the last or first element of each (sub)-array as the pivot. However, it can be seen that for some special arrays - namely, for the choice of the pivot as the first element - (nearly) sorted arrays will scale as $O(n^2)$ instead of the expected $O(n\log{n})$! 

Using a _random_ element as the pivot for each array does away with this problem and ensures an average time complexity of $O(n \log{n})$ at the cost of introducing some minor overhead of generating random integers for indexing. 

For vectors populated by values drawn from a unit random distribution - `randn()` - the two different quicksort!() implementations have a very similar performance. We have evaluted the average time to execution using `BenchMarkTools.jl`, each time running on a different seed.

![randn()_quicksort](https://github.com/ArchHem/julia_deeper_magic/blob/main/project_images/quicksort_randn.png)

As we can see, for pretty much all vector lengths, the randomized quicksort has a small overhead but the two algorithms offer the same scaling.

For nearly sorted arrays (where we have taken a sorted array and randomly swapped 5% of its elements around) the dependence becomes much clearer.

![randn()_quicksort](https://github.com/ArchHem/julia_deeper_magic/blob/main/project_images/quicksort_nearly_sorted.png)

As we can see, the 1-pivot quicksort quickly reverts to a dramatically worse (quadratic) scaling. 

# Simulated annealing 

# Metropolis-Hasting




