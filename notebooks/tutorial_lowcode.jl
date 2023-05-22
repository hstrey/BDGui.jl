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

# ╔═╡ 33b2249f-4dff-4eed-9be9-b0abff4074b1
# ╠═╡ show_logs = false
begin
	using Pkg
	Pkg.activate(mktempdir())
	Pkg.add("CondaPkg")
	Pkg.add("PythonCall")
	Pkg.add(url="https://github.com/Dale-Black/BDTools.jl")
	Pkg.add("CairoMakie")
	Pkg.add("NIfTI")
	Pkg.add("PlutoUI")
	Pkg.add("CSV")
	Pkg.add("DataFrames")
	Pkg.add("Statistics")

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

# ╔═╡ 8e4185b7-103b-4cdd-9af6-7f97d03ea25c
md"""
Enter File Path to Save B-field Corrected Phantom: $(@bind output_dir confirm(TextField()))
"""

# ╔═╡ f8278545-bb5d-4f91-8d56-eeab4e7e4929
md"""
# Appendix
"""

# ╔═╡ e885bd90-2474-48dc-bba6-d4b9aaebcacf
md"""
## (Code) Import Packages
"""

# ╔═╡ 56a64c10-e461-43bd-b448-94ed0e7b40fa
sitk = pyimport("SimpleITK")

# ╔═╡ a6081d85-7903-4ea7-ac77-16f9161e1d65
TableOfContents()

# ╔═╡ 22fd7fc7-5b53-49dd-b648-0281a121f8c9
md"""
## (Code) Load Phantom, Logs, & Acquisition Times
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

# ╔═╡ 6b4e39ab-9fe8-4166-a7a0-ceccf2da58a7
if uploaded
	try
		global df_log = CSV.read(download(log_file), DataFrame)
		
		global df_acq = CSV.read(download(acq_file), DataFrame)
			
		global phantom = niread(download(nifti_file))
	catch
		global df_log = CSV.read(log_file, DataFrame)
		
		global df_acq = CSV.read(acq_file, DataFrame)
			
		global raw_phantom = niread(nifti_file)
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
## (Code) Identify Good Slices
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
		Select the range of good slices between 1 to 60 by scrolling through the slider and note when the first good slice starts and when the last good slice ends
		$(inputs)
		"""
	end
end

# ╔═╡ 444c3158-8b08-462a-abdc-6debbe65ffd9
@bind g_slices confirm(good_slice_info("First good slice: ", "Last good slice: "))

# ╔═╡ 09e300b5-7ae8-417a-8bb8-87c72750a5c9
slices = g_slices[1] != "" && g_slices[2] != ""

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

	max_motion = findmax(df_log[!,"Tmot"])[1]
	slices_without_motion = df_acq[!,"Slice"][df_acq[!,"Time"] .> max_motion]
	slices_ok = sort(
		slices_without_motion[parse(Int, first(g_slices))-1 .<= slices_without_motion .<= parse(Int, last(g_slices))+1]
	)
	slices_wm = [x in slices_ok ? 1 : 0 for x in good_slices]
	slices_df = DataFrame(Dict(:slice => good_slices, :no_motion => slices_wm))
end;

# ╔═╡ 51ee9269-4455-4118-8af8-632959653447
md"""
## (Code) Calculate Average Static Phantom
"""

# ╔═╡ 797159df-a9bf-4048-aacb-bc8f83dfde6e
if slices
	sph = staticphantom(phantom_ok, Matrix(slices_df); staticslices=static_range)
	phantom_header.dim = (length(size(sph.data)), size(sph.data)..., 1, 1, 1, 1)
	avg_static_phantom = Float32.(sph.data)
	tempdir = mktempdir()
	
	avg_static_phantom_path = joinpath(tempdir, "image.nii")
	niwrite(avg_static_phantom_path, NIVolume(phantom_header, avg_static_phantom))
end;

# ╔═╡ 89326ccf-1274-473f-b077-1e3dc67adf49
md"""
## (Code) Create Mask for B-field Correction
"""

# ╔═╡ 8d349bbd-abcf-44fe-af35-0042fec17aad
if slices
	msk3D = zeros(Int, size(sph.data)[1:2]..., length(good_slices))
	for i in axes(sph.data, 3)
		msk3D[:, :, i] = BDTools.segment3(sph.data[:, :, i]).image_indexmap
	end
	msk3D = parent(msk3D)
	binary_msk3D = Float64.(ifelse.(msk3D .== 1, 0, 1))

	mask_path = joinpath(tempdir, "mask.nii")
	niwrite(mask_path, NIVolume(phantom_header, binary_msk3D))
end;

# ╔═╡ 3a96e5db-8db8-4051-ab72-83598aa82330
md"""
## (Code) Run B-field Correction on Static Image
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
## (Code) Correct 4D Phantom w/ B-field
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

# ╔═╡ 6625f7cc-fe32-4448-9f83-190febdc8ed6
if output_dir != ""
	niwrite(joinpath(output_dir, "bfc_phantom.nii"), NIVolume(phantom_header, bfc_phantom))
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
# ╟─312081a5-e9d8-4368-9e12-87694f24d5dc
# ╟─8e4185b7-103b-4cdd-9af6-7f97d03ea25c
# ╟─f8278545-bb5d-4f91-8d56-eeab4e7e4929
# ╟─e885bd90-2474-48dc-bba6-d4b9aaebcacf
# ╠═33b2249f-4dff-4eed-9be9-b0abff4074b1
# ╠═56a64c10-e461-43bd-b448-94ed0e7b40fa
# ╠═a6081d85-7903-4ea7-ac77-16f9161e1d65
# ╟─22fd7fc7-5b53-49dd-b648-0281a121f8c9
# ╟─4ec60d96-3269-43ac-9c55-8b803673456b
# ╠═e69d1614-2511-4776-8ac4-5f94a947e498
# ╠═6b4e39ab-9fe8-4166-a7a0-ceccf2da58a7
# ╟─63caf69b-1194-450f-99d1-aa776a3d9bb3
# ╟─09db762a-5d46-45e1-a024-e1e1a986f8cf
# ╠═09e300b5-7ae8-417a-8bb8-87c72750a5c9
# ╠═b4a83883-70b6-48b0-b0fa-8ad965e28386
# ╟─7a5d5d09-db35-427b-9228-7b9cfa2522cf
# ╟─51ee9269-4455-4118-8af8-632959653447
# ╠═797159df-a9bf-4048-aacb-bc8f83dfde6e
# ╟─89326ccf-1274-473f-b077-1e3dc67adf49
# ╠═8d349bbd-abcf-44fe-af35-0042fec17aad
# ╟─3a96e5db-8db8-4051-ab72-83598aa82330
# ╠═61505bbe-ca29-4d5a-9ada-e837b6cceed1
# ╟─608a56bf-ccf1-45cb-8114-e4b23e7a7ad3
# ╠═d8412662-ac5a-46e4-95ed-e68bdedd0732
# ╠═6625f7cc-fe32-4448-9f83-190febdc8ed6
