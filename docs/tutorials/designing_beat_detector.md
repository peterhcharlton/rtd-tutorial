# Designing a Beat Detector

The tutorials on this page demonstrate the processes undertaken to design MSPTDfast, an efficient PPG beat detection algorithm.

## Designing MSPTDfast (v.1)

This tutorial demonstrates the processes undertaken to design MSPTDfast (v.1), which was designed using a single dataset. The publication describing this work is available [here](https://doi.org/10.1101/2024.07.18.24310627).

- Install the PPG-beats toolbox. _The usual instructions [here](https://ppg-beats.readthedocs.io/en/latest/toolbox/getting_started/) are for downloading the latest version of the toolbox, whereas you will need the [v.2.0](https://github.com/peterhcharlton/ppg-beats/releases/tag/v.2.0) release to replicate the analysis exactly. This can be downloaded from [here](https://github.com/peterhcharlton/ppg-beats/archive/refs/tags/v.2.0.zip)._
- Download the PPG-DaLiA dataset in Matlab format from [here](https://zenodo.org/records/12793711/files/ppg_dalia_lunch_break_data.mat?download=1).
- Use the `assess_multiple_datasets.m` script to run the analysis.
- During this process a new folder will have been created called `proc_data_ppg_dalia_lunch_break`. Within this folder you will find files storing the analysis steps, including the file containing the results: the `ppg_detect_stats.mat` file. Note down the location of this file.
- Finally, analyse the performance of the different algorithm configuration options by running the [msptdfast_cinc_analysis.m](https://raw.githubusercontent.com/peterhcharlton/ppg-beats/main/source/publication_specific_scripts/msptdfast_cinc_analysis_post_20240701.m) script.

This tutorial is demonstrated in the following video:

<iframe width="560" height="315" src="https://www.youtube.com/embed/MuNOddpluL0" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Designing MSPTDfast (v.2)

This tutorial demonstrates the processes undertaken to design MSPTDfast (v.2), which was designed using multiple development datasets, and then benchmarked against state-of-the-art algorithms on multiple testing datasets. The publication describing this work is available [here](https://peterhcharlton.github.io/publication/charlton2024-msptdfast/).

- Install the PPG-beats toolbox. _The usual instructions [here](https://ppg-beats.readthedocs.io/en/latest/toolbox/getting_started/) are for downloading the latest version of the toolbox, whereas you will need the [v.2.2](https://github.com/peterhcharlton/ppg-beats/releases/tag/v.2.2) release to replicate the analysis exactly. This can be downloaded from [here](https://github.com/peterhcharlton/ppg-beats/archive/refs/tags/v.2.2.zip)._
- Download the required datasets in Matlab format by following the instructions [here](https://ppg-beats.readthedocs.io/en/latest/datasets/summary/). The required datasets are: CapnoBase, BIDMC, MIMIC PERform Training, MIMIC PERform Testing, MIMIC PERform AF, MIMIC PERform Ethnicity, WESAD, and PPG-DaLiA.
- Use the `assess_multiple_datasets.m` script to run the analysis. Use one of the following options:
   - To follow the design process: set `do_msptdfastv2_design` to 1 on lines 633 and 1143 of `assess_multiple_datasets.m`.
   - To follow the internal validation process: set `do_msptdfastv2_internal_validation` to 1 on lines 638 and 1149 of `assess_multiple_datasets.m`.
   - To follow the benchmarking process: set `do_msptdfastv2_benchmarking` to 1 on lines 643 and 1155 of `assess_multiple_datasets.m`.
-  During this process a new folder will have been created called `proc_data_<dataset name>`. Within this folder you will find files storing the analysis steps, including the file containing the results: the `ppg_detect_stats.mat` file. Note down the location of this file for each dataset.
- Then, run further analyses using the following additional scripts (adjusting the file paths in the scripts to provide the paths to the files mentioned above):
   - To follow the design analysis: use `msptdfastv2_design.m`.
   - To follow the internal validation analysis: use `msptdfastv2_internal_validation.m`.
   - To follow the benchmarking analysis: use `msptdfastv2_testing.m`. To generate the results for performance at different SNRs, you will need to set: `uParams.analysis.sig_qual_tools = {'accel'; 'ppgq'};' on line 152 of `assess_beat_detectors.m'. You will also require the [ppg-quality](https://ppg-quality.readthedocs.io/) toolbox.
   - To produce the examples of PPG beat detection challenges (shown in Fig. 7 of the publication), use `make_plot_of_ppg_beat_detection_challenges_msptdfastv2.m'