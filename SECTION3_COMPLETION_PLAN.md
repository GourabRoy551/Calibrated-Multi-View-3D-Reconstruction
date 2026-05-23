# Section 3 Completion Plan

This file is a focused plan to finish Section 3 of the lab evaluation using the requirements from `PLAN.md` and `LabFinal.pdf`.

Target outputs:

- A standalone script: `Roy_Gourab_3.m`
- Section 3 report draft for now: `Roy_Gourab.docx`
- Final report later: `Roy_Gourab.pdf`
- Saved numeric, metadata, and visual outputs in `results/section_3/`

Current status from the folder:

- Current script: `Roy_Gourab_3.m`
- Section 1 calibration outputs are available in `results/section_1/`
- Section 2 matching outputs are available in `results/section_2/`
- Scene images are available in `images/scene/`
- Reconstruction helpers found locally:
- `MatFunProjectiveCalib.m`
- `BAProjectiveCalib.m`
- `PDLT_NA.m`
- `TriangEuc.m`
- `factorize_E.m`
- `CameraMatrix2KRC.m`
- `ErrorRetroproy.m`
- `draw_reproj_error.m`
- `draw_scene.m`
- `draw_3Dpoints.m`
- Missing or not found locally, handled by local fallbacks in `Roy_Gourab_3.m`:
- `n_view_matching`
- `vgg_F_from_P`
- Coding status: `Roy_Gourab_3.m` now implements the Section 3 reconstruction pipeline and saves report-ready outputs to `results/section_3/`.
- Still pending: after the user reruns/accepts the outputs, write Section 3 in the DOCX report.

---

## 0. Required Section 3 Output Folder

All values, metadata, and figures needed for writing the Section 3 report must be saved inside:

- `results/section_3/`

This includes:

- scene image filenames used for reconstruction
- image sizes and scale factors
- intrinsic matrix `A` used for Euclidean reconstruction
- detected keypoints for each image
- descriptors for each image
- N-view track data
- visibility mask
- selected two-camera pair for initial reconstruction
- matched-points figure for the initial pair
- initial fundamental matrix
- projective camera matrices
- initial projective 3D points
- reprojection error values and histograms
- resectioned camera matrices
- projective bundle adjustment results
- fundamental matrix recomputed from projection matrices
- essential matrix
- recovered Euclidean `R` and `t`
- Euclidean 3D point cloud
- Euclidean camera matrices
- aggregated reprojection error
- 3D cloud figures and `.fig` exports
- optional improved/colored point cloud outputs

Recommended files to create:

- `results/section_3/section3_metrics.mat`
- `results/section_3/section3_report_values.txt`
- `results/section_3/keypoints_view_XX.png`
- `results/section_3/n_view_tracks.mat`
- `results/section_3/initial_pair_matches.png`
- `results/section_3/initial_F.txt`
- `results/section_3/initial_reprojection_hist.png`
- `results/section_3/resection_reprojection_hist.png`
- `results/section_3/ba_reprojection_hist.png`
- `results/section_3/F_from_P.txt`
- `results/section_3/essential_matrix.txt`
- `results/section_3/euclidean_reprojection_hist.png`
- `results/section_3/cloud_with_cameras_view_1.png`
- `results/section_3/cloud_with_cameras_view_2.png`
- `results/section_3/cloud_scene_only_view_1.png`
- `results/section_3/cloud_scene_only_view_2.png`
- `results/section_3/cloud_with_cameras.fig`
- `results/section_3/cloud_scene_only.fig`
- `results/section_3/colored_cloud.png`

The goal is that the DOCX report can be written directly from `results/section_3/`.

---

## 1. What "Section 3 Complete" Means

Section 3 is complete only when all of the following are true:

1. `Roy_Gourab_3.m` runs from `clear all` without relying on manual leftovers.
2. The script loads the Section 1 intrinsic matrix `A`.
3. The script reuses the Section 2 scene images.
4. The script uses the Section 2 detector/descriptor decision as guidance.
5. Interest points are detected on all reconstruction images.
6. Consistent tracks are computed across multiple views.
7. The initial two-camera fundamental matrix and projective reconstruction are computed.
8. Mean reprojection error and histogram are saved for the initial two-camera reconstruction.
9. Remaining cameras are resectioned.
10. Mean reprojection error and histogram are saved after resectioning.
11. Projective bundle adjustment is run.
12. Mean reprojection error and histogram are saved after bundle adjustment.
13. A fundamental matrix is recomputed from the projective camera matrices.
14. The essential matrix is computed from `A` and `F`.
15. A Euclidean reconstruction is obtained.
16. Euclidean camera matrices are obtained for all cameras.
17. Aggregated Euclidean reprojection error and histogram are saved.
18. 3D point cloud figures are saved with cameras and scene-only views.
19. All report values and figures are saved under `results/section_3/`.
20. `Roy_Gourab.docx` contains Section 3 subsections `3.1` through `3.6`.

---

## 2. Exact Section 3 Requirements

### 2.1 Consistent N-View Matches

Required by the assignment:

- Compute consistent point matches among `N` views.
- Use `n_view_matching` if available.
- If `n_view_matching` is unavailable, use another strategy to match feature points among all views.
- Provide images used for N-view matching with detected interest points.

Local situation:

- `n_view_matching` is not currently found in `lib/`.
- The script should implement a fallback strategy.

Recommended fallback:

- Use the Section 2 best detector choice, currently MATLAB SIFT.
- Detect SIFT features and descriptors in each scene view.
- Match consecutive pairs and optionally match a reference view to all other views.
- Build tracks by linking feature indices across pairwise matches.
- Keep tracks visible in at least 2 cameras.
- Prefer tracks visible in more cameras for bundle adjustment.
- Save:
- `q(2, npoints, ncam)` or `q(3, npoints, ncam)` pixel coordinates
- `vp(npoints, ncam)` visibility mask
- `frames{k}` as `2 x Mk` keypoint coordinates
- `descrs{k}` as descriptors

### 2.2 Initial Fundamental Matrix and Projective Reconstruction

Required by the assignment:

- Compute the fundamental matrix from two cameras.
- Compute an initial projective reconstruction from those two cameras.
- Provide images used, detected interest points, and point matches.
- Provide mean reprojection error and reprojection error histogram.

Recommended implementation:

- Choose the best pair from Section 2 if it has strong inlier counts.
- Current best pair from Section 2: `view_04.jpeg` and `view_06.jpeg`.
- Use tracks or inlier matches for that pair.
- Call:

```matlab
[F, P_est, Q_est, q_est] = MatFunProjectiveCalib(q_2);
err_initial = ErrorRetroproy(q_2, P_est, Q_est) / 2;
draw_reproj_error(q_2, P_est, Q_est);
```

Save:

- `initial_pair_matches.png`
- `initial_F.txt`
- `initial_reprojection_hist.png`
- mean initial reprojection error

### 2.3 Resectioning and Projective Bundle Adjustment

Required by the assignment:

- Improve the initial reconstruction with Projective Bundle Adjustment using more images.
- Provide mean reprojection error and histogram after:
- resectioning
- Projective Bundle Adjustment
- Discuss why the error changes between initial two-camera reconstruction, resectioning, and bundle adjustment.

Recommended implementation:

- Use `PDLT_NA(Q_est, q(:,:,k))` to estimate camera matrices for remaining views.
- Use only visible points for each camera.
- Stack all projection matrices into `P(:,:,k)`.
- Run:

```matlab
[P_BA, Q_BA, q_BA] = BAProjectiveCalib(q, P, Q_est, vp);
```

Save:

- `resection_reprojection_hist.png`
- `ba_reprojection_hist.png`
- `P_resection`
- `P_BA`
- `Q_BA`
- mean reprojection errors

Expected discussion:

- Initial two-camera error can be low because it fits only two views.
- Resectioning may increase error because additional views are added with linear estimates.
- Bundle adjustment should reduce reprojection error by jointly refining cameras and 3D points.

### 2.4 Fundamental Matrix from Projection Matrices

Required by the assignment:

- Recompute the fundamental matrix between two cameras using projection matrices obtained after bundle adjustment.
- The PDF suggests `vgg_F_from_P`.

Local situation:

- `vgg_F_from_P` is not currently found in the local `lib/`.

Recommended fallback:

- Implement a local helper in `Roy_Gourab_3.m`:
- compute the camera center of `P1` from the null space
- project that center into camera 2 to get the epipole
- compute `F = skew(e2) * P2 * pinv(P1)`
- normalize `F`

Save:

- `F_from_P.txt`
- comparison against initial `F`
- Frobenius norm or normalized matrix difference

### 2.5 Essential Matrix and Euclidean Reconstruction

Required by the assignment:

- Use the intrinsic parameters from Section 1.
- Use the properties of the essential matrix to obtain a Euclidean reconstruction.
- Use reprojected points after Projective Bundle Adjustment.

Recommended implementation:

- Use the correct scaled `A` for the selected image size.
- Compute:

```matlab
E = A' * F_from_P * A;
[R, t] = factorize_E(E);
```

- Choose the valid `R,t` configuration using a cheirality check.
- Construct:

```matlab
P1_eucl = A * [eye(3), zeros(3,1)];
P2_eucl = A * [R, t];
Q_eucl = TriangEuc(q(:,:,1), q(:,:,2), P1_eucl, P2_eucl);
```

Important note:

- `A'` here means transpose of `A`, not the custom matrix `A_prime`.

Save:

- `essential_matrix.txt`
- chosen `R`
- chosen `t`
- cheirality result
- Euclidean 3D points

### 2.6 Euclidean Resectioning and Final Point Cloud

Required by the assignment:

- Obtain Euclidean projection matrices for all cameras using resectioning techniques.
- Provide aggregated reprojection error histogram.
- Provide several viewpoints and the 3D MATLAB figure of the point cloud.
- Include figures with cameras and scene, and scene alone.
- Optional extra: improved point cloud with color, line segments, or clusters.

Recommended implementation:

- For each camera after the initial pair:
- use `PDLT_NA(Q_eucl, q(:,:,k))` or a PnP-style method if enough points exist
- decompose with `CameraMatrix2KRC`
- prefer known intrinsics `A` when possible
- compute all-camera reprojection error
- save histogram
- plot cloud with cameras
- plot scene-only cloud
- save `.png` and `.fig`

Optional improvement:

- Color the cloud from the RGB values in the reference image.
- Save `colored_cloud.png`.

---

## 3. Code Work Needed in `Roy_Gourab_3.m`

### 3.1 Startup and Folders

The script should start with:

```matlab
clear all; close all; clc;
addpath(genpath('./lib'));
```

Then create:

```matlab
section_dir = fullfile('results', 'section_3');
if ~exist(section_dir, 'dir')
    mkdir(section_dir);
end
```

### 3.2 Load Dependencies

Load:

- `results/section_1/A_screen.mat`
- `results/section_2/section2_metrics.mat`
- scene images from `images/scene/`

Use:

- screen-calibration `A`
- Section 2 best pair and best detector/setup as guidance
- per-image scaling if scene images were resized

### 3.3 Detect Features and Save Keypoint Figures

For each scene view:

- detect features
- extract descriptors
- save `frames{k}` and `descrs{k}`
- overlay detected keypoints on the image
- save `keypoints_view_XX.png`

Recommended detector:

- MATLAB SIFT, because Section 2 used it successfully and VLFeat MEX files are missing.

### 3.4 Build N-View Tracks

If `n_view_matching` exists:

- call it using `frames` and `descrs`.

If it does not exist:

- implement a track builder:
- match consecutive image pairs
- match reference image to all other images
- link feature indices with a simple union-find or track table
- keep tracks visible in at least 2 views
- optionally keep a smaller high-quality subset visible in 3 or more views for bundle adjustment

Save:

- `n_view_tracks.mat`
- track count
- visibility count histogram
- track overlay figure if useful

### 3.5 Initial Two-Camera Reconstruction

Use the best pair from Section 2 or select the strongest pair from track visibility.

Save:

- pair names
- matched-points figure
- `F`
- `P_est`
- `Q_est`
- `q_est`
- mean reprojection error
- reprojection histogram

### 3.6 Resectioning and Bundle Adjustment

Steps:

1. Estimate projection matrices for remaining views.
2. Compute post-resection reprojection error and histogram.
3. Run projective bundle adjustment.
4. Compute post-BA reprojection error and histogram.
5. Save all matrices and errors.

### 3.7 Projective-to-Euclidean Reconstruction

Steps:

1. Compute `F_from_P`.
2. Compute `E = A' * F_from_P * A`.
3. Factorize `E` into possible `R,t`.
4. Select the cheirality-valid solution.
5. Triangulate Euclidean points.
6. Resection remaining Euclidean cameras.
7. Compute aggregated reprojection error.
8. Save point cloud and camera figures.

### 3.8 Save Report-Ready Values

Save:

- `results/section_3/section3_metrics.mat`
- `results/section_3/section3_report_values.txt`

Suggested structure in `section3_metrics.mat`:

- `scene.image_files`
- `scene.image_width`
- `scene.image_height`
- `scene.scale_factors`
- `scene.A_used`
- `features.frames`
- `features.descrs`
- `tracks.q`
- `tracks.vp`
- `tracks.npoints`
- `tracks.ncam`
- `initial_pair.indices`
- `initial_pair.names`
- `initial.F`
- `initial.P`
- `initial.Q`
- `initial.mean_reprojection_error`
- `resection.P`
- `resection.mean_reprojection_error`
- `ba.P`
- `ba.Q`
- `ba.mean_reprojection_error`
- `f_from_p.F`
- `f_from_p.comparison`
- `essential.E`
- `essential.R`
- `essential.t`
- `euclidean.P`
- `euclidean.Q`
- `euclidean.mean_reprojection_error`
- `cloud.figure_paths`

---

## 4. Recommended Implementation Order

1. Create `results/section_3/`.
2. Update `Roy_Gourab_3.m` startup paths and output folder.
3. Load `A_screen.mat` and Section 2 metrics.
4. Read the same scene images used in Section 2.
5. Reuse the same resizing convention as Section 2.
6. Detect SIFT features and save keypoint overlays.
7. Build N-view tracks with local fallback matching.
8. Pick the initial two-camera pair.
9. Compute initial `F` and projective reconstruction.
10. Save initial reprojection histogram and mean error.
11. Resection remaining cameras.
12. Save resection reprojection histogram and mean error.
13. Run Projective Bundle Adjustment.
14. Save BA reprojection histogram and mean error.
15. Compute `F_from_P` with local fallback if `vgg_F_from_P` is missing.
16. Compute `E`, choose `R,t`, and triangulate Euclidean points.
17. Resection Euclidean cameras.
18. Save aggregated reprojection histogram.
19. Save cloud figures and `.fig` files.
20. Save `section3_metrics.mat` and `section3_report_values.txt`.
21. Write Section 3 in `Roy_Gourab.docx`.

---

## 5. Report-Writing Plan for `Roy_Gourab.docx`

Use clearly labeled subsections `3.1` through `3.6`.

### 5.1 Section 3.1: N-View Input Images and Keypoints

Include:

- scene images used for reconstruction
- keypoint overlay figures
- detector used
- number of detected keypoints per image
- number of tracks
- visibility summary

Required figures:

- `keypoints_view_XX.png`

Suggested discussion:

- Explain that the Section 2 best-performing detector guided the detector choice.
- Mention any practical limitation, such as mixed image orientation or missing VLFeat MEX files.

### 5.2 Section 3.2: Initial Two-Camera Reconstruction

Include:

- selected two-camera pair
- matched-points figure
- initial fundamental matrix
- mean reprojection error
- reprojection error histogram

Required outputs:

- `initial_pair_matches.png`
- `initial_F.txt`
- `initial_reprojection_hist.png`

### 5.3 Section 3.3: Resectioning and Bundle Adjustment

Include:

- post-resection mean reprojection error
- post-resection histogram
- post-BA mean reprojection error
- post-BA histogram
- explanation of error changes

Required outputs:

- `resection_reprojection_hist.png`
- `ba_reprojection_hist.png`

Suggested discussion:

- Resectioning adds more views and can increase error.
- Bundle adjustment jointly refines cameras and points and should reduce error.

### 5.4 Section 3.4: Fundamental Matrix from Projection Matrices

Include:

- `F_from_P`
- comparison with initial `F`
- explanation that `F_from_P` was computed from bundle-adjusted camera matrices

Required output:

- `F_from_P.txt`

If `vgg_F_from_P` is unavailable:

- state that an equivalent local computation was used.

### 5.5 Section 3.5: Essential Matrix and Euclidean Factorization

Include:

- essential matrix `E`
- note that `E = A' * F * A`
- recovered `R` and `t`
- cheirality check result

Required output:

- `essential_matrix.txt`

Suggested discussion:

- The essential matrix uses the calibrated camera intrinsics from Section 1.
- There are multiple `R,t` candidates, and the physically valid one is chosen by positive depth.

### 5.6 Section 3.6: Final Euclidean Point Cloud

Include:

- aggregated reprojection error histogram
- point cloud with cameras
- scene-only point cloud
- several viewpoints
- `.fig` export mention
- optional improved cloud

Required outputs:

- `euclidean_reprojection_hist.png`
- `cloud_with_cameras_view_1.png`
- `cloud_with_cameras_view_2.png`
- `cloud_scene_only_view_1.png`
- `cloud_scene_only_view_2.png`
- `cloud_with_cameras.fig`
- `cloud_scene_only.fig`

Optional output:

- `colored_cloud.png`

---

## 6. Ready-to-Write Report Checklist

Before writing Section 3 in the DOCX, confirm that you have:

- keypoint figures for all reconstruction views
- N-view track count and visibility summary
- initial pair matched-points figure
- initial fundamental matrix
- initial reprojection mean and histogram
- resection reprojection mean and histogram
- BA reprojection mean and histogram
- fundamental matrix recomputed from projection matrices
- essential matrix
- chosen `R,t`
- Euclidean reprojection mean and histogram
- cloud figures with cameras
- cloud figures scene-only
- `.fig` files for 3D cloud outputs
- optional improved cloud figure
- concise discussion of error changes
- concise discussion of Euclidean factorization and cheirality

---

## 7. Final Acceptance Checklist

Section 3 should be considered finished only if this checklist is fully true:

- `Roy_Gourab_3.m` runs on its own from a fresh MATLAB session
- all needed helper functions are in `lib/`
- `results/section_1/A_screen.mat` is loaded successfully
- `results/section_2/section2_metrics.mat` is loaded successfully
- `images/scene/` contains the scene images
- `results/section_3/section3_metrics.mat` exists
- `results/section_3/section3_report_values.txt` exists
- keypoint overlay figures exist
- `results/section_3/initial_pair_matches.png` exists
- `results/section_3/initial_F.txt` exists
- `results/section_3/initial_reprojection_hist.png` exists
- `results/section_3/resection_reprojection_hist.png` exists
- `results/section_3/ba_reprojection_hist.png` exists
- `results/section_3/F_from_P.txt` exists
- `results/section_3/essential_matrix.txt` exists
- `results/section_3/euclidean_reprojection_hist.png` exists
- point cloud PNGs exist
- point cloud `.fig` files exist
- `Roy_Gourab.docx` contains Section 3.1 through Section 3.6

---

## 8. Best Next Action

The next practical move is:

1. create `results/section_3/`
2. implement `Roy_Gourab_3.m` so all Section 3 outputs go to `results/section_3/`
3. run the script in MATLAB
4. ask Codex to check generated outputs
5. write Section 3 in `Roy_Gourab.docx`
