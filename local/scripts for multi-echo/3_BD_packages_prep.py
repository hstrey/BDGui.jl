# import packages
import os
import glob
import sys
import nibabel as nib
import numpy as np
import pandas as pd
import shutil
import json
import re

root = sys.argv[1]
log_root = sys.argv[2]
output_dir = sys.argv[3]

nifti_out_temp = os.path.join(output_dir, 'nifti_temp')
log_out_temp = os.path.join(output_dir, 'log_temp')

os.makedirs(nifti_out_temp, exist_ok=True)
os.makedirs(log_out_temp, exist_ok=True)

file_ls = glob.glob(root + '/**/*.nii*', recursive=True)

# remove Localizer from the list
file_ls = [x for x in file_ls if 'Localizer' not in x]

# remove files that are less than 100MB
file_ls = [x for x in file_ls if os.path.getsize(x) > 100000000]

print(file_ls)

for img_path in file_ls:
    if 'TE1' in img_path:
        static_path_ls = [x for x in file_ls if 'e1' in x]
    elif 'TE2' in img_path:
        static_path_ls = [x for x in file_ls if 'e2' in x]
    elif 'TE3' in img_path:
        static_path_ls = [x for x in file_ls if 'e3' in x]
    else:
        continue
    img = nib.load(img_path)

    # check if the image is 4d
    if len(img.shape) != 4:
        continue

    # go thru static_path_ls and find the file with biggest size
    static_path = max(static_path_ls, key=os.path.getsize)

    # find the path in file_ls that contains e1
    
    # load the img
    static = nib.load(static_path)

    # laod the json file by replacing the nii with json in static_path
    json_path = static_path.replace('nii.gz', 'json').replace('nii', 'json')

    # append img to e1
    static_data = static.get_fdata()[:,:,:,:400]
    # print shape
    print(static_data.shape)
    img_data = img.get_fdata()[:,:,:,:400]
    print(img_data.shape)
    static_data = np.concatenate((static_data, img_data), axis=-1)
    print(static_data.shape)

    header = static.header
    header['dim'][4] = static_data.shape[-1]

    # save the new e1
    static_data = nib.Nifti1Image(static_data, static.affine, header)
    nib.save(static_data, os.path.join(nifti_out_temp, os.path.basename(img_path)))

    # copy the json to the outpath
    json_outpath = os.path.join(nifti_out_temp, os.path.basename(img_path).replace('nii.gz', 'json').replace('nii', 'json'))
    os.system(f'cp {json_path} {json_outpath}')

log_ls = glob.glob(log_root + '/*.csv')

static_log_path = [file for file in log_ls if 'static' in file][0]

static_log = pd.read_csv(static_log_path, skiprows=2, index_col=0).reset_index()[:400]

for log_path in log_ls:
    if 'static' in log_path:
        continue
    log = pd.read_csv(log_path, skiprows=2, index_col=0).reset_index()
    log.loc[5:,'Seq#'] = log.loc[5:,'Seq#'] + 5

    log = pd.concat([static_log, log], axis=0)
    log.to_csv(os.path.join(log_out_temp,os.path.basename(log_path)), index=False)

# find files in log folder
log_files = glob.glob(log_out_temp + '/*sequence.csv')

# find folders in nifti folder
nifti_files = glob.glob(nifti_out_temp + '/*.nii*')

for nifti_path in nifti_files:
    filename = nifti_path.split('/')[-1]

    # Define the pattern to search for *E{d1}*
    pattern = r'TE\d+'

    # Search for the pattern in the filename
    match = re.search(pattern, filename)

    echo = match[0].lower()
    
    log_file = [file for file in log_files if echo in file][0]
    out_folder_temp = os.path.join(output_dir, echo + '/')
    os.makedirs(out_folder_temp, exist_ok=True)

    log_out = os.path.join(out_folder_temp, 'log.csv')
    if 'nii.gz' in nifti_path:
        nifti_out = os.path.join(out_folder_temp, 'epi.nii.gz')
    else:
        nifti_out = os.path.join(out_folder_temp, 'epi.nii')
    acq_out = os.path.join(out_folder_temp, 'acq_times.csv')

    log_df = pd.read_csv(log_file, skiprows=0, index_col=0).reset_index()

    log_df['Seq#'] = range(1, len(log_df)+1)
    log_df.index = log_df['Seq#']
    log_df.drop(columns=['Seq#'],inplace=True)

    # Define a regular expression pattern to match strings inside parentheses with a length more than 1 unit
    pattern = r'\(([^)]{2,})\)'

    # Rename columns based on the pattern
    log_df.columns = [re.search(pattern, col).group(1) if re.search(pattern, col) else col for col in log_df.columns]

    log_df.to_csv(log_out)

    if not os.path.exists(nifti_out):
        print('Processing: ', nifti_path)
        json_path = nifti_path.replace('nii.gz', 'json').replace('nii', 'json')
        # Open the JSON file for reading
        with open(json_path, 'r') as file:
            # Load the JSON data into a Python object
            data = json.load(file)

        out_time = data['SliceTiming']
        out_df = pd.DataFrame(out_time).reset_index()
        out_df.columns = ['Slice','Time']
        out_df['Time'] = out_df['Time']*1000
        out_df.index = out_df['Time'].astype('int')
        out_df = out_df.drop(columns=['Time'])

        out_df.to_csv(acq_out)
        
        shutil.copy(nifti_path, nifti_out)

