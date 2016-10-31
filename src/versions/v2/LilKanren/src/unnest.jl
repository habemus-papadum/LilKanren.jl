module Unnest
  type Partial
    p
  end
end

UN = Unnest

MaybePartial = Union((Any,Any),UN.Partial)

function equivalent(u,v::UN.Partial)
  resolvePartial(v,u)
end

function resolvePartial(p::LilKanren.Unnest.Partial, u)
   fresh()  do o
    p.p(o) ∧ (o ≡ u)
  end
end

