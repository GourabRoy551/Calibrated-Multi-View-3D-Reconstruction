# LabFinal Report Fix Procedure

This procedure is designed so the report can be fixed **one step at a time**.

When you are ready, tell Codex exactly one command such as:

```text
Do Step 1
```

Codex should then complete only that step, verify it, and stop.

---

## Goal

Prepare the final report so it follows `LabFinal.pdf` exactly.

The report must:

- Be written as a clear academic report.
- Use the required structure from `LabFinal.pdf`.
- Use only saved outputs from the project.
- Include the required numerical values, figures, tables, and discussion.
- Not invent or manually change result values.
- Be submitted as `Roy_Gourab.pdf`.

Main report file:

```text
latex_report/main.tex
```

Current output folders:

```text
results/section_1/
results/section_2/
results/section_3/
```

LaTeX image folders:

```text
latex_report/images/section_1/
latex_report/images/section_2/
latex_report/images/section_3/
```

---

## LabFinal Report Requirements Checklist

Use this checklist as the standard for judging the final report.

### Section 1: Intrinsic Camera Calibration

Required by `LabFinal.pdf`:

- Screen checkerboard size in millimeters.
- Set of screen-checkerboard calibration images.
- Resolution of captured calibration images.
- Intrinsic matrix `A`.
- Quantitative analysis of:
  - Pixel squareness.
  - Principal point versus image center.
  - Orthogonality of image axes.
- Custom physical calibration pattern.
- Rationale for selecting the custom pattern.
- Captured images of the custom pattern.
- Intrinsic matrix `A_prime`.
- Same quantitative analysis for `A_prime`.
- Theoretical and practical relationship between `A` and `A_prime`.

Current status:

```text
Section 1 is already acceptable.
No major Section 1 report fix is required.
```

### Section 2: Local Matches Between Several Views

Required by `LabFinal.pdf`:

- Mosaic/montage of all captured scene views.
- Brief description of the scene and its challenging factors.
- Representative selected pairs of views.
- Selected detector/descriptor/matching setups.
- Numerical comparison of explored setups.
- Discussion of performance based on scene complexity and method behavior.
- Discussion of homography and fundamental matrix quality.
- Per-octave experiment:
  - Qualitative results.
  - Advantages and drawbacks.
- Best combination:
  - Pair of images with correspondences overlaid.
  - Estimated homography.
  - Panoramic image.
  - Estimated fundamental matrix.
  - Screen capture of `vgg_gui_F.m` GUI.
- Section 2 should be concise and should not exceed the page limit suggested in `LabFinal.pdf`.

Current issues:

```text
Some Section 2 images copied into latex_report/images/section_2/ are outdated.
The report should include a compact table that explicitly compares SIFT, SURF, and ORB.
```

### Section 3: 3D Reconstruction and Calibration

Required by `LabFinal.pdf`:

- Images used for N-view matching with detected interest points shown in each image.
- Initial two-camera reconstruction:
  - Images used for fundamental matrix estimation.
  - Detected points and matches.
  - Mean reprojection error.
  - Reprojection error histogram.
- Projective Bundle Adjustment:
  - Mean reprojection error after resectioning.
  - Reprojection histogram after resectioning.
  - Mean reprojection error after Projective Bundle Adjustment.
  - Reprojection histogram after Projective Bundle Adjustment.
  - Explanation of why the reprojection errors differ.
- Fundamental matrix recomputed from projection matrices after BA.
- Essential-matrix-based Euclidean reconstruction.
- Euclidean projection matrices for all cameras by resectioning.
- Final Euclidean mean reprojection error and histogram.
- 3D point cloud:
  - Several viewpoints.
  - Figures with cameras and scene.
  - Figures with scene alone.
  - 3D MATLAB `.fig` files.
- Improved point cloud, such as colored point cloud.

Current issues:

```text
The report currently shows only two keypoint figures for Section 3.
It should show all five keypoint figures.
The report says tracks were built using a union-find structure, but the code uses reference-view matching.
```

---

# Step-by-Step Fix Plan

Each step below is independent and should be completed only when requested.

---

## Step 1: Sync Section 2 Figures With Current Results

### Command to give Codex

```text
Do Step 1
```

### Purpose

Make sure the report uses the latest Section 2 figures from `results/section_2/`.

### Files to copy

Copy these files:

```text
results/section_2/scene_montage.png
results/section_2/per_octave_results.png
results/section_2/best_matches.png
results/section_2/best_panorama.png
```

Into:

```text
latex_report/images/section_2/
```

### Why this is needed

The current report text uses the latest numerical values, but some images inside the LaTeX folder are older copies. The figures must match the saved results.

### Expected result

These copied images should match their source files exactly:

```text
latex_report/images/section_2/scene_montage.png
latex_report/images/section_2/per_octave_results.png
latex_report/images/section_2/best_matches.png
latex_report/images/section_2/best_panorama.png
```

### Verification

Compare file hashes between the `results/section_2/` versions and the `latex_report/images/section_2/` versions.

Expected result:

```text
All four files match.
```

---

## Step 2: Add Missing Section 3 Keypoint Images to the LaTeX Folder

### Command to give Codex

```text
Do Step 2
```

### Purpose

Prepare the missing keypoint images so the report can show all five N-view matching images required by `LabFinal.pdf`.

### Files to copy

Copy these missing files:

```text
results/section_3/keypoints_view_02.png
results/section_3/keypoints_view_04.png
results/section_3/keypoints_view_05.png
```

Into:

```text
latex_report/images/section_3/
```

These two already exist but should also be checked:

```text
latex_report/images/section_3/keypoints_view_01.png
latex_report/images/section_3/keypoints_view_03.png
```

### Why this is needed

`LabFinal.pdf` asks for the images used in N-view matching with detected interest points shown in each image. Since five images were used, all five keypoint figures should be available to the LaTeX report.

### Expected result

The LaTeX Section 3 image folder should contain:

```text
keypoints_view_01.png
keypoints_view_02.png
keypoints_view_03.png
keypoints_view_04.png
keypoints_view_05.png
```

### Verification

Check that all five files exist and match the files in `results/section_3/`.

Expected result:

```text
All five keypoint images exist in latex_report/images/section_3/.
All five copied images match the current results.
```

---

## Step 3: Update Section 3 Keypoint Figure Content in `main.tex`

### Command to give Codex

```text
Do Step 3
```

### Purpose

Modify the Section 3 report text so it includes all five keypoint figures, not only two representative examples.

### File to edit

```text
latex_report/main.tex
```

### Required change

Find the current Section 3 keypoint paragraph and figure. It currently describes only representative keypoint visualisations for `View_01` and `View_03`.

Replace that with wording that states all five images are shown.

Required idea:

```text
Figures X-Y show the detected SIFT interest points for all five views used in the N-view matching stage.
```

### Required figures

Include all five:

```text
section_3/keypoints_view_01.png
section_3/keypoints_view_02.png
section_3/keypoints_view_03.png
section_3/keypoints_view_04.png
section_3/keypoints_view_05.png
```

### Required captions

Each caption should clearly identify:

- The view name.
- The keypoint count.
- The reference view where relevant.

Use these values:

```text
View_01.jpeg: 2576 keypoints
View_02.jpeg: 2579 keypoints
View_03.jpeg: 2600 keypoints, reference view
View_04.jpeg: 2685 keypoints
View_05.jpeg: 2699 keypoints
```

### Why this is needed

This directly satisfies Section 3.1 of `LabFinal.pdf`.

### Verification

Search `latex_report/main.tex` for:

```text
keypoints_view_01
keypoints_view_02
keypoints_view_03
keypoints_view_04
keypoints_view_05
```

Expected result:

```text
All five filenames appear in main.tex.
```

---

## Step 4: Correct the Section 3 Track-Building Description

### Command to give Codex

```text
Do Step 4
```

### Purpose

Make the report description match the actual code in `Roy_Gourab_3.m`.

### File to edit

```text
latex_report/main.tex
```

### Problem

The report currently says the N-view tracks were built using a “union-find structure.”

The actual code uses a reference-view strategy:

- `View_03.jpeg` is used as the reference view.
- Other views are matched against the reference view.
- Matches are filtered using fundamental-matrix RANSAC.

### Required replacement wording

Replace the union-find sentence with:

```latex
N-view tracks were built using a reference-view strategy. The middle view,
View\_03.jpeg, was selected as the reference because it provides strong overlap
with neighbouring views. Each remaining view was matched against the reference
view, and the matches were filtered using fundamental-matrix RANSAC before being
kept as multi-view tracks.
```

### Why this is needed

The professor may compare the report to the script. The written method should match the actual implementation.

### Verification

Search `latex_report/main.tex` for:

```text
union-find
```

Expected result:

```text
No match should be found.
```

---

## Step 5: Improve Section 2 Detector/Descriptor Comparison

### Command to give Codex

```text
Do Step 5
```

### Purpose

Make Section 2 clearly satisfy the requirement to compare different detector/descriptor/matching setups.

### File to edit

```text
latex_report/main.tex
```

### Required setups to compare

The report should explicitly compare:

```text
SIFT MATLAB default
SIFT MATLAB strict
SURF matchFeatures
ORB matchFeatures
```

### Recommended table

Add a compact table for the best pair `View_02.jpeg vs View_03.jpeg`.

Use these values:

```latex
\begin{table}[htbp]
\centering
\caption{Detector/descriptor comparison for View\_02.jpeg vs View\_03.jpeg.}
\label{tab:section2_four_setup_comparison}
\begin{tabular}{lrrrrr}
\hline
Setup & Matches & H inl. & H res. & F inl. & F err. \\
\hline
SIFT MATLAB default & 955  & 326 & 0.500576 & 703 & 0.110435 \\
SIFT MATLAB strict  & 1003 & 306 & 0.709384 & 714 & 0.183218 \\
SURF matchFeatures  & 304  & 183 & 1.649812 & 185 & 0.389158 \\
ORB matchFeatures   & 390  & 251 & 0.990057 & 301 & 0.139163 \\
\hline
\end{tabular}
\end{table}
```

### Required discussion

Add a short academic discussion after the table:

```latex
For the selected best pair, both SIFT variants produced substantially more
fundamental-matrix inliers than SURF and ORB. ORB was competitive in speed and
had a low Sampson error, but it produced fewer reliable correspondences than
SIFT. SURF produced fewer matches and a higher homography residual on this
scene. The strict SIFT setup was selected because it gave the largest number of
fundamental-matrix inliers, which is the most important criterion for the later
3D reconstruction stage.
```

### Why this is needed

`LabFinal.pdf` asks for a numerical comparison and discussion of explored setups. A compact table is enough and keeps Section 2 concise.

### Verification

Search `latex_report/main.tex` for:

```text
SURF matchFeatures
ORB matchFeatures
tab:section2_four_setup_comparison
```

Expected result:

```text
The table and discussion are present.
```

---

## Step 6: Check Section 2 Page Length and Reduce If Needed

### Command to give Codex

```text
Do Step 6
```

### Purpose

Make sure Section 2 stays concise, as requested by `LabFinal.pdf`.

### File to inspect

```text
latex_report/main.tex
```

### What to check

Section 2 should include only the most important figures and tables:

- Scene montage.
- Detector/setup comparison table.
- Top combination table.
- Per-octave figure/table.
- Best matches.
- Homography.
- Panorama.
- Fundamental matrix.
- `vgg_gui_F` screenshot.

### What not to do

Do not include the full 20-row CSV table unless absolutely necessary.

### If Section 2 is too long

Shorten discussion text before removing required outputs.

Recommended reductions:

- Keep the best-pair table.
- Keep the compact four-setup comparison table.
- Shorten long prose paragraphs.
- Mention that the full CSV exists instead of printing all rows.

### Verification

Compile the report and check the page range of Section 2 in the table of contents or generated PDF.

Expected result:

```text
Section 2 is concise and close to the LabFinal suggested length.
```

---

## Step 7: Check Section 3 Required Outputs and Discussion

### Command to give Codex

```text
Do Step 7
```

### Purpose

Confirm Section 3 explicitly covers every required item from `LabFinal.pdf`.

### File to inspect

```text
latex_report/main.tex
```

### Required Section 3 values

The report should include:

```text
Images used: 5
Detector: MATLAB SIFT
Tracks retained: 672
Reference view: View_03.jpeg
Min track visibility: 2 views
Max track visibility: 5 views
Mean track visibility: 3.107 views
Initial pair: View_02.jpeg vs View_03.jpeg
Pair tracks: 734
Initial F inliers after RANSAC: 672
Initial mean reprojection error: 0.169020 px
Post-resection mean reprojection error: 0.397073 px
BA status: BAProjectiveCalib completed successfully
Post-BA mean reprojection error: 0.397073 px
F_from_P normalized difference from initial F: 0.000000
Intrinsic matrix selection: direct scaled portrait calibration
Selected-pair Euclidean reprojection error: 6.489063 px
Cheirality-positive depth count: 1344
Chosen pose convention: P2 = K [R | -R*T]
Translation direction: [0.995713, 0.091376, -0.014380]^T
Euclidean mean reprojection error: 4.465095 px
```

### Required Section 3 figures/files

The report should include or mention:

```text
keypoints_view_01.png
keypoints_view_02.png
keypoints_view_03.png
keypoints_view_04.png
keypoints_view_05.png
initial_pair_matches.png
initial_reprojection_hist.png
resection_reprojection_hist.png
ba_reprojection_hist.png
euclidean_reprojection_hist.png
cloud_with_cameras_view_1.png
cloud_with_cameras_view_2.png
cloud_scene_only_view_1.png
cloud_scene_only_view_2.png
colored_cloud.png
cloud_with_cameras.fig
cloud_scene_only.fig
initial_F.txt
F_from_P.txt
essential_matrix.txt
euclidean_intrinsic_matrix.txt
```

### Verification

Search for all required values and filenames in `latex_report/main.tex`.

Expected result:

```text
All required values and figures are present or explicitly mentioned.
```

---

## Step 8: Compile the LaTeX Report

### Command to give Codex

```text
Do Step 8
```

### Purpose

Generate the updated PDF and ensure all references, figures, equations, and tables compile correctly.

### Working folder

```text
latex_report/
```

### Compile commands

Run:

```powershell
pdflatex main.tex
pdflatex main.tex
```

Run twice so cross-references and table/figure numbers are updated.

### Verification

Check that the PDF was generated successfully:

```text
latex_report/main.pdf
```

Check the LaTeX log for:

```text
Undefined references
Missing files
LaTeX errors
```

Expected result:

```text
main.pdf is created.
No missing figures.
No undefined important references.
No fatal LaTeX errors.
```

---

## Step 9: Create the Final Submission PDF Name

### Command to give Codex

```text
Do Step 9
```

### Purpose

Create the final PDF using the filename required by `LabFinal.pdf`.

### Required output name

```text
latex_report/Roy_Gourab.pdf
```

### Required action

Copy:

```text
latex_report/main.pdf
```

To:

```text
latex_report/Roy_Gourab.pdf
```

### Why this is needed

`LabFinal.pdf` asks the report to be named using the student surname and name format.

### Verification

Check:

```text
latex_report/Roy_Gourab.pdf
```

Expected result:

```text
Roy_Gourab.pdf exists and opens correctly.
```

---

## Step 10: Final Full Report Verification

### Command to give Codex

```text
Do Step 10
```

### Purpose

Perform a final read-through and compliance check against `LabFinal.pdf`.

### What to verify

Check:

- Final PDF exists as `Roy_Gourab.pdf`.
- Title page identifies the course/lab report and student name.
- Section 1 includes all calibration requirements.
- Section 2 includes scene montage, detector comparison, per-octave experiment, best combination outputs, and `vgg_gui_F` screenshot.
- Section 3 includes all five keypoint figures, projective reconstruction, BA, `F_from_P`, Essential matrix, Euclidean reconstruction, reprojection histograms, and point-cloud figures.
- All values match saved report-values text files.
- No old/outdated images are used.
- No invented values appear.
- No incorrect “union-find” wording remains.
- The report is written in academic style and is not overly verbose.

### Expected result

Codex should respond with one of:

```text
Ready for submission.
```

or:

```text
Not ready yet.
Missing/fix these exact items:
...
```

---

# Recommended Order

Complete the steps in this order:

```text
Step 1  - Sync Section 2 figures
Step 2  - Copy missing Section 3 keypoint figures
Step 3  - Add all five keypoint figures to main.tex
Step 4  - Correct Section 3 method wording
Step 5  - Improve Section 2 setup comparison
Step 6  - Check Section 2 length
Step 7  - Check Section 3 completeness
Step 8  - Compile report
Step 9  - Create Roy_Gourab.pdf
Step 10 - Final verification
```

---

# One-Step-at-a-Time Rule

To avoid accidental large changes, use this rule:

```text
Only ask Codex to do one step at a time.
```

Example:

```text
Do Step 1
```

After Codex finishes and verifies Step 1, then ask:

```text
Do Step 2
```

Continue until Step 10.

