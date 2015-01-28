using Patchwork
using Patchwork.HTML5

Patchwork.load_js_runtime()


## output

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
        s = span("")
        for i=1:length(ar)
            s = s << pp(ar[i])
            if i < length(ar)
                s = s << span(",")  ## lazy-bones
            end
        end
        s = s & [:style => [:"font-size"=>"smaller"]]
        s = span("❀(") << s << span(")")
        return s
    else
        return span("(") << pp(h) << span(", ") << pp(t) << span(")")
    end
end

pp(x::LK.Var) = begin
    label = span("x") & [:style => [:"font-style"=>"italic"]]
    subscript = sub("$(x.id)") & [:style => [:"font-style"=>"italic"]]
    label << subscript
end

pp(x::LK.FreeValue) = begin
    label = span("✽") & [:style => [:"font-style"=>"italic"]]
    subscript = sub("$(x.id)") & [:style => [:"font-style"=>"italic"]]
    label << subscript
end
pp(x::LK.SelfRef) = begin
    label = span("$(x.name)") & [:style => [:"font-style"=>"italic"]]
    label
end


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
        LK.FreeValue(fvalCount)
    end

    function rfy(var,subs,context)
        var
    end

    function rfy(x::(Any,Any),subs,context)
        (h,t) = x
        (rfy(h,subs,context),rfy(t,subs,context))
    end

    function rfy(var::LK.Var,subs,context)
        (names, freevals,selfrefs,walking) = context

        if haskey(freevals,var)
            return freevals[var]
        else
            if var in walking
                ref = LK.SelfRef(names[var])
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

## table styling
## generated with http://tablestyler.com/#
function setupStyling()
  css = ".datagrid table { border-collapse: collapse; text-align: left; width: 100%; margin:0px auto; } .datagrid {margin:0px auto; font: normal 16px/150% Georgia, Times New Roman, Times, serif; background: #fff; overflow: hidden; border: 1px solid #8C8C8C; }.datagrid table td, .datagrid table th { padding: 4px 10px; }.datagrid table thead th {background:-webkit-gradient( linear, left top, left bottom, color-stop(0.05, #8C8C8C), color-stop(1, #7D7D7D) );background:-moz-linear-gradient( center top, #8C8C8C 5%, #7D7D7D 100% );filter:progid:DXImageTransform.Microsoft.gradient(startColorstr='#8C8C8C', endColorstr='#7D7D7D');background-color:#8C8C8C; color:#FFFFFF; font-size: 16px; font-weight: bold; border-left: 1px solid #A3A3A3; } .datagrid table thead th:first-child { border: none; }.datagrid table tbody td { color: #1A1E21; border-left: 1px solid #DBDBDB;font-size: 16px;font-weight: normal; }.datagrid table tbody .alt td { background: #EBEBEB; color: #1A1E21; }.datagrid table tbody td:first-child { border-left: none; }.datagrid table tbody tr:last-child td { border-bottom: none; }.datagrid table tfoot td div { border-top: 1px solid #8C8C8C;background: #EBEBEB;} .datagrid table tfoot td { padding: 0; font-size: 16px } .datagrid table tfoot td div{ padding: 2px; }.datagrid table tfoot td ul { margin: 0; padding:0; list-style: none; text-align: right; }.datagrid table tfoot  li { display: inline; }.datagrid table tfoot li a { text-decoration: none; display: inline-block;  padding: 2px 8px; margin: 1px;color: #F5F5F5;border: 1px solid #8C8C8C;-webkit-border-radius: 3px; -moz-border-radius: 3px; border-radius: 3px; background:-webkit-gradient( linear, left top, left bottom, color-stop(0.05, #8C8C8C), color-stop(1, #7D7D7D) );background:-moz-linear-gradient( center top, #8C8C8C 5%, #7D7D7D 100% );filter:progid:DXImageTransform.Microsoft.gradient(startColorstr='#8C8C8C', endColorstr='#7D7D7D');background-color:#8C8C8C; }.datagrid table tfoot ul.active, .datagrid table tfoot ul a:hover { text-decoration: none;border-color: #7D7D7D; color: #F5F5F5; background: none; background-color:#8C8C8C;}div.dhtmlx_window_active, div.dhx_modal_cover_dv { position: fixed !important; }"
  display("text/html", "<style>$css</style>")
end

display("text/html",
"""
<script type="text/javascript">

\$( document ).ready(function() {
console.log( "Fixing red boxes" );
\$( ".err" ).css( "border", "0px solid red" );
\$( ".err" ).css( "border-style", "none" );
});

</script>"""
)
varTable(res) = begin
    function items(r)
        e = Elem[]
        for i=1:length(r)
            (name,value) = r[i]
            row = tr(td(span(name)), td(pp(value)))
            if i % 2 == 0
              row = row & [:className => "alt"]
            end
            push!(e,row)
        end
        e
    end

    d = div(style=[:display => :flex,
                   "flex-wrap"=>:wrap])
    d = d << div(
        table(
    thead(tr(th("Var"),th("Value"))),
          tbody(items(res)...))) & [:className => :datagrid, :style => [:display=>"inline-block", :margin=>"10px"]]
    d
end

disphtml(x) = display("text/html", x)

ppreify(namedvars,state) = disphtml(varTable(reify(namedvars,state)))

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

## flex layout wrapper
wrapper(e...) = begin
    d = div(style=[:display => :flex,
                   "flex-wrap"=>:wrap])
    for i=1:length(e)
        d = d << (div(e[i]) & [:style => [:display=>"inline-block", :margin=>"10px"]])
    end
    d
end

storeTable(s) = begin
    function items(s::(),res=Elem[])
        return res
    end
    function items(s::(Any,Any),res=Elem[])
        (b, rest) = s
        push!(res,binding(b, length(res)+1))
        items(rest,res)
    end
    function binding(b, index)
        r = tr(td(var(first(b))), td(value(second(b))))
        if index % 2 == 0
            r = r & [:className => "alt"]
        end
        r
    end
    function var(v)
        s = @sprintf "%s" v
        span(s)
    end
    function value(v)
        s = @sprintf "%s" v
        span(s)
    end

    div(
        table(
          thead(tr(th("Var"),th("Binding"))),
          tbody(items(s)...))) & [:className => :datagrid]
end


function slurpityDooDah(freshBody::Function;
                     maxResults = 10, maxSteps=1_000_000, maxTime=5s,
            suppressOutput=false, elideAfter=20, returnResults=false)

    params = functionParams(freshBody)
    namedVars = cell(length(params))
    for i=1:length(namedVars)
        namedVars[i] = (params[i], LK.Var(i))
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
        div(table,div(span(info) & [:style => ["font-size" => "8pt", "font-family" => "Georgia, Times New Roman"]]))
    end

    gcTime = endGC-startGC
    gcBytes = endBytes-startBytes
    runTime = current-start


########################################

    ##display
    html = div()
    if !suppressOutput

        tables = [annotateTable(varTable(reify(namedVars,(s,count))),count,steps, nanos) for ((s,count),steps,nanos) = results[1:min(elideAfter,length(results))]]
        html = html << wrapper(tables...)

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
        html = html << div(pre(summaryString))
    end

    if returnResults
        return results
    else
        return html
    end
end

ηs = 1
s  = 1_000_000_000
minutes = 60*s
nothing
