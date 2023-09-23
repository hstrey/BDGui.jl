### A Pluto.jl notebook ###
# v0.19.27

#> [frontmatter]
#> title = "Brain Dancer GUI"
#> sidebar = "false"

using Markdown
using InteractiveUtils

# ╔═╡ 535d5388-0672-47f9-8243-176838c59bf6
using HypertextLiteral

# ╔═╡ a4679185-2610-485c-942c-3b7bdbf68f80
html"""
<head>
	<link rel="preconnect" href="https://fonts.googleapis.com">
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
	<link href="https://fonts.googleapis.com/css2?family=Alegreya+Sans:ital,wght@0,400;0,700;1,400&family=Vollkorn:ital,wght@0,400;0,700;1,400;1,700&display=swap" rel="stylesheet">
	<link href="https://cdn.jsdelivr.net/npm/daisyui@3.7.4/dist/full.css" rel="stylesheet" type="text/css" />
	<script src="https://cdn.tailwindcss.com"></script>
</head>

<div class="bg-transparent dark:bg-[#1f1f1f]">
	<div id="BrainDancerHeader" class="flex justify-center items-center">
		<div class="header card bg-[#ADD8E6] text-center">
			<div class="card-body">
				<img src="https://alascience.com/wp-content/uploads/2020/07/Logo-registered-trademark.jpg" alt="Brain Dancer Logo" class="mx-auto rounded-md max-w-[150px] my-2">
				<h1 class="card-title text-[2.5em] font-serif">BrainDancer</h1>
				<p class="card-text text-[1.2em]">Data analysis notebooks for the BrainDancer Dynamic Phantom.</p>
			</div>
		</div>
	</div>
</div>
"""

# ╔═╡ 17ccdf35-b187-4ce1-a78c-50b64d35ec27
struct Article
	title::String
	path::String
	image_url::String
end

# ╔═╡ 08e35276-f0e2-4a74-b1c0-4193a4004cd4
article_list = Article[
	Article("Time Series Analysis", "tutorials/time_series.jl", "https://images.unsplash.com/photo-1501139083538-0139583c060f?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2670&q=80"),
	Article("Neural Network Denoiser", "tutorials/denoiser.jl", "https://images.unsplash.com/photo-1545987796-200677ee1011?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=2670&q=80"),
];

# ╔═╡ c3c98d68-1ca2-4433-abd5-fb530e2bd3cf
function ArticleTile(article)
	@htl("""
	<a href="$(article.path)" class="card bordered hover:shadow-lg" style="border-color: #ADD8E6;">
		<div class="card-body">
			<h2 class="card-title">$(article.title)</h2>
			<p>Click to open the notebook.</p>
		</div>
		<figure>
			<img src="$(article.image_url)" alt="$(article.title)">
		</figure>
	</a>
	""")
end;

# ╔═╡ c627a83e-ad20-4bc6-aa5e-05065509e768
@htl("""
<link href="https://cdn.jsdelivr.net/npm/daisyui@3.7.4/dist/full.css" rel="stylesheet" type="text/css" />
<script src="https://cdn.tailwindcss.com"></script>

<div class="grid grid-cols-2 gap-4">
	$([ArticleTile(article) for article in article_list])
</div>
""")

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
HypertextLiteral = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"

[compat]
HypertextLiteral = "~0.9.4"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.0-beta2"
manifest_format = "2.0"
project_hash = "fc304fba520d81fb78ea25b98f5762b4591b1182"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.Tricks]]
git-tree-sha1 = "aadb748be58b492045b4f56166b5188aa63ce549"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.7"
"""

# ╔═╡ Cell order:
# ╟─a4679185-2610-485c-942c-3b7bdbf68f80
# ╟─c627a83e-ad20-4bc6-aa5e-05065509e768
# ╟─535d5388-0672-47f9-8243-176838c59bf6
# ╟─17ccdf35-b187-4ce1-a78c-50b64d35ec27
# ╟─08e35276-f0e2-4a74-b1c0-4193a4004cd4
# ╟─c3c98d68-1ca2-4433-abd5-fb530e2bd3cf
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
