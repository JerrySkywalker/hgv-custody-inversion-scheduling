function result = policy_tracking_dynamic(caseData, cfg)
%POLICY_TRACKING_DYNAMIC  Minimal tracking-oriented dynamic baseline.
%
% This phase-3 baseline uses real case objects and a simple tracking-oriented
% selection policy. The RMSE surrogate is tied to inner-loop position error
% and improves when more tracking satellites are selected.

if nargin < 2 || isempty(cfg)
    cfg = default_ch5_params();
end

inner = run_inner_loop_filter(caseData, cfg);

t = caseData.time.t(:);
N = numel(t);

selected_sets = cell(N, 1);
tracking_sat_count = zeros(N, 1);

for k = 1:N
    selected_ids = select_satellite_set_tracking(caseData, k, cfg);
    selected_sets{k} = selected_ids;
    tracking_sat_count(k) = numel(selected_ids);
end

base_err = inner.pos_err_norm(:);

% Minimal tracking surrogate:
%   0 sat -> worst
%   1 sat -> baseline
%   2 sat -> improved
rmse_scale = ones(N, 1);
rmse_scale(tracking_sat_count == 0) = 1.35;
rmse_scale(tracking_sat_count == 1) = 1.00;
rmse_scale(tracking_sat_count >= 2) = 0.82;

rmse_pos = base_err .* rmse_scale;

result = struct();
result.method = 'T';
result.time = t;
result.selected_sets = selected_sets;
result.tracking_sat_count = tracking_sat_count;
result.rmse_pos = rmse_pos;
end
