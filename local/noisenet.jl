### A Pluto.jl notebook ###
# v0.19.38

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

# ╔═╡ edb43714-cc19-11ee-03db-490ff56099d0
begin
	using Pkg
	Pkg.activate(temp = true)

	Pkg.add(url = "https://github.com/hstrey/BDTools.jl")
	Pkg.add.(["CairoMakie", "PlutoUI", "NIfTI", "CUDA", "cuDNN", "Flux"])
	
	using BDTools
	using CairoMakie
	using PlutoUI
	using NIfTI
	using CUDA
	using Flux
	using Statistics
end

# ╔═╡ 82ba726c-366c-49d0-8ddd-481ace54244b
md"""
## Load model and denoise phantom
"""

# ╔═╡ d816a6db-4ace-4812-8c43-d4b0ea996268
md"""
Enter File Path to Upload Trained Model: 

$(@bind model_path confirm(TextField()))
"""

# ╔═╡ 0cc67409-eb84-422a-9be0-0a14ee9d7469
if (@isdefined model_path) && (model_path != "")
	trained_model = BDTools.Denoiser.load(model_path)
end;

# ╔═╡ eb1dfec2-7680-4e7d-9123-83d709acc51b
md"""
Enter File Path to 4-d NIfTI to denoise: 

$(@bind brain_path confirm(TextField()))
"""

# ╔═╡ 6d71c466-1ca3-4fc0-a98a-ea1fe7617108
md"""
Enter File Path to 4-d mask to denoise: 

$(@bind mask_path confirm(TextField()))
"""

# ╔═╡ 2a53f610-0323-4607-bf73-f306c3e90e9a
if (@isdefined brain_path) && (brain_path != "") && (@isdefined mask_path) && (mask_path != "")
	brain = niread(brain_path)
	mask = niread(mask_path)
	maskbool = Bool.(mask.raw)
	n_times = sum(maskbool)
	nothing
end

# ╔═╡ 7aaa612d-f9f8-4a59-939b-76172350ff17
md"""
This NIftI contains $n_times time-series

Please use the sliders below to inspect the time series at each point in the brain

Choose x: $(@bind brainx PlutoUI.Slider(axes(brain,1); default=1, show_value=true))

Choose y: $(@bind brainy PlutoUI.Slider(axes(brain,2); default=1, show_value=true))

Choose y: $(@bind brainz PlutoUI.Slider(axes(brain,3); default=1, show_value=true))

"""

# ╔═╡ a82f7f9f-5f7f-4fa9-b0c2-e9d0a62bc5c7
if (@isdefined brain_path) && (brain_path != "") && (@isdefined mask_path) && (mask_path != "")
	f = Figure(size = (800, 600))

	ax = CairoMakie.Axis(
		f[1, 1],
		title="Time Series at $(brainx),$(brainy),$(brainz)",
		xlabel = "Time in TRs",
		ylabel = "BOLD in arb. units"
	)
	lines!(ax,brain[brainx,brainy,brainz,:])
	f
end

# ╔═╡ 519a862c-9739-4c82-bff4-aff1d3762229
if (@isdefined brain_path) && (brain_path != "") && (@isdefined mask_path) && (mask_path != "")
	brain_denoised = Array(brain[:,:,:,end-599:end])
	for x in axes(brain,1)
		for y in axes(brain,2)
			for z in axes(brain,3)
				if maskbool[x,y,z]
					ts = Float32.(brain[x,y,z,end-599:end])
					ts_std = std(ts)
					ts_mean = mean(ts)
					ts_dn = BDTools.denoise(trained_model, reshape((ts .- ts_mean) ./ ts_std,(600,1,1))) .* ts_std .+ ts_mean
					brain_denoised[x,y,z,:] = ts_dn[:,1,1]
				end
			end
		end
	end
end


# ╔═╡ 72eb3f52-fb1e-4ee0-9273-7d4229ad0c62
md"""
Choose x: $(@bind brainxx PlutoUI.Slider(axes(brain,1); default=1, show_value=true))

Choose y: $(@bind brainyy PlutoUI.Slider(axes(brain,2); default=1, show_value=true))

Choose y: $(@bind brainzz PlutoUI.Slider(axes(brain,3); default=1, show_value=true))

Choose mult factor: $(@bind brainf PlutoUI.Slider(0.01:0.01:10; default=1.0, show_value=true))
"""

# ╔═╡ 73d8050d-035c-47ce-ba63-199ee22ea111
begin
	f2 = Figure(size = (800, 600))

	ax2 = CairoMakie.Axis(
		f2[1, 1],
		title="Denoised Time Series at $(brainxx),$(brainyy),$(brainzz)",
		xlabel = "Time in TRs",
		ylabel = "BOLD in arb. units"
	)
	bdn = brain_denoised[brainxx,brainyy,brainzz,:]
	bdn_mean = mean(bdn)
	lines!(ax2,(bdn .- bdn_mean) .* brainf .+ bdn_mean, label="denoised")
	lines!(ax2,brain[brainxx,brainyy,brainzz,end-599:end], label="original")
	axislegend(ax2)
	f2
end

# ╔═╡ cabad321-a926-4532-9af3-bf51901c423e
md"""
Enter File Path to Upload Trained Model: 

$(@bind denoised_path confirm(TextField()))
"""

# ╔═╡ ddcc2b01-8f8a-4660-8c35-6620c0163989
begin
	brain_head = brain.header
	bhd = brain_head.dim
	brain_head.dim = (bhd[1],bhd[2],bhd[3],bhd[4],600,1,1,1)
	ni_denoised = NIVolume(brain_head, Float64.(brain_denoised))
	niwrite(denoised_path,ni_denoised)
end

# ╔═╡ Cell order:
# ╠═edb43714-cc19-11ee-03db-490ff56099d0
# ╟─82ba726c-366c-49d0-8ddd-481ace54244b
# ╟─d816a6db-4ace-4812-8c43-d4b0ea996268
# ╟─0cc67409-eb84-422a-9be0-0a14ee9d7469
# ╟─eb1dfec2-7680-4e7d-9123-83d709acc51b
# ╟─6d71c466-1ca3-4fc0-a98a-ea1fe7617108
# ╟─2a53f610-0323-4607-bf73-f306c3e90e9a
# ╟─7aaa612d-f9f8-4a59-939b-76172350ff17
# ╟─a82f7f9f-5f7f-4fa9-b0c2-e9d0a62bc5c7
# ╟─519a862c-9739-4c82-bff4-aff1d3762229
# ╟─73d8050d-035c-47ce-ba63-199ee22ea111
# ╟─72eb3f52-fb1e-4ee0-9273-7d4229ad0c62
# ╟─cabad321-a926-4532-9af3-bf51901c423e
# ╟─ddcc2b01-8f8a-4660-8c35-6620c0163989
