### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# ╔═╡ d1b04f49-471e-4603-9114-243165a9a26a
# ╠═╡ show_logs = false
begin
	using Pkg
	Pkg.add(url="https://github.com/hstrey/BDTools.jl")
	Pkg.add(["Plots", "NIfTI", "DelimitedFiles", "PlutoUI"])
	
	using BDTools
	using Plots
	using NIfTI
	using DelimitedFiles
	using PlutoUI
end

# ╔═╡ e4906e8d-ab33-4f52-9a50-b4a370da62b1
md"""
# Tutorial

Load libraries required for this tutorial.
"""

# ╔═╡ 080729a4-4906-4b8a-8c84-2e031dc51ce6
TableOfContents()

# ╔═╡ 4de25947-ad80-4f30-a4b3-b2e1b5d697e6
md"""
## Loading data

First, we load phantom data from a NIfTI formatted file.
"""

# ╔═╡ eda28346-cb70-4c53-8199-81532ae6fc04
begin
	const DATA_DIR = "/Users/daleblack/Desktop/BrainDancerProject/data"
	phantom_ts = niread(joinpath(DATA_DIR, "BFC_time_series.nii"));
	sz = size(phantom_ts)
end

# ╔═╡ 0066b927-8c3e-4d47-90d1-08a10b9bc0e0
md"""
Next, we load rotation angles from rotation data, and slice motion information.
"""

# ╔═╡ fd8e9d78-a118-47fd-9e09-f85b1acf2b8f
angles, firstrotidx = BDTools.getangles(joinpath(DATA_DIR,  "log.csv"))

# ╔═╡ 7d57840f-daad-43da-8486-a53653b483ec
sliceinfo, _ = readdlm(joinpath(DATA_DIR, "slices.csv"), ',', Int, header=true)

# ╔═╡ 6a499bc8-760b-4f39-8eb9-7f19d33572b7
md"""
## Construct static phantom

Use `staticphantom` function to construct a static phantom object
by providing phantom data time series and slice motion info.
Resulting object contains an ellipse fit for each slice of a static phantom.
"""

# ╔═╡ f52b6f5b-bf2a-458f-a9f5-ecd16e6ed790
sph = staticphantom(convert(Array, phantom_ts), sliceinfo);

# ╔═╡ 8fd8d0d5-9a1b-4cc1-8f1b-271b779b4234
md"""
### Show phantom center axis

Using phantom fitted ellipse parameters, we construct a phantom center axis (z-axis),
and fit ellipse centers on this axis.
"""

# ╔═╡ 16a3b242-cbb0-4a98-9408-cf9540e03cfb
let 
	ecs = BDTools.centers(sph)
	rng = collect(-1.:0.15:1.)
    # show original data
    p = scatter(ecs[:,1], ecs[:,2], label="centers", legend=:topleft)
    # show predicted phantom center axis
    cc = map(t->BDTools.predictcenter(sph, t), rng)
    plot!(p, map(first, cc), map(last, cc), label="axis")
    # project slice centers to a fitted center axis
    xy = BDTools.fittedcenters(sph)
    scatter!(p, xy[:,1], xy[:,2], label="fitted")
end

# ╔═╡ 8cc3293a-5118-4206-932c-487bcbe6f914
md"""
## Construct ground truth dataset

We can construct a ground truth data at any rotation angle.
Providing a rotation angle `α` and a slice coordinate `z`, we generate
a rotated phantom.
"""

# ╔═╡ 57b99ddf-e5de-44b7-b786-e1947a7c44c4
let 
	α = deg2rad(10)
	z = 3
    # get ellipse parameters at slice z
    origin, a, b = BDTools.getellipse(sph, z)
    # get a ellipse's initial rotation angle
    γ = BDTools.findinitialrotation(sph, z)

    # Coordinate transformation
    coords = [BDTools.ellipserot(α, γ, a, b)*([i,j,z].-origin).+origin for i in 1:sz[1], j in 1:sz[2]]
    # interpolate intensities
    sim = map(c->sph.interpolation(c...), coords)
    # generate image
    gen = BDTools.Images.Colors.Gray.(sim |> BDTools.genimg)
    # show averaged image
    ave = BDTools.Images.Colors.Gray.(sph.data[:,:,z] |> BDTools.genimg)
    pave = plot(ave, aspect_ratio=1.0, axis=nothing, framestyle=:none, title="Slice $z", size=(300,350))
    # show generated image
    pgen = plot(gen, aspect_ratio=1.0, axis=nothing, framestyle=:none, title="Rotated at $(rad2deg(α))°", legend=:none)
    plot(pave, pgen)
end

# ╔═╡ 39de5d21-f3fd-4c0b-897f-6f4b6c00205c
md"""
## Generate rotated predictions

For a rotation information, we can generate a predictions of rotated phantoms.
"""

# ╔═╡ bca7d56b-227a-4575-a6be-319ae2d01779
res = BDTools.groundtruth(sph, phantom_ts, angles; startmotion=firstrotidx, threshold=.95);

# ╔═╡ b8c2ce83-2459-437c-94e0-121f6468d5d2
md"""
and plot prediction and original data
"""

# ╔═╡ 24c5458b-a2bd-4f72-8303-a65603742f6c
let 
	x = 42
	y = 52
	z = 3 # get coordinates
    data, sliceidx, maskcoords = res;

    # get a coordinate index
    c = CartesianIndex(x,y)
    cidx = findfirst(m->m == c, maskcoords)
    cidx === nothing && return

    # plot data
    plot(data[:, cidx, z, 1], label="prediction", title="Intensity")
    plot!(data[:, cidx, z, 2], label="original")
end

# ╔═╡ Cell order:
# ╟─e4906e8d-ab33-4f52-9a50-b4a370da62b1
# ╠═d1b04f49-471e-4603-9114-243165a9a26a
# ╠═080729a4-4906-4b8a-8c84-2e031dc51ce6
# ╟─4de25947-ad80-4f30-a4b3-b2e1b5d697e6
# ╠═eda28346-cb70-4c53-8199-81532ae6fc04
# ╟─0066b927-8c3e-4d47-90d1-08a10b9bc0e0
# ╠═fd8e9d78-a118-47fd-9e09-f85b1acf2b8f
# ╠═7d57840f-daad-43da-8486-a53653b483ec
# ╟─6a499bc8-760b-4f39-8eb9-7f19d33572b7
# ╠═f52b6f5b-bf2a-458f-a9f5-ecd16e6ed790
# ╟─8cc3293a-5118-4206-932c-487bcbe6f914
# ╠═57b99ddf-e5de-44b7-b786-e1947a7c44c4
# ╟─8fd8d0d5-9a1b-4cc1-8f1b-271b779b4234
# ╠═16a3b242-cbb0-4a98-9408-cf9540e03cfb
# ╟─39de5d21-f3fd-4c0b-897f-6f4b6c00205c
# ╠═bca7d56b-227a-4575-a6be-319ae2d01779
# ╟─b8c2ce83-2459-437c-94e0-121f6468d5d2
# ╠═24c5458b-a2bd-4f72-8303-a65603742f6c
