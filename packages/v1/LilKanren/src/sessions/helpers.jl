## useful for resetting Module list
LightTable.raise(LightTable.global_client, "julia.set-modules", @Jewel.d(:modules => [string(m) for m in Jewel.allchildren(Main)]))
## not needed -- use refreshditor module command

function generic(x)
  x
end

functionParams(generic)
functionParams(x-> x+ 2)
dump(uncompressAst(generic.env.defs.func))
dump(uncompressAst((x) -> x + 2))

