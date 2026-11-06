%% RUN_SAFECL_BLDC_QUICK v2.2.3 -- execution/protocol validation only
clear;clc;close all;projectRoot=string(fileparts(mfilename("fullpath")));addpath(char(projectRoot));cfg=scu_config(projectRoot);cfg.quickMode=true;cfg.runAblation=false;rng(cfg.seed,'twister');
scu_check_requirements(cfg);data=scu_load_or_extract_features(cfg);results=scu_run_study(data,cfg);scu_export_results(results,data,cfg);fprintf('QUICK completed: %s\n',cfg.outputDir);fprintf('Do not use QUICK as thesis evidence.\n');
