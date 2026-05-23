# Section 1 Completion Plan

This file is a focused plan to finish Section 1 of the lab evaluation using the requirements from `PLAN.md` and `LabFinal.pdf`.

Target outputs:

- A standalone script: `Roy_Gourab_1.m`
- Section 1 report draft for now: `Roy_Gourab.docx`
- Final report later: `Roy_Gourab.pdf`
- Saved numeric, metadata, and visual outputs in `results/section_1/`

Current status from the folder:

- Available screen-calibration images: `images/calibration_screen/`
- Available custom-pattern images: `images/calibration_custom/`
- Current script: `Roy_Gourab_1.m`
- Section 1 output folder exists: `results/section_1/`
- `Roy_Gourab_1.m` has been updated to write Section 1 outputs to `results/section_1/`
- Still pending: run `Roy_Gourab_1.m` in MATLAB, verify all outputs, then write the Section 1 report draft in `Roy_Gourab.docx`

---

## 0. Required Section 1 output folder

All values, metadata, and figures needed for writing the Section 1 report must be saved inside:

- `results/section_1/`

This includes numerical calibration values and also image-related values used in the report, such as:

- image filenames used for calibration
- image resolution `W x H`
- number of detected or manually selected points
- number of valid calibration images
- measured checkerboard width and square size
- custom pattern dimensions and point layout
- detected image points used for the screen calibration
- manually clicked image points used for the custom calibration
- corresponding world points in millimeters
- homographies
- intrinsic matrices
- reprojection errors
- paths of saved figures

Recommended files to create:

- `results/section_1/A_screen.mat`
- `results/section_1/A_custom.mat`
- `results/section_1/section1_metrics.mat`
- `results/section_1/section1_report_values.txt`
- `results/section_1/montage_screen.png`
- `results/section_1/montage_custom.png`
- `results/section_1/reprojection_screen.png`
- `results/section_1/reprojection_custom.png`

The goal is that the DOCX report can be written directly from `results/section_1/`, without hunting through MATLAB output or old figures.

---

## 1. What "Section 1 complete" means

Section 1 is complete only when all of the following are true:

1. `Roy_Gourab_1.m` runs from `clear all` without relying on manual leftovers from previous runs.
2. The script computes and saves:
   - screen calibration matrix `A`
   - custom-pattern calibration matrix `A_prime`
   - screen montage
   - custom montage
   - at least one reprojection sanity-check figure for screen calibration
   - at least one reprojection sanity-check figure for custom calibration
   - numeric comparison between `A` and `A_prime`
3. Every report value and figure is saved under `results/section_1/`.
4. `Roy_Gourab.docx` contains all required text, matrices, figures, and discussion for Sections `1.1` and `1.2`.
5. The final `Roy_Gourab.pdf` can later be exported from the DOCX.
6. You have chosen which intrinsic matrix you will carry forward to Sections 2 and 3, and you can justify that choice in one short sentence.

---

## 2. Exact Section 1 requirements

### 2.1 Section 1.1: Screen checkerboard calibration

Required in the report:

- checkerboard size on screen in millimeters
- the set of screen-checkerboard images used for calibration
- image resolution in pixels
- intrinsic matrix `A`
- quantitative analysis of:
  - square pixels
  - principal point vs image center
  - orthogonality of image axes
- reprojection sanity check figure and mean reprojection error

Required saved outputs:

- `results/section_1/A_screen.mat`
- `results/section_1/montage_screen.png`
- `results/section_1/reprojection_screen.png`
- screen image metadata saved in `results/section_1/section1_metrics.mat`

### 2.2 Section 1.2: Custom pattern calibration

Required in the report:

- rationale for the chosen physical pattern
- explanation of the selected measured points and why they are enough
- the set of custom-pattern images used for calibration
- intrinsic matrix `A_prime`
- the same three quantitative analyses as in Section 1.1
- comparison and discussion of `A` vs `A_prime`
- reprojection sanity check figure and mean reprojection error

Required saved outputs:

- `results/section_1/A_custom.mat`
- `results/section_1/montage_custom.png`
- `results/section_1/reprojection_custom.png`
- comparison values saved in a `.mat` file or printed clearly from the script
- custom image metadata, clicked points, and world points saved in `results/section_1/section1_metrics.mat`

### 2.3 Comparison requirements

The report must explain:

- why `A` and `A_prime` should be theoretically similar
- why they may differ in practice
- how large the differences actually are

Minimum useful comparison values:

- Frobenius norm: `norm(A - A_prime, 'fro')`
- focal length percentage differences
- principal-point differences
- skew difference
- aspect-ratio difference

---

## 3. Code work needed in `Roy_Gourab_1.m`

### 3.1 Make the screen-calibration part fully standalone

Add or confirm the following steps:

1. Read all screen images from `images/calibration_screen/`.
2. Save a montage figure as `results/section_1/montage_screen.png`.
3. Detect checkerboard points for each valid image.
4. Build world points from the measured square size.
5. Compute homographies and refine them.
6. Compute `A` and save it.
7. Compute and print the required metrics:
   - aspect ratio
   - aspect-ratio deviation from 1
   - principal-point offset in pixels
   - principal-point offset as a percentage of half the image diagonal
   - skew and axis-orthogonality measure
8. Pick one valid calibration image and do a reprojection sanity check:
   - recover extrinsics with `external_parameters_solve_vmmc`
   - reproject the world points using `project_points`
   - overlay detected points and reprojected points on the image
   - compute mean reprojection error in pixels
   - save the overlay figure to `results/section_1/reprojection_screen.png`
9. Save all image-related report values:
   - source image filenames
   - image width and height
   - checkerboard measurement values
   - detected points
   - world points
   - valid image count
   - selected reprojection-check image

Recommended robustness fixes:

- infer image width and height from the first image instead of hard-coding them
- stop with an error if fewer than 5 valid screen images are detected
- print how many screen images were valid for calibration

### 3.2 Make the custom-pattern part fully standalone

Keep the current custom workflow if you want to use the floor-tile pattern, but complete it as follows:

1. Read all custom images from `images/calibration_custom/`.
2. Save a montage as `results/section_1/montage_custom.png`.
3. For each image, click the same 9 measured points in the same order.
4. Use the measured world coordinates already defined in the script, or replace them with corrected measured coordinates if needed.
5. Compute and refine each homography.
6. Compute `A_prime` and save it.
7. Compute and print the same quantitative metrics as for `A`.
8. Add one custom-pattern reprojection sanity check:
   - recover extrinsics from one custom image
   - reproject the 9 custom world points
   - overlay clicked points and reprojected points
   - compute mean reprojection error
   - save as `results/section_1/reprojection_custom.png`
9. Save all image-related report values:
   - source image filenames
   - image width and height
   - tile size or measured pattern dimensions
   - clicked image points
   - custom world points
   - valid image count
   - selected reprojection-check image

Recommended robustness fixes:

- stop with an error if fewer than 5 custom images are used
- save the clicked image points if you want reproducibility later
- print a reminder that the clicking order must remain identical across all images

### 3.3 Complete the `A` vs `A_prime` comparison block

Expand the comparison so the script prints or saves:

- `A`
- `A_prime`
- Frobenius norm
- `alpha` percent difference
- `beta` percent difference
- principal point `u0` and `v0` differences
- skew difference
- aspect-ratio difference

Recommended output file:

- `results/section_1/section1_metrics.mat`
- `results/section_1/section1_report_values.txt`

Suggested structure inside that file:

- `screen.A`
- `screen.image_files`
- `screen.image_width`
- `screen.image_height`
- `screen.valid_image_count`
- `screen.board_width_mm`
- `screen.square_size_mm`
- `screen.detected_points`
- `screen.world_points`
- `screen.homographies`
- `screen.aspect_ratio`
- `screen.aspect_error_percent`
- `screen.principal_point_offset_px`
- `screen.principal_point_offset_percent`
- `screen.skew`
- `screen.orthogonality_measure`
- `screen.reprojection_error_px`
- `screen.reprojection_image`
- `custom.A_prime`
- `custom.image_files`
- `custom.image_width`
- `custom.image_height`
- `custom.valid_image_count`
- `custom.pattern_description`
- `custom.tile_size_mm`
- `custom.clicked_points`
- `custom.world_points`
- `custom.homographies`
- `custom.aspect_ratio`
- `custom.aspect_error_percent`
- `custom.principal_point_offset_px`
- `custom.principal_point_offset_percent`
- `custom.skew`
- `custom.orthogonality_measure`
- `custom.reprojection_error_px`
- `custom.reprojection_image`
- `comparison.frobenius_norm`
- `comparison.alpha_percent_diff`
- `comparison.beta_percent_diff`
- `comparison.u0_diff`
- `comparison.v0_diff`
- `comparison.skew_diff`

---

## 4. Recommended implementation order

1. Clean `Roy_Gourab_1.m` so it regenerates `montage_screen.png` and `reprojection_screen.png`.
2. Add the missing custom reprojection figure `reprojection_custom.png`.
3. Add the full comparison metrics block and save them.
4. Run the script from a fresh MATLAB session.
5. Re-click the 9 custom points for all custom images in a consistent order.
6. Check that all required files appear in `results/section_1/`.
7. Write the Section 1 report draft in `Roy_Gourab.docx` using only values and figures from `results/section_1/`.
8. Re-run the script once more from `clear all` to confirm it is standalone.

---

## 5. Exact formulas to use in the report

### 5.1 Square pixels

Use:

- `r = A(1,1) / A(2,2)`
- `deviation_percent = 100 * abs(r - 1)`

Interpretation:

- very close to `1` means pixels are nearly square
- larger deviation means non-square pixel scaling or calibration noise

### 5.2 Principal point vs image center

Use:

- `du = A(1,3) - W/2`
- `dv = A(2,3) - H/2`
- `offset_px = sqrt(du^2 + dv^2)`
- `offset_percent = 100 * offset_px / (0.5 * sqrt(W^2 + H^2))`

Interpretation:

- small offset means the principal point is close to the center of the image

### 5.3 Orthogonality of axes

Use:

- `gamma = A(1,2)`
- `theta = atan2d(-A(1,2), A(1,1))`

Report:

- the skew value `gamma`
- the angular deviation implied by the skew

Interpretation:

- `gamma` near zero means the image axes are nearly orthogonal

### 5.4 Reprojection error

For both screen and custom calibration:

- project the known world points back to one image
- compute the Euclidean pixel error point by point
- report the mean reprojection error in pixels

Interpretation:

- lower mean reprojection error means the recovered camera model fits the data better

---

## 6. Report-writing plan for `Roy_Gourab.docx`

Remember:

- use clearly labeled headers
- include images at real size
- do not use `subplot`
- write the report in `Roy_Gourab.docx` for now
- later export the DOCX to `Roy_Gourab.pdf` for submission
- only use values and figures saved in `results/section_1/`

### 6.1 Suggested Section 1.1 report structure

Header:

- `1.1 Screen-checkerboard calibration`

Write this content in order:

1. One short paragraph describing:
   - the selected camera
   - that intrinsics were kept fixed
   - the screen checkerboard method
2. State:
   - checkerboard width in mm
   - square size in mm
   - image resolution
   - number of calibration images used
3. Insert the screen montage figure.
4. Insert matrix `A`.
5. Insert a compact numeric summary table with:
   - `alpha`
   - `beta`
   - `gamma`
   - `u0`
   - `v0`
   - aspect ratio
   - aspect-ratio deviation
   - principal-point offset
   - orthogonality/skew measure
   - mean reprojection error
6. Insert the reprojection overlay figure.
7. Add a short discussion:
   - are pixels approximately square?
   - is the principal point close to the center?
   - are axes approximately orthogonal?
   - is the reprojection error reasonable?

### 6.2 Suggested Section 1.2 report structure

Header:

- `1.2 Custom physical pattern calibration`

Write this content in order:

1. One short paragraph describing the chosen pattern.
   - If you keep the current approach, describe it as a floor-tile planar grid with tile size `330 mm`.
2. Explain the rationale for the pattern:
   - planar surface
   - measurable geometry
   - enough repeated reference points
   - visible corners for manual selection
3. Explain the selected point layout:
   - `3 x 3` grid
   - `9` measured points
   - same point order across all images
   - multiple views at different orientations
4. Insert the custom montage figure.
5. Insert matrix `A_prime`.
6. Insert a compact numeric summary table with the same metrics as in Section 1.1.
7. Insert the custom reprojection overlay figure.
8. Add a short discussion of the custom calibration quality.

### 6.3 Suggested `A` vs `A_prime` comparison subsection

Header:

- `1.2 Comparison between A and A_prime`

Include:

1. A small comparison table:
   - `alpha`
   - `beta`
   - `gamma`
   - `u0`
   - `v0`
   - aspect ratio
2. Numeric comparison values:
   - Frobenius norm
   - per-parameter percentage differences
3. Short discussion:
   - theoretically both matrices should be similar because the same camera was used
   - practical differences can come from manual clicking, measurement errors, pattern planarity, point localization noise, and image pose diversity
4. Final decision sentence:
   - state which intrinsic matrix you will use for the next sections and why

---

## 7. Ready-to-write report checklist

Before writing the DOCX report draft, confirm that you have:

- screen montage figure in `results/section_1/`
- custom montage figure in `results/section_1/`
- screen reprojection figure in `results/section_1/`
- custom reprojection figure in `results/section_1/`
- matrix `A` saved in `results/section_1/`
- matrix `A_prime` saved in `results/section_1/`
- screen image resolution saved in `results/section_1/`
- measured screen checkerboard size in mm saved in `results/section_1/`
- image filenames and valid-image counts saved in `results/section_1/`
- detected or clicked points saved in `results/section_1/`
- world points saved in `results/section_1/`
- custom pattern explanation
- point-layout justification
- square-pixel analysis for `A`
- principal-point analysis for `A`
- orthogonality analysis for `A`
- square-pixel analysis for `A_prime`
- principal-point analysis for `A_prime`
- orthogonality analysis for `A_prime`
- `A` vs `A_prime` comparison table saved in `results/section_1/`
- final sentence selecting the intrinsic matrix for Sections 2 and 3

---

## 8. Final acceptance checklist

Section 1 should be considered finished only if this checklist is fully true:

- `Roy_Gourab_1.m` runs on its own from a fresh MATLAB session
- all needed helper functions are in `lib/`
- `results/section_1/A_screen.mat` exists
- `results/section_1/A_custom.mat` exists
- `results/section_1/section1_metrics.mat` exists
- `results/section_1/section1_report_values.txt` exists
- `results/section_1/montage_screen.png` exists
- `results/section_1/montage_custom.png` exists
- `results/section_1/reprojection_screen.png` exists
- `results/section_1/reprojection_custom.png` exists
- `Roy_Gourab.docx` contains both `1.1` and `1.2`
- `Roy_Gourab.docx` uses full-size images and no subplots
- `Roy_Gourab.docx` includes the required numerical discussion, not only figures
- `Roy_Gourab.pdf` is exported from the DOCX when the report is ready for final submission

---

## 9. Best next action

The next practical move is:

1. run `Roy_Gourab_1.m` in MATLAB
2. click the 9 custom calibration points in the requested order if MATLAB asks for them
3. confirm that all expected files appear in `results/section_1/`
4. ask Codex to check the generated outputs
5. write Section 1 of `Roy_Gourab.docx` directly from those outputs
