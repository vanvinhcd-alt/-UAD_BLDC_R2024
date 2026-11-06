%% RUN_SAFECL_BLDC_CONFIRMATION v2.2.3 -- LOCKED 20-seed confirmation
% Run only after the unchanged v2.2.3 development package passes all Development gates.
clear;clc;close all;projectRoot=string(fileparts(mfilename("fullpath")));addpath(char(projectRoot));cfg=scu_config(projectRoot);cfg.quickMode=false;cfg.runAblation=false;cfg.fullSeeds=cfg.confirmationSeeds;
cfg.outputDir=fullfile(projectRoot,'results_safecl_bldc_v223_CONFIRMATION');cfg.figureDir=fullfile(cfg.outputDir,'figures');cfg.csvDir=fullfile(cfg.outputDir,'tables_csv');cfg.resultWorkbook='SAFECL_BLDC_v223_CONFIRMATION_Results.xlsx';cfg.resultMat='SAFECL_BLDC_v223_CONFIRMATION_Results.mat';rng(cfg.seed,'twister');
scu_check_requirements(cfg);data=scu_load_or_extract_features(cfg);results=scu_run_study(data,cfg);scu_export_results(results,data,cfg);
if all(results.ReadinessCriteria.ThesisReady),fprintf('LOCKED CONFIRMATION PASS.\n');else,fprintf('At least one locked thesis gate FAILED.\n');end
