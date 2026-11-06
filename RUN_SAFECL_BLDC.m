%% RUN_SAFECL_BLDC v2.2.3
clear;clc;close all;projectRoot=string(fileparts(mfilename("fullpath")));addpath(char(projectRoot));cfg=scu_config(projectRoot);rng(cfg.seed,'twister');
fprintf('\nSAFE-CL-UAD v%s Audited Multi-Bank | MATLAB %s\n',cfg.version,version);
try
    scu_check_requirements(cfg);data=scu_load_or_extract_features(cfg);results=scu_run_study(data,cfg);scu_export_results(results,data,cfg);fprintf('DONE: %s\n',cfg.outputDir);
catch ME
    if ~isfolder(cfg.outputDir),mkdir(cfg.outputDir);end;logPath=fullfile(cfg.outputDir,'RUN_ERROR_LOG.txt');fid=fopen(logPath,'w');if fid>=0,fprintf(fid,'%s\n',getReport(ME,'extended','hyperlinks','off'));fclose(fid);end;fprintf(2,'RUN FAILED [%s]\n%s\n',ME.identifier,ME.message);rethrow(ME);
end
