## helpers

fresh(f::Function,n) = begin
    (sc) -> begin
        (bindings,count) = sc
        vars = [Var(i) for i=count:count+(n-1)]
        goal = f(vars...)
        sc = (bindings,count+n)
        goal(sc)
    end
end

conj(goal) = goal
disj(goal) = goal

conj(goals...) = begin
    # avoiding an infinite loop relies
    # on our prior definition and
    # Julia's dispatch being smart re: splats
    conj(goals[1], conj(goals[2:end]...))
end


disj(goals...) = begin
    disj(goals[1], disj(goals[2:end]...))
end

# DRAGON, SLEEP!
η⁻¹(goal) = :((st) -> () -> $(esc(goal))(st))

macro ☾(goal)  ## It's a moon
    η⁻¹(goal)
end

macro zzz(op, goals...)
    Expr(:call, op, [η⁻¹(goal) for goal in goals]...)
end




list() = ()
list(x...) = (x[1], list(x[2:end]...))
const ❀ = list  # There should be more flowers in CS
const ⊞ = list

islist(x) = false
islist(x::()) = true
islist(x::(Any,Any)) = begin
    (h,t) = x
    return islist(t)
end

list➜array(x) = begin
    ## pedantic
    function buildAr(x::(),ar)
       ar
    end
    function buildAr(x::(Any,Any),ar)
       (h,t) = x
       push!(ar,h)
       buildAr(t,ar)
    end

    if islist(x)
        ar = Any[]
        return buildAr(x,ar)
    else
        error("Not a list: $x")
    end
end

export @☾, @zzz, list➜array, islist, ❀, list
