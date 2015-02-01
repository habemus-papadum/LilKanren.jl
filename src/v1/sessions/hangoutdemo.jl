using LilKanren

## basics
slurp() do q, a, b, c, d, e
    ( q     ≡ (:♣, :♠) )  ∧
    ( (a,b) ≡ q        )  ∧
    ( c     ≡ (1,d)    )  ∧
    ( d     ≡ (1,c)    )
end

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
        @☾(appendᵒ(temp,t,back)))
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

## Booleans
𝔹 =  litᵒ(:✓) ∥ litᵒ(:✗)

## A random sequence
seq3 = litᵒ(:α) → litᵒ(:β) → litᵒ(:γ)


slurp() do q,r,s
  (q ∈ 𝔹)     ∧
  (r ∈ 𝔹)     ∧
  (s ∈ seq3)
end


## Peano numbers
natᵒ = litᵒ(❀(:№𝟘)) ∥ (litᵒ(:✚𝟙) → @g☾(natᵒ))

slurp() do q
  (q ∈ natᵒ)
end


## little endian binary

zeroᵒ = litᵒ(:№𝟘)
oneᵒ  = litᵒ(:№𝟙)

binaryᵒ = zeroᵒ ∥ @g☾(posᵒ)
posᵒ    = oneᵒ  ∥ @g☾(gt𝟙ᵒ)
gt𝟙ᵒ    = (zeroᵒ ∥ oneᵒ) → @g☾(posᵒ)


slurp() do q
  (q ∈ binaryᵒ)
end

## peano-kitty
function peanoᵒkitty(z,s)
  r = (o,v) -> begin
    ((v ≡ ❀(:№𝟘)) ∧ z(o)) ∨
    fresh(2) do n,o′
      (v ≡ (:✚𝟙, n)) ∧
      @☾ r(o′,n)     ∧
      s(o,o′)
    end
  end
end

#############################
notᵒ(o,x) = begin
  (x ≡ :✓) ∧ (o ≡ :✗) ∨
  (x ≡ :✗) ∧ (o ≡ :✓)
end

evenᵒ = peanoᵒkitty( o ->  o ≡ :✓,
                     (o,o′) -> notᵒ(o,o′))

slurp() do q
  (q ∈ natᵒ) ∧
  evenᵒ(:✓, q)
end


#############################
plusᵒ(o,x,y) = begin
  plusxᵒ = peanoᵒkitty(o ->  o ≡ x,
                       (o,o′) -> o ≡ (:✚𝟙,o′))
  plusxᵒ(o,y)
end


slurp() do x,y
  plusᵒ(❀(:✚𝟙, :✚𝟙, :✚𝟙, :✚𝟙, :✚𝟙, :№𝟘), x, y)
end


#############################
multᵒ(o,x,y) = begin
  multxᵒ = peanoᵒkitty(o ->  o ≡ ❀(:№𝟘),
                       (o,o′) -> plusᵒ(o,o′,x) )
  multxᵒ(o,y)
end

slurp() do x,y
  multᵒ(❀(:✚𝟙, :✚𝟙, :✚𝟙, :✚𝟙, :✚𝟙, :✚𝟙, :№𝟘), x, y)
end




############## WIP
slurp() do b, pos, gt1
  ((b ≡ :№𝟘) ∨ (b ≡ pos)) ∧
  ((pos ≡ :№𝟙) ∨ (gt1 ≡ pos)) ∧
  fresh() do leading
    ((leading ≡ :№𝟘) ∨ (leading ≡ :№𝟙)) ∧
    (gt1 ≡ (leading, pos))
  end
end

