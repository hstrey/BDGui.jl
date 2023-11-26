### A Pluto.jl notebook ###
# v0.19.32

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

# ╔═╡ e0700b91-6663-4279-a544-c1ff5aea6723
# ╠═╡ show_logs = false
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
end

# ╔═╡ 2f58d100-4aac-4943-a433-f831067890ae
md"""
# Load packages and files
"""

# ╔═╡ e5eaba7c-3b1d-403b-88e1-0f1004efe784
md"""
## Import Packages
"""

# ╔═╡ 5c7abe91-4ab6-4155-a62d-3858f2335245
md"""
!!! info
	If you plan on running this notebook more than once, setting up a long-term environment for this set is recommended. This can done in the terminal or in a code cell like below:

	```julia
		begin
			using Pkg
			Pkg.activate(".")
			Pkg.add(url = "https://github.com/hstrey/BDTools.jl")
			Pkg.add.([
				"CairoMakie", 
				"PlutoUI", 
				"NIfTI",
				"CUDA",
				"cuDNN",
				"Flux"
			])
		end
	```

	Then, when you launch this notebook (and other notebooks inside this environment), you will no longer need to add these packages everytime you load the notebook, and can instead just use:

	```julia
	using BDTools
	using CairoMakie
	using PlutoUI
	using NIfTI
	using CUDA
	using Flux
	```
"""

# ╔═╡ 72309c72-72ff-4835-bd93-9ed185a0f500
TableOfContents()

# ╔═╡ 4cf1d0e1-681f-4cb5-be14-55e3a968c745
md"""
## Loading data
"""

# ╔═╡ 6995e379-717e-448c-9b66-93287feb6ae0
md"""
!!! success "Important Reminder"

	For those who frequently run this notebook multiple times, there is a convenient
	option to avoid repetitively clicking all the subsequent boxes. Simply click the box below, and it will automatically select your upcoming boxes.

	**⚠️Caution⚠️: Exercise this option with care. Each step in the process often requires manual adjustments. If these cells automatically respond to previous modifications, it can significantly slow down the interactive experience.**

"""

# ╔═╡ c6637949-67bc-48e9-a3b3-21ab31ba0964
md"""
Check all following boxes: $(@bind check_all PlutoUI.CheckBox())
"""

# ╔═╡ 6c4edc39-b5d3-4241-9493-0b0671731f88
default_box = check_all

# ╔═╡ ba8efdbd-a307-495b-871d-bceebdef5e84
function upload_files(phtm, grd_phtm)
	
	return PlutoUI.combine() do Child
		
		inputs = [
			md""" $(phtm): $(
				Child(TextField(60))
			)""",
			md""" $(grd_phtm): $(
				Child(TextField(60))
			)"""
		]
		
		md"""
		#### Upload Files
		Provide URLs or file paths to the necessary files. If running locally, file paths are expected. If running on the web, provide URL links. We recommend DropBox, as Google Drive will likely not work.
		
		Ensure the raw phantom file is in `.nii` or `.nii.gz` format and ground truth phantom file is in `.h5` format. Then click submit
		$(inputs)
		"""
	end
end

# ╔═╡ b6a6adac-33e0-43fa-8a78-4ac8e892cca0
@bind up_files confirm(upload_files("Upload Phantom File", "Upload Ground Truth File"))

# ╔═╡ af675880-6c09-4b4d-8294-61ac7fd95b0e
phantomfile, groundtruthfile = up_files

# ╔═╡ 60559bbc-3ab6-47ef-b183-31abf4b7290b
uploaded = phantomfile != "" && groundtruthfile != "";

# ╔═╡ af76692c-37f4-4397-8a2f-09b817e22d7f
if uploaded
	gt, removeidx, sim, _ = BDTools.load_ground_truth(groundtruthfile)
	ori, _ = BDTools.load_phantom(gt, phantomfile; valid_slices = true, remove = removeidx)
end;

# ╔═╡ ec4976a3-6d9e-4a99-a91b-281ee2ec6986
md"""
# Train Model
"""

# ╔═╡ f431b64e-7045-4c76-902e-a81b3e4f2bcc
md"""
## Construct a denoiser model
"""

# ╔═╡ 9d4ebdb5-5511-4902-b1ca-1c1ea70e3252
if CUDA.has_cuda()
	dev = Flux.gpu
	default = 200
else
	dev = Flux.cpu
	default = 20
end

# ╔═╡ 5f826726-1fde-4ab0-911a-0245b1038edb
md"""
Choose Number of Epochs: $(@bind epochs NumberField(default ÷ 2:default ÷ 10:default * 2; default = default))
"""

# ╔═╡ 504670e7-0731-4852-b581-4307c5f1e6eb
model = DenoiseNet(BDTools.TrainParameters(; epochs = epochs); dev = dev)

# ╔═╡ 24c7815a-88e5-47b4-9359-c057294f88c3
md"""
Start training: $(@bind start PlutoUI.CheckBox(default = default_box))
"""

# ╔═╡ 13145ff9-aa6e-40f6-b473-0acf2e6af58b
if start
	losses = BDTools.train!(model, sim, ori)
end

# ╔═╡ 9c3a1bcf-4185-4659-82fa-10a25388c33f
if (@isdefined losses)
	let
		f = Figure()
		ax = CairoMakie.Axis(
			f[1, 1],
			title = "Training Loss",
			xlabel = "Epoch",
			ylabel = "Loss"
		)
		scatterlines!(losses)
		f
	end
end

# ╔═╡ 4c8dc227-9a18-4dfb-ae5a-94d139c9d128
md"""
Enter File Path to Save Trained Model: 

$(@bind output_dir confirm(TextField()))
"""

# ╔═╡ 492de824-dfd0-4420-9a1f-8f85d72a7504
if output_dir != ""
	BDTools.Denoiser.save(joinpath(output_dir, "denoiser_model"), model)
end;

# ╔═╡ 2cc71331-6bb2-460a-8a7e-f5c4d0a7069a
md"""
# Model Inference
"""

# ╔═╡ 8e59220c-ce88-45ec-bd6b-358eba342133
md"""
## Load model and denoise phantom
"""

# ╔═╡ 14b9cc91-83e5-4ad5-9e32-9845f970eb51
md"""
Enter File Path to Upload Trained Model: 

$(@bind model_path confirm(TextField()))
"""

# ╔═╡ c321172c-07ce-4b9c-9268-dffaad9ba640
if (@isdefined model_path) && (model_path != "")
	trained_model = BDTools.Denoiser.load(model_path)
end;

# ╔═╡ d36a7cf2-9ca9-4afe-ae09-639b7081ef70
if (@isdefined model_path) && (model_path != "")
	let 
		i = 450
	    original = ori[:,:,i:i]
	    simulated = sim[:,:,i:i]
	    denoised = BDTools.denoise(model, original)
		
		f = Figure()
		ax = CairoMakie.Axis(
			f[1, 1],
			title = "Denoised Model"
		)
	
	
	    lines!(vec(simulated), label="prediction")
	    lines!(vec(original), label="original")
	    lines!(vec(denoised), label="denoised")
	
		axislegend(ax)
	
		f
	end
end

# ╔═╡ Cell order:
# ╟─2f58d100-4aac-4943-a433-f831067890ae
# ╟─e5eaba7c-3b1d-403b-88e1-0f1004efe784
# ╠═e0700b91-6663-4279-a544-c1ff5aea6723
# ╟─5c7abe91-4ab6-4155-a62d-3858f2335245
# ╠═72309c72-72ff-4835-bd93-9ed185a0f500
# ╟─4cf1d0e1-681f-4cb5-be14-55e3a968c745
# ╟─6995e379-717e-448c-9b66-93287feb6ae0
# ╟─c6637949-67bc-48e9-a3b3-21ab31ba0964
# ╠═6c4edc39-b5d3-4241-9493-0b0671731f88
# ╟─b6a6adac-33e0-43fa-8a78-4ac8e892cca0
# ╠═af675880-6c09-4b4d-8294-61ac7fd95b0e
# ╠═60559bbc-3ab6-47ef-b183-31abf4b7290b
# ╠═af76692c-37f4-4397-8a2f-09b817e22d7f
# ╟─ba8efdbd-a307-495b-871d-bceebdef5e84
# ╟─ec4976a3-6d9e-4a99-a91b-281ee2ec6986
# ╟─f431b64e-7045-4c76-902e-a81b3e4f2bcc
# ╠═9d4ebdb5-5511-4902-b1ca-1c1ea70e3252
# ╟─5f826726-1fde-4ab0-911a-0245b1038edb
# ╠═504670e7-0731-4852-b581-4307c5f1e6eb
# ╟─24c7815a-88e5-47b4-9359-c057294f88c3
# ╠═13145ff9-aa6e-40f6-b473-0acf2e6af58b
# ╟─9c3a1bcf-4185-4659-82fa-10a25388c33f
# ╟─4c8dc227-9a18-4dfb-ae5a-94d139c9d128
# ╠═492de824-dfd0-4420-9a1f-8f85d72a7504
# ╟─2cc71331-6bb2-460a-8a7e-f5c4d0a7069a
# ╟─8e59220c-ce88-45ec-bd6b-358eba342133
# ╟─14b9cc91-83e5-4ad5-9e32-9845f970eb51
# ╠═c321172c-07ce-4b9c-9268-dffaad9ba640
# ╟─d36a7cf2-9ca9-4afe-ae09-639b7081ef70
