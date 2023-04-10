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
                Stipple.select(:selected_file; options=:upfiles)
            ]
        )])
    row([
        cell(
            class="st-module",
            [
                h5("Image Viewer")
                plot(:image_viewer)
            ]
        )
    ])
] |> string