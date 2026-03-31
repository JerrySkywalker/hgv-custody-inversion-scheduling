function caseData = build_ch5_case(cfg)
%BUILD_CH5_CASE  Build a minimal chapter 5 case object for smoke testing.
%
% This function intentionally avoids any modification to chapter 4 code.
% In phase 0, it only builds a lightweight wrapped scene summary.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5_params();
end

t = (cfg.time.t0:cfg.time.dt:cfg.time.tf).';

num_sats = cfg.constellation.num_planes * cfg.constellation.sats_per_plane;

% Minimal placeholder candidate-count profile.
candidate_count = zeros(size(t));
for k = 1:numel(t)
    candidate_count(k) = 2 + mod(k-1, max(1, min(4, num_sats)));
end

caseData = struct();
caseData.meta = struct();
caseData.meta.phase_name = cfg.phase_name;
caseData.meta.created_from = mfilename;
caseData.meta.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

caseData.time = t;
caseData.num_steps = numel(t);

caseData.target = cfg.target;
caseData.constellation = cfg.constellation;
caseData.sensor = cfg.sensor;

caseData.candidates = struct();
caseData.candidates.count = candidate_count;
caseData.candidates.min_count = min(candidate_count);
caseData.candidates.max_count = max(candidate_count);
caseData.candidates.mean_count = mean(candidate_count);

caseData.summary = struct();
caseData.summary.time_start = cfg.time.t0;
caseData.summary.time_end = cfg.time.tf;
caseData.summary.dt = cfg.time.dt;
caseData.summary.num_steps = numel(t);
caseData.summary.num_sats = num_sats;
caseData.summary.min_candidate_count = min(candidate_count);
caseData.summary.max_candidate_count = max(candidate_count);
caseData.summary.mean_candidate_count = mean(candidate_count);
end
