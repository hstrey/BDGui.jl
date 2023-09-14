### A Pluto.jl notebook ###
# v0.19.26

#> [frontmatter]
#> title = "Brain Dancer GUI"
#> sidebar = "false"

using Markdown
using InteractiveUtils

# ╔═╡ 535d5388-0672-47f9-8243-176838c59bf6
using HypertextLiteral

# ╔═╡ a4679185-2610-485c-942c-3b7bdbf68f80
md"""
# Brain Dancer GUI
"""

# ╔═╡ 4b362eb2-ae9b-4afe-a5c0-5c74e7433b7d
struct Article
	title::String
	path::String
end

# ╔═╡ dd8c2bbf-f077-4a51-88bd-bf58689738ec
article_list = Article[
	Article("Time Series Anaysis", "tutorials/time_series.jl"),
	Article("Neural Network Denoiser", "tutorials/denoiser.jl"),
];

# ╔═╡ 5e154989-66e9-4a6e-9eba-6d9e92f055b4
function ArticleTile(article)
	@htl("""
	<div class="ArticleTile">
		<a href="$(article.path)">
			$(article.title)
		</a>
	</div>
	""")
end;

# ╔═╡ 5ee28794-9029-482d-90e7-7829ec0b9c1f
@htl("""
<div class = "ArticleList">
	$([ArticleTile(article) for article in article_list])
</div>
""")

# ╔═╡ 75b6b00c-f63e-4111-92a0-4e8cb2cd9ca1
@htl("""
<style>
	.ArticleList {
		display: flex;
		flex-direction: column;
	}
	.ArticleTile {
		margin-top: 15px;
		border-radius: 15px;
		background-color: #efefef;
	}
	.ArticleTile > a {
		width: 100%;
		display: block;
		padding: 20px;
		text-decoration: none;
	}
	.ArticleTile > a:hover {
		text-decoration: underline;
	}
</style>
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

julia_version = "1.9.3"
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
# ╠═535d5388-0672-47f9-8243-176838c59bf6
# ╟─a4679185-2610-485c-942c-3b7bdbf68f80
# ╠═4b362eb2-ae9b-4afe-a5c0-5c74e7433b7d
# ╠═dd8c2bbf-f077-4a51-88bd-bf58689738ec
# ╠═5e154989-66e9-4a6e-9eba-6d9e92f055b4
# ╠═5ee28794-9029-482d-90e7-7829ec0b9c1f
# ╠═75b6b00c-f63e-4111-92a0-4e8cb2cd9ca1
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
