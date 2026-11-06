function cfg = scu_config(projectRoot)
%SCU_CONFIG SAFE-CL-UAD v2.2.3 Ambiguity-Aware Verified Bank configuration.
% MATLAB R2024a. The v2 architecture intentionally resets the adaptive
% subsystem while keeping the validated BLDC feature extractor.

if nargin < 1 || strlength(string(projectRoot)) == 0
    projectRoot = string(fileparts(mfilename("fullpath")));
else
    projectRoot = string(projectRoot);
end

cfg.version = "2.2.3";
cfg.featurePipelineVersion = "1.0.2"; % feature extraction unchanged
cfg.projectRoot = projectRoot;
cfg.dataRoot = "D:\Datasets\BrushlessMotor\BrushlessMotor";

%% Run control
cfg.seed = 42;
cfg.quickMode = true;
cfg.useFeatureCache = true;
cfg.forceRebuildCache = false;
cfg.runAblation = true;
cfg.makeFigures = true;
cfg.writeExcel = true;
cfg.verbose = true;
cfg.fullSeeds = [42 142 242 342 442];
cfg.confirmationSeeds = 42:100:1942; % 20 seeds, only after development PASS
cfg.contaminationLevelsQuick = [0 0.10];
cfg.contaminationLevelsFull  = [0 0.01 0.05 0.10 0.20 0.30 -1];
cfg.contaminationAbsTolerance = 0.015;

%% Data / features
cfg.windowSeconds = 0.100;
cfg.gyroWarmupSeconds = 0.035;
cfg.sensorNames = ["imp23absu_mic","ism330dhcx_acc","ism330dhcx_gyro"];
cfg.sensorShort = ["Mic","Acc","Gyro"];
cfg.nominalFs = [16000 7063 7063];
cfg.expectedChannels = [1 3 3];
cfg.maxWindowsPerSegmentQuick = 5;
cfg.maxWindowsPerSegmentFull = inf;
cfg.minSamplesPerWindow = 16;
cfg.maxSegmentsQuickTrain = 180;
cfg.maxSegmentsQuickTest = 180;

%% Representation
cfg.pcaVariance = 0.95;
cfg.pcaMinDim = 4;
cfg.pcaMaxDim = 30;
cfg.viewPcaVariance = 0.95;
cfg.viewPcaMinDim = 3;
cfg.viewPcaMaxDim = 16;
cfg.robustZClip = 12;

%% Audited protocol
cfg.sourceFitFraction = 0.60;
cfg.sourceCalFraction = 0.20;
cfg.evalFraction = 0.50;
cfg.minEvalPerClassPerEpisode = 1;
cfg.batchSize = 12;
cfg.shuffleWithinEpisode = true;
cfg.includeTargetTrainInStream = true;
cfg.contaminationAllocation = "GLOBAL_STRATIFIED_GROUP_SAFE";
cfg.contaminationAdaptFraction = 0.50;
cfg.requireGroupDisjoint = true;
cfg.groupStripRegex = "(?i)(?:[_-]?(?:segment|datalog|part|window)[_-]?\d+)$";

%% Bank scoring
cfg.knnK = 5;
cfg.scoreKnnWeight = 0.55;
cfg.scoreMahWeight = 0.45;
cfg.bankThresholdQuantile = 0.95;
cfg.covShrinkage = 0.10;
cfg.minBankFit = 8;
cfg.minBankCal = 4;
cfg.maxSourceMemory = 160;

% IMPORTANT: baseline memory is frozen across every v2 experiment.
cfg.baselineAdaptiveMemory = 120;

%% SAFE-CL v2 multi-bank capacity
cfg.safeMaxBanks = 4; % framework capacity; BLDC main study locks verified target-bank birth below
cfg.maxVerifiedTargetBanksBLDC = 1;
cfg.safeBankSeedMax = 24;
cfg.safeBankDynamicMax = 40;
cfg.safeTotalDynamicMax = 120;
cfg.safeMinSeedSamples = 12;
cfg.safeSeedTargetN = 12; % v2.2.3 compact immutable seed
cfg.safeMinSeedBatches = 4;
cfg.safeRefitFitFraction = 0.67;

%% Protected routing / direct update
cfg.sourceProtectScore = 1.00;
cfg.routeAdaptiveMaxScore = 1.20;
cfg.routeAdaptiveVsSourceRatio = 0.95;
cfg.routeViewMaxScore = 1.25;
cfg.routeViewVsSourceRatio = 0.98;
cfg.routeMinViewVotes = 2;
cfg.safeDirectScore = 0.80;
cfg.safeAdaptiveDirectScore = 0.72;
cfg.reliabilityBeta = 1.0;
cfg.safeReliabilityMin = exp(-cfg.reliabilityBeta*cfg.safeDirectScore);

%% Drift / candidate reservoir
cfg.driftWindowSamples = 12;
cfg.driftQuantile = 0.99;
cfg.driftThresholdInflation = 1.20;
cfg.driftBootstrapRepeatsQuick = 50;
cfg.driftBootstrapRepeatsFull = 300;
cfg.driftConsecutiveBatches = 2;
cfg.driftCooldownBatches = 1;
cfg.candidateSourceScoreMin = 0.80;
cfg.candidateSourceScoreMax = 2.20;
cfg.candidateMinSamples = 14;
cfg.candidateMinBatches = 5;
cfg.candidateMaxSamples = 120;
cfg.candidateMaxAgeBatches = 60;
cfg.candidateDensityKeepFraction = 0.65; % legacy/audit only; v2.1 uses continuous consensus
cfg.candidateCrossBatchK = 3;
cfg.candidateMinViewVotes = 2;
cfg.candidateMinConsensusFraction = 0.60; % legacy/audit only
cfg.candidateMaxSourceAnchorRouteFraction = 0.15;
cfg.candidateMergeMedianScore = 1.00;
cfg.candidateMergeMinViewFraction = 0.60;
cfg.candidateCooldownBatches = 2;
cfg.candidateRejectPruneFraction = 0.20; % used only after explicit unsafe LOBO evidence
cfg.candidateConsensusFusedWeight = 0.45;
cfg.candidateCoreConsensusWeight = 0.60;
cfg.candidateCoreFraction = 0.85;
cfg.candidateLOBOFusedMaxScore = 1.60;
cfg.candidateLOBOViewMaxScore = 1.75;
cfg.candidateLOBOMinViewVotes = 2;
cfg.candidateLOBOMinPassFraction = 0.70;
cfg.candidateLOBOMinFolds = 4;
cfg.candidateLOBOMinEligibleSamples = 10;
cfg.candidateRejectMinSamples = 24;
cfg.candidateRejectMaxPassFraction = 0.35;

%% Rapid-Unresolved-Novelty abstention (development-locked from v2.1 diagnostic)
% Candidate accumulation rate = unique candidate samples / current stream batch.
% Mic DeltaBIC compares 1-mode versus 2-mode diagonal-Gaussian descriptions
% in the first up-to-3 frozen Mic latent coordinates. No labels are used.
cfg.ambiguityEnabled = true;
cfg.ambiguityEarlyScreenEnabled = true; % v2.2.3: screen before LOBO/calibrated-seed readiness
cfg.ambiguityAccumulationRateHigh = 2.08;
cfg.ambiguityMicDeltaBICLow = 7.30;
cfg.ambiguityLatentDims = 3;
cfg.ambiguityKmeansStarts = 20;
cfg.ambiguityMinSamples = 12;
cfg.ambiguityLockBankBirthOnHighRisk = true;

%% Immutable-seed admission for dynamic updates
cfg.seedAdmissionFusedMaxScore = 1.20;
cfg.seedAdmissionViewMaxScore = 1.25;
cfg.seedAdmissionMinViewVotes = 2;

%% Seed-referenced local health and localized dynamic rollback
cfg.healthEMADecay = 0.80;
cfg.healthSeedCenterDriftMax = 1.00;
cfg.healthSeedCovInflationMax = 2.00;
cfg.healthSeedThresholdInflationMax = 1.50;
cfg.healthDynamicSeedMedianMax = 1.20;
cfg.healthBadStreakForRollback = 2;
cfg.healthDynamicFreezeBatches = 6;
cfg.healthMaxRepeatedRollbacks = 3;

%% Baselines / ablations
cfg.defaultMethods = ["Static","Naive","Replay","SafeCL_MB"];
cfg.ablationMethods = ["SafeCL_MB_NoAmbiguity","SafeCL_MB_NoSeedGuard"];
cfg.replayAcceptScore = 1.00;

%% Metrics
cfg.fprTarget = 0.10;
cfg.bootstrapRepeatsQuick = 100;
cfg.bootstrapRepeatsFull = 1000;

%% Development / thesis readiness -- post-hoc only
cfg.readinessMinSeedsForThesis = 20;
cfg.readinessCleanTargetGainVsStatic = 0.10;
cfg.readinessCleanOverallGainVsStatic = 0.03;
cfg.readinessMinAUC10 = 0.90;
cfg.readinessMinTargetAUC10 = 0.85;
cfg.readinessMaxMemoryContam10 = 0.05;
cfg.readinessMaxMemoryContam20 = 0.08;
cfg.readinessMaxMemoryContam30 = 0.12;
cfg.readinessMaxNaturalMemoryContam = 0.10;
cfg.readinessMinAUC10VsReplayDelta = 0.03;
cfg.readinessMinNaturalAUCVsStaticDelta = -0.02;
cfg.readinessMinTarget20GainVsStatic = 0.05;
cfg.readinessMinPrimarySeedPassRate = 0.80;
cfg.readinessMaxControlledFalseAbstentionRate = 1/30; % <=1 false abstention in 30 development runs
cfg.readinessMinNaturalAbstentionRate = 0.80;

%% Output
cfg.outputDir = fullfile(projectRoot,"results_safecl_bldc_v223");
cfg.cacheDir = fullfile(projectRoot,"cache_safecl_bldc");
cfg.figureDir = fullfile(cfg.outputDir,"figures");
cfg.csvDir = fullfile(cfg.outputDir,"tables_csv");
cfg.resultWorkbook = "SAFECL_BLDC_v223_Results.xlsx";
cfg.resultMat = "SAFECL_BLDC_v223_Results.mat";
cfg.featureCacheName = "BLDC_segment_features_SAFECL_v1_0_2.mat";
end
