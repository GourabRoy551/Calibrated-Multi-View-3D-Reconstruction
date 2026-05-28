# Calibrated Multi-View 3D Reconstruction Portfolio Card

## Short Description

Calibrated Multi-View 3D Reconstruction is a MATLAB computer-vision pipeline that calibrates a real camera, validates image correspondences with epipolar geometry, and reconstructs a sparse 3D scene from multiple moving-camera views.

## Portfolio Title

**Calibrated Multi-View 3D Reconstruction**

## Suggested Portfolio Blurb

Built a complete 3D vision pipeline in MATLAB using real captured images. The project estimates camera intrinsics from planar calibration patterns, compares SIFT/SURF/ORB matching configurations, verifies correspondences through homography and fundamental-matrix RANSAC, and reconstructs a sparse Euclidean point cloud with multi-view tracks and bundle adjustment.

## Key Skills Demonstrated

- Camera calibration using planar homographies.
- Feature detection, description, matching, and ratio-test filtering.
- Homography and fundamental-matrix estimation with RANSAC.
- Epipolar-geometry validation and Sampson-error analysis.
- Multi-view feature tracking, projective reconstruction, resectioning, and bundle adjustment.
- Euclidean upgrade using calibrated intrinsics and essential-matrix factorization.
- Technical reporting with reproducible figures and quantitative metrics.

## Resume Bullet Options

- Developed a MATLAB multi-view vision pipeline that calibrated camera intrinsics, compared feature-matching strategies, and reconstructed a sparse 3D point cloud from five real scene views.
- Implemented geometric verification with homography and fundamental-matrix RANSAC, selecting a best SIFT configuration with 1003 matches and 714 epipolar inliers.
- Built a projective-to-Euclidean reconstruction workflow using 672 retained multi-view tracks, resectioning, bundle adjustment, and calibrated essential-matrix decomposition.

## Best Screenshots To Use

- `results/section_2/best_matches.png`
- `results/section_2/best_panorama.png`
- `results/section_3/colored_cloud.png`
- `results/section_3/cloud_with_cameras_view_1.png`
- `results/section_3/cloud_scene_only_view_1.png`

## Recommended GitHub Topics

`computer-vision`, `3d-reconstruction`, `camera-calibration`, `matlab`, `epipolar-geometry`, `sift`, `bundle-adjustment`, `multi-view-geometry`
