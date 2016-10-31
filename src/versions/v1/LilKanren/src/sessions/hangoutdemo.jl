using LilKanren


## Contents:
## =======================
## * Basic equivalences
## * Lists
## * "Grammars"
## * Peano Numbers
## * Binary Numbers
## * Logic Puzzles


## basics
slurp() do q, a, b, c, d, e
    ( q     ≡ (:♣, :♠) )  ∧
    ( (a,b) ≡ q        )  ∧
    ( c     ≡ (1,d)    )  ∧
    ( d     ≡ (1,c)    )
end

## The "Classic"
#############################
function appendᵒ(o,front,back)
  ∨(    # <-- Disjunction
    # The base case
    ∧(() ≡ front,
       o ≡ back),

    # The recursive case
    fresh(3) do h,t,temp
      ∧((h,t)    ≡ front,
        (h,temp) ≡ o,
        appendᵒ(temp,t,back))
    end)
end

## run it forwards
slurp() do q
    appendᵒ(q,
            ❀(:✌︎, :✒︎, :✂︎, :☼),
            ❀(:☿,:♆))
end

## run it backwards
slurp() do front, back
    appendᵒ(❀(:✌︎, :✒︎, :✂︎, :☼,:☿),
            front,
            back)
end

##  "Grammars"
## operators
litᵒ(val) = (x) -> x ≡ ❀(val)

∥(a,b) = (x) -> a(x) ∨ b(x)

→(a,b) = (x) -> begin
  fresh(2) do front,back
    a(front) ∧
    b(back)  ∧
    @☾ appendᵒ(x,front,back)
  end
end

## internals
g☾(pred) = (val) -> @☾ pred(val)
pred⁻¹(pred) = :(v -> st -> g☾($(esc(pred)))(v)(st))
macro g☾(pred)
  pred⁻¹(pred)
end
Base.in(val, relation::Function) = relation(val)


## Booleans
trueᵒ = litᵒ(:✓)
falseᵒ = litᵒ(:✗)
𝔹ᵒ =  trueᵒ ∥ falseᵒ
notᵒ(o,x) = begin
  trueᵒ(x)  ∧ falseᵒ(o) ∨
  falseᵒ(x) ∧ trueᵒ(o)
end

## A random sequence
αβγᵒ = litᵒ(:α) → litᵒ(:β) → litᵒ(:γ)


slurp() do q,r,s
  (q ∈ 𝔹ᵒ)     ∧
  (r ∈ 𝔹ᵒ)     ∧
  (s ∈ αβγᵒ)
end


## Peano numbers
natᵒ = litᵒ(:№𝟘) ∥ (litᵒ(:✚𝟙) → @g☾(natᵒ))

slurp() do q
  q ∈ natᵒ
end


## big endian binary
№𝟘ᵒ = litᵒ(:№𝟘)
№𝟙ᵒ  = litᵒ(:№𝟙)

binaryᵒ = №𝟘ᵒ ∥ @g☾(posᵒ)
posᵒ    = №𝟙ᵒ ∥ @g☾(gt𝟙ᵒ)
gt𝟙ᵒ    = @g☾(posᵒ) → (№𝟘ᵒ ∥ №𝟙ᵒ)


slurp() do q
  q ∈ binaryᵒ
end

## catamorphisms
function peanoᵒkitty(z,s)
  r = (o,v) -> begin
    ((v ≡ ❀(:№𝟘)) ∧ z(o)) ∨
    fresh(2) do n,o′
      (v ≡ (:✚𝟙, n)) ∧
      s(o,o′)        ∧
      @☾ r(o′,n)
    end
  end
end

#############################

evenᵒ = peanoᵒkitty( o ->  trueᵒ(o),
                     (o,o′) -> notᵒ(o,o′))

slurp() do q
  fresh() do parity
    (q ∈ natᵒ)         ∧
    evenᵒ(parity, q)   ∧
    trueᵒ(parity)
  end
end


#############################
plusᵒ(o,x,y) = begin
  plusxᵒ = peanoᵒkitty(o ->  o ≡ x,
                       (o,o′) -> o ≡ (:✚𝟙,o′))
  plusxᵒ(o,y)
end


# Partition 5
slurp() do x,y
  plusᵒ(❀(:✚𝟙, :✚𝟙, :✚𝟙, :✚𝟙, :✚𝟙, :№𝟘), x, y)
end


#############################
multᵒ(o,x,y) = begin
  multxᵒ = peanoᵒkitty(o ->  o ≡ ❀(:№𝟘),
                       (o,o′) -> plusᵒ(o,o′,x) )
  multxᵒ(o,y)
end

## Factor 6
slurp() do x,y
  multᵒ(❀(:✚𝟙, :✚𝟙, :✚𝟙, :✚𝟙, :✚𝟙, :✚𝟙, :№𝟘), x, y)
end


#########################
## Smullyan Puzzles !!!

# You journey upon an island which has two types of inhabitants:
#   Knights, who always tell the truth
#   and Knaves, who always lie.
#
#  During your travels, you encounter two inhabitants, Will and Dan.
#  Will says, "Dan will say that I'm a Knight"
#
#  Who's who?
#########################

♞ᵒ = litᵒ(:♞) ## Knights
⚗ᵒ = litᵒ(:⚗)  ## Knaves

Inhabitantᵒ = ♞ᵒ ∥ ⚗ᵒ


function Inhabitantᵒkitty(♞,⚗)
  r = (o,v) -> begin
    (v ∈ ♞ᵒ) ∧ ♞(o)  ∨
    (v ∈ ⚗ᵒ)  ∧ ⚗(o)
  end
  r
end

## binary relation
is♞ᵒ = Inhabitantᵒkitty( o -> trueᵒ(o),
                          o -> falseᵒ(o))
shallSayᵒ(o,who,what) = begin
  r = Inhabitantᵒkitty( o -> o ≡ what,
                        o -> notᵒ(o,what))
  r(o,who)
end

slurp() do Will, Dan
  fresh(2) do Will′s_Statement,Dan′s_Statement
    shallSayᵒ(❀(:✓),Will,Will′s_Statement)              ∧
    shallSayᵒ(Will′s_Statement,Dan,Dan′s_Statement)      ∧
    is♞ᵒ(Dan′s_Statement,Will)
  end
end

# Dan's a ♞, can't be sure about that Will....
