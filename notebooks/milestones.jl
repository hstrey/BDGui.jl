### A Pluto.jl notebook ###
# v0.19.25

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

# ╔═╡ 866b498e-52cc-461a-90dc-bfd6d53dd80d
# ╠═╡ show_logs = false
begin
	using Pkg
	Pkg.activate(mktempdir())
	Pkg.add("CondaPkg")
	Pkg.add("PythonCall")
	Pkg.add(url="https://github.com/hstrey/BDTools.jl")
	Pkg.add("CairoMakie")
	Pkg.add("NIfTI")
	Pkg.add("PlutoUI")
	Pkg.add("CSV")
	Pkg.add("DataFrames")

	using CondaPkg; CondaPkg.add("SimpleITK")
	using PythonCall
	using BDTools
	using CairoMakie
	using PlutoUI
	using NIfTI
	using CSV
	using DataFrames
	using Statistics
end

# ╔═╡ 90b6279b-7595-43de-b3f7-10ffdbeabf58
sitk = pyimport("SimpleITK")

# ╔═╡ e7a428ce-0489-43c3-8c5a-bae818f0ca03
TableOfContents()

# ╔═╡ bbd3d93f-8775-48aa-93e0-5600fd1b5355
md"""
# Milestone 1
"""

# ╔═╡ dc6717ba-25fb-4f7d-933a-18dc69fea34d
md"""
## Load Phantom, Logs, & Acqusition Times
"""

# ╔═╡ d90a11ce-52fd-48e4-9cb1-755bc2b29e51
function upload_files(logs, acqs, phtm)
	
	return PlutoUI.combine() do Child
		
		inputs = [
			md""" $(logs): $(@bind log_file TextField(60; default="https://www.dropbox.com/s/y2hyz2devw30s5x/log104.csv?dl=0"))""",
			md""" $(acqs): $(@bind acq_file TextField(60; default="https://www.dropbox.com/s/qu75ggnbc2rsji5/acq_times_104.csv?dl=0"))""",
			md""" $(phtm): $(@bind nifti_file TextField(60 ; default="https://www.dropbox.com/s/hikpi7t89mwbb4w/104.nii?dl=0"))"""
		]
		
		md"""
		#### Upload Files
		Provide URLs or file paths to the necessary files. If running locally, file paths are expected. If running on the web, provide URL links. We recommend DropBox, as Google Drive will likely not work.
		
		Ensure log and acquisition files are in `.csv` format & phantom file is in `.nii` or `.nii.gz` format. Then click submit
		$(inputs)
		"""
	end
end

# ╔═╡ d2e0accd-2395-4115-8842-e9176a0a132e
confirm(upload_files("Upload Log File: ", "Upload Acquisition Times: ", "Upload Phantom Scan: "))

# ╔═╡ 19b12720-4bd9-4790-84d0-9cf660d8ed70
try
	global df_log = CSV.read(download(log_file), DataFrame)
	
	global df_acq = CSV.read(download(acq_file), DataFrame)
		
	global phantom = niread(download(nifti_file))
catch
	global df_log = CSV.read(log_file, DataFrame)
	
	global df_acq = CSV.read(acq_file, DataFrame)
		
	global phantom = niread(nifti_file)
end;

# ╔═╡ b0e58a0a-c6a7-4e4d-8a14-efbfbf7251e9
phantom_header = phantom.header

# ╔═╡ 3dcddb92-6277-46d2-9e34-3863f0a60731
vsize = voxel_size(phantom.header) # mm

# ╔═╡ 7f2148e2-8649-4fb6-a50b-3dc54bca7505
md"""
## Identify Good Slices
"""

# ╔═╡ 6a8117e0-e450-46d7-897f-0503d71f06af
function good_slice_info(good_slices_first, good_slices_last)
	
	return PlutoUI.combine() do Child
		
		inputs = [
			md""" $(good_slices_first): $(
				Child(TextField(default=string(29)))
			)""",
			md""" $(good_slices_last): $(
				Child(TextField(default=string(44)))
			)"""
		]
		
		md"""
		#### Good Slices
		Select the range of good slices between 1 to 60 by scrolling through the slider and note when the first good slice starts and when the last good slice ends
		$(inputs)
		"""
	end
end

# ╔═╡ 8eb754de-37b7-45fb-a7fc-c14c11e0216f
@bind g_slices confirm(good_slice_info("First good slice: ", "Last good slice: "))

# ╔═╡ 7eacbaef-eae0-426a-be36-9c00a3b09d1b
good_slices_files_ready = g_slices[1] != "" && g_slices[2] != "" 

# ╔═╡ 49557d91-e4de-486b-99ed-3d564c7b7960
@bind good_slices_slider PlutoUI.Slider(axes(phantom, 3); default=div(size(phantom, 3), 2), show_value=true)

# ╔═╡ 04c7cf73-fa75-45e1-aafe-4ca658706289
heatmap(phantom.raw[:, :, good_slices_slider, 1], colormap=:grays)

# ╔═╡ 4a485292-f875-44c4-b940-8f2714f6d26f
if good_slices_files_ready
	good_slices_range = parse(Int, first(g_slices)):parse(Int, last(g_slices))
end;

# ╔═╡ f11be125-facc-44ff-8d00-8cd748d6d110
if good_slices_files_ready
	good_slices = collect(parse(Int, g_slices[1]):parse(Int, g_slices[2]));
end;

# ╔═╡ 8724296c-6118-4c0f-bea4-3173222a40cf
function static_slice_info(good_slices_first, good_slices_last)
	
	return PlutoUI.combine() do Child
		
		inputs = [
			md""" $(good_slices_first): $(
				Child(TextField(default="1"))
			)""",
			md""" $(good_slices_last): $(
				Child(TextField(default="200"))
			)"""
		]
		
		md"""
		#### Static Slices
		Select the range of good slices between 1 to 60 by scrolling through the slider and note when the first good slice starts and when the last good slice ends
		$(inputs)
		"""
	end
end

# ╔═╡ 877c4ec3-5c00-496a-b4e0-d09fc46fd207
@bind static_ranges confirm(static_slice_info("Starting static slice: ", "Ending static slice: "))

# ╔═╡ 1d1fa36d-774b-43a8-9e4e-acc013ae8efe
@bind b_slider PlutoUI.Slider(axes(phantom, 4); default=div(size(phantom, 4), 2), show_value=true)

# ╔═╡ 32292190-1124-4087-b728-8f998e3c3814
heatmap(phantom[:, :, div(size(phantom, 3), 2), b_slider], colormap=:grays)

# ╔═╡ 15681a0d-a217-42af-be91-6edeff37dfaa
begin
	num_static_range_low = parse(Int, static_ranges[1])
	num_static_range_high = parse(Int, static_ranges[2])
	static_range = num_static_range_low:num_static_range_high
end;

# ╔═╡ 886c9748-b423-4d68-acb4-2b32c65ebc1d
if good_slices_files_ready
	phantom_ok = phantom[:, :, good_slices_range, static_range]
	phantom_ok = Float64.(convert(Array, phantom_ok))
end;

# ╔═╡ de4e1b7c-2a70-499d-a375-87c8aaca0ad3
begin
	max_motion = findmax(df_log[!,"Tmot"])[1]
	slices_without_motion = df_acq[!,"Slice"][df_acq[!,"Time"] .> max_motion]
	slices_ok = sort(
		slices_without_motion[parse(Int, first(g_slices))-1 .<= slices_without_motion .<= parse(Int, last(g_slices))+1]
	)
	slices_wm = [x in slices_ok ? 1 : 0 for x in good_slices]
	slices_df = DataFrame(Dict(:slice => good_slices, :no_motion => slices_wm))
end

# ╔═╡ d0c6dc6d-b85f-4f76-a478-02fcd9484344
md"""
## Calculate Average Static Phantom
"""

# ╔═╡ d75e495c-bf4e-4608-bd7f-357d3fe1023b
sph = staticphantom(phantom_ok, Matrix(slices_df); staticslices=static_range);

# ╔═╡ db78c6f2-5afe-4d12-b39f-f6b4286f2d17
phantom_header.dim = (length(size(sph.data)), size(sph.data)..., 1, 1, 1, 1)

# ╔═╡ 35e1fcca-f1e0-4b33-82c7-e0c1325464d0
if good_slices_files_ready
	@bind c_slider PlutoUI.Slider(axes(sph.data, 3) ; default=div(size(sph.data, 3), 2), show_value=true)
end

# ╔═╡ fc87815b-54d1-4f69-ac8d-b0fbeab7f53d
if good_slices_files_ready
	@bind d_slider PlutoUI.Slider(axes(phantom, 4), ; default=div(size(phantom, 4), 2), show_value=true)
end

# ╔═╡ f57cb424-9dd2-4432-8485-034ded569f13
if good_slices_files_ready
	ave = BDTools.genimg(sph.data[:, :, c_slider])
end;

# ╔═╡ e570adef-e2d1-4080-86e8-4ac57ad8a6f0
let
	if good_slices_files_ready
		f = Figure(resolution=(1000, 700))
		ax = CairoMakie.Axis(
			f[1, 1],
			title="Raw 4D fMRI"
		)
		heatmap!(phantom[:, :, slices_df[c_slider, 2], d_slider], colormap=:grays)
	
		ax = CairoMakie.Axis(
			f[1, 2],
			title="Average Static Image"
		)
		heatmap!(ave[:, :], colormap=:grays)
		f
	end
end

# ╔═╡ 4de55168-94c0-400e-a072-feb34a07fe2b
avg_static_phantom = Float32.(sph.data);

# ╔═╡ a649bf25-f3e4-44b4-bb3e-266a456f2f21
begin
	tempdir = mktempdir()
	
	avg_static_phantom_path = joinpath(tempdir, "image.nii")
	niwrite(avg_static_phantom_path, NIVolume(phantom_header, avg_static_phantom))
end

# ╔═╡ 5e364415-8ab9-4f8d-a775-03d45748b249
md"""
## Create Mask for B-field Correction
"""

# ╔═╡ 056f3868-9a21-4c68-9f51-a9ed2d662e46
if good_slices_files_ready
	@bind c_slider2 PlutoUI.Slider(axes(sph.data, 3); show_value=true)
end

# ╔═╡ 13b34063-4fea-4044-9648-7d72fd90ed2d
msk = BDTools.segment3(sph.data[:, :, c_slider2]);

# ╔═╡ e512474b-a648-416a-a52f-19b0e52fbd17
let
	if good_slices_files_ready
		cartesian_indices1 = findall(x -> x == 2, msk.image_indexmap)
		x_indices1 = [index[1] for index in cartesian_indices1]
		y_indices1 = [index[2] for index in cartesian_indices1]
		xys1 = hcat(x_indices1, y_indices1)
	
		cartesian_indices2 = findall(x -> x == 3, msk.image_indexmap)
		x_indices2 = [index[1] for index in cartesian_indices2]
		y_indices2 = [index[2] for index in cartesian_indices2]
		xys2 = hcat(x_indices2, y_indices2)
	
		f = Figure()
		ax = CairoMakie.Axis(
			f[1, 1],
			title = "Raw Phantom + Mask"
		)
		heatmap!(sph.data[:, :, c_slider2], colormap=:grays)
		scatter!(xys1[:, 1], xys1[:, 2], color=:red)
		scatter!(xys2[:, 1], xys2[:, 2], color=:blue)
		f
	end
end

# ╔═╡ cb3c7d65-dcdf-48c9-a1fa-56ba71b327e5
begin
	msk3D = zeros(Int, size(sph.data)[1:2]..., length(good_slices))
	for i in axes(sph.data, 3)
		msk3D[:, :, i] = BDTools.segment3(sph.data[:, :, i]).image_indexmap
	end
	msk3D = parent(msk3D)
end;

# ╔═╡ 4168038a-7257-4082-8243-525175d12be0
begin
	binary_msk3D = zeros(Int, size(msk3D))
	idxs = findall(x -> x == 2 || x == 3, msk3D)
	for i in idxs
		binary_msk3D[i] = 1
	end
	binary_msk3D = Float32.(binary_msk3D)
end;

# ╔═╡ 51a6b51f-55fd-442c-a6a0-5d9be970d300
begin
	mask_path = joinpath(tempdir, "mask.nii")
	niwrite(mask_path, NIVolume(phantom_header, binary_msk3D))
end

# ╔═╡ 692360cc-dcb0-456a-8234-f747ce371b1b
heatmap(binary_msk3D[:, :, 10], colormap=:grays)

# ╔═╡ 659ec1a1-356c-4742-bd63-0ebaa3df5b96
md"""
## Run B-field Correction on Static Image
"""

# ╔═╡ 79bfc734-f19d-4d5b-a585-ef02bf2b0144
function bfield_correction(image_path, mask_path)
	inputImage = sitk.ReadImage(image_path, sitk.sitkFloat32)
	image = inputImage
	
	maskImage = sitk.ReadImage(mask_path, sitk.sitkUInt8)
	
	corrector = sitk.N4BiasFieldCorrectionImageFilter()

	corrected_image = corrector.Execute(image, maskImage)
    log_bias_field = corrector.GetLogBiasFieldAsImage(inputImage)

	tempdir = mktempdir()
	corrected_image_path = joinpath(tempdir, "corrected_image.nii")
	log_bias_field_path = joinpath(tempdir, "log_bias_field.nii")

	sitk.WriteImage(corrected_image, corrected_image_path)
	sitk.WriteImage(log_bias_field, log_bias_field_path)

	return (
		niread(image_path),
		niread(mask_path),
		niread(log_bias_field_path),
		niread(corrected_image_path)
	)
end

# ╔═╡ bafa6302-6dbc-4b46-afc2-a414079a0472
input_image, mask, bfield, corrected_image = bfield_correction(avg_static_phantom_path, mask_path);

# ╔═╡ d21b03e8-ff8f-4875-b9bd-009eb34e11ad
md"""
Select Slice: $(@bind bfield_slider PlutoUI.Slider(axes(bfield, 3); show_value=true))


Set color range: 
  - Low: $(@bind colorrange_low PlutoUI.Slider(Int.(round(minimum(corrected_image))):Int.(round(maximum(corrected_image)))))
  - High: $(@bind colorrange_high PlutoUI.Slider(Int.(round(minimum(corrected_image))):Int.(round(maximum(corrected_image))); default=Int.(round(maximum(corrected_image)))))
"""

# ╔═╡ 87f3ccf9-4ee4-466e-a15c-f5000d6a3eca
let
	if good_slices_files_ready
		f = Figure(resolution=(1000, 1000))
		ax = CairoMakie.Axis(
			f[1, 1],
			title="Input Phantom"
		)
		heatmap!(input_image[:, :, bfield_slider], colorrange = (colorrange_low, colorrange_high), colormap=:grays)
	
		ax = CairoMakie.Axis(
			f[1, 2],
			title="Corrected Average Static Phantom"
		)
		heatmap!(corrected_image[:, :, bfield_slider], colorrange = (colorrange_low, colorrange_high), colormap=:grays)

		ax = CairoMakie.Axis(
			f[2, 1],
			title="Difference"
		)
		heatmap!(corrected_image[:, :, bfield_slider] - input_image[:, :, bfield_slider])

		ax = CairoMakie.Axis(
			f[2, 2],
			title="B-Field"
		)
		heatmap!(bfield[:, :, bfield_slider])
		f
	end
end

# ╔═╡ 01455019-c0bd-43b4-9157-c757901e18dc
md"""
## Correct 4D Phantom w/ B-field
"""

# ╔═╡ 304923f3-fbe0-4ef6-852b-fab8f49fd43d
phantom_whole = phantom[:, :, good_slices_range, :];

# ╔═╡ 3042e311-40fb-40a0-a4f2-d641dfb07809
begin 
	bfc_phantom = zeros(size(phantom_whole))
	for i in axes(phantom_whole, 4)
		for j in axes(phantom_whole, 3)
			bfc_phantom[:,:,j,i] = phantom_whole[:, :, j, i] ./ exp.(bfield[:, :, j])
		end
	end
end

# ╔═╡ 78b90c9f-4859-4710-8e52-46241c969d36
begin
	bfc_true_path = "https://www.dropbox.com/s/wetphdvwibhrovm/BFC_time_series.nii?dl=0"
	bfc_true_nii = niread(download(bfc_true_path))
end;

# ╔═╡ 0f10f6b7-a97f-4305-b14b-8aafed390d64
md"""
Select Slice (New): $(@bind bfield_slider3 PlutoUI.Slider(axes(bfc_phantom, 3); show_value=true))

Select Slice (Ground Truth): $(@bind bfield_slider4 PlutoUI.Slider(axes(bfc_true_nii, 3); show_value=true))

Select Time Point: $(@bind z3 PlutoUI.Slider(axes(bfc_phantom, 4); show_value=true))
"""

# ╔═╡ b80c17d2-6867-454c-b4cb-b20f7f9d1b3d
let
	if good_slices_files_ready
		f = Figure(resolution=(1000, 1000))
		ax = CairoMakie.Axis(
			f[1, 1],
			title="BFC Phantom"
		)
		heatmap!(bfc_phantom[:, :, bfield_slider3, z3], colormap=:grays)
	
		ax = CairoMakie.Axis(
			f[1, 2],
			title="Ground Truth BFC Phantom"
		)
		heatmap!(bfc_true_nii[:, :, bfield_slider4, z3], colormap=:grays)
		
		f
	end
end

# ╔═╡ 91980ceb-92ce-47f1-999c-25ebe4701ebb
md"""
# Milestone 2
"""

# ╔═╡ e4097235-99d6-4efc-a670-a630938c8731
md"""
## Fit Center & Radius
"""

# ╔═╡ c5b32d5f-773e-44c4-abb4-95ed33d607d5
# Original Centers
ecs = BDTools.centers(sph);

# ╔═╡ efff0880-9ab8-45e6-946f-fbaa1715a174
# Predicted center axis
begin
	rng = collect(-1.:0.15:1.)
	cc = map(t->BDTools.predictcenter(sph, t), rng)
end;

# ╔═╡ 4d5e03fd-eefe-47bc-8007-a3d4b173875e
# Fitted Centers
xy = BDTools.fittedcenters(sph);

# ╔═╡ 16f026d4-4dc7-4bb9-8814-d30933a65b23
let
	f = Figure()
	ax = CairoMakie.Axis(f[1, 1])
	scatter!(ecs[:, 1], ecs[:, 2], label="Centers")
	lines!(map(first, cc), map(last, cc), label="Predicted Axis", color=:orange)
	scatter!(xy[:, 1], xy[:, 2], label="Fitted Centers", color=:green)
	axislegend(ax, position=:lt)
	f
end

# ╔═╡ 1bf8f6e1-a17a-4b9f-a334-7a0d7ce217a6
md"""
## Construct Ground Truth Phantom
Users might need to input `threshold`
"""

# ╔═╡ aef7eda7-e79f-4538-b8b5-79e934fa279b
sz = size(bfc_phantom)

# ╔═╡ ea79465d-fbf3-4779-8bc3-f3414793e45a
# angles, firstrotidx = BDTools.getangles(log_path);

# ╔═╡ d92f6df1-58de-4ab4-ae43-2e19cbca10d3
begin
	pos = df_log[!, :EndPos]
	firstrotidx = findfirst(e -> e > 20, pos)
	angles, firstrotidx = [a > π ? a-2π : a for a in (pos ./ 2^13).*(2π)], firstrotidx
end

# ╔═╡ be222517-d2ff-4131-971e-853144ec22c8
res = BDTools.groundtruth(sph, bfc_phantom, angles; startmotion=firstrotidx, threshold=.95);

# ╔═╡ 367979f1-9303-46a7-a831-3c2fd8452057
data, sliceidx, maskcoords = res.data, res.sliceindex, res.maskindex

# ╔═╡ 6ccc174f-c42e-4347-ae2f-979a57a1af86
md"""
## Fit Centerline of Rotation
"""

# ╔═╡ 986c0d5c-c8ad-4800-8271-99f8e3beaf40
begin
	x = 42
	y = 52
	cidx = res[x, y] # get a masked coordinate index
    cidx === nothing && return
end

# ╔═╡ fc9e2b2a-66e3-4e4a-984c-2cab89147ffe
@bind z PlutoUI.Slider(eachindex(sliceidx); default=3, show_value=true)

# ╔═╡ 2fa99031-29a3-4fd4-9fb4-b2b7b940514a
let
	f = Figure()
	ax = CairoMakie.Axis(f[1, 1])
    lines!(data[:, cidx, z, 2], label="original")
    lines!(data[:, cidx, z, 1], label="prediction")
	axislegend(ax)
	f
end

# ╔═╡ 6bdad393-9a77-4056-bb7d-96a8367224d3
md"""
## Calculate Ground Truth By Rotations & Interpolation
"""

# ╔═╡ 74b70f05-31cf-494f-92f6-bc82dd8b2168
begin
	degrees = 0
	α = deg2rad(degrees)
	γ = BDTools.findinitialrotation(sph, z)
end;

# ╔═╡ e1a3e357-3d3c-4018-8179-9e9ad1d69691
origin, a, b = BDTools.getellipse(sph, z);

# ╔═╡ 38e0ffee-cf4c-460f-92a2-c2d8ea7c4fb4
coords = [BDTools.ellipserot(α, γ, a, b)*([i,j,z].-origin).+origin for i in 1:sz[1], j in 1:sz[2]];

# ╔═╡ ffa76c31-5650-4372-ab2a-bf3d1d58f90a
# interpolate intensities
sim = map(c->sph.interpolation(c...), coords);

# ╔═╡ 718c5bee-3eb9-41e1-9535-53c29bf5662c
# generate image
gen = sim |> BDTools.genimg;

# ╔═╡ 5e2d2964-efc2-4f7c-9fd4-6c1d96dc9b54
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

# ╔═╡ 1a274a20-d067-4682-afb2-5abf5b7626f6
md"""
# Milestone 3
"""

# ╔═╡ 56785b5d-eb3d-4e13-9d9e-fc82ab6e5c54
md"""
## Calulcate Quality Control Measures
"""

# ╔═╡ cb058e2b-f874-4324-a188-292bf303e5b2
md"""
# Milestone 4
"""

# ╔═╡ 1edf262c-2bde-45ff-ba02-c14ab481cfe3
md"""
## Train Neural Network w/ Time Series
"""

# ╔═╡ c2d61056-7ef3-48c8-bc6b-a856ada983e1
md"""
# Milestone 5
"""

# ╔═╡ 7ede7ab7-be1d-4d99-9cc6-6d16c19cf4a6
md"""
## Processed 4D fMRI from Neural Network
"""

# ╔═╡ Cell order:
# ╠═866b498e-52cc-461a-90dc-bfd6d53dd80d
# ╠═90b6279b-7595-43de-b3f7-10ffdbeabf58
# ╠═e7a428ce-0489-43c3-8c5a-bae818f0ca03
# ╟─bbd3d93f-8775-48aa-93e0-5600fd1b5355
# ╟─dc6717ba-25fb-4f7d-933a-18dc69fea34d
# ╟─d90a11ce-52fd-48e4-9cb1-755bc2b29e51
# ╟─d2e0accd-2395-4115-8842-e9176a0a132e
# ╠═19b12720-4bd9-4790-84d0-9cf660d8ed70
# ╠═b0e58a0a-c6a7-4e4d-8a14-efbfbf7251e9
# ╠═3dcddb92-6277-46d2-9e34-3863f0a60731
# ╟─7f2148e2-8649-4fb6-a50b-3dc54bca7505
# ╟─6a8117e0-e450-46d7-897f-0503d71f06af
# ╟─8eb754de-37b7-45fb-a7fc-c14c11e0216f
# ╠═7eacbaef-eae0-426a-be36-9c00a3b09d1b
# ╟─49557d91-e4de-486b-99ed-3d564c7b7960
# ╟─04c7cf73-fa75-45e1-aafe-4ca658706289
# ╠═4a485292-f875-44c4-b940-8f2714f6d26f
# ╠═f11be125-facc-44ff-8d00-8cd748d6d110
# ╟─877c4ec3-5c00-496a-b4e0-d09fc46fd207
# ╟─8724296c-6118-4c0f-bea4-3173222a40cf
# ╟─1d1fa36d-774b-43a8-9e4e-acc013ae8efe
# ╟─32292190-1124-4087-b728-8f998e3c3814
# ╠═15681a0d-a217-42af-be91-6edeff37dfaa
# ╠═886c9748-b423-4d68-acb4-2b32c65ebc1d
# ╠═de4e1b7c-2a70-499d-a375-87c8aaca0ad3
# ╟─d0c6dc6d-b85f-4f76-a478-02fcd9484344
# ╠═d75e495c-bf4e-4608-bd7f-357d3fe1023b
# ╠═db78c6f2-5afe-4d12-b39f-f6b4286f2d17
# ╟─35e1fcca-f1e0-4b33-82c7-e0c1325464d0
# ╟─fc87815b-54d1-4f69-ac8d-b0fbeab7f53d
# ╟─f57cb424-9dd2-4432-8485-034ded569f13
# ╟─e570adef-e2d1-4080-86e8-4ac57ad8a6f0
# ╠═4de55168-94c0-400e-a072-feb34a07fe2b
# ╠═a649bf25-f3e4-44b4-bb3e-266a456f2f21
# ╟─5e364415-8ab9-4f8d-a775-03d45748b249
# ╟─056f3868-9a21-4c68-9f51-a9ed2d662e46
# ╠═13b34063-4fea-4044-9648-7d72fd90ed2d
# ╟─e512474b-a648-416a-a52f-19b0e52fbd17
# ╠═cb3c7d65-dcdf-48c9-a1fa-56ba71b327e5
# ╠═4168038a-7257-4082-8243-525175d12be0
# ╠═51a6b51f-55fd-442c-a6a0-5d9be970d300
# ╟─692360cc-dcb0-456a-8234-f747ce371b1b
# ╟─659ec1a1-356c-4742-bd63-0ebaa3df5b96
# ╠═79bfc734-f19d-4d5b-a585-ef02bf2b0144
# ╠═bafa6302-6dbc-4b46-afc2-a414079a0472
# ╟─d21b03e8-ff8f-4875-b9bd-009eb34e11ad
# ╟─87f3ccf9-4ee4-466e-a15c-f5000d6a3eca
# ╟─01455019-c0bd-43b4-9157-c757901e18dc
# ╠═304923f3-fbe0-4ef6-852b-fab8f49fd43d
# ╠═3042e311-40fb-40a0-a4f2-d641dfb07809
# ╠═78b90c9f-4859-4710-8e52-46241c969d36
# ╟─0f10f6b7-a97f-4305-b14b-8aafed390d64
# ╟─b80c17d2-6867-454c-b4cb-b20f7f9d1b3d
# ╟─91980ceb-92ce-47f1-999c-25ebe4701ebb
# ╟─e4097235-99d6-4efc-a670-a630938c8731
# ╠═c5b32d5f-773e-44c4-abb4-95ed33d607d5
# ╠═efff0880-9ab8-45e6-946f-fbaa1715a174
# ╠═4d5e03fd-eefe-47bc-8007-a3d4b173875e
# ╟─16f026d4-4dc7-4bb9-8814-d30933a65b23
# ╟─1bf8f6e1-a17a-4b9f-a334-7a0d7ce217a6
# ╠═aef7eda7-e79f-4538-b8b5-79e934fa279b
# ╠═ea79465d-fbf3-4779-8bc3-f3414793e45a
# ╠═d92f6df1-58de-4ab4-ae43-2e19cbca10d3
# ╠═be222517-d2ff-4131-971e-853144ec22c8
# ╠═367979f1-9303-46a7-a831-3c2fd8452057
# ╟─6ccc174f-c42e-4347-ae2f-979a57a1af86
# ╠═986c0d5c-c8ad-4800-8271-99f8e3beaf40
# ╟─fc9e2b2a-66e3-4e4a-984c-2cab89147ffe
# ╟─2fa99031-29a3-4fd4-9fb4-b2b7b940514a
# ╟─6bdad393-9a77-4056-bb7d-96a8367224d3
# ╠═74b70f05-31cf-494f-92f6-bc82dd8b2168
# ╠═e1a3e357-3d3c-4018-8179-9e9ad1d69691
# ╠═38e0ffee-cf4c-460f-92a2-c2d8ea7c4fb4
# ╠═ffa76c31-5650-4372-ab2a-bf3d1d58f90a
# ╠═718c5bee-3eb9-41e1-9535-53c29bf5662c
# ╠═5e2d2964-efc2-4f7c-9fd4-6c1d96dc9b54
# ╟─1a274a20-d067-4682-afb2-5abf5b7626f6
# ╟─56785b5d-eb3d-4e13-9d9e-fc82ab6e5c54
# ╟─cb058e2b-f874-4324-a188-292bf303e5b2
# ╟─1edf262c-2bde-45ff-ba02-c14ab481cfe3
# ╟─c2d61056-7ef3-48c8-bc6b-a856ada983e1
# ╟─7ede7ab7-be1d-4d99-9cc6-6d16c19cf4a6
