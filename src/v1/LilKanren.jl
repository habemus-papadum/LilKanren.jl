using Jewel

module LilKanren
  include("core.jl")
  include("helpers.jl")
  include("ui.jl")
end

if isdefined(Main, :IJulia)
  css = """
  .output table {
    color: black; }
    .output table td {
      border: 1px solid rgba(0, 0, 0, 0.05); }
  .output table.array tr:nth-child(odd) td:nth-child(even), .output table.array tr:nth-child(even) td:nth-child(odd) {
    background: rgba(0, 0, 200, 0.04); }
  """
  display("text/html", "<style> $(css) </style>")

  display("text/html",
      """
      <script type="text/javascript">

      \$( document ).ready(function() {
      console.log( "Fixing red boxes" );
      \$( ".err" ).css( "border", "0px solid red" );
      \$( ".err" ).css( "border-style", "none" );
      });

      </script>""")
end


