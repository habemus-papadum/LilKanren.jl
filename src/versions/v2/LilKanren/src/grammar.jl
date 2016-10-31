litᵒ(val) = (x) -> x ≡ val

∥(a,b) = (val) -> a(val) ∨ b(val)

→(a,b) = (val) -> begin
  fresh(2) do h,t
    ((h,t) ≡ val) ∧
    a(h)          ∧
    b(t)
  end
end


g☾(pred) = (val) -> @☾ pred(val)

pred⁻¹(pred) = :(v -> st -> g☾($(esc(pred)))(v)(st))
macro g☾(pred)
  pred⁻¹(pred)
end

Base.in(val, relation::Function) = relation(val)

export @g☾,g☾,∥,litᵒ,→

