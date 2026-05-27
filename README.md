# VBM-multilingualism
VBM second-level GLM analysis of grey matter volume and multilingual experience (NEBULA101, N=51) using CAT12 + SPM25

# Grey Matter VBM Analysis — NEBULA101
**Person A contribution | Multimodal Neuroimaging Project | Spring 2026**

## Overview
Voxel-based morphometry (VBM) analysis examining associations between grey matter (GM) 
volume and two dimensions of multilingual experience — language count (nlang) and language 
use balance (entropy) — in 51 healthy young adults from the NEBULA101 dataset 
(OpenNeuro ds005613).

## Pipeline
1. **Preprocessing** — CAT12 (v26.0 rc3) in SPM25: segmentation, MNI normalisation, 
   modulated GM maps (mwp1)
2. **Smoothing** — 8mm FWHM Gaussian kernel applied via SPM (run_VBM_second_level.m)
3. **Second-level GLM** — Multiple regression in SPM25 with 5 regressors:
   nlang_z, entropy_z, age_z, edu_z, sex_binary
4. **Contrasts** — Positive and negative effects of nlang and entropy on GM volume

## Key Result
- **entropy_z_negative**: greater language diversity associated with reduced GM volume
  - Peak T = 5.00, k = 1160 voxels, FDR corrected p = 0.010
  - Only FDR-corrected finding across the full multimodal study
- All other contrasts uncorrected only (p < 0.001 unc., k ≥ 10 voxels)

## Scripts
- `person_a.m` — Main pipeline: loads design matrix, locates mwp1 GM maps, 
   smooths (8mm FWHM), builds second-level GLM, estimates model, defines 4 contrasts
- `main.m` — Brain rendering: resamples T-maps to MNI template space, 
   generates axial slice figures with thresholded overlays, saves PDFs
- See `methods_notes.txt` for manual CAT12 preprocessing steps done via SPM GUI
  
## Data
- Dataset: NEBULA101 (OpenNeuro ds005613, Pliatsikas et al. 2024)
- N = 51 subjects (stratified subset preserving full nlang range)
- Design matrix: shared_design_matrix.csv

## Software
- CAT12 v26.0 rc3 / SPM25 v25.01.02
- MATLAB R2023b
