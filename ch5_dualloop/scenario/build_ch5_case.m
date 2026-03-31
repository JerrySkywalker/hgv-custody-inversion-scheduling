function caseData = build_ch5_case(cfg)
%BUILD_CH5_CASE  Build a unified chapter 5 case object using real wrapped engines.
%
% Phase 2.5C target:
%   - truth from Stage02 engine wrapper
%   - satbank from Stage03 engine wrapper
%   - candidates from Stage03 visibility wrapper
%   - no modification to chapter 4 code

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end

profile = build_ch5_target_profile(cfg);
truth = build_ch5_truth_from_stage02_engine(profile, cfg);
satbank = build_ch5_satbank_from_stage03_engine(cfg, truth.t);
candidates = build_ch5_candidates_from_stage03_engine(truth, satbank, cfg);

num_steps = numel(truth.t);
num_sats = satbank.Ns;

caseData = struct();

caseData.meta = struct();
caseData.meta.phase_name = cfg.phase_name;
caseData.meta.created_from = mfilename;
caseData.meta.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

caseData.cfg = cfg;
caseData.profile = profile;

caseData.time = struct();
caseData.time.t = truth.t(:);
caseData.time.t0 = truth.t(1);
caseData.time.tf = truth.t(end);
caseData.time.dt = median(diff(truth.t(:)));
caseData.time.num_steps = num_steps;

caseData.target = cfg.target;
caseData.constellation = cfg.constellation;
caseData.sensor = cfg.sensor;

caseData.truth = truth;
caseData.satbank = satbank;
caseData.candidates = candidates;

caseData.summary = struct();
caseData.summary.time_start = caseData.time.t0;
caseData.summary.time_end = caseData.time.tf;
caseData.summary.dt = caseData.time.dt;
caseData.summary.num_steps = num_steps;
caseData.summary.num_sats = num_sats;
caseData.summary.min_candidate_count = candidates.min_count;
caseData.summary.max_candidate_count = candidates.max_count;
caseData.summary.mean_candidate_count = candidates.mean_count;
end
