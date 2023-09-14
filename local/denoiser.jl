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

# ╔═╡ ec23f1ff-5050-4e83-b6e4-7b7c43f5bbb4
# ╠═╡ show_logs = false
begin
	using Pkg
	Pkg.activate("..")

	using CairoMakie
	using PlutoUI
	using NIfTI
	using CUDA
	using Flux
	using BDTools
end

# ╔═╡ 4a4977b9-3d36-4cd0-83db-7614db5b2d0f
html"""
<html>
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
  box-shadow: 0 4px 8px 0 rgba(0, 0, 0, 0.2);
}

.header h1 {
  font-size: 2.5em;
  margin-bottom: 0.3em;
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

</html>
"""

# ╔═╡ 375d51fd-e2b4-4741-bf2e-bf0d30fb782e
md"""
# Load packages and files
"""

# ╔═╡ 67a5097d-5f2f-42d5-a58d-bd61bd3ff538
md"""
## Import Packages
"""

# ╔═╡ a9253e1b-686f-4752-98da-b9b8c95335af
TableOfContents()

# ╔═╡ afb61442-6760-43e4-91b3-3b09e2d81c15
md"""
## Loading data
"""

# ╔═╡ 97dee264-71f6-4256-970c-0c7bf5da0c57
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

# ╔═╡ a1cef4b6-2921-4368-973b-cadeb2235587
@bind up_files confirm(upload_files("Upload Phantom File", "Upload Ground Truth File"))

# ╔═╡ 8d8c0b39-2309-4d2a-b86a-6a2de2a6217b
phantomfile, groundtruthfile = up_files

# ╔═╡ 6ff1043e-2335-4469-92cf-c5cfa489e719
uploaded = phantomfile != "" && groundtruthfile != "";

# ╔═╡ 9cb8e5d1-7bc4-46c5-a88f-9f887a616f49
if uploaded
	gt, removeidx, sim, _ = BDTools.load_ground_truth(groundtruthfile)
	ori, _ = BDTools.load_phantom(gt, phantomfile; valid_slices = true, remove = removeidx)
end;

# ╔═╡ 12d45783-1d6c-4ee1-bc22-ab95b5531cda
md"""
# Train Model
"""

# ╔═╡ 5c863eb7-462a-4d30-8504-d122d0db0b6e
md"""
## Construct a denoiser model
"""

# ╔═╡ 1682dcba-e2e1-43d1-a795-cd186d14f26c
if CUDA.has_cuda()
	dev = Flux.gpu
	default = 200
else
	dev = Flux.cpu
	default = 20
end

# ╔═╡ 332ab1a8-1f2a-48e7-8cea-9eeda2a30880
md"""
Choose Number of Epochs: $(@bind epochs NumberField(default ÷ 2:default ÷ 10:default * 2; default = default))
"""

# ╔═╡ 6a9fe5de-7f8a-481f-8cc2-604a36e8f92e
model = DenoiseNet(BDTools.TrainParameters(; epochs = epochs); dev = dev)

# ╔═╡ 2fc31ba1-6ab5-4b27-9d6e-7c7f7a5634be
md"""
Start training: $(@bind start PlutoUI.CheckBox())
"""

# ╔═╡ a8b1edae-fc3f-4284-90be-19130dc8dc29
if start
	losses = BDTools.train!(model, sim, ori)
end

# ╔═╡ 52c893f4-ca0b-4bf7-b4c1-efdf39d92a69
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

# ╔═╡ 2cd9e521-352e-4e2d-9759-76efaac869ac
md"""
Enter File Path to Save Trained Model: 

$(@bind output_dir confirm(TextField()))
"""

# ╔═╡ b04f5dd8-1415-4a51-b5c9-820c4c7370ad
if output_dir != ""
	BDTools.Denoiser.save(joinpath(output_dir, "denoiser_model"), model)
end;

# ╔═╡ 7edfe114-e6a9-42db-a743-5c4f52f5434f
md"""
# Model Inference
"""

# ╔═╡ 0ec91b61-f1f6-4a9a-8390-9de90c7df421
md"""
## Load model and denoise phantom
"""

# ╔═╡ 45f66d99-fa2e-4669-8f54-c587f42464ec
md"""
Enter File Path to Upload Trained Model: 

$(@bind model_path confirm(TextField()))
"""

# ╔═╡ dfcd661a-0809-4b7c-8c4e-913f12f27760
if model_path != ""
	trained_model = BDTools.Denoiser.load(model_path)
end;

# ╔═╡ 9e4eed2f-aa20-45ee-9b0f-ac4968403469
if model_path != ""
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
# ╟─4a4977b9-3d36-4cd0-83db-7614db5b2d0f
# ╟─375d51fd-e2b4-4741-bf2e-bf0d30fb782e
# ╟─67a5097d-5f2f-42d5-a58d-bd61bd3ff538
# ╠═ec23f1ff-5050-4e83-b6e4-7b7c43f5bbb4
# ╠═a9253e1b-686f-4752-98da-b9b8c95335af
# ╟─afb61442-6760-43e4-91b3-3b09e2d81c15
# ╟─a1cef4b6-2921-4368-973b-cadeb2235587
# ╠═8d8c0b39-2309-4d2a-b86a-6a2de2a6217b
# ╠═6ff1043e-2335-4469-92cf-c5cfa489e719
# ╠═9cb8e5d1-7bc4-46c5-a88f-9f887a616f49
# ╟─97dee264-71f6-4256-970c-0c7bf5da0c57
# ╟─12d45783-1d6c-4ee1-bc22-ab95b5531cda
# ╟─5c863eb7-462a-4d30-8504-d122d0db0b6e
# ╠═1682dcba-e2e1-43d1-a795-cd186d14f26c
# ╟─332ab1a8-1f2a-48e7-8cea-9eeda2a30880
# ╠═6a9fe5de-7f8a-481f-8cc2-604a36e8f92e
# ╟─2fc31ba1-6ab5-4b27-9d6e-7c7f7a5634be
# ╠═a8b1edae-fc3f-4284-90be-19130dc8dc29
# ╟─52c893f4-ca0b-4bf7-b4c1-efdf39d92a69
# ╟─2cd9e521-352e-4e2d-9759-76efaac869ac
# ╠═b04f5dd8-1415-4a51-b5c9-820c4c7370ad
# ╟─7edfe114-e6a9-42db-a743-5c4f52f5434f
# ╟─0ec91b61-f1f6-4a9a-8390-9de90c7df421
# ╟─45f66d99-fa2e-4669-8f54-c587f42464ec
# ╠═dfcd661a-0809-4b7c-8c4e-913f12f27760
# ╟─9e4eed2f-aa20-45ee-9b0f-ac4968403469
