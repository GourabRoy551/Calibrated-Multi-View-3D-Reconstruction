# Section 2 Completion Plan

This file is a focused plan to finish Section 2 of the lab evaluation using the requirements from `PLAN.md` and `LabFinal.pdf`.

Target outputs:

- A standalone script: `Roy_Gourab_2.m`
- Section 2 report draft for now: `Roy_Gourab.docx`
- Final report later: `Roy_Gourab.pdf`
- Saved numeric, metadata, and visual outputs in `results/section_2/`

Current status from the folder:

- Current script: `Roy_Gourab_2.m`
- Section 1 outputs are available in `results/section_1/`
- Scene image folder exists: `images/scene/`
- Section 2 output folder exists: `results/section_2/`
- Scene images available: 6 views in `images/scene/`
- `Roy_Gourab_2.m` has been implemented and tested end to end
- Current generated outputs exist in `results/section_2/`
- Still pending: user rerun if desired, verify final outputs, then write Section 2 in the DOCX report

---

## 0. Required Section 2 Output Folder

All values, metadata, and figures needed for writing the Section 2 report must be saved inside:

- `results/section_2/`

This includes numerical matching values and also image-related values used in the report, such as:

- scene image filenames
- original image resolution
- resized image resolution, if resizing is used
- scale factor applied to Section 1 intrinsic matrix `A`
- selected image pairs
- detector/descriptor/matcher setup names and parameters
- number of keypoints per image
- number of raw matches
- number of homography inliers
- homography residuals
- estimated homography matrices
- number of fundamental-matrix inliers
- fundamental matrices
- Sampson or epipolar errors
- runtime per setup
- per-octave SIFT match counts and quality values
- best selected pair and best setup
- paths of saved figures

Recommended files to create:

- `results/section_2/scene_montage.png`
- `results/section_2/section2_metrics.mat`
- `results/section_2/section2_report_values.txt`
- `results/section_2/setup_comparison.csv`
- `results/section_2/best_matches.png`
- `results/section_2/best_panorama.png`
- `results/section_2/best_homography.txt`
- `results/section_2/best_fundamental_matrix.txt`
- `results/section_2/per_octave_results.png`
- `results/section_2/vgg_gui_F_best_pair.png`

The goal is that the DOCX report can be written directly from `results/section_2/`, without hunting through MATLAB console output.

---

## 1. What "Section 2 Complete" Means

Section 2 is complete only when all of the following are true:

1. `Roy_Gourab_2.m` runs from `clear all` without relying on manual leftovers.
2. Scene images exist in `images/scene/`.
3. The script loads the Section 1 screen-calibration intrinsic matrix `A` from `results/section_1/A_screen.mat`.
4. If scene images are resized, the script saves the resized image size and the scaled intrinsic matrix.
5. The script generates a scene montage.
6. The script evaluates multiple representative image pairs.
7. The script evaluates at least three detector/descriptor/matching setups, unless toolbox availability forces a documented fallback.
8. The script performs the required SIFT per-octave experiment.
9. The script estimates homographies and fundamental matrices for evaluated setups.
10. The script selects the best four pair/setup combinations.
11. The script saves all report values and figures under `results/section_2/`.
12. `Roy_Gourab.docx` contains Section 2 subsections `2(a)`, `2(b)`, and `2(c)`.
13. Section 2 stays within the assignment limit of at most four report pages.

---

## 2. Exact Section 2 Requirements

### 2.1 Object/Scene Capture

Required by the assignment:

- Use the camera calibrated in Section 1.
- Keep intrinsics fixed: no zoom, no focal distance changes, and no aspect-ratio changes.
- Capture several views of one object or scene.
- Prefer textured 3D objects with sharp rectilinear contours.
- Vary camera angle and distance.
- Preserve enough image overlap for matching.
- Optional but useful: include lighting, shadow, or occlusion changes for discussion.

Recommended capture target:

- 6 to 10 images
- save as `images/scene/view_01.jpg`, `view_02.jpg`, etc.
- use the same camera settings as Section 1
- avoid pure rotation; translate the camera between views
- keep at least 50% overlap between consecutive views

Current action needed:

- add the captured scene images to `images/scene/`

### 2.2 Detection, Description, and Matching

Required by the assignment:

- Select representative pairs of views, not every possible pair.
- Extract and describe feature points for each selected view.
- Match feature points between each pair.
- Estimate a homography for each selected pair/setup.
- Repeat matching using points from each octave separately and discuss the effect.
- Estimate a fundamental matrix for each selected pair/setup.
- Use qualitative and quantitative indicators to choose the best setups.
- Use `vgg_gui_F.m` to inspect the estimated fundamental matrix quality.

Recommended evaluated setups:

- `SIFT + VLFeat vl_ubcmatch`
- `SURF + matchFeatures`
- `ORB + matchFeatures` or `KAZE + matchFeatures`

Fallback rule:

- If one toolbox method is unavailable, document the fallback in `section2_report_values.txt` and still compare at least three meaningful setups if possible, for example different SIFT thresholds or matching thresholds.

### 2.3 Selection

Required by the assignment:

- Choose the best four pairs of views and function setups according to the results.
- For the best combination only, include:
  - image pair with correspondences overlaid
  - estimated homography
  - panoramic image
  - estimated fundamental matrix
  - screenshot from `vgg_gui_F.m`

---

## 3. Code Work Needed in `Roy_Gourab_2.m`

### 3.1 Startup and Folders

The script should start with:

```matlab
clear all; close all; clc;
addpath(genpath('./lib'));
addpath(genpath('./vlfeat-0.9.21'));
run('vl_setup');
```

Then create:

```matlab
section_dir = fullfile('results', 'section_2');
if ~exist(section_dir, 'dir')
    mkdir(section_dir);
end
```

### 3.2 Load Section 1 Intrinsics

Load:

- `results/section_1/A_screen.mat`

Use the screen-calibration matrix `A`, because Section 1 showed it was more reliable than `A_prime`.

If images are resized, save:

- original width and height
- resized width and height
- scale factor
- `A_scaled`

Use:

```matlab
s = new_W / orig_W;
A_scaled = A;
A_scaled(1:2,:) = s * A(1:2,:);
```

### 3.3 Read Scene Images

The script should:

1. Read all images from `images/scene/`.
2. Sort filenames consistently.
3. Stop with a clear error if fewer than 4 scene images exist.
4. Save scene image metadata:
   - filenames
   - original size
   - resized size if applicable
   - scale factor
5. Build and save the montage:
   - `results/section_2/scene_montage.png`

### 3.4 Select Representative Pairs

Choose 3 to 5 representative pairs:

- adjacent pair, for example `view_01` and `view_02`
- medium-baseline pair, for example `view_02` and `view_04`
- wide-baseline pair, for example `view_01` and `view_05`
- challenging pair, if lighting or occlusion changes are present

Save:

- selected pair indices
- selected pair filenames
- reason for each pair selection

### 3.5 Implement Feature Pipelines

For each selected pair, run each setup:

1. `SIFT + VLFeat`
   - detect with `vl_sift`
   - match with `vl_ubcmatch`
   - apply ratio threshold if implemented manually, or use VLFeat scores
2. `SURF`
   - `detectSURFFeatures`
   - `extractFeatures`
   - `matchFeatures`
3. `ORB` or `KAZE`
   - `detectORBFeatures` or `detectKAZEFeatures`
   - `extractFeatures`
   - `matchFeatures`

For every pair/setup, save:

- number of keypoints in image 1
- number of keypoints in image 2
- number of raw matches
- matched point coordinates
- runtime

### 3.6 Homography Estimation

For every pair/setup:

1. Estimate homography using RANSAC:
   - `estimateGeometricTransform2D`
2. Save:
   - homography matrix `H`
   - number of inliers
   - inlier ratio
   - mean residual on inliers
   - matched-points figure for important pairs

Recommended output:

- save all homographies in `section2_metrics.mat`
- save best homography as `best_homography.txt`

### 3.7 Fundamental Matrix Estimation

For every pair/setup:

1. Estimate fundamental matrix:

```matlab
[F, inliers] = estimateFundamentalMatrix(pts1, pts2, ...
    'Method', 'RANSAC', ...
    'DistanceThreshold', 1e-3);
```

2. Save:
   - `F`
   - number of inliers
   - inlier ratio
   - mean Sampson or epipolar error
   - visual inspection result from `vgg_gui_F`

Recommended output:

- save all fundamental matrices in `section2_metrics.mat`
- save best fundamental matrix as `best_fundamental_matrix.txt`

### 3.8 Per-Octave SIFT Experiment

The assignment requires this.

For the best or most representative pair:

1. Run SIFT.
2. Group SIFT keypoints by octave or scale.
3. Match points using only one octave group at a time.
4. For each octave, estimate `H` and `F` if enough matches exist.
5. Save:
   - octave ID
   - keypoint count
   - raw match count
   - homography inlier count
   - fundamental-matrix inlier count
   - residual/error values
6. Save a plot or table:
   - `results/section_2/per_octave_results.png`

Important note:

- In VLFeat, `f(3,:)` gives the keypoint scale. The existing `PLAN.md` suggests using `floor(log2(scale))` as a practical octave grouping.

### 3.9 Best Combination Outputs

For the single best pair/setup, save:

- `results/section_2/best_matches.png`
- `results/section_2/best_panorama.png`
- `results/section_2/best_homography.txt`
- `results/section_2/best_fundamental_matrix.txt`
- `results/section_2/vgg_gui_F_best_pair.png`

For the panorama:

- use the estimated homography and either MATLAB warping or the Lab1 `stitch_vmmc` reference if available

For `vgg_gui_F`:

- run `vgg_gui_F(I1, I2, F_best)`
- take a screenshot manually if the GUI cannot be exported automatically
- save the screenshot as `results/section_2/vgg_gui_F_best_pair.png`

### 3.10 Save Report-Ready Values

Save:

- `results/section_2/section2_metrics.mat`
- `results/section_2/section2_report_values.txt`
- `results/section_2/setup_comparison.csv`

Suggested structure in `section2_metrics.mat`:

- `scene.image_files`
- `scene.image_width`
- `scene.image_height`
- `scene.scale_factor`
- `scene.A_used`
- `pairs`
- `setups`
- `results(pair_idx, setup_idx).keypoints_1`
- `results(pair_idx, setup_idx).keypoints_2`
- `results(pair_idx, setup_idx).raw_matches`
- `results(pair_idx, setup_idx).homography`
- `results(pair_idx, setup_idx).homography_inliers`
- `results(pair_idx, setup_idx).homography_residual`
- `results(pair_idx, setup_idx).fundamental_matrix`
- `results(pair_idx, setup_idx).fundamental_inliers`
- `results(pair_idx, setup_idx).fundamental_error`
- `results(pair_idx, setup_idx).runtime_seconds`
- `octave_results`
- `best.pair`
- `best.setup`
- `best.H`
- `best.F`
- `best.figure_paths`

---

## 4. Recommended Implementation Order

1. Capture and place scene images in `images/scene/`.
2. Create `results/section_2/`.
3. Update `Roy_Gourab_2.m` startup paths and output folder.
4. Load `A` from Section 1.
5. Read scene images and save `scene_montage.png`.
6. Implement SIFT matching first.
7. Estimate homography and fundamental matrix for one pair.
8. Add SURF and ORB/KAZE setups.
9. Add the selected-pair loop.
10. Add the per-octave SIFT experiment.
11. Select the best four pair/setup combinations.
12. Save best-pair figures, matrices, and panorama.
13. Manually save the `vgg_gui_F` screenshot.
14. Save `section2_metrics.mat`, `setup_comparison.csv`, and `section2_report_values.txt`.
15. Write Section 2 in `Roy_Gourab.docx`.

---

## 5. Report-Writing Plan for `Roy_Gourab.docx`

Remember:

- Section 2 must be at most four pages.
- Use clearly labeled subsections `2(a)`, `2(b)`, and `2(c)`.
- Use values and figures saved in `results/section_2/`.
- Keep discussion concise but quantitative.

### 5.1 Section 2(a): Scenario Montage and Scene Description

Include:

- montage of all captured views
- brief scene description
- number of images
- camera/intrinsics note
- challenging factors

Suggested text points:

- The same calibrated camera from Section 1 was used.
- Intrinsics were kept fixed.
- The scene was chosen for texture and rectilinear structure.
- The views include camera translation and viewpoint changes.
- Mention lighting, shadows, occlusion, low texture, or repeated patterns if present.

Required figure:

- `results/section_2/scene_montage.png`

### 5.2 Section 2(b): Pair/Setup Comparison

Include:

- why the selected pairs were chosen
- comparison table over pairs and setups
- per-octave SIFT results
- discussion of homography quality
- discussion of fundamental matrix quality

Recommended table columns:

- pair
- setup
- keypoints image 1
- keypoints image 2
- raw matches
- H inliers
- H inlier ratio
- H mean residual
- F inliers
- F inlier ratio
- F error
- runtime

Discussion must address:

- which methods produced more/fewer matches
- which methods produced better geometric consistency
- how baseline and scene difficulty affected matching
- why homography may work poorly for a non-planar 3D scene
- why fundamental matrix is more appropriate for two views of a 3D scene
- what changed when using per-octave SIFT filtering

Required outputs:

- `results/section_2/setup_comparison.csv`
- `results/section_2/per_octave_results.png`

### 5.3 Section 2(c): Best Combination

For only the best pair/setup, include:

- matched-points figure
- estimated homography matrix
- panoramic image
- estimated fundamental matrix
- `vgg_gui_F` screenshot

Required outputs:

- `results/section_2/best_matches.png`
- `results/section_2/best_homography.txt`
- `results/section_2/best_panorama.png`
- `results/section_2/best_fundamental_matrix.txt`
- `results/section_2/vgg_gui_F_best_pair.png`

Suggested final paragraph:

- State why this pair/setup was selected as best.
- Mention its inlier count, geometric error, and visual epipolar-line quality.
- State whether the pair is suitable to pass into Section 3.

---

## 6. Ready-to-Write Report Checklist

Before writing Section 2 in the DOCX, confirm that you have:

- scene montage saved in `results/section_2/`
- scene image filenames saved in `results/section_2/`
- Section 1 `A` or scaled `A` saved as the matrix used
- selected pairs and reasons saved
- comparison table saved
- per-octave results saved
- best matched-points figure saved
- best homography matrix saved
- best panorama saved
- best fundamental matrix saved
- `vgg_gui_F` screenshot saved
- short notes about the strengths and weaknesses of each setup
- final best pair/setup decision

---

## 7. Final Acceptance Checklist

Section 2 should be considered finished only if this checklist is fully true:

- `Roy_Gourab_2.m` runs on its own from a fresh MATLAB session
- all needed helper functions are in `lib/`
- `results/section_1/A_screen.mat` is loaded successfully
- `images/scene/` contains the scene images
- `results/section_2/scene_montage.png` exists
- `results/section_2/section2_metrics.mat` exists
- `results/section_2/section2_report_values.txt` exists
- `results/section_2/setup_comparison.csv` exists
- `results/section_2/per_octave_results.png` exists
- `results/section_2/best_matches.png` exists
- `results/section_2/best_homography.txt` exists
- `results/section_2/best_panorama.png` exists
- `results/section_2/best_fundamental_matrix.txt` exists
- `results/section_2/vgg_gui_F_best_pair.png` exists
- `Roy_Gourab.docx` contains Section 2(a), 2(b), and 2(c)
- Section 2 in the report is at most four pages

---

## 8. Best Next Action

The next practical move is:

1. rerun `Roy_Gourab_2.m` in MATLAB if you want to regenerate the outputs yourself
2. optionally follow `results/section_2/vgg_gui_F_instructions.txt` to capture the exact GUI screenshot
3. ask Codex to check the generated outputs
4. write Section 2 in `Roy_Gourab.docx`
