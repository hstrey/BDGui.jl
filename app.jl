using GenieFramework, DataFrames, CSV, NIfTI
@genietools

Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

const FILE_PATH = "uploads"
mkpath(FILE_PATH)

@in selected_file_image = ""
@in selected_file_log = ""
@in selected_file_acq = ""
@in selected_z_slice = 1
@in selected_t_slice = 1

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
    @onchange selected_file_image, selected_file_log, selected_file_acq begin
        # -- Load the phantom image -- #
        img = niread(joinpath(FILE_PATH, selected_file_image))
        img_raw = img.raw
        # @show img_raw

        # -- Load the log file -- #
        df_log = CSV.read(joinpath(FILE_PATH, selected_file_log), DataFrame)

        # -- Load the acquisition times -- #
        df_acq = CSV.read(joinpath(FILE_PATH, selected_file_acq), DataFrame)

        # -- Visualize phantom -- #
        slice = img_raw[:, :, 11, 100]
        @info slice
        hmap = PlotData(
            z=collect(eachcol(slice)),
            plot="heatmap",
            colorscale="Greys"
        )
    end
end

@page("/", "ui.jl")
# @page("/", "app.jl.html")
Server.isrunning() || Server.up()