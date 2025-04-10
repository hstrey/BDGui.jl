
# Check if root argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <root_directory>"
    exit 1
fi

# Assign the first argument to root
root="$1"

# Process DICOM folders
for d in $(find "$root" -type d -name 'DICOM'); do
    # Get the parent folder
    parent=$(dirname "$d")
    # Get the output folder
    outdir="$parent/nifti/"
    indir="$d/"
    # Create the output folder
    mkdir -p "$outdir"
    # Run dcm2niix
    dcm2niix -o "$outdir" "$d"
done