# 3DVMMC Lab Final — Step-by-Step Plan

**Goal:** Calibrate a camera, capture multiple views of a scene, match features, estimate the fundamental matrix, and produce a 3D point cloud reconstruction. 

**Deliverables**: `Roy_Gourab.zip` (scripts) + `Roy_Gourab.pdf` (report).

---

## 0. Repository Map (what's already on disk)


| Lab   | Path                                      | Contains                                                                                                                                                                                                  | Maps to                                  |
| ----- | ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- |
| Lab1  | [Lab1/LA1_Files/](../Lab1/LA1_Files/)     | `homography_solve_vmmc.m`, `homography_auto_vmmc.m`, `stitch_vmmc.m`                                                                                                                                      | Pre-req: homography for calibration      |
| Lab2  | [Lab2/LA2_Files/](../Lab2/LA2_Files/)     | `internal_parameters_solve_vmmc.m`, `external_parameters_solve_vmmc.m`, `get_real_points_checkerboard_vmmc.m`, `homography_refine_vmmc.m`, `get_user_points_vmmc.m`, `matrot_vmmc.m`, `FixedCamera_Data/` | **Section 1 (Zhang's calibration)**      |
| Lab3  | [Lab3/LA3_code/](../Lab3/LA3_code/)       | Gaussian pyramids / scale-space                                                                                                                                                                           | Background for SIFT                      |
| Lab4  | [Lab4/LA4_imgcode/](../Lab4/LA4_imgcode/) | **VLFeat 0.9.21** with SIFT, demo images                                                                                                                                                                  | **Section 2 (detection/description)**    |
| Lab5  | [Lab5/imgLA5/](../Lab5/imgLA5/)           | 10-image panorama sequence                                                                                                                                                                                | Section 2 (matching demo data)           |
| Lab6  | [Lab6/LAVI/](../Lab6/LAVI/)               | `fundamental_matrix_1.m`, `fundamental_matrix_2.m`, **ACT_lite/**, **extra_funs/**                                                                                                                        | **Section 2/3 (F-matrix, BA)**           |
| Lab7  | [Lab7/LAVII/](../Lab7/LAVII/)             | `fundamental_matrix_3.m`, `fundamental_matrix_4.m`, real-image F-matrix                                                                                                                                   | **Section 3 (Euclidean reconstruction)** |
| Lab8  | [Lab8/LAVIII/](../Lab8/LAVIII/)           | `n_view.m`, `data_BA_lab.mat`                                                                                                                                                                             | **Section 3 (N-view BA pipeline)**       |
| Final | [Final/](.)                               | `LabFinal.pdf`, `vgg_gui_F.m`                                                                                                                                                                             | This folder — final scripts go here      |


**Critical helpers in `Lab6/LAVI/ACT_lite/`:**

- `MatFunProjectiveCalib.m` — F + P up to projective from correspondences (in `extra_funs/`)
- `BAProjectiveCalib.m` — projective bundle adjustment
- `BundleAdjustment_vp.m`, `BundleP2Matrices.m` — BA utilities with visibility
- `BundleErrorReproy.m`, `ErrorRetroproy.m`, `draw_reproj_error.m` — error stats / histograms
- `linear_triangulation.m`, `TriangEuc.m` — triangulation
- `factorize_E.m` — essential matrix → R, t
- `PDLT_NA.m`, `PDLT_B.m` — DLT for resectioning
- `CameraMatrix2KRC.m` — decompose P into K, R, C
- `draw_scene.m`, `draw_camera.m`, `draw_3Dpoints.m`, `draw_3D_cube_segments.m` — 3D plotting
- `project_points.m`, `homogenize_coords.m`, `un_homogenize_coords.m` — utilities

---

## 1. Setup (do once, before anything)

1. Create the working folder structure inside `Final/`:
  ```
   Final/
   ├── images/
   │   ├── calibration_screen/    ← Section 1.1 (screen checkerboard)
   │   ├── calibration_custom/    ← Section 1.2 (your own pattern)
   │   └── scene/                 ← Section 2/3 (object views)
   ├── results/                   ← saved figures (.png/.fig) + .mat data
   ├── lib/                       ← copies of helper functions used by the scripts
   ├── Roy_Gourab_1.m
   ├── Roy_Gourab_2.m
   └── Roy_Gourab_3.m
  ```
2. Copy the helper functions you'll reuse into `Final/lib/` so each script is self-contained:
  - From `Lab2/LA2_Files/`: `internal_parameters_solve_vmmc.m`, `external_parameters_solve_vmmc.m`, `get_real_points_checkerboard_vmmc.m`, `homography_solve_vmmc.m`, `homography_refine_vmmc.m`, `get_user_points_vmmc.m`, `matrot_vmmc.m`
  - From `Lab6/LAVI/ACT_lite/` and `Lab6/LAVI/extra_funs/`: copy the **whole folders** (used by Sections 2 + 3)
  - From `Lab4/LA4_imgcode/toolboxes/vlfeat-0.9.21/`: keep at original location and `addpath` it (or copy the `toolbox/` subfolder)
  - `Final/lib/vgg_gui_F.m` is already in place
3. Each script must start with:
  ```matlab
   close all; clc;
   addpath(genpath('./lib'));
   addpath(genpath('./vlfeat-0.9.21'));
   run('vl_setup');   % only if VLFeat is used
  ```

---

## 2. Section 1 — Camera Calibration → `Roy_Gourab_1.m`

**Reference scripts:** [Lab2/LA2_Script.pdf](../Lab2/LA2_Script.pdf) and [Lab2/LA2_Files/](../Lab2/LA2_Files/)

### 2.1. Screen-checkerboard calibration (Subsection 1.1)

Steps the script performs:

1. **Capture phase (manual, before running).** Open the provided 1080×1080 checkerboard image fullscreen on your screen, photograph it from **≥ 5 different orientations** (tilt left/right/up/down + frontal). Use **fixed focal length** — no autofocus, no zoom changes. Save as `images/calibration_screen/PatternImage_Orientation_1.jpg` … `PatternImage_Orientation_5.bmp`.
2. **Measure** the on-screen checkerboard with a ruler in mm — record `square_size_mm`. Note the camera resolution (e.g., 4032×3024).
3. **In MATLAB:** for each captured image:
  - Read image with `imread`.
  - Either use MATLAB's `detectCheckerboardPoints` *or* manual click corners with `get_user_points_vmmc` for a 9×9 / 8×8 grid.
  - Generate the corresponding world points with `get_real_points_checkerboard_vmmc(num_points, square_size_mm)`.
  - Compute the homography H_i with `homography_solve_vmmc` then refine with `homography_refine_vmmc`.
4. **Compute A:** `A = internal_parameters_solve_vmmc(H);` where `H` is a cell array of all per-image homographies.
5. **Quantitative analysis (must appear in PDF):**
  - **Square pixels:** report aspect ratio `r = A(1,1)/A(2,2)` (i.e. α/β). Deviation from 1.0 in % = `100*|r-1|`. Comment if < 1% (square) or larger.
  - **Principal point vs. image center:** compute `du = A(1,3) - W/2`, `dv = A(2,3) - H/2`, and the distance `sqrt(du^2+dv^2)` in pixels. Express as `% of half-diagonal`.
  - **Orthogonality of axes:** the skew `γ = A(1,2)`. Compute the actual angle between axes: `θ = atan2d(-A(1,2), A(1,1))` measured from 90°. Report deviation from 90° in degrees.
6. **Reprojection sanity check:** for one image, recover external parameters using `external_parameters_solve_vmmc(A, H{i})`, reproject world corners with `project_points`, overlay on the captured image, and compute mean reprojection error (in pixels). Save plot.

**Outputs to save in** `Final/results/`**:** `A_screen.mat`, mosaic of calibration captures (`montage`), reprojection error figure.

### 2.2. Custom physical pattern → A' (Subsection 1.2)

1. **Choose your pattern.** Options ranked by reliability:
  - Best: print an A4/A3 checkerboard (free generators online), tape to a flat rigid board.
  - Good: a tiled wall (regular tile grid), a brick pattern with measurable spacing.
  - Acceptable: a known framed picture / poster with measurable corners.
  - Justify the choice in the PDF: planarity, number of measurable points, contrast for corner detection, ease of accurate measurement.
2. **Decide point layout.** Need ≥ 4 known world coordinates per image to fit a homography (8 DoF), but Zhang requires multiple homographies — aim for ≥ 6 points per image and ≥ 5 images at distinct orientations. Justify this in the report.
3. **Measure** each reference point's real-world (X, Y) in mm with a ruler/caliper. Place all on a single plane (Z = 0).
4. Repeat steps 3–6 from §2.1 with the new images and a custom `world_points` matrix → produce **A'**.
5. **Compare A vs A'** in a table: focal lengths, principal point, skew, aspect ratio. Discuss:
  - Theoretically A == A' since the camera intrinsics don't depend on the pattern.
  - In practice, expect drift due to: pattern measurement accuracy, point count, planarity error, corner localization noise. Quantify the difference (Frobenius norm `norm(A-A','fro')` and per-parameter % difference).

---

## 3. Section 2 — Feature Matching → `Roy_Gourab_2.m`

**Reference scripts:** Lab4 (VLFeat SIFT), [Lab6/LAVI/fundamental_matrix_2.m](../Lab6/LAVI/fundamental_matrix_2.m), [Lab7/LAVII/](../Lab7/LAVII/), [Lab5/](../Lab5/)

### 3.1. Capture the scene (manual, before running)

- Use the **same camera with the same intrinsics** as Section 1 (no zoom/focus change).
- Subject: **textured 3D object with sharp rectilinear contours** — e.g., 2-3 books stacked, a rubik's cube, a textured box on a desk. Place 1-2 small props (coloured tag, post-it) for extra texture.
- Capture **6–10 views** orbiting around the object, varying angle and distance. Keep significant overlap (≥ 50% of features visible across consecutive views).
- (Optional challenge) Two extra captures with altered conditions: shadow / partial occlusion / changed light. Helps the discussion section.
- Save to `images/scene/view_01.jpg` … `view_NN.jpg`. **Decide if you need to downscale** (e.g., to 1024 px wide) — if you do, scale `A` accordingly:
  ```matlab
  s = new_W / orig_W;        % scale factor
  A_scaled = A; 
  A_scaled(1:2,:) = s * A(1:2,:);   % don't scale row 3
  ```

### 3.2. Detection / description / matching

1. **Build mosaic** with `montage` of all captures → save as Section 2(a) deliverable.
2. **Pick representative pairs** (3–5 of them): adjacent views, wide-baseline pair, a challenging pair (low overlap or different lighting).
3. For each pair, run feature pipelines and compare. Try at least 3 setups:
  - **VLFeat SIFT** (`vl_sift`) + ratio-test matching (`vl_ubcmatch`)
  - **MATLAB SURF** (`detectSURFFeatures` + `extractFeatures` + `matchFeatures`)
  - **MATLAB ORB** (`detectORBFeatures`) or **KAZE**
4. **Per-octave filtering experiment (required by exam):** with SIFT, group keypoints by octave (`f(3,:)` from `vl_sift` encodes scale; octave is `floor(log2(scale))`). Run matching with each octave separately. Note effect on number of matches and on H/F estimation quality.
5. **Estimate homography** with `estimateGeometricTransform2D` (or RANSAC via `vgg_H_from_x_lin` if you import that). Evaluate inlier ratio and mean residual on inliers.
6. **Estimate fundamental matrix** with `estimateFundamentalMatrix(pts1, pts2, 'Method','RANSAC','DistanceThreshold',1e-3)`. Record inlier count, Sampson distance.
7. **Quality inspection** with `vgg_gui_F(I1, I2, F)` from [Final/lib/vgg_gui_F.m](./vgg_gui_F.m) — click points and verify epipolar lines lie on corresponding features.

### 3.3. Required tables / figures (≤ 4 pages)

For the report, organise as 2(a), 2(b), 2(c) per the PDF:

- **2(a):** Montage + scene description (mention textures, occlusions, lighting).
- **2(b):** Comparison table over pairs × setups: # keypoints (left, right), # raw matches, # inlier matches, H residual, F Sampson error, runtime. Discuss.
- **2(c):** For the **single best pair+setup**: matched-points figure (use `showMatchedFeatures`), printed H matrix, panoramic stitch (use `stitch_vmmc` from Lab1 as reference), printed F matrix, vgg_gui_F screenshot.

---

## 4. Section 3 — 3D Reconstruction → `Roy_Gourab_3.m`

**Reference scripts:** [Lab8/LAVIII/n_view.m](../Lab8/LAVIII/n_view.m), [Lab6/LAVI/fundamental_matrix_2.m](../Lab6/LAVI/fundamental_matrix_2.m), [Lab7/LAVII/fundamental_matrix_4.m](../Lab7/LAVII/fundamental_matrix_4.m).

The script reuses Section 2 captures + Section 1 intrinsics. Strategy mirrors `n_view.m` but with real images.

### Step 1 — Consistent N-view matches

1. Re-detect features on all `N` scene views with the chosen detector (from Section 2). Save into the Section-2 format: `frames{k}` (2×Mk for points), `descrs{k}` (D×Mk).
2. Run the **provided** `n_view_matching` (if a copy was given in class — otherwise iterate pairwise matches and keep tracks visible in ≥ 2 cameras). Output:
  - `q(:, npoints, ncam)` — pixel coordinates of consistent points across views
  - visibility mask `vp(npoints, ncam)`
3. Plot interest points overlaid on each view (one figure per view) → Section 3.1(a).

### Step 2 — Initial F + projective reconstruction (2 cameras)

```matlab
q_2 = q(:,:,[i j]);                                  % pick 2 well-separated cameras
[F, P_est, Q_est, q_est] = MatFunProjectiveCalib(q_2);   % Lab6 helper
err = ErrorRetroproy(q_2, P_est, Q_est) / 2;
draw_reproj_error(q_2, P_est, Q_est);                % histogram
```

- Save F, mean reprojection error, histogram → Section 3.2(a)(b).
- Show the matched-points figure for the pair used.

### Step 3 — Resectioning + Projective Bundle Adjustment

1. **Resection** the remaining cameras using `PDLT_NA(Q_est, q(:,:,k))` for each new k. Stack into `P(:,:,k)`.
2. Compute reprojection error after resectioning → save mean + histogram.
3. **Projective BA:**
  ```matlab
   vp = ones(npoints, ncam);   % or from visibility mask
   [P_BA, Q_BA, q_BA] = BAProjectiveCalib(q, P, Q_est, vp);
  ```
4. Compute reprojection error after BA → save mean + histogram.
5. **In the report (Section 3.3.b):** justify the change between (i) initial 2-cam error in 2.b, (ii) post-resection error, (iii) post-BA error. Expected: 2-cam ≤ resection-only (because adding views with linear estimation increases error before refinement), BA < both.

### Step 4 — F from projective P matrices

```matlab
F2 = vgg_F_from_P(P_BA(:,:,1), P_BA(:,:,2));
```

Compare to F estimated in Step 2.

### Step 5 — Essential matrix → Euclidean reconstruction

```matlab
% Use the calibrated A from Section 1 (scaled if you downsized images)
E = A' * F2 * A;                     % normalize with intrinsics
[R, t] = factorize_E(E);             % helper from ACT_lite (or decomposeEssentialMatrix)
% Choose the (R,t) configuration with positive depth in both cameras (cheirality check)
P1_eucl = A * [eye(3) zeros(3,1)];
P2_eucl = A * [R t];
% Triangulate using the inlier points
Q_eucl  = TriangEuc(q(:,:,1), q(:,:,2), P1_eucl, P2_eucl);
```

### Step 6 — Resect remaining cameras (Euclidean) + final cloud

1. For each k=3..N, resection with `PDLT_NA(Q_eucl, q(:,:,k))` → recover `P_k_eucl`.
2. Decompose: `[K_k, R_k, C_k] = CameraMatrix2KRC(P_k_eucl);` and force `K_k ≈ A` (use the known intrinsics, only solve for R, t — `extrinsicsToCameraMatrix` or solve PnP with `estimateWorldCameraPose`).
3. Aggregate reprojection error across all cameras → mean + histogram (Section 3.6.a).
4. **Plot the 3D point cloud** with `draw_scene(Q_eucl, K_arr, R_arr, t_arr)` for cameras+scene, and `draw_3Dpoints(Q_eucl)` for scene alone. Provide several viewpoints (`view(...)`) and save the `.fig` file.

### Step 6c — Extra (do this if time permits)

Pick one or several:

- **Colour the cloud** with the RGB at the projected pixel of the reference view: `for i=1:npoints, c = I1( y(i), x(i), :); end`.
- **Line segments** between known structural pairs (book corners, box edges) — use `draw_3D_cube_segments`.
- **Cluster** points (e.g. with `kmeans` in 3D) and colour by cluster.

---

## 5. PDF Report Structure

Open `Roy_Gourab.pdf` with these clearly labeled headers (full-size figures, no `subplot`):

**Section 1**

- 1.1: square-size mm, montage of screen captures, image resolution, A matrix, 3 quantitative analyses (square pixels, principal-point offset, orthogonality), reprojection sanity check.
- 1.2: pattern rationale, point layout justification, montage of custom captures, A' matrix, same 3 quantitative analyses, A vs A' comparison + discussion.

**Section 2** (max 4 pages)

- 2(a): Montage + challenges.
- 2(b): Setup table, per-octave experiment figures + discussion.
- 2(c): Best pair → matched figure, H, panorama, F, vgg_gui_F screenshot.

**Section 3**

- 3.1: N-view input images with keypoints.
- 3.2: 2-cam matches, F, reproj error mean + histogram.
- 3.3: Histograms after resection (i) and after BA (ii) + discussion.
- 3.4: F recomputed via `vgg_F_from_P` + comparison.
- 3.5: Note on E → R,t factorisation.
- 3.6: Aggregated reproj error histogram, 3D cloud figures (with cameras + scene-only, multiple viewpoints), `.fig` exports. Optional improved cloud.

---

## 6. What you need (physical / software)

**Hardware**

- Camera with **fixed intrinsics during the whole exam** (phone main lens locked, or DSLR fixed focal length). Avoid digital zoom, AF refocus between captures.
- Laptop/desktop screen for the screen-checkerboard.
- Ruler/caliper (mm precision) for both screen and custom pattern measurements.
- Custom calibration pattern: printed checkerboard on rigid backing **or** a measured wall section.
- Scene object: textured + rectilinear (books, boxed game, Rubik's cube + props).

**Software**

- MATLAB (Computer Vision Toolbox for `estimateFundamentalMatrix`, `detectCheckerboardPoints`, `detectSURFFeatures`).
- VLFeat 0.9.21 — already in [Final/vlfeat-0.9.21/](../Lab4/LA4_imgcode/toolboxes/vlfeat-0.9.21/). Run `vl_setup` once per session.
- vgg-mvg helpers — `vgg_gui_F.m` is in this folder; you may need `vgg_F_from_P.m`. If not in the labs, download from the VGG MVG toolbox and drop into `lib/`.
- Lab2 calibration helpers — copied into `lib/`.
- Lab6 ACT_lite + extra_funs — copied into `lib/`.

---

## 7. Execution order checklist

- Set up `Final/` folder structure and `lib/` with helpers.
- Capture screen-checkerboard images (≥ 5 orientations).
- Capture custom-pattern images (≥ 5 orientations).
- Capture scene views (6–10).
- Run / write `Roy_Gourab_1.m` → produce A and A'. Verify reasonable values.
- Run / write `Roy_Gourab_2.m` → choose best detector + pair. Save F, H, panorama.
- Run / write `Roy_Gourab_3.m` → projective recon → BA → Euclidean → 3D cloud.
- Confirm each script runs standalone with `clear all` at top.
- Assemble `Roy_Gourab.pdf` (full-size images, labelled sections).
- Zip the three `.m` files + any helpers in `lib/` into `Roy_Gourab.zip`.
- Submit both files to Moodle.

---

## 8. Common pitfalls to avoid

- **Changing focal length between captures** — ruins calibration. Lock focus on phone (long-press AE/AF lock).
- **Forgetting to scale A** when downsizing images for Sections 2/3. Only scale rows 1–2 of A, never `A(3,3)`.
- **Too few calibration views or all from the same angle** — Zhang needs varied orientations.
- **Pure rotation between views in Sections 2/3** — F is degenerate; you must translate the camera between captures.
- **Repeating texture** (e.g. fabric pattern) creates wrong matches; rely on RANSAC and inlier filtering.
- **Mixing pixel and homogeneous coordinates** — `homogenize_coords`/`un_homogenize_coords` should bracket every projection.
- **Cheirality** after factorising E: there are 4 candidate (R,t) pairs; only one has positive depth in both cameras. Check `Q(3,:) > 0` in both frames.
- **Writing to the report only at the end** — fill it incrementally; a `clear all` mid-script destroys data otherwise.
