module StipplePlotlyExport

import Genie, Stipple, StipplePlotly, PlotlyBase, Base64
include("KaleidoExport.jl")
using .KaleidoExport

function save(data::Union{StipplePlotly.Charts.PlotData,Vector{StipplePlotly.Charts.PlotData}},
              layout::StipplePlotly.Charts.PlotLayout = StipplePlotly.Charts.PlotLayout();
              width::Int = 700,
              height::Int = 500,
              scale::Real = 1,
              format::String = "png")

  format in KaleidoExport.ALL_FORMATS || error("Unknown format $format. Expected one of $(KaleidoExport.ALL_FORMATS)")

  payload = Dict(
    :data => Dict(
      :data => Stipple.render(data),
      :layout => Stipple.render(layout)
    ),
    :width => width,
    :height => height,
    :scale => scale,
    :format => format
  )

  KaleidoExport._start_kaleido_process()
  KaleidoExport._ensure_kaleido_running() || KaleidoExport._restart_kaleido_process()

  # Integrally copied from PlotlyBase.jl -- big thank you to the contributors!

  bytes = transcode(UInt8, Stipple.JSONParser.json(payload))
  write(KaleidoExport.P.stdin, bytes)
  write(KaleidoExport.P.stdin, transcode(UInt8, "\n"))
  flush(KaleidoExport.P.stdin)

  # read stdout and parse to json
  res = readline(KaleidoExport.P.stdout)
  js = Stipple.JSONParser.parse(res)

  # check error code
  code = get(js, "code", 0)
  if code != 0
      msg = get(js, "message", nothing)
      error("Transform failed with error code $code: $msg")
  end

  # get raw image
  img = String(js["result"])

  # base64 decode if needed, otherwise transcode to vector of byte
  if format in KaleidoExport.TEXT_FORMATS
      return transcode(UInt8, img)
  else
      return Base64.base64decode(img)
  end
end


function save(io::Union{String,IO},
              data::Union{StipplePlotly.Charts.PlotData,Vector{StipplePlotly.Charts.PlotData}},
              layout::StipplePlotly.Charts.PlotLayout = StipplePlotly.Charts.PlotLayout();
              width::Int = 700,
              height::Int = 500,
              scale::Real = 1,
              format::String = "png")
  write(io, save(data, layout; width=width, height=height, scale=scale, format=format))
end

end
