# Calibrated Multi-View 3D Reconstruction

Camera calibration, feature matching, panorama estimation, and multi-view 3D reconstruction from real images.

Calibrated Multi-View 3D Reconstruction is a MATLAB computer-vision project that turns a small captured image set into calibrated camera models, verified two-view geometry, and a sparse 3D reconstruction. It was built from a 3D Vision for Multiple and Moving Cameras lab, then packaged as a portfolio-ready project with reproducible scripts, saved metrics, and report-quality visual outputs.

## What It Does

- Calibrates camera intrinsics from a digital checkerboard and a custom planar pattern.
- Compares feature pipelines across SIFT, SURF, and ORB-style matching setups.
- Estimates homographies and fundamental matrices with RANSAC-based geometric verification.
- Builds multi-view feature tracks across five scene images.
- Reconstructs a projective point cloud, refines it with bundle adjustment, and upgrades it to Euclidean geometry using the calibrated intrinsics.
- Saves figures, matrices, metrics, and the final written report for inspection.

## Project Highlights

- **Camera calibration:** 7 valid calibration images, focal lengths near 1530 px, square-pixel deviation of 0.22%.
- **Feature matching:** best pair used SIFT with 1003 raw matches and 714 fundamental-matrix inliers.
- **3D reconstruction:** 672 retained multi-view tracks over 5 images.
- **Reprojection quality:** initial two-view reprojection error of 0.169 px; final Euclidean mean reprojection error of 4.465 px.
- **Deliverables:** MATLAB scripts, captured image data, generated results, LaTeX report sources, and final PDF report.

## Visual Results

| Feature matches | Panorama |
| --- | --- |
| ![Best feature matches](results/section_2/best_matches.png) | ![Estimated panorama](results/section_2/best_panorama.png) |

| Colored reconstruction | Cameras and point cloud |
| --- | --- |
| ![Colored sparse point cloud](results/section_3/colored_cloud.png) | ![Point cloud with camera poses](results/section_3/cloud_with_cameras_view_1.png) |

## Repository Layout

```text
.
|-- Roy_Gourab_1.m              # Section 1: camera calibration
|-- Roy_Gourab_2.m              # Section 2: feature matching and two-view geometry
|-- Roy_Gourab_3.m              # Section 3: multi-view reconstruction
|-- run_sceneforge3d.m          # Reproducible entrypoint for one or all sections
|-- setup_sceneforge3d.m        # Path setup and environment checks
|-- checkerboard.py             # Optional checkerboard generator
|-- images/                     # Calibration and scene images
|-- lib/                        # MATLAB helper functions used by the pipeline
|-- results/                    # Generated figures, matrices, metrics, and .mat files
|-- latex_report/               # Report source and compiled PDF
|-- vlfeat-0.9.21/              # Optional VLFeat dependency
|-- docs/                       # Portfolio summary, results, and project notes
`-- LabFinal.pdf                # Original lab statement
```

## Requirements

- MATLAB with Image Processing Toolbox and Computer Vision Toolbox.
- Optional: VLFeat 0.9.21. The scripts fall back to MATLAB's built-in SIFT path when matching VLFeat MEX files are unavailable.
- Optional for checkerboard generation: Python 3.10+ and Pillow.

Install the optional Python helper dependency:

```bash
pip install -r requirements.txt
```

## Quick Start

Open MATLAB in the project root and run:

```matlab
setup_sceneforge3d
run_sceneforge3d
```

To run only one stage:

```matlab
run_sceneforge3d("section1")
run_sceneforge3d("section2")
run_sceneforge3d("section3")
```

The sections are ordered because Section 2 depends on the calibration output from Section 1, and Section 3 depends on the matching summary from Section 2.

## Generated Outputs

Important result files are saved under `results/`:

- `results/section_1/section1_report_values.txt`
- `results/section_2/section2_report_values.txt`
- `results/section_3/section3_report_values.txt`
- `results/section_2/best_matches.png`
- `results/section_2/best_panorama.png`
- `results/section_3/colored_cloud.png`
- `results/section_3/cloud_with_cameras_view_1.png`
- `results/section_3/cloud_scene_only_view_1.png`

The final report is available at `latex_report/Roy_Gourab.pdf` and `Roy_Gourab.pdf`.

## Portfolio Summary

Use the project title **Calibrated Multi-View 3D Reconstruction** in a portfolio. A compact project-card description is available in [docs/PORTFOLIO.md](docs/PORTFOLIO.md), and the main metrics are summarized in [docs/RESULTS.md](docs/RESULTS.md).

Suggested one-line description:

> Built a MATLAB multi-view vision pipeline that calibrates a real camera, verifies feature matches with epipolar geometry, and reconstructs a sparse 3D scene from multiple moving-camera views.

## Notes

The project includes third-party academic code and VLFeat support files. See [THIRD_PARTY.md](THIRD_PARTY.md) before publishing or relicensing the repository.
