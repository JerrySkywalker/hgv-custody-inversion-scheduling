function caseData = build_ch5_case(cfg)
%BUILD_CH5_CASE  Build a unified chapter 5 case object.
%
% Phase 1 target:
%   - unified scenario object
%   - no policy yet
%   - no chapter 4 code modification

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end

t = (cfg.time.t0:cfg.time.dt:cfg.time.tf).';
num_steps = numel(t);
num_sats = cfg.constellation.num_planes * cfg.constellation.sats_per_plane;

% Minimal placeholder target truth trajectory for shell-stage development.
truth = struct();
truth.t = t;
truth.x = 1000 + 2.0 * t;
truth.y = 500 + 1.0 * t;
truth.z = 80 + 0.05 * t;

% Minimal placeholder candidate-count profile.
candidate_count = zeros(size(t));
for k = 1:num_steps
    candidate_count(k) = 2 + mod(k-1, max(1, min(4, num_sats)));
end

% Minimal placeholder candidate index list.
candidate_sets = cell(num_steps, 1);
for k = 1:num_steps
    candidate_sets{k} = 1:candidate_count(k);
end

caseData = struct();

caseData.meta = struct();
caseData.meta.phase_name = cfg.phase_name;
caseData.meta.created_from = mfilename;
caseData.meta.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

caseData.cfg = cfg;

caseData.time = struct();
caseData.time.t = t;
caseData.time.t0 = cfg.time.t0;
caseData.time.tf = cfg.time.tf;
caseData.time.dt = cfg.time.dt;
caseData.time.num_steps = num_steps;

caseData.target = cfg.target;
caseData.constellation = cfg.constellation;
caseData.sensor = cfg.sensor;

caseData.truth = truth;

caseData.candidates = struct();
caseData.candidates.count = candidate_count;
caseData.candidates.sets = candidate_sets;
caseData.candidates.min_count = min(candidate_count);
caseData.candidates.max_count = max(candidate_count);
caseData.candidates.mean_count = mean(candidate_count);

caseData.summary = struct();
caseData.summary.time_start = cfg.time.t0;
caseData.summary.time_end = cfg.time.tf;
caseData.summary.dt = cfg.time.dt;
caseData.summary.num_steps = num_steps;
caseData.summary.num_sats = num_sats;
caseData.summary.min_candidate_count = min(candidate_count);
caseData.summary.max_candidate_count = max(candidate_count);
caseData.summary.mean_candidate_count = mean(candidate_count);
end
