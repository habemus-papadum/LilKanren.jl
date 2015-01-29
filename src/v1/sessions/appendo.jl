
using LilKanren

slurp() do q
    q ≡ (:♡, :♠)
end

function appendᵒ(o,front,back)
    ∨(
       ∧(❀() ≡ front,
          o ≡ back),
       fresh(3) do h,t,temp
         ∧(
             (h,t) ≡ front,
             (h,temp) ≡ o,
             @☾(appendᵒ(temp,t,back))
         )
       end
    )
end


slurp() do q
    appendᵒ(q, ❀(:✌︎, :✒︎, :✂︎, :☼), ❀(:☿,:♆))
end

slurp(maxResults=20) do front, back
    appendᵒ(❀(:✌︎, :✒︎, :✂︎, :☼,:☿,:♆,:✌︎, :✒︎, :✂︎, :☼,:☿,:♆),
            front, back)
end

