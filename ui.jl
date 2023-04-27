[
    heading("{{title}}")
    row([
        cell(class="st-module", [
            uploader(label="Upload fMRI", accpt=".nii", multiple=true, method="POST", url="http://localhost:8000/", field__name="nii_image")
        ])
        cell(class="st-module", [
            uploader(label="Upload Logs", accpt=".csv", multiple=true, method="POST", url="http://localhost:8000/", field__name="csv_logs")
        ])
        cell(class="st-module", [
            uploader(label="Upload Acquisition Times", accpt=".csv", multiple=true, method="POST", url="http://localhost:8000/", field__name="csv_acq")
        ])
    ])
    row([
        cell(
            class="st-module",
            [
                h6("File")
                Stipple.select(:selected_file_image; options=:upfiles)
                slider(:z_slices, :selected_z_slice)
                slider(:t_slices, :selected_t_slice)
            ]
        )
        cell(
            class="st-module",
            [
                h5("fMRI ({{selected_file}})")
                # slider(:slice; min=1, max=100, step=1, value=10)
                plot(:hmap, layout=:layout)
            ]
        )
    ])
] |> string