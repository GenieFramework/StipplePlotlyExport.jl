module StipplePlotlyExport

import Genie, Stipple, StipplePlotly, PlotlyBase, Base64

function save(data::Union{StipplePlotly.Charts.PlotData,Vector{StipplePlotly.Charts.PlotData}},
              layout::StipplePlotly.Charts.PlotLayout = StipplePlotly.Charts.PlotLayout();
              width::Int = 700,
              height::Int = 500,
              scale::Real = 1,
              format::String = "png")

  format in PlotlyBase.ALL_FORMATS || error("Unknown format $format. Expected one of $(PlotlyBase.ALL_FORMATS)")

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

  PlotlyBase._start_kaleido_process()
  PlotlyBase._ensure_kaleido_running() || PlotlyBase._restart_kaleido_process()

  # Integrally copied from PlotlyBase.jl -- big thank you to the contributors!

  bytes = transcode(UInt8, Stipple.JSONParser.json(payload))
  write(PlotlyBase.P.stdin, bytes)
  write(PlotlyBase.P.stdin, transcode(UInt8, "\n"))
  flush(PlotlyBase.P.stdin)

  # read stdout and parse to json
  res = readline(PlotlyBase.P.stdout)
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
  if format in PlotlyBase.TEXT_FORMATS
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
