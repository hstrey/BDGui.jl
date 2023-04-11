## Milestone 1
- Add three different file uploaders via `Stipple.jl` 
  - Accept only `.nii` file types (for now) for uploader1, and only `.csv` for the other two
- Display `.nii` files (input phantom) as a heatmap, via `niread()` and `StipplePlotly.jl`, with a `Slider` to scroll slice-by-slice
- Allow user to select "good slices" via `onclick`, and send the selected slice numbers to the server
- Run `BDTools.jl` code on server to compute B-field corrected 4-d phantom scan `corrected_phantom`, `slices.csv`
- Output `corrected_phantom` (in place of - or next to original phantom) as `heatmap` on frontend
- Output `slices.csv` from server and display as a table on frontend

## Milestone 2
- Gather necessary variables from Milestone 1
  - (1) Computer corrected phantom `corrected_phantom`
  - (2) Original `log.csv` (from uploader)
  - (3) Computed `slices.csv`
- Calculate necessary parameters for `BDTools.jl` to output ground truth time-series `gt_ts` and corresponding measured intensities
- Display ground truth time-series `gt_ts` via `StipplePlotly.jl`