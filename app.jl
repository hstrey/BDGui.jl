using GenieFramework, DataFrames, CSV, NIfTI
@genietools

Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

const FILE_PATH = "uploads"
mkpath(FILE_PATH)

@in selected_file = ""
@out upfiles = readdir(FILE_PATH)
@out hmap = PlotData()
@out layout = PlotLayout()

route("/", method=POST) do
    files = Genie.Requests.filespayload()
    for f in files
        write(joinpath(FILE_PATH, f[2].name), f[2].data)
    end
    if length(files) == 0
        @info "No file uploaded"
    end
    return "Upload finished"
end

@handlers begin
    @out hmap = PlotData()
    @out layout = PlotLayout()
    @onchange selected_file, isready begin
        img = niread(joinpath(FILE_PATH, selected_file))
        slice = img.raw[:, :, 10, 10]
        hmap = PlotData(
            z=collect(eachcol(slice)), 
            plot="heatmap",
            colorscale="Greys",
            colorbar=false
        )
    end
end

# @page("/", "ui.jl")
@page("/", "app.jl.html")
Server.isrunning() || Server.up()