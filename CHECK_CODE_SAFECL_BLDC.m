%% CHECK_CODE_SAFECL_BLDC v2.2.3
clear;clc;root=string(fileparts(mfilename('fullpath')));addpath(char(root));
files=["RUN_SAFECL_BLDC.m","RUN_SAFECL_BLDC_QUICK.m","RUN_SAFECL_BLDC_FULL.m","RUN_SAFECL_BLDC_CONFIRMATION.m","SELF_TEST_SAFECL_BLDC.m", ...
"scu_config.m","scu_build_protocol.m","scu_fit_multiview_encoder.m","scu_encode_multiview.m","scu_multibank_initialize.m","scu_multibank_score.m","scu_multibank_update.m","scu_fit_adaptive_multiview_bank.m","scu_verify_candidate_lobo.m","scu_select_compact_diverse_seed.m","scu_ambiguity_risk.m","scu_seed_model_health.m","scu_run_method.m"];
missing=files(~isfile(fullfile(root,files)));assert(isempty(missing),'Missing files: %s',strjoin(missing,', '));fprintf('Core v2.2.3 files present: %d\n',numel(files));SELF_TEST_SAFECL_BLDC;
