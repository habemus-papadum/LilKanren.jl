using LilKanren

slurp() do q, a, b, c, d, e
    ( q     ≡ (:♣, :♠) )  ∧
    ( (a,b) ≡ q        )  ∧
    ( c     ≡ (1,d)    )  ∧
    ( d     ≡ (1,c)    )
end

function appendᵒ(o,front,back)
  ∨(  ## <-- Disjunction

    # ... the base case
    ∧(() ≡ front,
       o ≡ back),

    # ... or the recursive case
    fresh(3) do h,t,temp
      ∧((h,t)    ≡ front,
        (h,temp) ≡ o,
        @☾(appendᵒ(temp,t,back)))  # <-- Look Here!
    end)
end


slurp() do q
    appendᵒ(q,
            ❀(:✌︎, :✒︎, :✂︎, :☼),
            ❀(:☿,:♆))
end

slurp(maxResults=20) do front, back
    appendᵒ(❀(:✌︎, :✒︎, :✂︎, :☼,:☿,:♆,:✌︎, :✒︎, :✂︎, :☼,:☿,:♆),
            front,
            back)
end

