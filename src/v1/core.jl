## Our current Kanren

export Var
immutable type Var
    id::Int
end

## for reification
immutable type FreeValue
    id::Int
end

immutable type SelfRef
   name
end



## A translation of µKanren
## ---------------------------
##
## Heaven
## ======
unify(u, v, s) =  begin
    (u,s) = walk(u,s) # dramatic foreshadowing
    (v,s) = walk(v,s)
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
const empty_state = (empty_store,1) ## when in Rome (Julia is one's based...)
const ∅ = empty_state
const ∞ = empty_state      ## it's a "glass half full" sort of thing...
                           ## ∅ constraints ≡ ∞ possibilities

## The State
## --------------
unifyLeft(u,v,s) = u===v ? s : nothing # base case
unifyLeft(u::Var,v,s) =  u==v ? s : ext_s(u,v,s)
unifyLeft(u::(Any,Any),v::(Any,Any),s) = begin
    (uhead,utail) = u
    (vhead,vtail) = v
    s = unify(uhead,vhead,s)
    s == nothing ? s : unify(utail,vtail,s)
end


## The Bourgeoisie
## ----------------
walk(u,s) = (u,s) ## base case
walk(u::Var,s) = begin
    (found,value) = lookup(u,s)
    found == :✔︎ ? walk(value,s) : (u,s)
end


## And finally, Joe The Plumber
## ----------------------------
## a pedantic man's assp <-- n.b. non-schemer's, this does not mean something dirty
lookup(x,s::()) = (:✘,nothing) ## base case
lookup(x,s) = begin
    (head,rest) = s
    (key,value) = head
    x == key ? (:✔︎, value) : lookup(x,rest)
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
        var = Var(count)
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
mplus(strand1::Function,strand2) = () -> mplus(strand2,strand1()) ## A true braid
mplus(strand1::(Any,Any),strand2) = (first(strand1),mplus(second(strand1),strand2))

bind(strand::(),g) = mzero
bind(strand::Function,g) = () -> bind(strand(),g)
bind(strand::(Any,Any),g) = mplus(g(first(strand)), bind(second(strand),g)) ## A true weave

export unify, unifyLeft, unifyLeft, walk, disj, conj, fresh, equivalent, mzero, unit, mplus, bind
export ∨, ∧, ⪢, ⪡, ∞, ø, ≡


