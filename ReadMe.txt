===================================================
===================fMRI decoding===================
===================================================

Task: fMRI-based visual stimulus reconstruction

--Y. Miyawaki et al., ''Visual image reconstruction from human brain activity using a combination of multiscale local image decoders,'' Neuron, vol. 60, no. 5, pp. 915–929, 2008.

How to run the code:

1. Download the fMRI dataset and preprocessing codes from http://brainliner.jp/data/brainliner/Visual_Image_Reconstruction

2. Generate the preprocessed fMRI .mat data using the 'make_fmri_mat_visRecon.m' script from the above-mentioned link

3. Move the preprocessed fMRI data 's1_fmri_roi-1to2mm_Th1_fromAna_s1071119ROI_resol10_v6.mat' to the 'fMRI-BasedVisualReconstruction' path

4. Run the 'MainVisualRecons.m' script in the 'fMRI-BasedVisualReconstruction' path which completes the training and evaluation of visual stimulus reconstruction

===================================================
===================ECoG decoding===================
===================================================

Task: ECoG-based movement trajectory reconstruction

--K. Shimoda et al., ''Decoding continuous three-dimensional hand trajectories from epidural electrocorticographic signals in japanese macaques,'' Journal of Neural Engineering, vol. 9, no. 3, p. 036015, 2012.

How to run the code:

1. Download the ECoG dataset from http://www.www.neurotycho.org/epidural-ecog-food-tracking-task

2. Move the downloaded dataset to the '/ECoG-BasedMovementReconstruction/data' folder as follows:

data/
├── MonkeyB/
│   ├── 20100623S1_Epidural-ECoG+Food-Tracking_B_Kentaro+Shimoda_mat_ECoG64-Motion6/
│         ├── ECoG_ch1.mat
│         ├── ECoG_ch2.mat
│         ├── ...
│         ├── ECoG_ch64.mat
│         ├── ECoG_time.mat
│         ├── Motion.mat
│   ├── 20100624S1_Epidural-ECoG+Food-Tracking_B_Kentaro+Shimoda_mat_ECoG64-Motion6/
│         ├── ECoG_ch1.mat
│         ├── ECoG_ch2.mat
│         ├── ...
│         ├── ECoG_ch64.mat
│         ├── ECoG_time.mat
│         ├── Motion.mat
│   ├── ...
│   └── 20100802S1_Epidural-ECoG+Food-Tracking_B_Kentaro+Shimoda_mat_ECoG64-Motion6/
├── MonkeyC/
│   ├── 20090915S1_Epidural-ECoG+Food-Tracking_C_Kentaro+Shimoda_mat_ECoG64-Motion6/
│         ├── ECoG_ch1.mat
│         ├── ECoG_ch2.mat
│         ├── ...
│         ├── ECoG_ch64.mat
│         ├── ECoG_time.mat
│         ├── Motion.mat
│   ├── 20091007S1_Epidural-ECoG+Food-Tracking_C_Kentaro+Shimoda_mat_ECoG64-Motion6/
│         ├── ECoG_ch1.mat
│         ├── ECoG_ch2.mat
│         ├── ...
│         ├── ECoG_ch64.mat
│         ├── ECoG_time.mat
│         ├── Motion.mat
│   ├── ...
│   └── 20091110S2_Epidural-ECoG+Food-Tracking_C_Kentaro+Shimoda_mat_ECoG64-Motion6/

3. Generate the wavelet features from preprocessed ECoG data by running the 'MainPreprocess.m' script in the 'ECoG-BasedMovementReconstruction/preprocess' folder

4. Run the 'MainDecoding.m' script in the 'ECoG-BasedMovementReconstruction/decoding' folder which completes the training and evaluation of movement trajectory reconstruction
