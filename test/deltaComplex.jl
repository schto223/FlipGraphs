using Random

function sameDcomplex(D1::DeltaComplex, D2::DeltaComplex)
    if D1.num_points.x!=D2.num_points.x
        return false
    end
    for i in eachindex(D1.V)
        v1 = D1.V[i]
        v2 = D2.V[i]
        if v1.points != v2.points || v1.id.x!=v2.id.x
            return false
        end
        for j in 1:3
            if v1.edges[j].id != v2.edges[j].id
                return false
            end
        end
    end
    for i in eachindex(D1.E)
        d1 = D1.E[i]
        d2 = D2.E[i]
        if d1.id != d2.id || d1.triangles != d2.triangles || d1.sides != d2.sides || d1.is_twisted != d2.is_twisted
            return false
        end
    end
    return true
end

@testset "deltaComplex" begin

    @testset "Sphere" begin
        for p = 3:8
            D = deltacomplex(0, p)
            @test nv(D) == 2*(p-2)  
            @test ne(D) == 3*(p-2) 
            @test np(D) == p
            @test is_orientable(D) == true
            @test euler_characteristic(D) == 2
            @test genus(D) == 0
        end
    end

    @testset "Orientable surfaces" begin
        for g = 1:7
            for p = 1:7
                D = deltacomplex(g, p)
                @test genus(D) == g
                @test np(D) == p
                @test is_orientable(D) == true
                @test euler_characteristic(D) == 2-2*g         
            end
        end

        #test flip
        D = deltacomplex(3,7)
        @test sum(point_degrees(D)) == 2*ne(D)
        e = get_edge(D,1)
        e_copy = deepcopy(e)
        t1,t2 = vertices_id(e)
        T1 = deepcopy(get_vertex(D, t1))
        T2 = deepcopy(get_vertex(D, t2))
        flip!(D,e)
        flip!(D,e)
        @test genus(D) == 3
        @test np(D) == 7
        @test is_orientable(D) == true
        @test euler_characteristic(D) == -4  
        flip!(D,e)
        flip!(D,e)        
        @test all(e_copy.triangles.==e.triangles) && all(e_copy.sides==e.sides) && e.is_twisted==e_copy.is_twisted
        for d in edges(D)
            @test is_twisted(d) == false
            @test D.E[d.id] == d
        end
        q = quadrilateral_edges(D, get_edge(D,3))
        q_ids = collect(d.id for d in q)
        flip!(D,3)
        qq = quadrilateral_edges(D,get_edge(D,3))
        qq_ids = collect(d.id for d in qq)
        @test issetequal(q_ids, qq_ids)

        d = get_edge(D,4)
        @test vertices(D,d) == (get_vertex(D,d.triangles[1]), get_vertex(D,d.triangles[2]))

        T = get_vertex(D,3)
        @test all(edges(T).==edges(D, id(T)))
        @test id(get_edge(T,2)) == get_edge_id(T,2)

        #test deltacomplex 
        D = deltacomplex([1,2,3,-3,-1,-2]) # torus with an added point that has only one outgoing edge
        @test sum(point_degrees(D)) == 2*ne(D)
        @test np(D)==2
        @test genus(D)==1
        e = filter(e-> 2 ∈ points(D,e) , edges(D))[1]
        @test is_flippable(e) == false
        @test has_point(get_vertex(D,1), 1)
        @test edges_id(D, 3) == edges_id(get_vertex(D, 3))
        @test 4 in get_edge(D, 4, 2).triangles 
    end

    @testset "non-orientable surfaces" begin
        @testset "kleinBottle" begin
            D = deltacomplex([1,2,-1,2]) #klein Bottle
            @test is_orientable(D) == false
            @test np(D) == 1 && nv(D) == 2 && ne(D) == 3
            @test demigenus(D) == 2
            e = filter(e-> !e.is_twisted , edges(D))[1]
            flip!(D,e) 
            @test is_orientable(D) == false
            @test np(D) == 1 && nv(D) == 2 && ne(D) == 3
            @test demigenus(D) == 2
            e = filter(e-> e.is_twisted , edges(D))[1]
            flip!(D,e) 
            @test is_orientable(D) == false
            @test np(D) == 1 && nv(D) == 2 && ne(D) == 3
            @test demigenus(D) == 2
        end

        @testset "projective plane" begin
            D = deltacomplex([1,2,1,2]) # projective plane
            @test is_orientable(D) == false
            @test np(D) == 2 && nv(D) == 2 && ne(D) == 3
            @test demigenus(D) == 1
            e = filter(e-> !e.is_twisted , edges(D))[1]
            flip!(D,e) 
            @test is_orientable(D) == false
            @test np(D) == 2 && nv(D) == 2 && ne(D) == 3
            @test demigenus(D) == 1
            e = filter(e-> e.is_twisted , edges(D))[1]
            flip!(D,e) 
            @test is_orientable(D) == false
            @test np(D) == 2 && nv(D) == 2 && ne(D) == 3
            @test demigenus(D) == 1
        end

        @testset "projective plane * kleinBottle" begin
            D = deltacomplex([1,2,1,2,3,4,-3,4]) # projective plane glued to klein Bottle
            @test is_orientable(D) == false
            @test np(D) == 2 && nv(D) == 6 && ne(D) == 9
            @test sum(point_degrees(D)) == 2*ne(D)
            @test demigenus(D) == 3
            e = filter(e-> !e.is_twisted , edges(D))[1]
            flip!(D,e) 
            @test is_orientable(D) == false
            @test np(D) == 2 && nv(D) == 6 && ne(D) == 9
            @test demigenus(D) == 3
            e = filter(e-> e.is_twisted , edges(D))[1]
            flip!(D,e) 
            @test is_orientable(D) == false
            @test np(D) == 2 && nv(D) == 6 && ne(D) == 9
            @test demigenus(D) == 3
        end

        for dg = 2:7
            for p = 1:7
                D = deltacomplex_non_orientable(dg, p)
                @test demigenus(D) == dg
                @test np(D) == p
                @test is_orientable(D) == false
            end
        end
        D = deltacomplex_non_orientable(1,2)
        @test demigenus(D) == 1
        @test np(D) == 2
        @test is_orientable(D) == false
    end

    @testset "functions" begin
        @test is_similar(DualEdge(3,1,4,2,false), DualEdge(3,1,4,2,false)) == true
        @test is_similar(DualEdge(3,3,4,2,false), DualEdge(3,1,4,1,false)) == true
        @test is_similar(DualEdge(4,3,3,2,false), DualEdge(3,1,4,1,false)) == true
        @test is_similar(DualEdge(4,3,3,2,true), DualEdge(3,1,4,1,true)) == true
        @test is_similar(DualEdge(4,3,3,2,false), DualEdge(3,1,4,1,true)) == false
        @test is_similar(DualEdge(3,3,3,2,true), DualEdge(3,1,4,1,true)) == false

        @test other_endpoint(DualEdge(3,3,3,2,false), 3,3) == (3,2)
        @test other_endpoint(DualEdge(1,3,3,1,false), 3,1) == (1,3)
        @test other_endpoint(DualEdge(2,1,2,2,false), 2,1) == (2,2)

        @test sides(DualEdge(1,2,1,3,false)) == (2,3)
    end 

    @testset "Errors" begin
        @test_throws ArgumentError deltacomplex([1])
        @test_throws ArgumentError deltacomplex([1,2,1,3])
        @test_throws ArgumentError deltacomplex([1,2,1,-2,1])

        D = deltacomplex(4)
        @test_throws ArgumentError demigenus(D)
        @test_throws ArgumentError deltacomplex(0)
        D = deltacomplex(0,3)
        @test_throws ArgumentError demigenus(D)

        D = deltacomplex([1,2,1,2])
        @test_throws ArgumentError genus(D)
        D = deltacomplex([1,2,-1,2])
        @test_throws ArgumentError genus(D)

        D = deltacomplex_non_orientable(3)
        @test_throws ArgumentError genus(D)
        @test_throws ArgumentError deltacomplex_non_orientable(0)
        @test_throws ArgumentError deltacomplex_non_orientable(1,1)
        @test_throws ArgumentError deltacomplex_non_orientable(2,0)

        @test_throws ArgumentError other_endpoint(DualEdge(1,2,1,3,false), 1,1)
    end

    @testset "diameter" begin
        D = deltacomplex(10,20)
        @test 1 <= diameter_triangulation(D) <= np(D)-1
        @test 1 <= diameter(D) <= nv(D)-1
        Random.seed!(1234)
        a = rand(1:ne(D), 1000)
        for i in eachindex(a)
            if is_flippable(D,a[i])
                flip!(D,a[i])
            end
        end 
        @test 1 <= diameter_triangulation(D) <= np(D)-1
        @test 1 <= diameter(D) <= nv(D)-1
    end

    @testset "Random flipping" begin
        D1 = deltacomplex(10,50)
        D2 = deltacomplex(10,50)

        randomize!(D1; num_initial_flips=100000, num_flips_per_step=10000, variance_interval_size=10, lookback_size=5)
        @test nv(D1) == nv(D2)
        @test ne(D1) == ne(D2)
        @test np(D1) == np(D2)
        @test sum(point_degrees(D1)) == 2*ne(D1)
    end

    @testset "twist and flip" begin
        D = deltacomplex(5,5)
        Random.seed!(2535)
        es = rand(1:ne(D), 1000)
        vs = rand(1:nv(D), 1000)
        bo = true
        for i in eachindex(es)
            flip!(D,es[i])
            twist_edges!(D,vs[i])
            if !is_orientable(D)
                bo = false
            end
        end
        @test bo == true
        @test genus(D) == 5
        @test np(D) == 5
    end

    @testset "left and right flip" begin
        D = deltacomplex(3,5)
        D1 = flip(D,5, left=true)
        D2 = flip(D,5, left=false)
        @test is_isomorphic(D1,D2) == true
    end
end



