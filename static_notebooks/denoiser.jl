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

# ╔═╡ 03e55164-f578-4001-9e6c-65f9f81321e5
# ╠═╡ show_logs = false
begin
	using Pkg
	Pkg.activate(temp = true)
	Pkg.add("CairoMakie")
	Pkg.add("PlutoUI")
	Pkg.add("NIfTI")
	Pkg.add("cuDNN")
	Pkg.add("CUDA")
	Pkg.add("Flux")
	Pkg.add(url="https://github.com/hstrey/BDTools.jl", rev="denoiser")

	using CairoMakie
	using PlutoUI
	using NIfTI
	using CUDA
	using Flux
	using BDTools
end

# ╔═╡ 72a1fcb5-39c6-47ff-b677-ec7a50b5d5e4
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

# ╔═╡ 4243e56a-e1f3-49d2-bd99-b73f6759823d
md"""
# Load packages and files
"""

# ╔═╡ bd41a744-196d-42ee-8d7a-be941fa8de5c
md"""
## Import Packages
"""

# ╔═╡ 010569ca-d4d3-4940-9925-b5927fa48dab
TableOfContents()

# ╔═╡ 179154a0-efa1-432b-a697-c1c8b333e65e
md"""
## Loading data
"""

# ╔═╡ b3498286-be06-4108-a2e1-bbbcc9a8dd78
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

# ╔═╡ 9854ae01-b2a5-432a-a59b-774d495b9ace
@bind up_files confirm(upload_files("Upload Phantom File", "Upload Ground Truth File"))

# ╔═╡ b0b268db-bbab-4dc8-9382-53e7f0baf740
phantomfile, groundtruthfile = up_files

# ╔═╡ 4a710900-6cfa-4cc3-8937-1aedbf0cf75b
uploaded = phantomfile != "" && groundtruthfile != "";

# ╔═╡ 7ed271b8-5718-4a92-b34f-197627b1202b
if uploaded
	phtm_file = download(phantomfile)
	gt_file = download(groundtruthfile)
end;

# ╔═╡ c4bc3195-7762-403f-87aa-81d3a4ba2fa5
if uploaded
	gt, removeidx, sim, _ = BDTools.load_ground_truth(gt_file)
	ori, _ = BDTools.load_phantom(gt, download(phantomfile); valid_slices = true, remove = removeidx)
end;

# ╔═╡ 12010cc9-457b-47e7-bdd1-c9e20a37754e
md"""
# Train Model
"""

# ╔═╡ bcc2e1b7-9e3e-4709-b73d-40db4cb0684f
md"""
## Construct a denoiser model
"""

# ╔═╡ 1b2df002-d6eb-4e89-b04f-5c7781df6b61
if CUDA.has_cuda()
	dev = Flux.gpu
	default = 200
else
	dev = Flux.cpu
	default = 20
end

# ╔═╡ 517005e8-022b-4d7d-ba97-a77a37a6d950
md"""
Choose Number of Epochs: $(@bind epochs NumberField(default ÷ 2:default ÷ 10:default * 2; default = default))
"""

# ╔═╡ c8a1d7c0-18ae-4704-904f-57f54b890601
model = DenoiseNet(BDTools.TrainParameters(; epochs = epochs); dev = dev)

# ╔═╡ 7704e48b-2402-42b7-ba7a-3077e7b69fcb
md"""
Start training: $(@bind start PlutoUI.CheckBox(default = true))
"""

# ╔═╡ 70552a19-26df-494c-8ec5-38f8bcc16297
if start
	losses = BDTools.train!(model, sim, ori)
end

# ╔═╡ f80f563a-ffd9-42d8-a801-25e119bf8906
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

# ╔═╡ 44694799-63dc-42a6-a156-bad4ef378754
md"""
Enter File Path to Save Trained Model: 

$(@bind output_dir confirm(TextField()))
"""

# ╔═╡ 17d1f293-35fd-4fb7-826d-0a454ecc6f56
if output_dir != ""
	BDTools.Denoiser.save(joinpath(output_dir, "denoiser_model"), model)
end;

# ╔═╡ 9e738395-c245-4fc1-8652-cf703384a7f9
md"""
# Model Inference
"""

# ╔═╡ 23893a9b-7f0a-44e3-a786-21b0e81a5cde
md"""
## Load model and denoise phantom
"""

# ╔═╡ 43bee9e2-d10b-4f76-9fdc-ed21562ee0ce
md"""
Enter File Path to Upload Trained Model: 

$(@bind model_path confirm(TextField(; default = "https://www.dropbox.com/scl/fi/9uav2ocexq7ttt3afue9r/denoiser_model.bson?rlkey=liz4y28cd188qe2a3mvjuqt1q&dl=0")))
"""

# ╔═╡ 3b47b0b2-599f-40e1-b505-8d01b9a17cc0
if model_path != ""
	trained_model = BDTools.Denoiser.load(download(model_path))
end;

# ╔═╡ efdd4b3f-9554-4729-98d1-26415da417bb
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
# ╟─72a1fcb5-39c6-47ff-b677-ec7a50b5d5e4
# ╟─4243e56a-e1f3-49d2-bd99-b73f6759823d
# ╟─bd41a744-196d-42ee-8d7a-be941fa8de5c
# ╠═03e55164-f578-4001-9e6c-65f9f81321e5
# ╠═010569ca-d4d3-4940-9925-b5927fa48dab
# ╟─179154a0-efa1-432b-a697-c1c8b333e65e
# ╟─9854ae01-b2a5-432a-a59b-774d495b9ace
# ╠═b0b268db-bbab-4dc8-9382-53e7f0baf740
# ╠═4a710900-6cfa-4cc3-8937-1aedbf0cf75b
# ╠═7ed271b8-5718-4a92-b34f-197627b1202b
# ╠═c4bc3195-7762-403f-87aa-81d3a4ba2fa5
# ╟─b3498286-be06-4108-a2e1-bbbcc9a8dd78
# ╟─12010cc9-457b-47e7-bdd1-c9e20a37754e
# ╟─bcc2e1b7-9e3e-4709-b73d-40db4cb0684f
# ╠═1b2df002-d6eb-4e89-b04f-5c7781df6b61
# ╟─517005e8-022b-4d7d-ba97-a77a37a6d950
# ╠═c8a1d7c0-18ae-4704-904f-57f54b890601
# ╟─7704e48b-2402-42b7-ba7a-3077e7b69fcb
# ╠═70552a19-26df-494c-8ec5-38f8bcc16297
# ╟─f80f563a-ffd9-42d8-a801-25e119bf8906
# ╟─44694799-63dc-42a6-a156-bad4ef378754
# ╠═17d1f293-35fd-4fb7-826d-0a454ecc6f56
# ╟─9e738395-c245-4fc1-8652-cf703384a7f9
# ╟─23893a9b-7f0a-44e3-a786-21b0e81a5cde
# ╟─43bee9e2-d10b-4f76-9fdc-ed21562ee0ce
# ╠═3b47b0b2-599f-40e1-b505-8d01b9a17cc0
# ╟─efdd4b3f-9554-4729-98d1-26415da417bb
