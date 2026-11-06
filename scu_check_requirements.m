function root = scu_check_requirements(cfg)
%SCU_CHECK_REQUIREMENTS MATLAB/package/dataset validation for v2.2.3.
if verLessThan('matlab','24.1'),error('SAFECL:MATLABVersion','MATLAB R2024a (24.1) or newer is required.');end
if exist('parquetread','file')~=2,error('SAFECL:Parquet','parquetread is unavailable.');end
required=["scu_config.m","scu_read_metadata.m","scu_load_or_extract_features.m","scu_extract_segment_features.m","scu_signal_features.m", ...
    "scu_build_protocol.m","scu_fit_encoder.m","scu_encode.m","scu_feature_view_masks.m","scu_fit_multiview_encoder.m","scu_encode_multiview.m", ...
    "scu_subset_views.m","scu_fit_bank.m","scu_score_bank.m","scu_fit_multiview_bank.m","scu_score_multiview_bank.m", ...
    "scu_multibank_initialize.m","scu_multibank_score.m","scu_multibank_update.m","scu_multibank_all_ids.m", ...
    "scu_fit_adaptive_multiview_bank.m","scu_verify_candidate_lobo.m", ...
    "scu_run_method.m","scu_metrics.m","scu_run_study.m","scu_research_readiness.m","scu_export_results.m","scu_plot_results.m"];
missing=required(~isfile(fullfile(cfg.projectRoot,required)));if ~isempty(missing),error('SAFECL:ProgramFiles','Package incomplete: %s',strjoin(missing,', '));end
root=resolveRoot(cfg);trainDir=fullfile(root,'train');testDir=fullfile(root,'test');
checkFiles(trainDir,["attributes_normal_source_train.csv","attributes_normal_target_train.csv"]);
checkFiles(testDir,["attributes_normal_source_test.csv","attributes_anomaly_source_test.csv","attributes_normal_target_test.csv","attributes_anomaly_target_test.csv"]);
if isempty(dir(fullfile(trainDir,'*.parquet')))||isempty(dir(fullfile(testDir,'*.parquet'))),error('SAFECL:ParquetFiles','No parquet files directly under train/test.');end
for d=[string(cfg.outputDir),string(cfg.cacheDir),string(cfg.figureDir),string(cfg.csvDir)],if ~isfolder(d),mkdir(d);end,end
fprintf('Dataset verified: %s\nMATLAB verified: %s\n',root,version);
end
function root=resolveRoot(cfg)
p=string(cfg.projectRoot);input=string(cfg.dataRoot);c=strings(0,1);if strlength(input)>0,c(end+1,1)=input;c(end+1,1)=string(fullfile(input,'BrushlessMotor'));end
c(end+1,1)=string(fullfile(p,'BrushlessMotor'));c(end+1,1)=string(fullfile(p,'data','BrushlessMotor'));c(end+1,1)=string(fullfile(p,'data'));c=unique(c(strlength(c)>0),'stable');root="";
for i=1:numel(c),if isfolder(fullfile(c(i),'train'))&&isfolder(fullfile(c(i),'test')),root=c(i);break;elseif isfolder(fullfile(c(i),'BrushlessMotor','train')),root=fullfile(c(i),'BrushlessMotor');break;end,end
if root=="",error('SAFECL:DataRoot','Cannot locate BrushlessMotor/train and test. Edit cfg.dataRoot.');end
end
function checkFiles(folder,names),missing=names(~isfile(fullfile(folder,names)));if ~isempty(missing),error('SAFECL:Metadata','Missing metadata in %s: %s',folder,strjoin(missing,', '));end,end
