### A Pluto.jl notebook ###
# v0.19.26

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
	Pkg.add("CairoMakie")
	Pkg.add("NIfTI")
	Pkg.add("PlutoUI")
	Pkg.add("CSV")
	Pkg.add("DataFrames")
	Pkg.add("Statistics")
	Pkg.add(url="https://github.com/hstrey/BDTools.jl")

	using CairoMakie
	using PlutoUI
	using NIfTI
	using CSV
	using DataFrames
	using Statistics
	using BDTools
end

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
begin
	if contains(log_file, "http")
		global df_log = CSV.read(download(log_file), DataFrame)
	else
		global df_log = CSV.read(log_file, DataFrame; header=3)

	end

	if contains(acq_file, "http")
		global df_acq = CSV.read(download(acq_file), DataFrame)
	else
		global df_acq = CSV.read(acq_file, DataFrame)

	end
	
	if contains(nifti_file, "http")
		global phantom = niread(download(nifti_file))
	else
		global phantom = niread(nifti_file)

	end
end;

# ╔═╡ b0e58a0a-c6a7-4e4d-8a14-efbfbf7251e9
phantom_header = phantom.header;

# ╔═╡ 3dcddb92-6277-46d2-9e34-3863f0a60731
vsize = voxel_size(phantom.header); # mm

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

# ╔═╡ 49557d91-e4de-486b-99ed-3d564c7b7960
@bind good_slices_slider PlutoUI.Slider(axes(phantom, 3); default=div(size(phantom, 3), 2), show_value=true)

# ╔═╡ 04c7cf73-fa75-45e1-aafe-4ca658706289
heatmap(phantom.raw[:, :, good_slices_slider, 1], colormap=:grays)

# ╔═╡ 4a485292-f875-44c4-b940-8f2714f6d26f
good_slices_range = parse(Int, first(g_slices)):parse(Int, last(g_slices));

# ╔═╡ f11be125-facc-44ff-8d00-8cd748d6d110
good_slices = collect(parse(Int, g_slices[1]):parse(Int, g_slices[2]));

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
phantom_ok = Float64.(convert(Array, phantom[:, :, good_slices_range, static_range]));

# ╔═╡ d0c6dc6d-b85f-4f76-a478-02fcd9484344
md"""
## Calculate Average Static Phantom
"""

# ╔═╡ d5faa518-5dc6-4662-990d-84b21eccfdee
avg_static_phantom = Float32.(mean(phantom_ok[:, :, :, static_range], dims=4)[:, :, :]);

# ╔═╡ db78c6f2-5afe-4d12-b39f-f6b4286f2d17
phantom_header.dim = (length(size(avg_static_phantom)), size(avg_static_phantom)..., 1, 1, 1, 1)

# ╔═╡ 35e1fcca-f1e0-4b33-82c7-e0c1325464d0
@bind c_slider PlutoUI.Slider(axes(avg_static_phantom, 3) ; default=div(size(avg_static_phantom, 3), 2), show_value=true)

# ╔═╡ fc87815b-54d1-4f69-ac8d-b0fbeab7f53d
@bind d_slider PlutoUI.Slider(axes(phantom, 4), ; default=div(size(phantom, 4), 2), show_value=true)

# ╔═╡ f57cb424-9dd2-4432-8485-034ded569f13
ave = BDTools.genimg(avg_static_phantom[:, :, c_slider]);

# ╔═╡ a649bf25-f3e4-44b4-bb3e-266a456f2f21
begin
	tempdir = mktempdir()
	
	avg_static_phantom_path = joinpath(tempdir, "image.nii")
	niwrite(avg_static_phantom_path, NIVolume(phantom_header, avg_static_phantom))
end;

# ╔═╡ 5e364415-8ab9-4f8d-a775-03d45748b249
md"""
## Create Mask for B-field Correction
"""

# ╔═╡ 056f3868-9a21-4c68-9f51-a9ed2d662e46
@bind c_slider2 PlutoUI.Slider(axes(avg_static_phantom, 3); show_value=true)

# ╔═╡ 13b34063-4fea-4044-9648-7d72fd90ed2d
msk = BDTools.segment3(avg_static_phantom[:, :, c_slider2]);

# ╔═╡ e512474b-a648-416a-a52f-19b0e52fbd17
let
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
	heatmap!(avg_static_phantom[:, :, c_slider2], colormap=:grays)
	scatter!(xys1[:, 1], xys1[:, 2], color=:red)
	scatter!(xys2[:, 1], xys2[:, 2], color=:blue)
	f
end

# ╔═╡ cb3c7d65-dcdf-48c9-a1fa-56ba71b327e5
begin
	segs = BDTools.segment3.(eachslice(avg_static_phantom, dims=3))
    mask_binary = cat(BDTools.labels_map.(segs)..., dims=3) .!= 1
	mask_float = Float32.(mask_binary)
end;

# ╔═╡ 51a6b51f-55fd-442c-a6a0-5d9be970d300
begin
	mask_path = joinpath(tempdir, "mask.nii")
	niwrite(mask_path, NIVolume(phantom_header, mask_float))
end;

# ╔═╡ 692360cc-dcb0-456a-8234-f747ce371b1b
heatmap(mask_float[:, :, 5], colormap=:grays)

# ╔═╡ 659ec1a1-356c-4742-bd63-0ebaa3df5b96
md"""
## Run B-field Correction on Static Image
"""

# ╔═╡ bafa6302-6dbc-4b46-afc2-a414079a0472
input_image, mask, bfield, corrected_image = BDTools.bfield_correction(avg_static_phantom_path, mask_path);

# ╔═╡ d21b03e8-ff8f-4875-b9bd-009eb34e11ad
md"""
Select Slice: $(@bind bfield_slider PlutoUI.Slider(axes(bfield, 3); show_value=true))


Set color range: 
  - Low: $(@bind colorrange_low PlutoUI.Slider(Int.(round(minimum(corrected_image))):Int.(round(maximum(corrected_image)))))
  - High: $(@bind colorrange_high PlutoUI.Slider(Int.(round(minimum(corrected_image))):Int.(round(maximum(corrected_image))); default=Int.(round(maximum(corrected_image)))))
"""

# ╔═╡ 87f3ccf9-4ee4-466e-a15c-f5000d6a3eca
let
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

# ╔═╡ 0f10f6b7-a97f-4305-b14b-8aafed390d64
md"""
Select Slice: $(@bind bfield_slider3 PlutoUI.Slider(axes(bfc_phantom, 3); show_value=true))

Select Time Point: $(@bind z3 PlutoUI.Slider(axes(bfc_phantom, 4); show_value=true))
"""

# ╔═╡ b80c17d2-6867-454c-b4cb-b20f7f9d1b3d
let
	f = Figure(resolution=(1000, 1000))
	ax = CairoMakie.Axis(
		f[1, 1],
		title="BFC Phantom"
	)
	heatmap!(bfc_phantom[:, :, bfield_slider3, z3], colormap=:grays)
	
	f
end

# ╔═╡ da492d58-6fa3-42c6-9d46-07eddcba5466
md"""
Save File to Path: $(@bind output_dir confirm(TextField()))
"""

# ╔═╡ 6fb79bd9-da41-4bf8-92f4-12e10a4d9867
if output_dir != ""
	niwrite(joinpath(output_dir, "bfc_phantom.nii"), NIVolume(phantom_header, bfc_phantom))
end

# ╔═╡ 91980ceb-92ce-47f1-999c-25ebe4701ebb
md"""
# Milestone 2
"""

# ╔═╡ bc5bca47-e67d-4e4d-aa95-176ca92cbdf3
md"""
## Choose Motion Start Time
"""

# ╔═╡ c770e399-f374-4af9-8ea2-2d9b301d9947
md"""
Typically, motion starts at `Seq#` 201 but choose the time by visually verifying the `Seq#` below:

Motion Start Sequence: $(@bind motion_start PlutoUI.Slider(df_log[!, "Seq#"]; show_value = true, default = 201))
"""

# ╔═╡ 7b4bf6a7-5424-4a13-b4a6-f838b3b73add
df_log[200:210, :]

# ╔═╡ e4097235-99d6-4efc-a670-a630938c8731
md"""
## Fit Center & Radius of Inner Cylinder for Each Slice
"""

# ╔═╡ 8c38dc26-24d1-47a9-9c51-3abf9850fe27
md"""
Beginning Corrected Slice: $(@bind rot_slices1 PlutoUI.Slider(axes(avg_static_phantom, 3); show_value = true, default = first(axes(avg_static_phantom, 3))))

End Corrected Slice: $(@bind rot_slices2 PlutoUI.Slider(axes(avg_static_phantom, 3); show_value = true, default = last(axes(avg_static_phantom, 3))))
"""

# ╔═╡ e3134051-6309-4fbd-9ca5-2c610346d438
begin
	# Get a list of all column names
	colnames = names(df_log)
	
	# Find the index of the first column whose name contains "Tmot"
	tmot_col_index = findfirst(name -> occursin("tmot", lowercase.(name)), colnames)

	max_motion = findmax(df_log[!, tmot_col_index])[1]
	max_motion2 = df_log[findall(x -> x == motion_start, df_log[!, "Seq#"]), tmot_col_index]
	slices_without_motion = df_acq[!,"Slice"][df_acq[!,"Time"] .> max_motion2]
	slices_ok = sort(
		slices_without_motion[parse(Int, first(g_slices))-1 .<= slices_without_motion .<= parse(Int, last(g_slices))+1]
	)
	slices_wm = [x in slices_ok ? 1 : 0 for x in good_slices]
	slices_df = DataFrame(Dict(:slice => good_slices, :no_motion => slices_wm))

	new_slices_df = slices_df[rot_slices1:rot_slices2, :]
	bfc_phantom2 = bfc_phantom[:, :, rot_slices1:rot_slices2, :]
	sph = staticphantom(bfc_phantom2, Matrix(new_slices_df))
end

# ╔═╡ e570adef-e2d1-4080-86e8-4ac57ad8a6f0
let
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

# ╔═╡ 6bdad393-9a77-4056-bb7d-96a8367224d3
md"""
## Construct Ground Truth Dataset
"""

# ╔═╡ aef7eda7-e79f-4538-b8b5-79e934fa279b
sz = size(bfc_phantom2)

# ╔═╡ 400020e5-ab6c-492b-8534-51adf73784bb
md"""
Select Angle of Rotation: $(@bind degrees PlutoUI.Slider(1:360, show_value = true, default = 20))


Select Slice: $(@bind z2 PlutoUI.Slider(axes(sph.data, 3); default=3, show_value=true))
"""

# ╔═╡ 74b70f05-31cf-494f-92f6-bc82dd8b2168
begin
	α = deg2rad(degrees)
	γ = BDTools.findinitialrotation(sph, z2)
end;

# ╔═╡ e1a3e357-3d3c-4018-8179-9e9ad1d69691
origin, a, b = BDTools.getellipse(sph, z2);

# ╔═╡ 38e0ffee-cf4c-460f-92a2-c2d8ea7c4fb4
coords = [BDTools.ellipserot(α, γ, a, b)*([i,j,z2].-origin).+origin for i in 1:sz[1], j in 1:sz[2]];

# ╔═╡ ffa76c31-5650-4372-ab2a-bf3d1d58f90a
# interpolate intensities
sim = map(c -> sph.interpolation(c...), coords);

# ╔═╡ 718c5bee-3eb9-41e1-9535-53c29bf5662c
# generate image
gen = sim |> BDTools.genimg;

# ╔═╡ 2c9d1563-2261-42a0-b682-66b9cc1b9431
ave2 = BDTools.genimg(sph.data[:, :, z2]);

# ╔═╡ 5e2d2964-efc2-4f7c-9fd4-6c1d96dc9b54
let
	f = Figure(resolution=(1000, 700))
	ax = CairoMakie.Axis(
		f[1, 1],
		title="Average Static Image @ Slice $(z2)"
	)
	heatmap!(ave2, colormap=:grays)

	ax = CairoMakie.Axis(
		f[1, 2],
		title="Generated Image @ Slice $(z2) & Rotated $(degrees) Degrees"
	)
	heatmap!(gen[:, :], colormap=:grays)
	f
end

# ╔═╡ 1bf8f6e1-a17a-4b9f-a334-7a0d7ce217a6
md"""
## Generate Rotated Predictions
"""

# ╔═╡ d92f6df1-58de-4ab4-ae43-2e19cbca10d3
begin
	# Find the index of the first column whose name contains "EndPos" or "CurPos"
	pos_col_indices = first([index for (index, name) in enumerate(colnames) if occursin("endpos", lowercase.(name)) || occursin("curpos", lowercase.(name))])
	
	quant = 2^13
	pos = df_log[!, pos_col_indices]
	firstrotidx = motion_start
	angles = [a > π ? a-2π : a for a in (pos ./ quant).*(2π)]
end

# ╔═╡ 29a143eb-b77b-40b7-ab7b-b219381420f2
gt = BDTools.groundtruth(sph, bfc_phantom2, angles; startmotion=firstrotidx, threshold=.95);

# ╔═╡ e6c2da4c-7f27-441f-b6da-688034824591


# ╔═╡ f7e9166a-340f-4950-b5b0-51f2313b3e8b
md"""
Choose Centerpoint Slice: $(@bind z4 PlutoUI.Slider(axes(gt.data, 3); default=3, show_value=true))
"""

# ╔═╡ 849d31df-d064-4126-85c4-52cb65781c90
let 
	x = Int(round(xy[z4, 1])) + 1
	y = Int(round(xy[z4, 2])) + 1
	z = z4 # get coordinates
    cidx = gt[x, y] # get a masked coordinate index
    cidx === nothing && return

    # plot data
	f = Figure()
	ax = CairoMakie.Axis(f[1, 1])
    lines!(gt[x, y, z], label="prediction", title="Intensity (x=$x, y=$y, z=$z)")
    lines!(gt[x, y, z, true], label="original")
	axislegend(ax, position=:lt)
	f
end

# ╔═╡ 1a274a20-d067-4682-afb2-5abf5b7626f6
md"""
# Milestone 3
"""

# ╔═╡ 56785b5d-eb3d-4e13-9d9e-fc82ab6e5c54
md"""
## Calculate Quality Control Measures
"""

# ╔═╡ dda13b35-f33a-410a-9ff6-8431aafc9cc8
md"""
### 1. ST-SNR
"""

# ╔═╡ 18512280-3716-47f3-94ee-e74e0ce28805
begin
	parseval_gt = sum(gt.data .^ 2)
	parseval_bfc = sum(bfc_phantom2[:, :, :, 1] .^ 2)
	parseval_gt / parseval_bfc
end

# ╔═╡ e6b187ad-4e1d-465e-b5fe-a0c182dd11e7
md"""
### 2. Dynamic Fidelity
"""

# ╔═╡ 8ae2a9d6-536b-426f-9a3f-54b2270b15aa
# cor(vec(gt.data), vec(bfc_phantom2[:, :, :, 1]))

# ╔═╡ 68bbfbf5-85ee-4d02-b20a-a3339467f266
gt

# ╔═╡ 60aa5791-f1a9-4ccf-841f-0a60c091b4a9
size(bfc_phantom2)

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
# ╟─d0c6dc6d-b85f-4f76-a478-02fcd9484344
# ╠═d5faa518-5dc6-4662-990d-84b21eccfdee
# ╠═db78c6f2-5afe-4d12-b39f-f6b4286f2d17
# ╟─35e1fcca-f1e0-4b33-82c7-e0c1325464d0
# ╟─fc87815b-54d1-4f69-ac8d-b0fbeab7f53d
# ╠═f57cb424-9dd2-4432-8485-034ded569f13
# ╟─e570adef-e2d1-4080-86e8-4ac57ad8a6f0
# ╠═a649bf25-f3e4-44b4-bb3e-266a456f2f21
# ╟─5e364415-8ab9-4f8d-a775-03d45748b249
# ╟─056f3868-9a21-4c68-9f51-a9ed2d662e46
# ╠═13b34063-4fea-4044-9648-7d72fd90ed2d
# ╠═e512474b-a648-416a-a52f-19b0e52fbd17
# ╠═cb3c7d65-dcdf-48c9-a1fa-56ba71b327e5
# ╠═51a6b51f-55fd-442c-a6a0-5d9be970d300
# ╟─692360cc-dcb0-456a-8234-f747ce371b1b
# ╟─659ec1a1-356c-4742-bd63-0ebaa3df5b96
# ╠═bafa6302-6dbc-4b46-afc2-a414079a0472
# ╟─d21b03e8-ff8f-4875-b9bd-009eb34e11ad
# ╟─87f3ccf9-4ee4-466e-a15c-f5000d6a3eca
# ╟─01455019-c0bd-43b4-9157-c757901e18dc
# ╠═304923f3-fbe0-4ef6-852b-fab8f49fd43d
# ╠═3042e311-40fb-40a0-a4f2-d641dfb07809
# ╟─0f10f6b7-a97f-4305-b14b-8aafed390d64
# ╟─b80c17d2-6867-454c-b4cb-b20f7f9d1b3d
# ╟─da492d58-6fa3-42c6-9d46-07eddcba5466
# ╠═6fb79bd9-da41-4bf8-92f4-12e10a4d9867
# ╟─91980ceb-92ce-47f1-999c-25ebe4701ebb
# ╟─bc5bca47-e67d-4e4d-aa95-176ca92cbdf3
# ╟─c770e399-f374-4af9-8ea2-2d9b301d9947
# ╟─7b4bf6a7-5424-4a13-b4a6-f838b3b73add
# ╟─e4097235-99d6-4efc-a670-a630938c8731
# ╠═e3134051-6309-4fbd-9ca5-2c610346d438
# ╠═c5b32d5f-773e-44c4-abb4-95ed33d607d5
# ╠═efff0880-9ab8-45e6-946f-fbaa1715a174
# ╠═4d5e03fd-eefe-47bc-8007-a3d4b173875e
# ╟─8c38dc26-24d1-47a9-9c51-3abf9850fe27
# ╟─16f026d4-4dc7-4bb9-8814-d30933a65b23
# ╟─6bdad393-9a77-4056-bb7d-96a8367224d3
# ╠═aef7eda7-e79f-4538-b8b5-79e934fa279b
# ╠═74b70f05-31cf-494f-92f6-bc82dd8b2168
# ╠═e1a3e357-3d3c-4018-8179-9e9ad1d69691
# ╠═38e0ffee-cf4c-460f-92a2-c2d8ea7c4fb4
# ╠═ffa76c31-5650-4372-ab2a-bf3d1d58f90a
# ╠═718c5bee-3eb9-41e1-9535-53c29bf5662c
# ╠═2c9d1563-2261-42a0-b682-66b9cc1b9431
# ╟─400020e5-ab6c-492b-8534-51adf73784bb
# ╟─5e2d2964-efc2-4f7c-9fd4-6c1d96dc9b54
# ╟─1bf8f6e1-a17a-4b9f-a334-7a0d7ce217a6
# ╠═d92f6df1-58de-4ab4-ae43-2e19cbca10d3
# ╠═29a143eb-b77b-40b7-ab7b-b219381420f2
# ╠═e6c2da4c-7f27-441f-b6da-688034824591
# ╟─f7e9166a-340f-4950-b5b0-51f2313b3e8b
# ╟─849d31df-d064-4126-85c4-52cb65781c90
# ╟─1a274a20-d067-4682-afb2-5abf5b7626f6
# ╟─56785b5d-eb3d-4e13-9d9e-fc82ab6e5c54
# ╟─dda13b35-f33a-410a-9ff6-8431aafc9cc8
# ╠═18512280-3716-47f3-94ee-e74e0ce28805
# ╟─e6b187ad-4e1d-465e-b5fe-a0c182dd11e7
# ╠═8ae2a9d6-536b-426f-9a3f-54b2270b15aa
# ╠═68bbfbf5-85ee-4d02-b20a-a3339467f266
# ╠═60aa5791-f1a9-4ccf-841f-0a60c091b4a9
# ╟─cb058e2b-f874-4324-a188-292bf303e5b2
# ╟─1edf262c-2bde-45ff-ba02-c14ab481cfe3
# ╟─c2d61056-7ef3-48c8-bc6b-a856ada983e1
# ╟─7ede7ab7-be1d-4d99-9cc6-6d16c19cf4a6
