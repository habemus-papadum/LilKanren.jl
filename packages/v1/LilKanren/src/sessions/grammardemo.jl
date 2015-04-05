using LilKanren


𝔹 =  litᵒ(:✓) ∥ litᵒ(:✗)
seq3 = litᵒ(:α) → litᵒ(:β) → litᵒ(:γ)

notᵒ(o,x) = begin
  (x ≡ :✓) ∧ (o ≡ :✗) ∨
  (x ≡ :✗) ∧ (o ≡ :✓)
end

slurp() do q,r,s
  (q ∈ 𝔹)     ∧
  notᵒ(r,q)   ∧
  (s ∈ seq3)
end

natᵒ = litᵒ(❀(:№𝟘)) ∥ (litᵒ(:✚𝟙) → @g☾(natᵒ))

slurp() do q
  (q ∈ natᵒ)
end

zeroᵒ = litᵒ(:№𝟘)
oneᵒ  = litᵒ(:№𝟙)

## little endian binary
binaryᵒ = zeroᵒ ∥ @g☾(posᵒ)
posᵒ = oneᵒ ∥ @g☾(gt𝟙ᵒ)
gt𝟙ᵒ = (zeroᵒ ∥ oneᵒ) → @g☾(posᵒ)


slurp() do q
  (q ∈ binaryᵒ)
end

#peano kitty



