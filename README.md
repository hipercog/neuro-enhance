# neuro-enhance
Processing and Analysis of data from the Helsinki-Beijing collaborative education-intervention project 'Neuro-Enhance'

OPERATION STEPS
# 1
Download + Install:
  * Matlab R2018a or newer
  * EEGLAB, latest version,
      git clone https://github.com/eeglabdevelopers/eeglab.git
      (`firfilt` plugin is also needed but should be included in latest EEGLAB as standard)
  * BVA-IO, BrainVision Analyzer reader (for HELSINKI data only)
      git clone https://github.com/widmann/bva-io
  * CTAP,
      git clone https://github.com/bwrc/ctap.git
  * NeuroEnhance repo,
      git clone https://github.com/zenBen/neuro-enhance.git

# 2
Set your working directory to CTAP root (wherever you cloned CTAP)

# 3
Add EEGLAB (+BVA-IO, firfilt) and CTAP to your Matlab path. For a script to do this see
update_matlab_path_ctap.m at CTAP repository root

# 4
Set up a directory to contain the data files:
  * EEG datasets (BrainAmp .eeg format) from NeuroEnhance Finland pre/post-test
  * EEG datasets (EGI .raw format) from NeuroEnhance Beijing pre- and post-test
  * Pass the complete path to the data directory into the variable 'proj_root', below

# 5
On the Matlab console, execute >> neuroenhance_branch_fin
Parameterise as wished, see code for details
