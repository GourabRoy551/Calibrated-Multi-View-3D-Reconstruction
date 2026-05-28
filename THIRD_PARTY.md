# Third-Party And Academic Code Notes

Calibrated Multi-View 3D Reconstruction includes original project scripts plus helper code gathered for an academic 3D-vision lab workflow.

## Included Dependencies

- `vlfeat-0.9.21/`: VLFeat computer-vision library. See `vlfeat-0.9.21/COPYING` and `vlfeat-0.9.21/README.md`.
- `lib/ACT_lite/`: academic helper functions for projective calibration, triangulation, bundle adjustment, and drawing.
- `lib/extra_funs/`: additional lab helper functions for fundamental matrix estimation, triangulation, and visualization.
- `lib/vgg_gui_F.m`: VGG-style epipolar-geometry visualization helper.

## Publishing Note

Before publishing this repository publicly, keep the original third-party license files with their code and add a project-level license only for the original files you own. If the portfolio repository is intended only for showcasing work, this file helps make the dependency boundary explicit.
