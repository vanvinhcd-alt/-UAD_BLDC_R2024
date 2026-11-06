%% RUN_SAFECL_BLDC_FULL v2.2.3 -- 5-seed architecture development
clear;clc;close all;projectRoot=string(fileparts(mfilename("fullpath")));addpath(char(projectRoot));cfg=scu_config(projectRoot);cfg.quickMode=false;cfg.runAblation=true;rng(cfg.seed,'twister');
scu_check_requirements(cfg);data=scu_load_or_extract_features(cfg);results=scu_run_study(data,cfg);scu_export_results(results,data,cfg);fprintf('DEVELOPMENT FULL completed: %s\n',cfg.outputDir);fprintf('Run 20-seed confirmation ONLY if ReadyForLockedConfirmation=true.\n');
