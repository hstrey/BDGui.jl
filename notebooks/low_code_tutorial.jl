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

# ╔═╡ 33b2249f-4dff-4eed-9be9-b0abff4074b1
# ╠═╡ show_logs = false
begin
	using Pkg
	Pkg.activate(temp = true)
	Pkg.add("CairoMakie")
	Pkg.add("NIfTI")
	Pkg.add("PlutoUI")
	Pkg.add("CSV")
	Pkg.add("DataFrames")
	Pkg.add("Statistics")
	Pkg.add("StatsBase")
	Pkg.add(url="https://github.com/hstrey/BDTools.jl")

	using CairoMakie
	using PlutoUI
	using NIfTI
	using CSV
	using DataFrames
	using Statistics
	using StatsBase
	using BDTools
end

# ╔═╡ ff531753-72d7-439e-85ee-de8da6a54268
md"""
# Brain Dancer GUI
"""

# ╔═╡ 02d49e3b-918e-41b1-966f-d3aa5b19019f
md"""
## Load Phantom, Logs, & Acquisition Times
"""

# ╔═╡ 9d0bafa4-861c-4259-9611-559969b2e03e
md"""
## Identify Good Slices
"""

# ╔═╡ 8ef47f99-21a9-4575-b4d1-ff98f0720364
md"""
## Visualize B-field Correction on 3D Static Phantom
"""

# ╔═╡ e49a06d1-4fa8-48d2-b913-75d9f90719e2
md"""
## Visualize B-field Corrected 4D Phantom
"""

# ╔═╡ a143c990-45db-4648-8782-2e65099d79f9
md"""
## Choose Motion Start Time
"""

# ╔═╡ 6a02123b-497e-4230-9ca4-4264c00e3f9c
md"""
## Check the Center Fitting Process
"""

# ╔═╡ 3b75fb03-4f9f-4c58-8757-c66323f2f3e6
md"""
## Visualize Generated Phantom w/ Rotations
"""

# ╔═╡ 70ebb35e-1dd2-4a2e-ba9a-524cacfda3ae
md"""
## Check Rotated Predictions
"""

# ╔═╡ a4b07c7e-6ae5-40f9-8ac9-03ee60b707e4
md"""
## Time Series Analysis
"""

# ╔═╡ 060ea16b-99bd-408f-be19-0ecc8d49b07e
md"""
#### Visualize Time Series (Pixels)
"""

# ╔═╡ d9c90d50-3db4-48d3-a43e-d112229bb8e0
md"""
#### Remove Outliers
"""

# ╔═╡ a1acebbc-95b8-44b0-b93b-34275fc8cdd2
md"""
## Quality Measurements
"""

# ╔═╡ e30df5c9-818c-400c-a5f8-28bfb12eb4c8
md"""
## Save Phantom(s)
"""

# ╔═╡ 8e4185b7-103b-4cdd-9af6-7f97d03ea25c
md"""
Enter File Path to Save `groundtruth` (raw and clean) phantoms: 

$(@bind output_dir confirm(TextField()))
"""

# ╔═╡ 77d6db81-955a-446e-be28-5b3bb2faeb9b
html"""
<!-- I replaced the ~20 cells with this, it's just a spacer! Update the height property to change how much space to include -->
<div style="height: 1000px"/>
"""

# ╔═╡ f8278545-bb5d-4f91-8d56-eeab4e7e4929
md"""
# Appendix
"""

# ╔═╡ e885bd90-2474-48dc-bba6-d4b9aaebcacf
md"""
#### (Code) Import Packages
"""

# ╔═╡ a6081d85-7903-4ea7-ac77-16f9161e1d65
TableOfContents()

# ╔═╡ 22fd7fc7-5b53-49dd-b648-0281a121f8c9
md"""
#### (Code) Load Phantom, Logs, & Acquisition Times
"""

# ╔═╡ 4ec60d96-3269-43ac-9c55-8b803673456b
function upload_files(logs, acqs, phtm)
	
	return PlutoUI.combine() do Child
		
		inputs = [
			md""" $(logs): $(@bind log_file TextField(60))""",
			md""" $(acqs): $(@bind acq_file TextField(60))""",
			md""" $(phtm): $(@bind nifti_file TextField(60))"""
		]
		
		md"""
		#### Upload Files
		Provide URLs or file paths to the necessary files. If running locally, file paths are expected. If running on the web, provide URL links. We recommend DropBox, as Google Drive will likely not work.
		
		Ensure log and acquisition files are in `.csv` format & phantom file is in `.nii` or `.nii.gz` format. Then click submit
		$(inputs)
		"""
	end
end

# ╔═╡ c099ea26-3d82-4d66-aa59-b6e14af7bece
confirm(upload_files("Upload Log File: ", "Upload Acquisition Times: ", "Upload Phantom Scan: "))

# ╔═╡ e69d1614-2511-4776-8ac4-5f94a947e498
uploaded = log_file != "" && acq_file != "" && nifti_file != ""

# ╔═╡ 7283f0fd-16ac-4349-9675-6edc1ddfadfc
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

# ╔═╡ 5f339c15-3538-49d1-8c32-7d8670baef86
function load_acqs(acq_file)
	if contains(acq_file, "http")
		df_acq = CSV.read(download(acq_file), DataFrame)
	else
		df_acq = CSV.read(acq_file, DataFrame)
	end
	return df_acq
end

# ╔═╡ 15a220d0-e1a8-40d3-bec4-f9563c3424be
function load_phantom(nifti_file)
	if contains(nifti_file, "http")
		phantom = niread(download(nifti_file))
	else
		phantom = niread(nifti_file)
	end
	return phantom
end

# ╔═╡ 6b4e39ab-9fe8-4166-a7a0-ceccf2da58a7
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

# ╔═╡ 90a17496-31ee-4809-b5bd-b262ef3000ce
if uploaded
	@bind good_slices_slider PlutoUI.Slider(axes(phantom, 3); default=div(size(phantom, 3), 2), show_value=true)
end

# ╔═╡ 737ae0fb-f34e-4c5a-afaa-61cf3f7197f8
if uploaded
	heatmap(phantom.raw[:, :, good_slices_slider, 1], colormap=:grays)
end

# ╔═╡ ef701dbf-7298-46eb-ba01-4870c4bc4ab6
if uploaded
	@bind b_slider PlutoUI.Slider(axes(phantom, 4); default=div(size(phantom, 4), 2), show_value=true)
end

# ╔═╡ 65abf0a8-f020-400d-af14-59645895cdaf
if uploaded
	heatmap(phantom[:, :, div(size(phantom, 3), 2), b_slider], colormap=:grays)
end

# ╔═╡ 63caf69b-1194-450f-99d1-aa776a3d9bb3
md"""
#### (Code) Identify Good Slices
"""

# ╔═╡ 09db762a-5d46-45e1-a024-e1e1a986f8cf
function good_slice_info(good_slices_first, good_slices_last)
	
	return PlutoUI.combine() do Child
		
		inputs = [
			md""" $(good_slices_first): $(
				Child(TextField())
			)""",
			md""" $(good_slices_last): $(
				Child(TextField())
			)"""
		]
		
		md"""
		#### Good Slices
		Select the range of good slices between by scrolling through the slider and note when the first good slice starts and when the last good slice ends
		$(inputs)
		"""
	end
end

# ╔═╡ 444c3158-8b08-462a-abdc-6debbe65ffd9
@bind g_slices confirm(good_slice_info("First good slice: ", "Last good slice: "))

# ╔═╡ 09e300b5-7ae8-417a-8bb8-87c72750a5c9
slices = g_slices[1] != "" && g_slices[2] != ""

# ╔═╡ 0476f3ae-b35b-4d6c-8713-2edec2bac798
if slices
md"""
If b-field correction looks accurate, check the box:
$(@bind bfc_ready PlutoUI.CheckBox())
"""
end

# ╔═╡ 98ad625f-ae5c-4ed4-8fec-0aef6abd12a1
if (@isdefined bfc_ready) && (bfc_ready == true)
md"""
Typically, motion starts at `Seq#` 201 but choose the time by visually verifying the `Seq#` below:

Motion Start Sequence: $(@bind motion_start PlutoUI.Slider(df_log[!, "Seq#"]; show_value = true, default = 201))
"""
end

# ╔═╡ 4100ec34-be7f-4c61-90bd-58bd0cb942ff
if (@isdefined bfc_ready) && (bfc_ready == true)
	df_log[200:210, :]
end

# ╔═╡ 466194a6-bec5-4bec-9e00-55cdc3d7c378
if (@isdefined bfc_ready) && (bfc_ready == true)
	md"""
	If the center fitting process looks accurate, check the box:
	$(@bind rot_ready PlutoUI.CheckBox())
	"""
end

# ╔═╡ 0c5d04fc-b921-405c-8c3b-9ecb64965edf
if (@isdefined rot_ready) && (rot_ready == true)
md"""
If the phantom is rotating the wrong direction, check the box below to flip the angles for the `groundtruth` phantom

Flip Angles: $(@bind flipangles PlutoUI.CheckBox())
"""
end

# ╔═╡ 49f9f28d-cf34-470a-b8dc-6d9cebb5fa2c
if (@isdefined rot_ready) && (rot_ready == true)
	md"""
	Choose Threshold: $(@bind thresh PlutoUI.Slider(0.50:0.05:1.00; default = 0.50, show_value = true))
	"""
end

# ╔═╡ caf7ed14-dbe6-4e69-8d19-156d6cfd09df
if (@isdefined rot_ready) && (rot_ready == true)
	md"""
	If the threshold looks correct, check the box:
	$(@bind skew_ready PlutoUI.CheckBox())
	"""
end

# ╔═╡ 827ba5b1-d998-4099-8ff7-e24b95b89265
if (@isdefined skew_ready) && (skew_ready == true)
	md"""
	Choose Outlier Removal Constant: $(@bind outlier_const PlutoUI.Slider(0:.5:10; default = 2, show_value = true))
	"""
end

# ╔═╡ 2533717f-2395-4123-953c-276129bb23d2
if (@isdefined skew_ready) && (skew_ready == true)
	md"""
	If the outliers were removed correctly, check the box:
	$(@bind outliers_ready PlutoUI.CheckBox())
	"""
end

# ╔═╡ 7a5d5d09-db35-427b-9228-7b9cfa2522cf
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

# ╔═╡ a70cdc7b-677f-4c84-9507-3cdc531dcd51
@bind static_ranges confirm(static_slice_info("Starting static slice: ", "Ending static slice: "))

# ╔═╡ b4a83883-70b6-48b0-b0fa-8ad965e28386
if slices
	good_slices_range = parse(Int, first(g_slices)):parse(Int, last(g_slices))
	good_slices = collect(parse(Int, g_slices[1]):parse(Int, g_slices[2]))

	num_static_range_low = parse(Int, static_ranges[1])
	num_static_range_high = parse(Int, static_ranges[2])
	static_range = num_static_range_low:num_static_range_high

	phantom_ok = Float64.(convert(Array, phantom[:, :, good_slices_range, static_range]))
end;

# ╔═╡ 51ee9269-4455-4118-8af8-632959653447
md"""
#### (Code) Calculate Average Static Phantom
"""

# ╔═╡ 797159df-a9bf-4048-aacb-bc8f83dfde6e
if slices
	avg_static_phantom = Float32.(mean(phantom_ok[:, :, :, static_range], dims=4)[:, :, :])
	phantom_header.dim = (length(size(avg_static_phantom)), size(avg_static_phantom)..., 1, 1, 1, 1)
	tempdir = mktempdir()
	
	avg_static_phantom_path = joinpath(tempdir, "image.nii")
	niwrite(avg_static_phantom_path, NIVolume(phantom_header, avg_static_phantom))
end;

# ╔═╡ 6402c226-2041-41bf-b7e9-3678bd211807
if (@isdefined bfc_ready) && (bfc_ready == true)
md"""
If the plot below shows that certain `Centers` are far from the predicted axis, these slices might need to be removed from the fitting. This can be done by dragging the sliders below

Beginning Corrected Slice: $(@bind rot_slices1 PlutoUI.Slider(axes(avg_static_phantom, 3); show_value = true, default = first(axes(avg_static_phantom, 3))))

End Corrected Slice: $(@bind rot_slices2 PlutoUI.Slider(axes(avg_static_phantom, 3); show_value = true, default = last(axes(avg_static_phantom, 3))))
"""
end

# ╔═╡ 89326ccf-1274-473f-b077-1e3dc67adf49
md"""
#### (Code) Create Mask for B-field Correction
"""

# ╔═╡ 8d349bbd-abcf-44fe-af35-0042fec17aad
if slices
	segs = BDTools.segment3.(eachslice(avg_static_phantom, dims=3))
    mask_binary = cat(BDTools.labels_map.(segs)..., dims=3) .!= 1
	mask_float = Float32.(mask_binary)

	mask_path = joinpath(tempdir, "mask.nii")
	niwrite(mask_path, NIVolume(phantom_header, mask_float))
end;

# ╔═╡ 3a96e5db-8db8-4051-ab72-83598aa82330
md"""
#### (Code) Run B-field Correction on Static Image
"""

# ╔═╡ 61505bbe-ca29-4d5a-9ada-e837b6cceed1
if slices
	input_image, mask, bfield, corrected_image = BDTools.bfield_correction(avg_static_phantom_path, mask_path)
end;

# ╔═╡ e23f0a47-3da8-4ff5-83c7-5115f3c822ee
if slices
md"""
Select Slice: $(@bind bfield_slider PlutoUI.Slider(axes(bfield, 3); show_value=true))


Set color range: 
  - Low: $(@bind colorrange_low PlutoUI.Slider(Int.(round(minimum(corrected_image))):Int.(round(maximum(corrected_image)))))
  - High: $(@bind colorrange_high PlutoUI.Slider(Int.(round(minimum(corrected_image))):Int.(round(maximum(corrected_image))); default=Int.(round(maximum(corrected_image)))))
"""
end

# ╔═╡ 74261be0-c641-4bef-bb4d-e09f41c87df1
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

# ╔═╡ 608a56bf-ccf1-45cb-8114-e4b23e7a7ad3
md"""
#### (Code) Correct 4D Phantom w/ B-field
"""

# ╔═╡ d8412662-ac5a-46e4-95ed-e68bdedd0732
if slices 
	phantom_whole = phantom[:, :, good_slices_range, :]
	
	bfc_phantom = zeros(size(phantom_whole))
	for i in axes(phantom_whole, 4)
		for j in axes(phantom_whole, 3)
			bfc_phantom[:,:,j,i] = phantom_whole[:, :, j, i] ./ exp.(bfield[:, :, j])
		end
	end
end

# ╔═╡ f267d838-7ddf-4f5f-b91e-6b154624660f
if slices
md"""
Select Slice: $(@bind bfield_slider3 PlutoUI.Slider(axes(bfc_phantom, 3); show_value=true))

Select Time Point: $(@bind z3 PlutoUI.Slider(axes(bfc_phantom, 4); show_value=true))
"""
end

# ╔═╡ 312081a5-e9d8-4368-9e12-87694f24d5dc
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

# ╔═╡ c8946acd-3765-4f4b-9664-9d73c4b3eb7e
md"""
#### (Code) Fit Center & Radius of Inner Cylinder for Each Slice
"""

# ╔═╡ fe339ac3-e62d-4e28-85c9-14ef89bea82c
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

# ╔═╡ fb7ef4c9-2c45-486e-bbf9-e3c8a6e32b62
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

# ╔═╡ f3cbe7c3-2caf-4bad-baf1-954b1f79f3e6
if (@isdefined rot_ready) && (rot_ready == true)
md"""
Select Angle of Rotation: $(@bind degrees PlutoUI.Slider(1:360, show_value = true, default = 20))


Select Slice: $(@bind z2 PlutoUI.Slider(axes(sph.data, 3); default=3, show_value=true))
"""
end

# ╔═╡ 4b1db7c4-ee32-4db5-b8f8-61b51d8329a4
md"""
#### (Code) Rotations
"""

# ╔═╡ 91899626-c34f-4534-820c-f34f795670de
if (@isdefined bfc_ready) && (bfc_ready == true)
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

# ╔═╡ 5afc0ac5-659f-4995-b840-a25b656c0d17
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

# ╔═╡ c1d3b670-58db-4cd1-a04b-4a4cc61a2b3f
md"""
#### (Code) Check Rotated Predictions
"""

# ╔═╡ e401ab6a-1169-45ac-a9ac-af4ca28c33ea
if (@isdefined rot_ready) && (rot_ready == true)
	# Find the index of the first column whose name contains "EndPos" or "CurPos"
	pos_col_indices = first([index for (index, name) in enumerate(colnames) if occursin("endpos", lowercase.(name)) || occursin("curpos", lowercase.(name))])
	
	quant = 2^13
	pos = df_log[!, pos_col_indices]
	firstrotidx = motion_start
	angles = [a > π ? a-2π : a for a in (pos ./ quant).*(2π)]
	
	gt = groundtruth(sph, bfc_phantom2, angles; startmotion=firstrotidx, threshold = thresh, flipangles = flipangles)
end;

# ╔═╡ 5965bf01-a4a9-4b36-aa00-47cfca4f4ba2
if (@isdefined rot_ready) && (rot_ready == true)
	md"""
	Choose Centerpoint Slice: $(@bind z4 PlutoUI.Slider(axes(gt.data, 3); default=3, show_value=true))

	Choose `x` Offset: $(@bind x4 PlutoUI.Slider(-10:10; default=1, show_value=true))

	Choose `y` Offset: $(@bind y4 PlutoUI.Slider(-10:10; default=1, show_value=true))
	"""
end

# ╔═╡ b4e7d29f-29a9-482d-85d4-7e31033fcc53
if (@isdefined rot_ready) && (rot_ready == true)
	let 
		x = Int(round(xy[z4, 1])) + x4
		y = Int(round(xy[z4, 2])) + y4
		z = z4 # get coordinates
	    cidx = gt[x, y] # get a masked coordinate index
	    cidx === nothing && return
	
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
end

# ╔═╡ 7060ebb2-a4f7-493f-8237-9704a5b60046
if (@isdefined rot_ready) && (rot_ready == true)
	md"""
	Select Slice: $(@bind z5 PlutoUI.Slider(axes(gt.data, 3); show_value = true))
	
	Select Timepoint: $(@bind z6 PlutoUI.Slider(axes(gt.data, 1); show_value = true)) 
	"""
end

# ╔═╡ 7d724a8b-6b67-4be7-8560-6405ca7b8b03
md"""
#### (Code) Visualize Time Series
"""

# ╔═╡ 31edf3b1-ad4a-46af-9ad4-52ca33df117d
if (@isdefined rot_ready) && (rot_ready == true)
	orig = gt.data[:, :, :, 1]
	pred = gt.data[:, :, :, 2]

	orig_vec = vec(orig[:, :, :])
	pred_vec = vec(pred[:, :, :])
end;

# ╔═╡ 5041d655-8a8d-4063-a8ab-bcb57bbbef44
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

# ╔═╡ 24a9e088-00d3-46e1-b7b7-b46dd610731f
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
		scatterlines!(pred_vec; markersize = 1, label = "predicted")
	
		axislegend(ax)
		
		f
	end
end

# ╔═╡ 50512420-92f2-4a7b-ae72-40075be93e05
md"""
#### (Code) Remove Outliers
"""

# ╔═╡ 6990dfe0-ecb7-49d1-b4d1-38b689abe7e7
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

# ╔═╡ f926ed88-c48a-40f9-900b-d95925eaf78b
if (@isdefined skew_ready) && (skew_ready == true)

	orig_clean_vec, pred_clean_vec, orig_clean_3D_nan, pred_clean_3D_nan = remove_outliers(orig, pred, outlier_const)
	
	orig_skew, pred_skew = skewness(orig_vec), skewness(pred_vec)
	
	orig_clean_skew, pred_clean_skew = skewness(orig_clean_vec), skewness(orig_clean_vec)
end

# ╔═╡ 676f2f3c-e02c-4d10-8626-7ea46120be59
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

# ╔═╡ 549b26f6-903f-477a-a528-877dd60ec8be
md"""
#### (CODE) Quality Measurements
"""

# ╔═╡ 0b66e9e0-68a9-4d1c-a0f2-9c98f41097f0
if (@isdefined outliers_ready) && (outliers_ready == true)
	mean_sigma, std_sigma, mean_amplitude, std_amplitude = BDTools.mul_noise(pred_clean_vec, orig_clean_vec)
	
	snr = BDTools.st_snr(pred_clean_vec, orig_clean_vec)

	p_cor = cor(pred_clean_vec, orig_clean_vec)
end

# ╔═╡ 819f9274-cfbf-4ba9-943c-2ac9244e9299
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

# ╔═╡ 9248d105-2b48-42ab-b770-8c2c36923503
md"""
#### (Code) Save Phantom(s)
"""

# ╔═╡ 6625f7cc-fe32-4448-9f83-190febdc8ed6
if output_dir != ""
	gt_data_clean = cat(orig_clean_3D_nan, pred_clean_3D_nan; dims = 4)
	gt_clean = BDTools.GroundTruth(gt_data_clean, copy(gt.sliceindex), copy(gt.maskindex))
	
	filepath_raw = joinpath(output_dir, "gt_raw.h5")
	BDTools.serialize(filepath_raw, gt)

	filepath_clean = joinpath(output_dir, "gt_clean.h5")
	BDTools.serialize(filepath_clean, gt_clean)
end

# ╔═╡ Cell order:
# ╟─ff531753-72d7-439e-85ee-de8da6a54268
# ╟─02d49e3b-918e-41b1-966f-d3aa5b19019f
# ╟─c099ea26-3d82-4d66-aa59-b6e14af7bece
# ╟─9d0bafa4-861c-4259-9611-559969b2e03e
# ╟─444c3158-8b08-462a-abdc-6debbe65ffd9
# ╟─90a17496-31ee-4809-b5bd-b262ef3000ce
# ╟─737ae0fb-f34e-4c5a-afaa-61cf3f7197f8
# ╟─a70cdc7b-677f-4c84-9507-3cdc531dcd51
# ╟─ef701dbf-7298-46eb-ba01-4870c4bc4ab6
# ╟─65abf0a8-f020-400d-af14-59645895cdaf
# ╟─8ef47f99-21a9-4575-b4d1-ff98f0720364
# ╟─e23f0a47-3da8-4ff5-83c7-5115f3c822ee
# ╟─74261be0-c641-4bef-bb4d-e09f41c87df1
# ╟─e49a06d1-4fa8-48d2-b913-75d9f90719e2
# ╟─f267d838-7ddf-4f5f-b91e-6b154624660f
# ╟─0476f3ae-b35b-4d6c-8713-2edec2bac798
# ╟─312081a5-e9d8-4368-9e12-87694f24d5dc
# ╟─a143c990-45db-4648-8782-2e65099d79f9
# ╟─98ad625f-ae5c-4ed4-8fec-0aef6abd12a1
# ╟─4100ec34-be7f-4c61-90bd-58bd0cb942ff
# ╟─6a02123b-497e-4230-9ca4-4264c00e3f9c
# ╟─6402c226-2041-41bf-b7e9-3678bd211807
# ╟─466194a6-bec5-4bec-9e00-55cdc3d7c378
# ╟─fb7ef4c9-2c45-486e-bbf9-e3c8a6e32b62
# ╟─3b75fb03-4f9f-4c58-8757-c66323f2f3e6
# ╟─f3cbe7c3-2caf-4bad-baf1-954b1f79f3e6
# ╟─5afc0ac5-659f-4995-b840-a25b656c0d17
# ╟─70ebb35e-1dd2-4a2e-ba9a-524cacfda3ae
# ╟─5965bf01-a4a9-4b36-aa00-47cfca4f4ba2
# ╟─b4e7d29f-29a9-482d-85d4-7e31033fcc53
# ╟─0c5d04fc-b921-405c-8c3b-9ecb64965edf
# ╟─a4b07c7e-6ae5-40f9-8ac9-03ee60b707e4
# ╟─060ea16b-99bd-408f-be19-0ecc8d49b07e
# ╟─7060ebb2-a4f7-493f-8237-9704a5b60046
# ╟─49f9f28d-cf34-470a-b8dc-6d9cebb5fa2c
# ╟─5041d655-8a8d-4063-a8ab-bcb57bbbef44
# ╟─caf7ed14-dbe6-4e69-8d19-156d6cfd09df
# ╟─d9c90d50-3db4-48d3-a43e-d112229bb8e0
# ╟─24a9e088-00d3-46e1-b7b7-b46dd610731f
# ╟─827ba5b1-d998-4099-8ff7-e24b95b89265
# ╟─676f2f3c-e02c-4d10-8626-7ea46120be59
# ╟─2533717f-2395-4123-953c-276129bb23d2
# ╟─a1acebbc-95b8-44b0-b93b-34275fc8cdd2
# ╟─819f9274-cfbf-4ba9-943c-2ac9244e9299
# ╟─e30df5c9-818c-400c-a5f8-28bfb12eb4c8
# ╟─8e4185b7-103b-4cdd-9af6-7f97d03ea25c
# ╟─77d6db81-955a-446e-be28-5b3bb2faeb9b
# ╟─f8278545-bb5d-4f91-8d56-eeab4e7e4929
# ╟─e885bd90-2474-48dc-bba6-d4b9aaebcacf
# ╠═33b2249f-4dff-4eed-9be9-b0abff4074b1
# ╠═a6081d85-7903-4ea7-ac77-16f9161e1d65
# ╟─22fd7fc7-5b53-49dd-b648-0281a121f8c9
# ╠═4ec60d96-3269-43ac-9c55-8b803673456b
# ╠═e69d1614-2511-4776-8ac4-5f94a947e498
# ╠═6b4e39ab-9fe8-4166-a7a0-ceccf2da58a7
# ╠═7283f0fd-16ac-4349-9675-6edc1ddfadfc
# ╠═5f339c15-3538-49d1-8c32-7d8670baef86
# ╠═15a220d0-e1a8-40d3-bec4-f9563c3424be
# ╟─63caf69b-1194-450f-99d1-aa776a3d9bb3
# ╠═09db762a-5d46-45e1-a024-e1e1a986f8cf
# ╠═09e300b5-7ae8-417a-8bb8-87c72750a5c9
# ╠═b4a83883-70b6-48b0-b0fa-8ad965e28386
# ╠═7a5d5d09-db35-427b-9228-7b9cfa2522cf
# ╟─51ee9269-4455-4118-8af8-632959653447
# ╠═797159df-a9bf-4048-aacb-bc8f83dfde6e
# ╟─89326ccf-1274-473f-b077-1e3dc67adf49
# ╠═8d349bbd-abcf-44fe-af35-0042fec17aad
# ╟─3a96e5db-8db8-4051-ab72-83598aa82330
# ╠═61505bbe-ca29-4d5a-9ada-e837b6cceed1
# ╟─608a56bf-ccf1-45cb-8114-e4b23e7a7ad3
# ╠═d8412662-ac5a-46e4-95ed-e68bdedd0732
# ╟─c8946acd-3765-4f4b-9664-9d73c4b3eb7e
# ╠═fe339ac3-e62d-4e28-85c9-14ef89bea82c
# ╟─4b1db7c4-ee32-4db5-b8f8-61b51d8329a4
# ╠═91899626-c34f-4534-820c-f34f795670de
# ╟─c1d3b670-58db-4cd1-a04b-4a4cc61a2b3f
# ╠═e401ab6a-1169-45ac-a9ac-af4ca28c33ea
# ╟─7d724a8b-6b67-4be7-8560-6405ca7b8b03
# ╠═31edf3b1-ad4a-46af-9ad4-52ca33df117d
# ╟─50512420-92f2-4a7b-ae72-40075be93e05
# ╠═6990dfe0-ecb7-49d1-b4d1-38b689abe7e7
# ╠═f926ed88-c48a-40f9-900b-d95925eaf78b
# ╟─549b26f6-903f-477a-a528-877dd60ec8be
# ╠═0b66e9e0-68a9-4d1c-a0f2-9c98f41097f0
# ╟─9248d105-2b48-42ab-b770-8c2c36923503
# ╠═6625f7cc-fe32-4448-9f83-190febdc8ed6
