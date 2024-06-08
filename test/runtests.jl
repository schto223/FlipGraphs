using Test
using FlipGraphs

if isempty(ARGS)
    tests = [
        "polygonTriangulations.jl",
        "flipGraph_planar.jl",
        "deltaComplex.jl",
        #"holeyDeltaComplex.jl",
        "flipGraph.jl",
        "show.jl"
    ]
else
    tests = ARGS
end

for test in tests
    include(test)
end