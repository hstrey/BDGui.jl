### A Pluto.jl notebook ###
# v0.19.26

#> [frontmatter]
#> title = "Phantom Preparation & Analysis"
#> category = "Tutorials"

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

# ╔═╡ 63d91761-537a-4324-8df8-0a35bcdc1807
# ╠═╡ show_logs = false
begin
	using Pkg
	Pkg.activate("..")
	Pkg.instantiate()

	using CairoMakie
	using PlutoUI
	using NIfTI
	using CSV
	using DataFrames
	using Statistics
	using StatsBase
	using BDTools
end

# ╔═╡ 543b5c8f-70f3-430c-8165-327f31132d6d
html"""
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Alegreya+Sans:ital,wght@0,400;0,700;1,400&family=Vollkorn:ital,wght@0,400;0,700;1,400;1,700&display=swap" rel="stylesheet">

<style>
body {
    background-color: transparent;
}

.header {
  font-family: 'Alegreya Sans', sans-serif;
  text-align: center;
  background-color: #ADD8E6; /* Light blue */
  color: #000;
  padding: 1em;
  border-radius: 10px;
}

.header h1 {
  font-size: 2.5em;
  font-family: 'Vollkorn', serif;
}

.header p {
  font-size: 1.2em;
}

.header img {
  max-width: 150px;
  margin-top: 10px;
  margin-bottom: 10px;
  border-radius: 3%;
}

@media (prefers-color-scheme: dark) {
  body {
    background-color: #1f1f1f; /* Dark background color */
  }
}

</style>

<div class="header">
  <img src="https://alascience.com/wp-content/uploads/2020/07/Logo-registered-trademark.jpg" alt="Brain Dancer Logo">
  <h1>Brain Dancer</h1>
  <p>Data analysis notebook for the BrainDancer Dynamic Phantom.</p>
</div>
"""

# ╔═╡ 773155ed-38c9-4aac-b400-f67a814e1f5a
md"""
# Load packages and files
"""

# ╔═╡ 06d87105-c48b-41ce-bd3c-14bd0363c2ac
md"""
## Import Packages
"""

# ╔═╡ 723e4ea5-0328-4816-85ec-ae50f986f2be
TableOfContents()

# ╔═╡ 233b8f26-0830-462d-87d7-a241ed4c0a09
md"""
## Load Phantom, Logs, & Acquisition Times
"""

# ╔═╡ a043515a-4d56-42df-974e-537aefcd9d92
function upload_files(logs, acqs, phtm)
	
	return PlutoUI.combine() do Child
		
		inputs = [
			md""" $(logs): $(
				Child(TextField(60; default = "https://www.dropbox.com/scl/fi/nlxodr5zzub0k0oc9y1vv/log104.csv?rlkey=b0hhybbodytvkfulc0wrfhpfv&dl=0"))
			)""",
			md""" $(acqs): $(
				Child(TextField(60; default = "https://www.dropbox.com/scl/fi/oy49k8gi9hq2gf3pxzxdn/acq_times_104.csv?rlkey=oxu1n5uv2bqnlhmfx1f0tfqy2&dl=0"))
			)""",
			md""" $(phtm): $(
				Child(TextField(60; default = "https://www.dropbox.com/s/hikpi7t89mwbb4w/104.nii?dl=0"))
			)"""
		]
		
		md"""
		#### Upload Files
		Provide URLs or file paths to the necessary files. If running locally, file paths are expected. If running on the web, provide URL links. We recommend DropBox, as Google Drive will likely not work.
		
		Ensure log and acquisition files are in `.csv` format & phantom file is in `.nii` or `.nii.gz` format. Then click submit
		$(inputs)
		"""
	end
end

# ╔═╡ c818025f-8da3-4762-b8fa-3580431d750f
@bind up_files confirm(upload_files("Upload Log File", "Upload Acquisition Times", "Upload Phantom Scan"))

# ╔═╡ 510a24fb-bd5e-457d-928a-3c853688890f
log_file, acq_file, nifti_file = up_files;

# ╔═╡ b79276ee-319d-4e1c-be3c-65bc01f168f0
uploaded = log_file != "" && acq_file != "" && nifti_file != "";

# ╔═╡ 50225cf7-ec2c-4538-95be-8e32ff9405c5
function load_logs(log_file)
	if contains(log_file, "http")
		df_log = CSV.read(download(log_file), DataFrame; silencewarnings = true)
		cols = names(df_log)
		if !any(contains.(lowercase.(cols), "tmot"))
			df_log = CSV.read(download(log_file), DataFrame; header=3, silencewarnings = true)
		end
	else
		df_log = CSV.read(log_file, DataFrame; silencewarnings = true)
		cols = names(df_log)
		if !any(contains.(lowercase.(cols), "tmot"))
			df_log = CSV.read(log_file, DataFrame; header=3, silencewarnings = true)
		end
	end
	return df_log
end

# ╔═╡ 0f20df87-6727-497c-a245-8f8e3d6770f1
function load_acqs(acq_file)
	if contains(acq_file, "http")
		df_acq = CSV.read(download(acq_file), DataFrame)
	else
		df_acq = CSV.read(acq_file, DataFrame)
	end
	return df_acq
end

# ╔═╡ a80a7b2e-3406-40f8-85b2-a15f7883476b
function load_phantom(nifti_file)
	if contains(nifti_file, "http")
		phantom = niread(download(nifti_file))
	else
		phantom = niread(nifti_file)
	end
	return phantom
end

# ╔═╡ 20e44e50-13e1-4014-86cb-25cce1a8d735
if uploaded
	df_log = load_logs(log_file)
	df_acq = load_acqs(acq_file)
	phantom = load_phantom(nifti_file)

	time_points = size(phantom, 4)
	sequences = length(df_log[!, "Seq#"])

	if time_points < sequences
		df_log = df_log[1:time_points, :]
	elseif time_points > sequences
		header = phantom.header
		header.dim = (header.dim[1:4]..., sequences, header.dim[6:end]...)
		_phantom = phantom[:, :, :, 1:sequences]
		phantom = NIVolume(phantom.header, _phantom)
	end
	phantom_header = phantom.header
	vsize = voxel_size(phantom.header) # mm
end;

# ╔═╡ 74ffb64c-97e0-4e09-ad90-58619ec3cee8
md"""
# Phantom B-field Correction
"""

# ╔═╡ ca6f0305-abc7-4fe4-adee-4982a960d878
md"""
## Identify Good Slices
"""

# ╔═╡ ba39efcb-4295-4222-92f5-809e0337643d
if uploaded
	@bind good_slices_slider PlutoUI.Slider(axes(phantom, 3); default=div(size(phantom, 3), 2), show_value=true)
end

# ╔═╡ af055420-a355-40a1-aa37-fccf1f350c0a
if uploaded
	heatmap(phantom.raw[:, :, good_slices_slider, 1], colormap=:grays)
end

# ╔═╡ 2d4bfb9e-6fba-4019-b27a-dcc3e3182e69
if uploaded
	@bind b_slider PlutoUI.Slider(axes(phantom, 4); default=div(size(phantom, 4), 2), show_value=true)
end

# ╔═╡ 297aa7da-0896-40e5-ace9-a6895ecebda9
if uploaded
	heatmap(phantom[:, :, div(size(phantom, 3), 2), b_slider], colormap=:grays)
end

# ╔═╡ 1337fe2d-8969-4602-a94b-fbc071b4d3b9
function good_slice_info(good_slices_first, good_slices_last)
	
	return PlutoUI.combine() do Child
		
		inputs = [
			md""" $(good_slices_first): $(
				Child(TextField(; default = "32"))
			)""",
			md""" $(good_slices_last): $(
				Child(TextField(; default = "42"))
			)"""
		]
		
		md"""
		#### Good Slices
		Select the range of good slices between by scrolling through the slider and note when the first good slice starts and when the last good slice ends
		$(inputs)
		"""
	end
end

# ╔═╡ 4946e638-4c27-40af-90f8-79ffb611efce
@bind g_slices confirm(good_slice_info("First good slice: ", "Last good slice: "))

# ╔═╡ c4528c0a-040f-4d34-afce-0cd83faa9cf6
slices = g_slices[1] != "" && g_slices[2] != "";

# ╔═╡ 55d21ac9-3fd8-43ed-a7e8-b914e7b1a309
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

# ╔═╡ 3edba034-3185-4797-9a08-997430a1e7d5
@bind static_ranges confirm(static_slice_info("Starting static slice: ", "Ending static slice: "))

# ╔═╡ ba278bba-ca56-4206-8674-15b09cb505ed
if slices
	good_slices_range = parse(Int, first(g_slices)):parse(Int, last(g_slices))
	good_slices = collect(parse(Int, g_slices[1]):parse(Int, g_slices[2]))

	num_static_range_low = parse(Int, static_ranges[1])
	num_static_range_high = parse(Int, static_ranges[2])
	static_range = num_static_range_low:num_static_range_high

	phantom_ok = Float64.(convert(Array, phantom[:, :, good_slices_range, static_range]))
end;

# ╔═╡ cfd65480-cf34-40e3-bd93-c6aa863602e6
md"""
## Visualize B-field Correction on 3D Static Phantom
"""

# ╔═╡ d2025ebd-7441-42dd-9fda-874f9e4db9e7
# Calculate Average Static Phantom
if slices
	avg_static_phantom = Float32.(mean(phantom_ok[:, :, :, static_range], dims=4)[:, :, :])
	phantom_header.dim = (length(size(avg_static_phantom)), size(avg_static_phantom)..., 1, 1, 1, 1)
	tempdir = mktempdir()
	
	avg_static_phantom_path = joinpath(tempdir, "image.nii")
	write(avg_static_phantom_path, NIVolume(phantom_header, avg_static_phantom))
end;

# ╔═╡ 3c181b45-708f-4bb8-8ebf-ff1795a34fc9
# Create Mask for B-field Correction
if slices
	segs = BDTools.segment3.(eachslice(avg_static_phantom, dims=3))
    mask_binary = cat(BDTools.labels_map.(segs)..., dims=3) .!= 1
	mask_float = Float32.(mask_binary)

	mask_path = joinpath(tempdir, "mask.nii")
	niwrite(mask_path, NIVolume(phantom_header, mask_float))
end;

# ╔═╡ 6d683aec-0065-4b09-80f2-3154185a6b36
# Run B-field Correction on Static Image
if slices
	input_image, mask, bfield, corrected_image = BDTools.bfield_correction(avg_static_phantom_path, mask_path)
end;

# ╔═╡ 05e8f53f-9221-4021-ab83-88e3e7e4645a
if slices
md"""
Select Slice: $(@bind bfield_slider PlutoUI.Slider(axes(bfield, 3); show_value=true))


Set color range: 
  - Low: $(@bind colorrange_low PlutoUI.Slider(Int.(round(minimum(corrected_image))):Int.(round(maximum(corrected_image)))))
  - High: $(@bind colorrange_high PlutoUI.Slider(Int.(round(minimum(corrected_image))):Int.(round(maximum(corrected_image))); default=Int.(round(maximum(corrected_image)))))
"""
end

# ╔═╡ 58320a5e-5b63-440a-ab01-295823ffe909
let
	if slices
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

# ╔═╡ 3a02d92d-c130-48f4-8b85-e4b88ad3cc3a
# Correct 4D Phantom w/ B-field
if slices
	phantom_whole = phantom[:, :, good_slices_range, :]
	
	bfc_phantom = zeros(size(phantom_whole))
	for i in axes(phantom_whole, 4)
		for j in axes(phantom_whole, 3)
			bfc_phantom[:,:,j,i] = phantom_whole[:, :, j, i] ./ exp.(bfield[:, :, j])
		end
	end
end

# ╔═╡ 5d65cd2b-9b89-4600-a95e-f88bb773eeb3
md"""
## Visualize B-field Corrected 4D Phantom
"""

# ╔═╡ 5cba808f-0359-404a-832b-7e93372c54b1
if slices
md"""
Select Slice: $(@bind bfield_slider3 PlutoUI.Slider(axes(bfc_phantom, 3); show_value=true))

Select Time Point: $(@bind z3 PlutoUI.Slider(axes(bfc_phantom, 4); show_value=true))
"""
end

# ╔═╡ 9d8f4f33-daeb-4da9-9432-db4c7b5185a9
if slices
md"""
If b-field correction looks accurate, check the box:
$(@bind bfc_ready PlutoUI.CheckBox(default = true))
"""
end

# ╔═╡ 6ecc0067-68e6-47ba-ac64-2994c4e78a8d
let
	if slices
		f = Figure(resolution=(1000, 1000))
		ax = CairoMakie.Axis(
			f[1, 1],
			title="BFC Phantom"
		)
		heatmap!(bfc_phantom[:, :, bfield_slider3, z3], colormap=:grays)
		
		f
	end
end

# ╔═╡ 706ffc9a-629c-40bd-902c-a42041ca1fce
md"""
# Fit Center
"""

# ╔═╡ 36924875-efef-4832-a1e9-21b089e89a26
md"""
## Choose Motion Start Time
"""

# ╔═╡ ee7259ff-dcb0-421a-be42-81f0efe8154b
if (@isdefined bfc_ready) && (bfc_ready == true)
md"""
Typically, motion starts at `Seq#` 201 but choose the time by visually verifying the `Seq#` below:

Motion Start Sequence: $(@bind motion_start PlutoUI.Slider(df_log[!, "Seq#"]; show_value = true, default = 201))
"""
end

# ╔═╡ 4bdd75e3-c4c6-452b-ad35-9fbcfbc35204
if (@isdefined bfc_ready) && (bfc_ready == true)
	df_log[200:210, :]
end

# ╔═╡ 66a8589d-1491-4f8f-a780-4afd51889fc0
md"""
## Check the Center Fitting Process
"""

# ╔═╡ a1bbf1a8-ce17-4be2-90cf-3da3d9c62f3b
if (@isdefined bfc_ready) && (bfc_ready == true)
md"""
If the plot below shows that certain `Centers` are far from the predicted axis, these slices might need to be removed from the fitting. This can be done by dragging the sliders below

Beginning Corrected Slice: $(@bind rot_slices1 PlutoUI.Slider(axes(avg_static_phantom, 3); show_value = true, default = first(axes(avg_static_phantom, 3))))

End Corrected Slice: $(@bind rot_slices2 PlutoUI.Slider(axes(avg_static_phantom, 3); show_value = true, default = last(axes(avg_static_phantom, 3))))
"""
end

# ╔═╡ e918d8dc-dfd5-4eb7-840b-f2e8960795b8
if (@isdefined bfc_ready) && (bfc_ready == true)
	md"""
	If the center fitting process looks accurate, check the box:
	$(@bind rot_ready PlutoUI.CheckBox(; default = true))
	"""
end

# ╔═╡ 6b5f4742-ea52-4a41-a508-226bbc03b757
# Fit Center & Radius of Inner Cylinder for Each Slice
if (@isdefined bfc_ready) && (bfc_ready == true)
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

	# Original Centers
	ecs = BDTools.centers(sph)

	rng = collect(-1.:0.15:1.)
	cc = map(t->BDTools.predictcenter(sph, t), rng)

	# Fitted Centers
	xy = BDTools.fittedcenters(sph);
end;

# ╔═╡ 8688c8f1-18b9-4b77-8408-74a4cb4a7b2d
if (@isdefined bfc_ready) && (bfc_ready == true)
	let
		if !@isdefined ecs
			@warn "Not enough data points. Check that the acqusition timings are correct"
		else
			f = Figure()
			ax = CairoMakie.Axis(f[1, 1])
			scatter!(ecs[:, 1], ecs[:, 2], label="Centers")
			lines!(map(first, cc), map(last, cc), label="Predicted Axis", color=:orange)
			scatter!(xy[:, 1], xy[:, 2], label="Fitted Centers", color=:green)
			axislegend(ax, position=:lt)
			f
		end
	end
end

# ╔═╡ cab0c52b-6f64-4ef3-bb09-ab86d3b02d35
md"""
# Time Series Analysis
"""

# ╔═╡ cc1b9279-1cd0-4404-be9a-eecf69e13f8d
md"""
## Visualize Generated Phantom w/ Rotations
"""

# ╔═╡ 89d58f11-358e-4ca0-a084-da9405f4c5ce
if (@isdefined rot_ready) && (rot_ready == true)
md"""
Select Angle of Rotation: $(@bind degrees PlutoUI.Slider(1:360, show_value = true, default = 20))


Select Slice: $(@bind z2 PlutoUI.Slider(axes(sph.data, 3); default=3, show_value=true))
"""
end

# ╔═╡ ba280f77-0f90-4ea4-bdce-839086dc332a
# Prepare rotated phantom
if (@isdefined rot_ready) && (rot_ready == true)
	sz = size(bfc_phantom2)
	
	α = deg2rad(degrees)
	γ = BDTools.findinitialrotation(sph, z2)
	origin, a, b = BDTools.getellipse(sph, z2)
	coords = [BDTools.ellipserot(α, γ, a, b)*([i,j,z2].-origin).+origin for i in 1:sz[1], j in 1:sz[2]]

	# interpolate intensities
	sim = map(c -> sph.interpolation(c...), coords)
	# generate image
	gen = sim |> BDTools.genimg
	ave2 = BDTools.genimg(sph.data[:, :, z2])
end;

# ╔═╡ 92bdae79-e855-4314-ba29-14669556329a
if (@isdefined rot_ready) && (rot_ready == true)
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
end

# ╔═╡ c3c71d85-56bd-44d4-8803-6b5f09ee97b6
md"""
## Check Rotated Predictions
"""

# ╔═╡ d8161b44-73fe-4a60-bc12-2f2166e10296
if (@isdefined rot_ready) && (rot_ready == true)
md"""
If the phantom is rotating the wrong direction, check the box below to flip the angles for the `groundtruth` phantom

Flip Angles: $(@bind flipangles PlutoUI.CheckBox())
"""
end

# ╔═╡ 169ebd03-8705-427e-ad0c-2c39d4c6cfe9
md"""
## Visualize Time Series (Pixels)
"""

# ╔═╡ 656daeff-4639-4b7a-9a71-c2dceec20c7b
if (@isdefined rot_ready) && (rot_ready == true)
	md"""
	Choose Threshold: $(@bind thresh PlutoUI.Slider(0.50:0.05:1.00; default = 0.50, show_value = true))
	"""
end

# ╔═╡ 05fa4ff1-4e32-4804-8fb4-2ccbe40eb157
# Check Rotated Predictions
if (@isdefined rot_ready) && (rot_ready == true)
	# Find the index of the first column whose name contains "EndPos" or "CurPos"
	pos_col_indices = first([index for (index, name) in enumerate(colnames) if occursin("endpos", lowercase.(name)) || occursin("curpos", lowercase.(name))])
	
	quant = 2^13
	pos = df_log[!, pos_col_indices]
	firstrotidx = motion_start
	angles = [a > π ? a-2π : a for a in (pos ./ quant).*(2π)]
	
	gt = groundtruth(sph, bfc_phantom2, angles; startmotion=firstrotidx, threshold = thresh, flipangles = flipangles)
end;

# ╔═╡ 1884cb24-09b8-4da3-9d99-d624d0a231a2
if (@isdefined rot_ready) && (rot_ready == true)
	md"""
	Choose Centerpoint Slice: $(@bind z4 PlutoUI.Slider(axes(gt.data, 3); default=3, show_value=true))

	Choose `x` Offset: $(@bind x4 PlutoUI.Slider(-10:10; default=1, show_value=true))

	Choose `y` Offset: $(@bind y4 PlutoUI.Slider(-10:10; default=1, show_value=true))
	"""
end

# ╔═╡ e8fd3f8c-17c5-4d32-946e-6a8cbde8feb5
function check_rotated_pred()
	x = Int(round(xy[z4, 1])) + x4
	y = Int(round(xy[z4, 2])) + y4
	z = z4 # get coordinates
	cidx = gt[x, y] # get a masked coordinate index
	cidx === nothing && return @warn "Offset out of bounds"

	# plot data
	f = Figure(resolution = (1200, 800))

	ax = CairoMakie.Axis(
		f[1, 1],
		title="Average Static Image @ Slice $(z2)"
	)
	heatmap!(ave2, colormap=:grays)
	scatter!([x], [y]; markercolor = :red, markersize = 20)
	
	ax = CairoMakie.Axis(
		f[1, 2],
		title = "Intensity (x=$x, y=$y, z=$z)",
		xlabel = "Time Point",
		ylabel = "Intensity"
	)
	lines!(gt[x, y, z], label="prediction")
	lines!(gt[x, y, z, true], label="original")
	axislegend(ax, position=:lt)
	f
end

# ╔═╡ 966054fd-e738-4bf0-a414-8f28c5ae6928
if (@isdefined rot_ready) && (rot_ready == true)
	check_rotated_pred()
end

# ╔═╡ 38d51e5a-85dd-4461-b690-a7f908be6053
if (@isdefined rot_ready) && (rot_ready == true)
	md"""
	Select Slice: $(@bind z5 PlutoUI.Slider(axes(gt.data, 3); show_value = true))
	
	Select Timepoint: $(@bind z6 PlutoUI.Slider(axes(gt.data, 1); show_value = true)) 
	"""
end

# ╔═╡ 3e936583-bd74-4976-be6d-7e8c109ca97d
if (@isdefined rot_ready) && (rot_ready == true)
	md"""
	If the threshold looks correct, check the box:
	$(@bind skew_ready PlutoUI.CheckBox(; default = true))
	"""
end

# ╔═╡ 9d8583fc-aeac-4151-b93e-2f7b2e01b04f
# Visualize Time Series
if (@isdefined rot_ready) && (rot_ready == true)
	orig = gt.data[:, :, :, 1]
	pred = gt.data[:, :, :, 2]

	orig_vec = vec(orig[:, :, :])
	pred_vec = vec(pred[:, :, :])
end;

# ╔═╡ 99dae694-ee04-447b-8e6d-e1154f4a9374
if (@isdefined rot_ready) && (rot_ready == true)
	let
		f = Figure()
		ax = Axis(
			f[1, 1],
			title = "Single Time Point & Slice",
			xlabel = "Pixel",
			ylabel = "Intensity"
		)
	
		orig_vec = vec(orig[z6, :, z5])
		pred_vec = vec(pred[z6, :, z5])
		
		scatterlines!(orig_vec; markersize = 1, label = "original")
		scatterlines!(pred_vec; markersize = 1, label = "predicted")
		
		axislegend(ax)
		
		f
	end
end

# ╔═╡ 28aafeac-21d2-46d3-ad17-7bc4c85b7e00
md"""
## Remove Outliers
"""

# ╔═╡ f3f44166-ced3-401f-be3e-9cbfbcf87c47
if (@isdefined skew_ready) && (skew_ready == true)
	let
		f = Figure()
		ax = Axis(
			f[1, 1],
			title = "All Time Points & Slices",
			xlabel = "Pixel",
			ylabel = "Intensity"
		)
	
		scatterlines!(orig_vec; markersize = 1, label = "original")
		scatterlines!(pred_vec; color = (:orange, 0.4), markersize = 1, label = "predicted")
	
		axislegend(ax)
		
		f
	end
end

# ╔═╡ 8db36cba-2ee6-46e3-80fd-33016f7e5e01
if (@isdefined skew_ready) && (skew_ready == true)
	md"""
	Choose Outlier Removal Constant: $(@bind outlier_const PlutoUI.Slider(0:.5:10; default = 0.5, show_value = true))
	"""
end

# ╔═╡ 188cd87c-bf37-43cb-8a27-a0a2db6d0457
if (@isdefined skew_ready) && (skew_ready == true)
	md"""
	If the outliers were removed correctly, check the box:
	$(@bind outliers_ready PlutoUI.CheckBox(; default = true))
	"""
end

# ╔═╡ ea7bb0d5-9489-4168-b70b-db9d269d4341
function remove_outliers(orig::Array{T, 3}, pred::Array{T, 3}, outlier_constant) where T
    orig_vec = vec(orig)
    pred_vec = vec(pred)

    upper_quartile = quantile(orig_vec, 0.75)
    lower_quartile = quantile(orig_vec, 0.25)
    IQR = (upper_quartile - lower_quartile) * outlier_constant
    quartile_set = (lower_quartile - IQR, upper_quartile + IQR)

    orig_mask = (orig_vec .>= quartile_set[1]) .& (orig_vec .<= quartile_set[2])

    orig_clean_vec = orig_vec[orig_mask]
    pred_clean_vec = pred_vec[orig_mask]  # Same mask for pred_vec

    orig_clean_3D_nan = fill(NaN, size(orig))
    pred_clean_3D_nan = fill(NaN, size(pred))

    count = 0
    for (idx, element) in enumerate(orig_mask)
        if element
            count += 1
            orig_clean_3D_nan[idx] = orig_clean_vec[count]
            pred_clean_3D_nan[idx] = pred_clean_vec[count]
        end
    end

    return orig_clean_vec, pred_clean_vec, orig_clean_3D_nan, pred_clean_3D_nan
end

# ╔═╡ 96d2e4f6-2238-4ec7-af70-f7b1f934d8d2
# Remove Outliers
if (@isdefined skew_ready) && (skew_ready == true)

	orig_clean_vec, pred_clean_vec, orig_clean_3D_nan, pred_clean_3D_nan = remove_outliers(orig, pred, outlier_const)
	
	orig_skew, pred_skew = skewness(orig_vec), skewness(pred_vec)
	
	orig_clean_skew, pred_clean_skew = skewness(orig_clean_vec), skewness(orig_clean_vec)
end

# ╔═╡ 7dd4bd96-147d-43e4-9ca6-e5a3951e7eae
if (@isdefined skew_ready) && (skew_ready == true)
	let
		f = Figure()
		ax = Axis(f[1, 1])
		hist!(orig_vec, bins = 1000, label = "Original")
		hist!(orig_clean_vec; bins = 1000, label = "Original Cleaned")
		axislegend(ax)
	
		ax = Axis(f[1, 2])
		hist!(pred_vec, bins = 1000, label = "Predicted")
		hist!(pred_clean_vec; bins = 1000, label = "Predicted Cleaned")
		axislegend(ax)
		
		f
	end
end

# ╔═╡ f19d278d-1887-4265-b397-d19074acd3ee
md"""
# Quality Assurance
"""

# ╔═╡ 3e16bcfd-ed9c-4b87-8a16-d7d89e714647
# Quality Measurements
if (@isdefined outliers_ready) && (outliers_ready == true)
	mean_sigma, std_sigma, mean_amplitude, std_amplitude = BDTools.mul_noise(pred_clean_vec, orig_clean_vec)
	
	snr = BDTools.st_snr(pred_clean_vec, orig_clean_vec)

	p_cor = cor(pred_clean_vec, orig_clean_vec)
end

# ╔═╡ b5d46866-778b-43b6-a0d2-bad02fb5433c
if (@isdefined outliers_ready) && (outliers_ready == true)
	md"""
	Variance (multiplicative noise):
	- Mean sigma: $(mean_sigma)
	- Std sigma: $(std_sigma)
	- Mean amplitude: $(mean_amplitude)
	- Std amplitude: $(std_amplitude)
	
	Power (standard signal to noise): $(snr)
	
	Pearson's correlation coefficient: $(p_cor)
	
	"""
end

# ╔═╡ 896d27ee-8ce6-4274-b8ff-05b65fd335a3
md"""
# Save Ground Truth Phantom(s)
"""

# ╔═╡ 4309d5b9-28a6-43e3-b8d8-8d833fc55bec
md"""
Enter File Path to Save `groundtruth` (raw and clean) phantoms: 

$(@bind output_dir confirm(TextField()))
"""

# ╔═╡ 4755dd68-575f-4bb9-9859-31e9122ae3d2
# Save Phantom(s)
if output_dir != ""
	gt_data_clean = cat(orig_clean_3D_nan, pred_clean_3D_nan; dims = 4)
	gt_clean = BDTools.GroundTruth(gt_data_clean, copy(gt.sliceindex), copy(gt.maskindex))
	
	filepath_raw = joinpath(output_dir, "gt_raw.h5")
	BDTools.serialize(filepath_raw, gt)

	filepath_clean = joinpath(output_dir, "gt_clean.h5")
	BDTools.serialize(filepath_clean, gt_clean)
end

# ╔═╡ Cell order:
# ╟─543b5c8f-70f3-430c-8165-327f31132d6d
# ╟─773155ed-38c9-4aac-b400-f67a814e1f5a
# ╟─06d87105-c48b-41ce-bd3c-14bd0363c2ac
# ╠═63d91761-537a-4324-8df8-0a35bcdc1807
# ╠═723e4ea5-0328-4816-85ec-ae50f986f2be
# ╟─233b8f26-0830-462d-87d7-a241ed4c0a09
# ╟─c818025f-8da3-4762-b8fa-3580431d750f
# ╠═510a24fb-bd5e-457d-928a-3c853688890f
# ╠═b79276ee-319d-4e1c-be3c-65bc01f168f0
# ╠═20e44e50-13e1-4014-86cb-25cce1a8d735
# ╟─a043515a-4d56-42df-974e-537aefcd9d92
# ╟─50225cf7-ec2c-4538-95be-8e32ff9405c5
# ╟─0f20df87-6727-497c-a245-8f8e3d6770f1
# ╟─a80a7b2e-3406-40f8-85b2-a15f7883476b
# ╟─74ffb64c-97e0-4e09-ad90-58619ec3cee8
# ╟─ca6f0305-abc7-4fe4-adee-4982a960d878
# ╟─4946e638-4c27-40af-90f8-79ffb611efce
# ╟─ba39efcb-4295-4222-92f5-809e0337643d
# ╟─af055420-a355-40a1-aa37-fccf1f350c0a
# ╟─3edba034-3185-4797-9a08-997430a1e7d5
# ╟─2d4bfb9e-6fba-4019-b27a-dcc3e3182e69
# ╟─297aa7da-0896-40e5-ace9-a6895ecebda9
# ╠═c4528c0a-040f-4d34-afce-0cd83faa9cf6
# ╠═ba278bba-ca56-4206-8674-15b09cb505ed
# ╟─1337fe2d-8969-4602-a94b-fbc071b4d3b9
# ╟─55d21ac9-3fd8-43ed-a7e8-b914e7b1a309
# ╟─cfd65480-cf34-40e3-bd93-c6aa863602e6
# ╠═05e8f53f-9221-4021-ab83-88e3e7e4645a
# ╟─58320a5e-5b63-440a-ab01-295823ffe909
# ╠═d2025ebd-7441-42dd-9fda-874f9e4db9e7
# ╠═3c181b45-708f-4bb8-8ebf-ff1795a34fc9
# ╠═6d683aec-0065-4b09-80f2-3154185a6b36
# ╠═3a02d92d-c130-48f4-8b85-e4b88ad3cc3a
# ╟─5d65cd2b-9b89-4600-a95e-f88bb773eeb3
# ╟─5cba808f-0359-404a-832b-7e93372c54b1
# ╟─9d8f4f33-daeb-4da9-9432-db4c7b5185a9
# ╟─6ecc0067-68e6-47ba-ac64-2994c4e78a8d
# ╟─706ffc9a-629c-40bd-902c-a42041ca1fce
# ╟─36924875-efef-4832-a1e9-21b089e89a26
# ╟─ee7259ff-dcb0-421a-be42-81f0efe8154b
# ╠═4bdd75e3-c4c6-452b-ad35-9fbcfbc35204
# ╟─66a8589d-1491-4f8f-a780-4afd51889fc0
# ╟─a1bbf1a8-ce17-4be2-90cf-3da3d9c62f3b
# ╟─e918d8dc-dfd5-4eb7-840b-f2e8960795b8
# ╟─8688c8f1-18b9-4b77-8408-74a4cb4a7b2d
# ╠═6b5f4742-ea52-4a41-a508-226bbc03b757
# ╟─cab0c52b-6f64-4ef3-bb09-ab86d3b02d35
# ╟─cc1b9279-1cd0-4404-be9a-eecf69e13f8d
# ╟─89d58f11-358e-4ca0-a084-da9405f4c5ce
# ╟─92bdae79-e855-4314-ba29-14669556329a
# ╠═ba280f77-0f90-4ea4-bdce-839086dc332a
# ╟─c3c71d85-56bd-44d4-8803-6b5f09ee97b6
# ╟─1884cb24-09b8-4da3-9d99-d624d0a231a2
# ╟─966054fd-e738-4bf0-a414-8f28c5ae6928
# ╟─d8161b44-73fe-4a60-bc12-2f2166e10296
# ╠═05fa4ff1-4e32-4804-8fb4-2ccbe40eb157
# ╠═e8fd3f8c-17c5-4d32-946e-6a8cbde8feb5
# ╟─169ebd03-8705-427e-ad0c-2c39d4c6cfe9
# ╟─38d51e5a-85dd-4461-b690-a7f908be6053
# ╟─656daeff-4639-4b7a-9a71-c2dceec20c7b
# ╟─99dae694-ee04-447b-8e6d-e1154f4a9374
# ╟─3e936583-bd74-4976-be6d-7e8c109ca97d
# ╠═9d8583fc-aeac-4151-b93e-2f7b2e01b04f
# ╟─28aafeac-21d2-46d3-ad17-7bc4c85b7e00
# ╟─f3f44166-ced3-401f-be3e-9cbfbcf87c47
# ╟─8db36cba-2ee6-46e3-80fd-33016f7e5e01
# ╟─7dd4bd96-147d-43e4-9ca6-e5a3951e7eae
# ╟─188cd87c-bf37-43cb-8a27-a0a2db6d0457
# ╠═96d2e4f6-2238-4ec7-af70-f7b1f934d8d2
# ╟─ea7bb0d5-9489-4168-b70b-db9d269d4341
# ╟─f19d278d-1887-4265-b397-d19074acd3ee
# ╟─b5d46866-778b-43b6-a0d2-bad02fb5433c
# ╠═3e16bcfd-ed9c-4b87-8a16-d7d89e714647
# ╟─896d27ee-8ce6-4274-b8ff-05b65fd335a3
# ╟─4309d5b9-28a6-43e3-b8d8-8d833fc55bec
# ╠═4755dd68-575f-4bb9-9859-31e9122ae3d2
