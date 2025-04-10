source 1_root_navigator.sh
#root="put your path by hand"

source 1_log_root_navigator.sh
#log_root="put your path by hand"

source 1_outputdir_request.sh
#output_dir="put your path by hand"

./2_dcm2niix.sh "$root"

python3 3_BD_packages_prep.py "$root" "$log_root" "$output_dir"

echo "Done. Next, run denoiser.ipynb using (ignore log_temp and nifti_temp):"
find $output_dir -mindepth 1 -maxdepth 1 -type d
