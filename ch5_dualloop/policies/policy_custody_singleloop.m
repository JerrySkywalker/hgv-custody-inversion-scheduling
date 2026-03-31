function result = policy_custody_singleloop(caseData, cfg)
%POLICY_CUSTODY_SINGLELOOP  Minimal single-loop custody-oriented dynamic policy.

if nargin < 2 || isempty(cfg)
    cfg = default_ch5_params();
end

inner = run_inner_loop_filter(caseData, cfg);

t = caseData.time.t(:);
N = numel(t);

selected_sets = cell(N, 1);
tracking_sat_count = zeros(N, 1);
switch_indicator = zeros(N, 1);

prev_ids = [];
for k = 1:N
    selected_ids = select_satellite_set_custody(caseData, k, prev_ids, cfg);
    selected_sets{k} = selected_ids;
    tracking_sat_count(k) = numel(selected_ids);

    if k > 1
        switch_indicator(k) = ~isequal(prev_ids, selected_ids);
    end
    prev_ids = selected_ids;
end

base_err = inner.pos_err_norm(:);

% C should favor continuity, so its RMSE can be slightly worse than T
rmse_scale = ones(N, 1);
rmse_scale(tracking_sat_count == 0) = 1.45;
rmse_scale(tracking_sat_count == 1) = 1.02;
rmse_scale(tracking_sat_count >= 2) = 0.90;

rmse_pos = base_err .* rmse_scale;

result = struct();
result.method = 'C';
result.time = t;
result.selected_sets = selected_sets;
result.tracking_sat_count = tracking_sat_count;
result.switch_indicator = switch_indicator;
result.rmse_pos = rmse_pos;
end
