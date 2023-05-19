using Pkg; Pkg.activate(".")
using GenieFramework
@genietools
using CondaPkg; CondaPkg.add("SimpleITK")
using PythonCall
using BDTools
using NIfTI
using CSV
using DataFrames
using Statistics

Genie.config.cors_headers["Access-Control-Allow-Origin"] = "*"
Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
Genie.config.cors_headers["Access-Control-Allow-Methods"] = "GET,POST,PUT,DELETE,OPTIONS"
Genie.config.cors_allowed_origins = ["*"]

# const FILE_PATH = "uploads"
# mkpath(FILE_PATH)
phantom = niread(joinpath("public/Phantom data UConn/104.nii"))
df_log = CSV.read(joinpath("public/Phantom data UConn/log104.csv"), DataFrame)
df_acq = CSV.read(joinpath("public/Phantom data UConn/acq_times_104.csv"), DataFrame)

max_motion = findmax(df_log[!,"Tmot"])[1]
slices_without_motion = df_acq[!,"Slice"][df_acq[!,"Time"] .> max_motion]

@handlers begin
    @in z = 1
    @in max_z = size(phantom, 3)
    @in min_z = 1

    @in t = 1
    @in max_t = size(phantom, 4)
    @in min_t = 1

    @out phantom_hmap = PlotData(
        z=collect(eachcol(phantom[:, :, 1, 1])),
        plot="heatmap",
        colorscale="Greys"
    )
    @onchange z, t begin
        phantom_hmap = PlotData(
            z=collect(eachcol(phantom[:, :, z, t])),
            plot="heatmap",
            colorscale="Greys"
        )
    end

    @in g_slices = RangeData(1:size(phantom, 3))
    @in t_slices = RangeData(1:200)

    @onchange g_slices, t_slices begin
        phantom_ok = phantom[:, :, g_slices, static_range]
        phantom_ok = Float64.(convert(Array, phantom_ok))
        slices_ok = sort(
            slices_without_motion[parse(Int, first(g_slices))-1 .<= slices_without_motion .<= parse(Int, last(g_slices))+1]
        )
        slices_wm = [x in slices_ok ? 1 : 0 for x in good_slices]
        slices_df = DataFrame(Dict(:slice => good_slices, :no_motion => slices_wm))
        sph = staticphantom(phantom_ok, Matrix(slices_df); staticslices=static_range);
    end
end

@page("/", "app.jl.html")
Server.isrunning() || Server.up()