

    ## Desiderata
    ## ================
    ## It is the solemn wish of this kanren implementation to:
    ## * Organize itself around a minimalitistic, functional core (like µKanren)
    ## * Perform a "newbie's" exploration of alternate search strategies (via lists, streams, tasks, ferns)
    ## * Find out why occurs✓ is necessary
    ## * Add a persistent data structure implementation of the constraint store (though this is a mere trifle)
    ## * Explore a "notion" about threading macros and nice syntax; Other notions about syntax abound
    
    ## Methodology
    ## =================
    ## The beginning will be rough and sloppy; any elegance will have to be accumulated later.  
    ## This is a notebook, not a library --> Prior definitions will be redefined as we go along, so keep your eyes peeled! 



    ## First step: a translation to µKanren
    
    ## For now we would like to stick to core Julia datatypes, but, aesthetically, var? = vector? is a bitter pill.
    ## So instead we'll use our own type.  
    
    module LilKanren ## it's best to wrap Julia types in a module, otherwise it is very difficult to change your mind
        immutable type Var
            id::Int
        end
    end 
    LK = LilKanren
        




    LilKanren




    ## Also, in case you are new to Julia, the following snippets may be helpful
    x = LK.Var(0)
    y = LK.Var(0)
    
    @show x==y 
    
    ## multiple dispatch
    foo(x,y) = "nope" ## base case
    foo(x::LK.Var,y::LK.Var) = "yes"
    foo(x::LK.Var,y) = "kinda"
    foo(x,y::LK.Var) = foo(y,x)
    
    @show foo(x,y)
    @show foo(1,y)
    @show foo(1,2)
    
    ## julia allows convenient destructuring of tuples
    z = (1,2)
    (a,b) = z
    ## n.b. dear schemer's,  (a,b) means (a . b)
    
    nothing  ## to suppress notebook output

    x == y => true
    foo(x,y) => "yes"
    foo(1,y) => "kinda"
    foo(1,2) => "nope"



    ## On with the show, being relatively faithful from now on... 
    
    ## Heaven
    ## ======
    unify(u, v, s) =  begin
        u = walk(u,s)
        v = walk(v,s)
        unifyTerms(u,v,s)
    end
    
    
    ## Earth
    ## =====
    ## The Church
    ## ----------
    unifyTerms(u,v,s)  = begin
        sn = unifyLeft(u,v,s)
        sn == nothing ? unifyLeft(v,u,s) : sn ## symmetrize
    end
    ## s -- the substitution store
    const empty_store = ()
    ext_s(x,v,s) = ((x,v),s)
    
    ## st -- a (bindings,count) based state 
    const empty_state = ((),1) ## when in Rome (Julia is one's based...) 
    const ∅ = empty_state
    const ∞ = empty_state      ## it's a "glass half full" sort of thing...
    
    ## The State
    ## --------------
    unifyLeft(u,v,s) = u==v ? s : nothing # base case
    unifyLeft(u::LK.Var,v,s) =  u==v ? s : ext_s(u,v,s)
    unifyLeft(u::(Any,Any),v::(Any,Any),s) = begin
        (uhead,utail) = u
        (vhead,vtail) = v
        s = unify(uhead,vhead,s)
        s == nothing ? s : unify(utail,vtail,s)
    end
    
    
    ## The Bourgeoisie
    ## ----------------
    walk(u,s) = u ## base case
    walk(u::LK.Var,s) = begin
        (found,value) = lookup(u,s)
        found ? walk(value,s) : u 
    end
    
    
    ## And finally, Joe The Plumber
    ## ----------------------------
    ## a pedantic man's assp 
    lookup(x,s::()) = (false,nothing) ## base case
    lookup(x,s) = begin
        (head,rest) = s
        (key,value) = head
        x == key ? (true, value) : lookup(x,rest)
    end
    
    second(x) = x[2]
    
    
    ## Purgatory -- aka Algebra 
    ## ========================
    equivalent(u,v) = begin
        (st) -> begin
            (s,count) = st
            s = unify(u,v,s)
            s == nothing ? mzero : unit((s,count))
        end
    end
    const ≡ = equivalent 
    
    fresh(f::Function) = begin
        (st) -> begin
            (bindings,count) = st
            var = LK.Var(count)
            goal = f(var)
            st = (bindings,count+1)
            goal(st)   
        end
    end
    
    disj(g1,g2) = (st) -> mplus(g1(st), g2(st))
    conj(g1,g2) = (st) -> bind(g1(st), g2)
    const ∨ = disj
    const ⫷ = disj #this is the picture in my head -- a weave 
    const ∧ = conj
    const ⫸ = conj #this is the picture in my head -- a braid
    
    ## The Bowels of Hell... 
    ## (or Heaven -- the whole thing is just a big snake eating its tail)
    ## ==================================================================
    const mzero = ()
    unit(st) = (st,mzero)
    
    mplus(strand1::(),strand2) = strand2
    mplus(strand1::Function,strand2) = () -> mplus(strand2,strand1()) ## braid
    mplus(strand1::(Any,Any),strand2) = (first(strand1),mplus(second(strand1),strand2))
    
    bind(strand::(),g) = mzero
    bind(strand::Function,g) = () -> bind(strand(),g) 
    bind(strand::(Any,Any),g) = mplus(g(first(strand)), bind(second(strand),g)) ##weave
    
    nothing


    
    ## Ok -- Let's take this puppy out for a spin...
    
    if Pkg.installed("Lazy") == nothing
      Pkg.add("Lazy")
    end  
    using Lazy: @>>, @> 
    
    vars = [LK.Var(i) for i=1:10] ## order up some vars
    
    ## create a scratch state
    s = @>> empty_store begin
        ext_s(vars[1], 2)
        ext_s(vars[2], vars[1])
        ext_s(vars[1], 3) #shadows prior binding
        ext_s(vars[3], (1,vars[2]))
    end
    @show s
    
    println()
    @show lookup("not even close", s)
    @show lookup(vars[1], s)
    @show lookup(vars[2], s)
    @show lookup(vars[3], s)
    @show lookup(vars[4], s)
    
    nothing

    s => ((Var(3),(1,Var(2))),((Var(1),3),((Var(2),Var(1)),((Var(1),2),()))))
    
    lookup("not even close",s) => (false,nothing)
    lookup(vars[1],s) => (true,3)
    lookup(vars[2],s) => (true,Var(1))
    lookup(vars[3],s) => (true,(1,Var(2)))
    lookup(vars[4],s) => (false,nothing)



    @show walk(vars[1],s)
    @show walk(vars[2],s)
    @show walk(vars[3],s)
    @show walk(vars[4],s)
    @show walk("not even close",s)
    @show walk((1,vars[4]),s)
    
    
    nothing

    walk(vars[1],s) => 3
    walk(vars[2],s) => 3
    walk(vars[3],s) => (1,Var(2))
    walk(vars[4],s) => Var(4)
    walk("not even close",s) => "not even close"
    walk((1,vars[4]),s) => (1,Var(4))



    ## Look, Ma! I can fly!
    @show unify((1,vars[4]), vars[3],s)
    # for clarity
    println()
    @show first(unify((1,vars[4]), vars[3],s))
    
    nothing

    unify((1,vars[4]),vars[3],s) => ((Var(4),3),((Var(3),(1,Var(2))),((Var(1),3),((Var(2),Var(1)),((Var(1),2),())))))
    
    first(unify((1,vars[4]),vars[3],s)) => (Var(4),3)



    ## climbing higher...
    
    fresh() do q
       q ≡ "♣"
    end (∞)
        




    ((((Var(1),"♣"),()),2),())




    ## and little higher...
    
    ⫸(
    fresh() do a
       a ≡ "♣"
    end,
    
    fresh() do b
       ⫷(
         b ≡ "♠",
        "♡" ≡ b 
        ) 
    end
    )(∞)
    





    ((((Var(2),"♠"),((Var(1),"♣"),())),3),((((Var(2),"♡"),((Var(1),"♣"),())),3),()))




    ## (I think) I like the above notation, but you may prefer
    
    ∞ |> fresh(a-> a ≡ "♣") ∧ fresh(b-> (b ≡ "♠") ∨ ("♡" ≡ b) )




    ((((Var(2),"♠"),((Var(1),"♣"),())),3),((((Var(2),"♡"),((Var(1),"♣"),())),3),()))




    ## ♪ Pump up the jam ♪
    ## let's make a few new toys
    
    fresh(f::Function,n) = begin
        (sc) -> begin
            (bindings,count) = sc
            vars = [LK.Var(i) for i=count:count+(n-1)]
            goal = f(vars...)
            sc = (bindings,count+n)
            goal(sc)   
        end
    end
    
    fresh(3) do a,b,c
       ⫸(
       (c,"♠") ≡ (((a,b),"♣"),"♠"),
       ⫸(
       ("♡",a) ≡ b,
       a ≡ "♣"
       ))
    end (∞)





    ((((Var(1),"♣"),((Var(2),("♡",Var(1))),((Var(3),((Var(1),Var(2)),"♣")),()))),4),())




    fresh(3) do a,b,c
       ⫸(
        (c,"♠") ≡ (((a,b),"♣"),"♣"), # <-- look here
       ⫸(
       ("♡",a) ≡ b,
       a ≡ "♣"
       ))
    end (∞)




    ()




    fresh(3) do a,b,c
       ⫸(
        (c, a) ≡ (((a,b),"♣"),"♣"), # <-- still look here
       ⫸(
       ("♡",a) ≡ b,
       a ≡ "♣"
       ))
    end (∞)




    ((((Var(2),("♡",Var(1))),((Var(1),"♣"),((Var(3),((Var(1),Var(2)),"♣")),()))),4),())




    ## variadic paradise is one of our many goals
    ## but for now this will suffice
    ## n.b. This is not a nanny-state. You shall do your own η⁻¹  
    ## but see below for some gov't approved options
    conj(goals...) = begin 
        conj(goals[1], conj(goals[2:end]...)) # relies on Julia's dispatch being smart re: splats
    end
    
    disj(goals...) = begin 
        disj(goals[1], disj(goals[2:end]...)) 
    end
    
    
    
    fresh(3) do a,b,c
       ⫸(
       (c,"♣") ≡ (((a,b),"♣"), a),
       ("♡",a) ≡ b,
       a ≡ "♣"
       )
    end (∞)




    ((((Var(2),("♡",Var(1))),((Var(1),"♣"),((Var(3),((Var(1),Var(2)),"♣")),()))),4),())




    ## Our first relation!
    ## And one of our first serious transgressions: 
    ## the output will come first --> my cult is organized around variadic paradise
    ## But the cute ᵒ at the end isn't going anywhere!  
    flipᵒ(o,tuple) = begin
        fresh(2) do a, b
            ⫸(
                (a,b) ≡ tuple,
                o ≡ (b,a)
            )
        end
    end
    
    fresh(2) do q,r
       flipᵒ((q,r), ("♡", "♣")) 
    end (∞)




    ((((Var(2),"♡"),((Var(1),"♣"),((Var(4),"♣"),((Var(3),"♡"),())))),5),())




    ## on to divergence
    
    ## a shocking revelation (we are definitely not in Kansas anymore)
    list() = ()
    list(x...) = (x[1], list(x[2:end]...))
    const ❀ = list  # There should be more flowers in CS
    const ⋯ = list
    
    @show ❀(1,2,3,4) 
    
    nothing

    ❀(1,2,3,4) => (1,(2,(3,(4,()))))



    ## grant ourselves a magic power
    zzz(goal) = (sc) -> () -> goal(sc)
    zzz(goals...) = begin
        η⁻¹(goal) = (sc) -> () -> goal(sc)
        [η⁻¹(goal) for goal in goals]
    end
    const ☽ = zzz # it's a half moon
    
    nothing


    ## Now that we have the power to put the dragon to sleep, we need a way to wake it up,
    ## but not this way!
    allIn(x)=x;allIn(x::Function)=allIn(x()) ## As in Texas Holdem'
    
    ## lilinjn is not Navajo; but if this notebook were a tapestry,
    ## 'allIn' would be his "ch’ihónít’i" -- use 'allIn' maybe never ever
    
    ## Exploring wild ideas of about interactively controlling and visualizing search are the topic
    ## for a future notebook.  For now we will content ourselves with the following hand tools:
    step(x,n=1)=x
    step(x::Function,n=1) = begin
        ## In my heart, Julia is a scheme; however, I don't think it TCO's
        while(typeof(x) <: Function && n > 0)
            x = x()
            n -= 1
        end
        x
    end
    
    stepInTime(x,t)=x  ## Just like Jolly Bert
    stepInTime(x,t) = begin 
        start = Base.time_ns()
        current = start
        nanos = t*1_000_000_000
        while(typeof(x) <: Function && current-start < nanos)
            x = x()
            current = Base.time_ns()
        end
        x
    end
    
    
    nothing


    @show step("♡")
    
    myLovely♡Thunks = () -> () -> () -> () -> "☆"
    @show step(myLovely♡Thunks,  2) ## ♪ make you luv drunk ♪
    @show step(myLovely♡Thunks, 10) ## ♪ off my thunks ♪
    
    ηs = 1e-9
    s = 1
    @show stepInTime(myLovely♡Thunks, 1ηs)
    @show stepInTime(myLovely♡Thunks, 1s)
    
    nothing

    step("♡") => "♡"
    step(myLovely♡Thunks,2) => (anonymous function)
    step(myLovely♡Thunks,10) => "☆"
    stepInTime(myLovely♡Thunks,1ηs) => (anonymous function)
    stepInTime(myLovely♡Thunks,1s) => "☆"



    res = ∞ |> fresh(q-> ☽(q ≡ "♠") ∨ ☽("♡" ≡ q) )
    @show res
    @show res=step(res)
    @show res=step(res)
    nothing

    res => (anonymous function)
    res = step(res) => (anonymous function)
    res = step(res) => ((((Var(1),"♠"),()),2),((((Var(1),"♡"),()),2),()))



    res = ∞ |> fresh() do q
        ⫷(☽(q ≡ "♠",
            "♡" ≡ q)...) ## variadic zzz
    end
    @show res
    @show res=step(res)
    @show res=step(res)
    nothing

    res => (anonymous function)
    res = step(res) => (anonymous function)
    res = step(res) => ((((Var(1),"♠"),()),2),((((Var(1),"♡"),()),2),()))



    
