[
    heading("Brain Dancer GUI")
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
        cell(class="st-module", [
            h6("Select fMRI")
            Stipple.select(:selected_file_image; options=:upfiles)
        ])
        cell(class="st-module", [
            h6("Select Logs")
            Stipple.select(:selected_file_log; options=:upfiles)
        ])
        cell(class="st-module", [
            h6("Select Acquisition Times")
            Stipple.select(:selected_file_acq; options=:upfiles)
        ])
    ])
    row([
        cell(
            class="st-module",
            [
                h5("fMRI ({{selected_file_image}})")
                plot(:hmap, layout=:layout)
            ]
        )
    ])
] |> string