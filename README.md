# BDGui.jl
Graphic User Interface (GUI) for the Braindancer Dynamic phantom. We acknowledge support for this package from the Center for Biotechnology, an Empire State Development Division of Science Technology and Innovation (NYSTAR) Center for Advanced Technology, and ALA Scientific Inc.

Installation Instructions
1) Install Julia from https://julialang.org/downloads/
2) Launch Julia
3) Install Pluto by going into the package manager (type "]")

   Pkg> add Pluto

   type "delete" to get back to the Julia prompt
4) Launch Pluto by

   julia> import Pluto

   julia> Pluto.run()
   
5) Go to your default web browser to see the Pluto notebook
6) Prepare analysis folder that should contain

   epi.nii               - phantom nifti file

   acq_times.csv         - acquisition times of the phantom scan

   log.csv               - log file from phantom scan

   time_series.jl        - fresh copy from BDGui.jl/local
   denoiser.jl           - fresh copy from BDGui.jl/local
   noisenet.jl           - fresh copy from BDGui.jl/local

7) Launch time_series.jl in Pluto notebook
8) Lerform time-series analysis and save results at the end
9) Launch denoiser.jl notebook to train a neural network on the scanner noise and save the neural net parameters
10) Launch noisenet.jl to clean human brain fMRIs using a mask


   
