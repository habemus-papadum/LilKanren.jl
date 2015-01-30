function uncompressAst(f)
    if isa(f.code.ast,Array{Uint8,1})
        ccall(:jl_uncompress_ast, Any, (Any, Any), f.code, f.code.ast)
    else
        f.code.ast
    end
end

function functionParams(f)
    if (isgeneric(f))
      f = f.env.defs.func
    end
    ast = uncompressAst(f)
    @assert ast.head == :lambda
    ae = ast.args[1]
    p = cell(length(ae))
    for i=1:length(ae)
        if (isa(ae[i],Expr) )
          @assert ae[i].head == :(::)
          p[i] = string(ae[i].args[1])
        elseif isa(ae[i], Symbol)
          p[i] = string(ae[i])
        else
           error("Unable to parse arguments from ast: $ast")
        end
    end
    p
end

