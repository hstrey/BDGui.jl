### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 0d33b6a4-d57c-11ed-0653-b3dfbbff4a37
# ╠═╡ show_logs = false
begin
	using Pkg
	Pkg.activate(mktempdir())
	Pkg.add("CairoMakie")
	Pkg.add("NIfTI")
	Pkg.add("PlutoUI")
	Pkg.add("CSV")
	Pkg.add("DataFrames")
	Pkg.add("DelimitedFiles")
	Pkg.add(url="https://github.com/hstrey/BDTools.jl")

	using BDTools
	using CairoMakie
	using PlutoUI
	using NIfTI
	using CSV
	using DataFrames
	using DelimitedFiles
end

# ╔═╡ c41089ed-5441-468d-9e26-575d2f80954e
TableOfContents()

# ╔═╡ a5fe545c-20a7-494b-b411-9a884f72bb6f
md"""
# Milestone 1
"""

# ╔═╡ dd68fccb-fb89-4d40-987f-94238173fa69
md"""
## Load Phantom, Logs, & Acqusition Times
"""

# ╔═╡ 2e497ff3-bff2-4d78-9d9b-aff7059ec960
const DATA_DIR = "/Users/daleblack/Desktop/BrainDancerProject/data"

# ╔═╡ 228a4d69-5cac-4ca5-809a-e85e03e93890
md"""
Logs Filepath: $(@bind log_path confirm(TextField(70; default = joinpath(DATA_DIR, "log.csv"))))

Slices Filepath: $(@bind slices_path confirm(TextField(70; default = joinpath(DATA_DIR, "slices.csv"))))

Phantom Filepath: $(@bind phantom_path confirm(TextField(70; default = joinpath(DATA_DIR, "epi.nii"))))
"""

# ╔═╡ 8a989ac7-6291-4161-9d2c-4a53d4af52dd
df_log = CSV.read(log_path, DataFrame);

# ╔═╡ 5765fc02-6a11-46c8-b454-d9d32bcc4705
df_slices = CSV.read(slices_path, DataFrame);

# ╔═╡ 11c68da0-bd03-4fd6-bc00-37fb13b5b0ef
phantom_ts = niread(phantom_path);

# ╔═╡ 5f50c101-876a-4219-aadd-13cf5f5057eb
sz = size(phantom_ts)

# ╔═╡ 053db414-c29a-4357-b4d7-8da8449409ac
sliceinfo, _ = readdlm(slices_path, ',', Int, header=true);

# ╔═╡ 49473160-6c7c-4759-8cc5-09563af6faf0
md"""
## Identify Good Slices
"""

# ╔═╡ c5014a85-c55a-4318-aad7-2371fd39de50
@bind a_slider PlutoUI.Slider(axes(phantom_ts, 3), ; default=8, show_value=true)

# ╔═╡ fae663d0-2e1f-42e1-ae2a-2135ad20293f
md"""
Select all the good slices by scrolling through the slider above and checking each corresponding good slice below:


$(@bind good_slices confirm(MultiCheckBox(axes(phantom_ts, 3), default=collect(9:21))))
"""

# ╔═╡ eb89195a-f073-4125-9304-da189f8c4825
let
	f = Figure()
	ax = CairoMakie.Axis(f[1, 1])
	heatmap!(phantom_ts[:, :, a_slider, 1], colormap=:grays)
	f
end

# ╔═╡ 950d6684-0e18-4f65-a17b-3e71ea371c8b
@bind b_slider PlutoUI.Slider(axes(phantom_ts, 4), ; default=div(size(phantom_ts, 4), 2), show_value=true)

# ╔═╡ 3cb29e91-7fc1-4be6-91e6-fa9ba39bdd42
md"""
Select the range of static slices between $(1) to $(size(phantom_ts, 4)) by scrolling through the slider inputting the starting static slice and ending static slice below:

Starting static slice: $(@bind static_range_low confirm(TextField(default="1")))


Ending static slice: $(@bind static_range_high confirm(TextField(default="200")))
"""

# ╔═╡ 39383d69-0a24-417e-8091-806573c00909
let
	half_slice = good_slices[div(length(good_slices), 2)]
	f = Figure()
	ax = CairoMakie.Axis(f[1, 1])
	heatmap!(phantom_ts[:, :, half_slice, b_slider], colormap=:grays)
	f
end

# ╔═╡ 1f981673-1877-40fe-b9cb-3eef357cb5fd
begin
	num_static_range_low = parse(Int, static_range_low)
	num_static_range_high = parse(Int, static_range_high)
	static_range = num_static_range_low:num_static_range_high
end;

# ╔═╡ 20cb3d85-5230-4762-a94e-a449984471c0
begin
	good_slices_matrix = Int.(hcat(zeros(size(phantom_ts, 3)), collect(axes(phantom_ts, 3))))
	for i in good_slices
		idx = findall(x -> x == i, good_slices_matrix[:, 2])
		good_slices_matrix[idx..., 1] = 1
	end
end;

# ╔═╡ 54dfdb37-8f29-4217-8103-c51f2bb394bb
md"""
## Calculate Average Static Phantom
"""

# ╔═╡ 48adf8e0-d9d6-45e6-9072-9278dcd2bf7a
@bind c_slider PlutoUI.Slider(good_slices, ; default=good_slices[div(length(good_slices), 2)], show_value=true)

# ╔═╡ c728e56d-9a05-4400-a49a-f686c791e0e9
@bind d_slider PlutoUI.Slider(axes(phantom_ts, 4), ; default=div(size(phantom_ts, 4), 2), show_value=true)

# ╔═╡ 1fb24381-f18b-4692-aa09-d71c7c388e87
good_slices_range = first(good_slices)-1:last(good_slices)+1

# ╔═╡ 3b12c28c-1c30-4ebe-8c61-6140d4b4aaf3
begin
	phantom_ok = phantom_ts[:, :, good_slices_range, static_range]
	phantom_ok = Float64.(convert(Array, phantom_ts))
end;

# ╔═╡ 0641a36d-2c56-4dd1-8472-52343432e1b3
sph = staticphantom(phantom_ok, good_slices_matrix; staticslices=static_range);

# ╔═╡ c879e109-1d00-4b9a-8437-437489dda727
ave = BDTools.genimg(sph.data[:, :, c_slider]);

# ╔═╡ b907b975-6a38-42ba-8ccd-676ee4974c9f
let
	f = Figure(resolution=(1000, 700))
	ax = CairoMakie.Axis(
		f[1, 1],
		title="Raw 4D fMRI"
	)
	heatmap!(phantom_ts[:, :, c_slider, d_slider], colormap=:grays)

	ax = CairoMakie.Axis(
		f[1, 2],
		title="Average Static Image"
	)
	heatmap!(ave[:, :], colormap=:grays)
	f
end

# ╔═╡ dacf738d-2578-49d8-b5b6-ad97c6ca3eec
md"""
## Create Mask for B-field Correction
"""

# ╔═╡ b6533951-3cec-4463-a364-a2d542a44acf
@bind c_slider2 PlutoUI.Slider(good_slices, ; default=8, show_value=true)

# ╔═╡ 90678bfe-dd91-4f00-97d5-36de25a1703d
msk = BDTools.mask(sph, c_slider2);

# ╔═╡ 8f919fae-d1e7-4d6e-9b76-ca90e836232b
let
	cartesian_indices = findall(isone, msk)
	x_indices = [index[1] for index in cartesian_indices]
	y_indices = [index[2] for index in cartesian_indices]
	xys = hcat(x_indices, y_indices)

	f = Figure()
	ax = CairoMakie.Axis(
		f[1, 1],
		title = "Raw Phantom + Mask"
	)
	heatmap!(sph.data[:, :, c_slider2], colormap=:grays)
	scatter!(xys[:, 1], xys[:, 2], color=:red)
	f
end

# ╔═╡ 54d65bea-5c67-496d-90a1-d7ecbed5660a
md"""
## Run B-field Correction on Static Image
"""

# ╔═╡ 30baf701-285d-4045-b3a2-7658cb1672ca


# ╔═╡ c3bfdc29-f6fe-4ed4-b576-14735716344b
md"""
## Correct 4D Phantom w/ Bias Field
"""

# ╔═╡ 32e07326-623a-48fe-ab0a-0532e3a77a10


# ╔═╡ cb420508-c180-49e0-a5aa-421a1c9aab0b
md"""
Right now, just load a previously corrected phantom until b-field correction is implemented
"""

# ╔═╡ ff4dcb17-58f2-4cc9-836a-ed21217d3d78
b_corrected_phantom = niread(joinpath(DATA_DIR, "epi_corrected.nii")).raw;

# ╔═╡ fd9c0b86-785b-4ae6-9f21-8fce4829da34
md"""
# Milestone 2
"""

# ╔═╡ d164815b-fafd-4979-b6f4-c64bc9799524
md"""
## Fit Center & Radius
"""

# ╔═╡ 7e2d3587-e444-44a7-9e8c-74e218de1f29
# Original Centers
ecs = BDTools.centers(sph);

# ╔═╡ b6e0f6d5-88d2-4b0e-bf7a-8e21f64efa3e
# Predicted center axis
begin
	rng = collect(-1.:0.15:1.)
	cc = map(t->BDTools.predictcenter(sph, t), rng)
end;

# ╔═╡ 0d980da8-0054-4d38-827d-d0b327036238
first(cc)

# ╔═╡ 560900d6-14ef-4324-ac88-bc78edb52d9b
# Fitted Centers
xy = BDTools.fittedcenters(sph);

# ╔═╡ 6527923a-e885-426d-9a11-c9c9b922fb08
let
	f = Figure()
	ax = CairoMakie.Axis(f[1, 1])
	scatter!(ecs[:, 1], ecs[:, 2], label="Centers")
	lines!(map(first, cc), map(last, cc), label="Predicted Axis", color=:orange)
	scatter!(xy[:, 1], xy[:, 2], label="Fitted Centers", color=:green)
	axislegend(ax, position=:lt)
	f
end

# ╔═╡ a6b36c93-95ca-4e78-9b90-a5eba88ffe05
md"""
## Calculate Ground Truth Phantom
Users might need to input `threshold`
"""

# ╔═╡ f07097bc-dceb-4b7f-87bc-b5f6a0a00557
angles, firstrotidx = BDTools.getangles(log_path);

# ╔═╡ 511a41a4-2e32-404e-9587-09d37a695ad7
res = BDTools.groundtruth(sph, phantom_ts, angles; startmotion=firstrotidx, threshold=.95);

# ╔═╡ 0900925a-5dcf-40c7-aa42-3fd36a647abf
data, sliceidx, maskcoords = res;

# ╔═╡ f0aa5533-9d39-41b2-b605-fc8138e9a44a
md"""
## Fit Centerline of Rotation
"""

# ╔═╡ f1f9b383-68f7-4fef-9ed2-ad85f50d13d1
begin
	x = 42
	y = 52
	# get a coordinate index
	c = CartesianIndex(x,y)
	cidx = findfirst(m -> m == c, maskcoords)
end

# ╔═╡ 9c2b444b-be82-492e-a550-e36d6733cff4
@bind z PlutoUI.Slider(eachindex(sliceidx); default=3, show_value=true)

# ╔═╡ d5b85b67-0a10-4b87-afbb-691244e6af03
let
	f = Figure()
	ax = CairoMakie.Axis(f[1, 1])
    lines!(data[:, cidx, z, 2], label="original")
    lines!(data[:, cidx, z, 1], label="prediction")
	axislegend(ax)
	f
end

# ╔═╡ 76ca0894-5a41-40fd-a600-57be607dd3e8
md"""
## Calculate Ground Truth By Rotations & Interpolation
"""

# ╔═╡ fa65ac38-4220-4883-a92f-0fdb3287ea30
begin
	degrees = 0
	α = deg2rad(degrees)
	γ = BDTools.findinitialrotation(sph, z)
end;

# ╔═╡ de4980db-e372-4939-82ee-74565a8a9320
origin, a, b = BDTools.getellipse(sph, z);

# ╔═╡ 8a4d08f7-a31f-4e1c-bf1a-517e532330f2
coords = [BDTools.ellipserot(α, γ, a, b)*([i,j,z].-origin).+origin for i in 1:sz[1], j in 1:sz[2]];

# ╔═╡ 025b9bbb-99e4-4bbb-ba5e-9bc563ff0c4c
# interpolate intensities
sim = map(c->sph.interpolation(c...), coords);

# ╔═╡ 143b92e0-758c-4d22-8232-c3e329a5a9d3
# generate image
gen = sim |> BDTools.genimg;

# ╔═╡ db626433-2c6f-42c5-b867-550fdf9d174a
let
	f = Figure(resolution=(1000, 700))
	ax = CairoMakie.Axis(
		f[1, 1],
		title="Average Static Image @ Slice $(c_slider)"
	)
	heatmap!(ave, colormap=:grays)

	ax = CairoMakie.Axis(
		f[1, 2],
		title="Generated Image @ Slice $(c_slider) & Rotated $(degrees) Degrees"
	)
	heatmap!(gen[:, :], colormap=:grays)
	f
end

# ╔═╡ be0de58c-4902-4532-ac09-d5a90741c2c8
md"""
# Milestone 3
"""

# ╔═╡ 46fc165b-603b-4f71-bd05-15cb0326c391
md"""
## Calulcate Quality Control Measures
"""

# ╔═╡ 746b12b1-592d-4d4a-867c-1871e783c628


# ╔═╡ 50a4d79b-c06d-4b88-967a-ccbf756a805e
md"""
# Milestone 4
"""

# ╔═╡ 261f4057-cecd-4e6b-bf23-ff11c329365c
md"""
## Train Neural Network w/ Time Series
"""

# ╔═╡ 40f38942-4220-41b4-8951-eb7a1414204d


# ╔═╡ 75929b1c-a8aa-426a-913c-73a102535810
md"""
# Milestone 5
"""

# ╔═╡ ee3b8be3-27ec-453a-a240-80a107a83d66
md"""
## Processed 4D fMRI from Neural Network
"""

# ╔═╡ 1c4d20c2-7bd0-474c-8381-828f40e17caf


# ╔═╡ Cell order:
# ╠═0d33b6a4-d57c-11ed-0653-b3dfbbff4a37
# ╠═c41089ed-5441-468d-9e26-575d2f80954e
# ╟─a5fe545c-20a7-494b-b411-9a884f72bb6f
# ╟─dd68fccb-fb89-4d40-987f-94238173fa69
# ╟─2e497ff3-bff2-4d78-9d9b-aff7059ec960
# ╟─228a4d69-5cac-4ca5-809a-e85e03e93890
# ╠═8a989ac7-6291-4161-9d2c-4a53d4af52dd
# ╠═5765fc02-6a11-46c8-b454-d9d32bcc4705
# ╠═11c68da0-bd03-4fd6-bc00-37fb13b5b0ef
# ╠═5f50c101-876a-4219-aadd-13cf5f5057eb
# ╠═053db414-c29a-4357-b4d7-8da8449409ac
# ╟─49473160-6c7c-4759-8cc5-09563af6faf0
# ╟─c5014a85-c55a-4318-aad7-2371fd39de50
# ╟─fae663d0-2e1f-42e1-ae2a-2135ad20293f
# ╟─eb89195a-f073-4125-9304-da189f8c4825
# ╟─950d6684-0e18-4f65-a17b-3e71ea371c8b
# ╟─3cb29e91-7fc1-4be6-91e6-fa9ba39bdd42
# ╟─39383d69-0a24-417e-8091-806573c00909
# ╠═1f981673-1877-40fe-b9cb-3eef357cb5fd
# ╠═20cb3d85-5230-4762-a94e-a449984471c0
# ╟─54dfdb37-8f29-4217-8103-c51f2bb394bb
# ╟─48adf8e0-d9d6-45e6-9072-9278dcd2bf7a
# ╟─c728e56d-9a05-4400-a49a-f686c791e0e9
# ╠═1fb24381-f18b-4692-aa09-d71c7c388e87
# ╠═3b12c28c-1c30-4ebe-8c61-6140d4b4aaf3
# ╠═0641a36d-2c56-4dd1-8472-52343432e1b3
# ╠═c879e109-1d00-4b9a-8437-437489dda727
# ╟─b907b975-6a38-42ba-8ccd-676ee4974c9f
# ╟─dacf738d-2578-49d8-b5b6-ad97c6ca3eec
# ╟─b6533951-3cec-4463-a364-a2d542a44acf
# ╠═90678bfe-dd91-4f00-97d5-36de25a1703d
# ╟─8f919fae-d1e7-4d6e-9b76-ca90e836232b
# ╟─54d65bea-5c67-496d-90a1-d7ecbed5660a
# ╠═30baf701-285d-4045-b3a2-7658cb1672ca
# ╟─c3bfdc29-f6fe-4ed4-b576-14735716344b
# ╠═32e07326-623a-48fe-ab0a-0532e3a77a10
# ╟─cb420508-c180-49e0-a5aa-421a1c9aab0b
# ╠═ff4dcb17-58f2-4cc9-836a-ed21217d3d78
# ╟─fd9c0b86-785b-4ae6-9f21-8fce4829da34
# ╟─d164815b-fafd-4979-b6f4-c64bc9799524
# ╠═7e2d3587-e444-44a7-9e8c-74e218de1f29
# ╠═b6e0f6d5-88d2-4b0e-bf7a-8e21f64efa3e
# ╠═0d980da8-0054-4d38-827d-d0b327036238
# ╠═560900d6-14ef-4324-ac88-bc78edb52d9b
# ╟─6527923a-e885-426d-9a11-c9c9b922fb08
# ╟─a6b36c93-95ca-4e78-9b90-a5eba88ffe05
# ╠═f07097bc-dceb-4b7f-87bc-b5f6a0a00557
# ╠═511a41a4-2e32-404e-9587-09d37a695ad7
# ╠═0900925a-5dcf-40c7-aa42-3fd36a647abf
# ╟─f0aa5533-9d39-41b2-b605-fc8138e9a44a
# ╠═f1f9b383-68f7-4fef-9ed2-ad85f50d13d1
# ╟─9c2b444b-be82-492e-a550-e36d6733cff4
# ╟─d5b85b67-0a10-4b87-afbb-691244e6af03
# ╟─76ca0894-5a41-40fd-a600-57be607dd3e8
# ╠═fa65ac38-4220-4883-a92f-0fdb3287ea30
# ╠═de4980db-e372-4939-82ee-74565a8a9320
# ╠═8a4d08f7-a31f-4e1c-bf1a-517e532330f2
# ╠═025b9bbb-99e4-4bbb-ba5e-9bc563ff0c4c
# ╠═143b92e0-758c-4d22-8232-c3e329a5a9d3
# ╟─db626433-2c6f-42c5-b867-550fdf9d174a
# ╟─be0de58c-4902-4532-ac09-d5a90741c2c8
# ╟─46fc165b-603b-4f71-bd05-15cb0326c391
# ╠═746b12b1-592d-4d4a-867c-1871e783c628
# ╟─50a4d79b-c06d-4b88-967a-ccbf756a805e
# ╟─261f4057-cecd-4e6b-bf23-ff11c329365c
# ╠═40f38942-4220-41b4-8951-eb7a1414204d
# ╟─75929b1c-a8aa-426a-913c-73a102535810
# ╟─ee3b8be3-27ec-453a-a240-80a107a83d66
# ╠═1c4d20c2-7bd0-474c-8381-828f40e17caf
