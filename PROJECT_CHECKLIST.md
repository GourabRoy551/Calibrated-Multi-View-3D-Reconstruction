# 3D Vision Lab — Project Completion Checklist
**Course:** 3D Vision for Multiple and Moving Cameras (2025/2026)  
**Student:** Roy Gourab  
**Checked against:** LabFinal.pdf

---

## HOW TO USE THIS FILE
Work through each section top to bottom. Mark items as done by changing `[ ]` to `[x]`.  
Items marked 🔴 are critical for submission. Items marked 🟡 affect the section score.

---

## PART 1 — SUBMISSION PACKAGING 🔴

- [ ] **Rename the report PDF** from `latex_report/3D_LabFinal.pdf` → `Roy_Gourab.pdf`
- [ ] **Create `Roy_Gourab.zip`** containing exactly these three files:
  - `Roy_Gourab_1.m`
  - `Roy_Gourab_2.m`
  - `Roy_Gourab_3.m`
- [ ] **Upload `Roy_Gourab.zip`** to the Moodle delivery link
- [ ] **Upload `Roy_Gourab.pdf`** to the Moodle delivery link

---

## PART 2 — SECTION 2 PAGE LIMIT 🔴

LabFinal.pdf states: *"use at most four pages for this section — exceeding this limit has a negative effect in the section score."*

**Current state:** Section 2 spans approximately 8 pages in the compiled PDF.  
**Target:** ≤ 4 pages.

### Suggested cuts to reach the 4-page limit

- [ ] **Remove Table 6** (scene capture parameters) — the values are already stated in the paragraph text; the table adds a full page for little gain.
- [ ] **Shorten Section 2.2** (Feature Detection setups) — condense the 4-item enumerated list into a single compact paragraph or a small inline table.
- [ ] **Remove the Section 2.5 "Summary" subsection** — it repeats information already in the body; the final paragraph of 2.5 can be folded into Section 2.3.
- [ ] **Reduce the best_matches figure** (`\textwidth` → `0.80\textwidth`) — it is a wide landscape image and currently forces a near-full-page float.
- [ ] **After all cuts, recompile and check the page count** of Section 2 before finalising.

---

## PART 3 — SECTION 2 CONTENT GAPS 🟡

### 3a. Scene challenging factors (Section 2.1)

LabFinal requires: *"a brief description of the challenging factors that it contains"* alongside the scene montage.

- [ ] Add 2–4 sentences after the scene montage figure describing what makes the scene challenging, for example:
  - Significant depth variation between the books (non-planar scene → homography is only approximate)
  - Repetitive texture on the bedsheet (risk of false matches)
  - Partial occlusions between views as the camera moves
  - Varying illumination and specular reflections on book covers

**Where to add it:** Directly after Figure 5 caption in `latex_report/main.tex`, before `\subsection{Feature Detection...}`.

---

### 3b. Per-octave qualitative results (Section 2.4)

LabFinal requires: *"Show qualitative results (pairs of images with the correspondences overlaid on them)"* for the per-octave experiment.

**Current state:** Only a bar chart (`per_octave_results.png`) is shown.  
**What is missing:** At least one image pair showing feature correspondences restricted to a single octave (e.g., Octave 0 which has the most matches).

- [ ] In `Roy_Gourab_2.m`, add code to save a correspondence image for the dominant octave (Octave 0). Use the same visualisation style as `best_matches.png`.
- [ ] Save the output to `results/section_2/octave0_matches.png`
- [ ] Copy `octave0_matches.png` to `latex_report/images/section_2/`
- [ ] In `main.tex`, add the figure after Table 9 with caption: *"Feature correspondences restricted to Octave 0 for V02–V03 (541 matches, 402 F inliers)."*

---

## PART 4 — FINAL REPORT COMPILATION

- [ ] Apply all content edits to `latex_report/main.tex`
- [ ] Recompile: open a terminal in `latex_report/` and run `pdflatex main.tex` (twice for correct cross-references)
- [ ] Verify Section 2 is ≤ 4 pages in the output PDF
- [ ] Verify all figures are present and not broken (no missing image warnings)
- [ ] Verify the table of contents page numbers are correct after recompile
- [ ] Rename the output `main.pdf` → `Roy_Gourab.pdf`

---

## PART 5 — FULL CONTENT VERIFICATION (Already Done ✅)

The items below are confirmed complete in the current report. No action needed.

### Section 1
- [x] Checkerboard size on screen (182.6 mm)
- [x] Screen calibration image montage (7 images, Figure 1)
- [x] Image resolution (1530 × 2040 px)
- [x] Intrinsic matrix **A** (Eq. 1)
- [x] Analysis — pixel squareness (α/β = 1.002176, 0.218% deviation)
- [x] Analysis — principal point location (65.43 px offset, 5.13% of half-diagonal)
- [x] Analysis — axis orthogonality (0.521° deviation)
- [x] Custom pattern rationale (4 bullet points)
- [x] Custom pattern calibration images (7 images, Figure 3)
- [x] Intrinsic matrix **A′** (Eq. 2)
- [x] Quantitative analysis of **A′** (same 3 aspects)
- [x] Comparison **A** vs **A′** with Frobenius norm, % differences (Section 1.3, Table 5)

### Section 2
- [x] Scene montage (Figure 5)
- [x] Pair and setup selection argumentation (Section 2.2)
- [x] Comparison tables for 20 combinations (Tables 7–8)
- [x] Performance discussion
- [x] Per-octave experiment table and bar chart (Table 9, Figure 6)
- [x] Drawbacks and advantages of per-octave filtering
- [x] Best pair correspondences overlaid (Figure 7)
- [x] Estimated homography **H** (Eq. 4)
- [x] Panoramic image (Figure 8)
- [x] Estimated fundamental matrix **F** (Eq. 5)
- [x] `vgg_gui_F` GUI screenshot (Figure 9)

### Section 3
- [x] N-view keypoint images with detected interest points (Figure 10)
- [x] Initial pair image with point matches (Figure 12)
- [x] Initial reprojection error (0.169020 px) and histogram (Figure 13)
- [x] Resectioning reprojection error (0.397073 px) and histogram (Figure 14)
- [x] Bundle adjustment reprojection error (0.397073 px) and histogram (Figure 15)
- [x] Justification of reprojection error differences
- [x] **F** recomputed from P matrices via `vgg_F_from_P` (Eq. 7)
- [x] Essential matrix **E** (Eq. 8) and Euclidean reconstruction
- [x] Cheirality selection described (1344 positive depths, candidate 10)
- [x] Final Euclidean reprojection error (4.465095 px) and histogram (Figure 16)
- [x] Point cloud with cameras — 2 viewpoints (Figures 17–18)
- [x] Scene-only point cloud — 2 viewpoints (Figures 19–20)
- [x] **Extra:** Colour-mapped point cloud (Figure 21)

---

## QUICK PRIORITY ORDER

1. 🔴 Fix Section 2 page count (cut to ≤ 4 pages)
2. 🟡 Add scene challenging factors paragraph (Section 2.1)
3. 🟡 Add per-octave correspondence image (Section 2.4)
4. 🔴 Recompile → rename output to `Roy_Gourab.pdf`
5. 🔴 Create and upload `Roy_Gourab.zip`
