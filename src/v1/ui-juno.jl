
## output
import LightTable
import LightTable.DOM
DM = LightTable.DOM
styleDefault = ["font-family" => "Monaco"]

stylestr(d::Dict) = begin a=map(t->"$(t[1]):$(t[2])", d); join(a,";") end
span(s,styleD::Dict=Dict()) = DM.span(s, style=stylestr(merge(styleDefault,styleD)))
span(s...; style::Dict=Dict()) = begin st = style; s = DM.span(s...); s.attrs = ["style" => stylestr(merge(styleDefault,st))]; s end
div(d...; style::Dict=Dict()) =  begin st = style; d = DM.div(d...); d.attrs = ["style" => stylestr(merge(styleDefault,st))]; d end

pp(x) = begin
  s = @sprintf "%s" x
  span(s)
end
pp(x::()) = begin
  s = "❀()"
  span(s)
end
pp(x::(Any,Any)) = begin
    (h,t) = x
    if islist(x)
        ar = list➜array(x)
        spans = {}
        push!(spans,span("❀("))
        for i=1:length(ar)
            push!(spans,pp(ar[i]))
            if i < length(ar)
                push!(spans,span(","))  ## lazy-bones
            end
        end
        push!(spans, span(")"))
        return span(spans...; style = [:"font-size"=>"smaller"])
    else
        return span(span("("), pp(h), span(", "), pp(t), span(")"))
    end
end

# pp(((),:♡))
# pp(⊞(1,2,3,4,⊞(1,2,3)))


pp(x::Var) = begin
    label = span("x")
    subscript =  DM.Node(:sub,"$(x.id)")
    span(label, subscript;style=[:"font-style"=>"italic"])
end
# pp(Var(12))

pp(x::FreeValue) = begin
    label = span("✽")
    subscript =  DM.Node(:sub,"$(x.id)")
    span(label, subscript;style=[:"font-style"=>"italic"])
end
# pp(FreeValue(10))

pp(x::SelfRef) = begin
    label = span("$(x.name)",["font-style"=>"italic"])
    label
end
# pp(SelfRef("foo"))


function reify(namedvars, state)
    (subs,count) = state
    res = cell(length(namedvars))
    names = Dict()

    for i = 1:length(namedvars)
        (name,var) = namedvars[i]
        names[var] = name
    end

    context = (names, Dict(), Dict(), Set())

    fvalCount = 0
    function newFreeVal()
        fvalCount += 1
        FreeValue(fvalCount)
    end

    function rfy(var,subs,context)
        var
    end

    function rfy(x::(Any,Any),subs,context)
        (h,t) = x
        (rfy(h,subs,context),rfy(t,subs,context))
    end

    function rfy(var::Var,subs,context)
        (names, freevals,selfrefs,walking) = context

        if haskey(freevals,var)
            return freevals[var]
        else
            if var in walking
                ref = SelfRef(names[var])
                selfrefs[var] = ref
                return ref
            elseif haskey(selfrefs,var)
                return selfrefs[var]
            else
                push!(walking,var)
                (wval,s) = walk(var,subs)
                if (wval==var)
                    val = newFreeVal()
                    freevals[var] = val
                else
                    val = rfy(wval,subs,(names, freevals,selfrefs,walking))
                end
                pop!(walking,var)
                return val
            end
        end
    end

    for i = 1:length(namedvars)
        (name,var) = namedvars[i]
        reified = rfy(var,subs, context)
        res[i] = (name,reified)
    end
    res

end


##hackey-hack
function uncompressAst(f)
    if isa(f.code.ast,Array{Uint8,1})
        ccall(:jl_uncompress_ast, Any, (Any, Any), f.code, f.code.ast)
    else
        f.code.ast
    end
end

function functionParams(f)
    ast = uncompressAst(f)
    @assert ast.head == :lambda
    ae = ast.args[1]
    p = cell(length(ae))
    for i=1:length(ae)
        @assert ae[i].head == :(::)
        p[i] = string(ae[i].args[1])
    end
    p
end


export slurpityDooDah
function slurpityDooDah(freshBody::Function;
                     maxResults = 10, maxSteps=1_000_000, maxTime=5s,
                     elideAfter=20, returnResults=false)

    params = functionParams(freshBody)
    namedVars = cell(length(params))
    for i=1:length(namedVars)
        namedVars[i] = (params[i], Var(i))
    end


    ## VIP's
    steps = 0
    results = Any[]

    ## thank you, julia!
    startBytes = Base.gc_bytes()
    start = Base.time_ns()
    startGC = Base.gc_time_ns()

    thisStart = start
    thisFirstStep = steps

    stream  = ∞ |> fresh(freshBody,length(params))

    done = () -> (steps >= maxSteps || length(results) >= maxResults || current - start >= maxTime || stream == ())

    steps += 1
    current = Base.time_ns()

    while(!done())
        if (typeof(stream) <: Function)
            stream = stream()
            steps += 1
        else
            if (typeof(stream) <: (Any,Any))
                push!(results, (first(stream),steps-thisFirstStep,current-thisStart))
                thisFirstStep = steps
                thisStart = current
                stream = second(stream)
            end
        end
        current = Base.time_ns()
    end

    endGC = Base.gc_time_ns()
    current = Base.time_ns()
    endBytes = Base.gc_bytes()


########################################
    ##utils
    function niceTime(nanos;morePrecision=false)
        f = morePrecision ? format2 : format
        if nanos < 1_000.0
            "$(f(nanos)) ηs"
        elseif nanos < 1_000_000.0
            "$(format2(nanos/1_000.0)) μs"
        elseif nanos < 1_000_000_000.0
            "$(format2(nanos/1_000_000.0)) ms"
        else
            "$(format2(nanos/1_000_000_000.0)) s"
        end
    end

    function niceBytes(bytes;morePrecision=false)
        f = morePrecision ? format2 : format
        if bytes < 2^10
            "$(f(bytes)) bytes"
        elseif bytes < 2^20
            "$(format2(bytes/2^10)) KB"
        elseif bytes < 2^30
            "$(format2(bytes/2^20)) MB"
        else
            "$(format2(bytes/2^30)) GB"
        end
    end

    function format(x)
        @sprintf "%.f"  x
    end
    function format2(x)
        @sprintf "%.2f"  x
    end

    function annotateTable(table, nextVar, steps, nanos)
      info = "Vars Alloc'd: $(nextVar-1), Steps: $(steps), Time: $(niceTime(nanos))"
      div(table,div(span(info),style = ["font-size" => "8pt"]))
    end

    gcTime = endGC-startGC
    gcBytes = endBytes-startBytes
    runTime = current-start


########################################

    ##display
    if !returnResults

        tables = [annotateTable(varTable(reify(namedVars,(s,count))),count,steps, nanos) for ((s,count),steps,nanos) = results[1:min(elideAfter,length(results))]]
        wrapped =  wrapper(tables...)

        summaryString =
        """
        Summary:
        ==============================
        Total # of steps: $steps
        Total # of results: $(length(results))  ($(format2(100.0*length(results)/steps))% Hit rate)
        Total Time: $(niceTime(runTime)) $(niceTime(runTime/steps,morePrecision=true))/step $(niceTime(runTime/length(results),morePrecision=true))/result
        Total GC Time: $(niceTime(gcTime)) $(niceTime(gcTime/steps,morePrecision=true))/step $(niceTime(gcTime/length(results),morePrecision=true))/result ($(format2(100.0*gcTime/runTime))%)
        Total GC Bytes: $(niceBytes(gcBytes)) $(niceBytes(gcBytes/steps,morePrecision=true))/step $(niceBytes(gcBytes/length(results),morePrecision=true))/result
        """

        if elideAfter < length(results)
            summaryString = "\n$(length(results)-elideAfter) Results Suppressed\n$summaryString"
        end
        return  div(wrapped,div(DM.Node(:pre,summaryString)))
    end

    return results
end

ηs = 1
s  = 1_000_000_000
minutes = 60*s


## flex layout wrapper
wrapper(e...) = begin
    ds = cell(length(e))

    for i=1:length(e)
#         ds[i] = div(e[i],style=["display"=>"inline-block", "margin"=>"10px"])
          ds[i] = div(e[i],style=["margin"=>"10px"])
    end
#     div(ds...,style=["display" => "flex",
#                          "flex-wrap"=>"wrap"])
     div(ds...)

end




function varTable(res)
    tr(x...)  = DM.Node(:tr,x...)
    td(x...)  = DM.Node(:td,x...)

    function items(r)
        e = {}
        for i=1:length(r)
            (name,value) = r[i]
            row = tr(td(span(name)), td(pp(value)))
            push!(e,row)
        end
        e
    end

    t = DM.Node(:table, items(res)...)
    t.attrs=["class"=>"array"]
    t
end

