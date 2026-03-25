function window_case = compute_window_metric(vis_case, satbank, engine_cfg)
%COMPUTE_WINDOW_METRIC Compute worst-window metrics for one visibility case.
% Inputs:
%   vis_case   : visibility-case struct
%   satbank    : propagated constellation bank
%   engine_cfg : engine configuration tree; defaults to default_params()
%
% Output:
%   window_case: Stage04-style worst-window scan result

if nargin < 3 || isempty(engine_cfg)
    engine_cfg = default_params();
end

window_case = legacy_scan_worst_window_stage04_impl(vis_case, satbank, engine_cfg);
end
