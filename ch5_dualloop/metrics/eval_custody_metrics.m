function summary = eval_custody_metrics(result)
%EVAL_CUSTODY_METRICS  Evaluate custody-oriented metrics from result struct.
%
% Required fields in result:
%   time
%   phi_series
%   threshold
%
% Outputs:
%   q_worst_point   - pointwise minimum of phi_series
%   q_worst_window  - minimum rolling-window mean of phi_series
%   q_worst         - alias to q_worst_window (chapter-5 preferred)
%   phi_mean
%   outage_ratio
%   longest_outage_steps
%   sc_ratio
%   dc_ratio
%   loc_ratio

assert(isfield(result, 'phi_series'), 'Result must contain field: phi_series');
assert(isfield(result, 'time'), 'Result must contain field: time');

phi = result.phi_series(:);
t = result.time(:);

if isfield(result, 'threshold') && ~isempty(result.threshold)
    threshold = result.threshold;
else
    threshold = 0.45;
end

N = numel(phi);

% pointwise worst value
q_worst_point = min(phi);

% window worst value: use local rolling mean as chapter-5 window metric
if N <= 1
    phi_roll = phi;
else
    % default 20-step window to align with current chapter-5 experiments
    W = min(20, N);
    phi_roll = movmean(phi, [W-1, 0], 'Endpoints', 'shrink');
end

q_worst_window = min(phi_roll);

bad = (phi < threshold);

summary = struct();
summary.time = t;
summary.phi_series = phi;
summary.threshold = threshold;

summary.q_worst_point = q_worst_point;
summary.q_worst_window = q_worst_window;
summary.q_worst = q_worst_window;

summary.phi_mean = mean(phi);
summary.outage_ratio = mean(bad);
summary.longest_outage_steps = local_longest_run(bad);

summary.sc_ratio = mean(phi >= threshold);
summary.dc_ratio = mean((phi < threshold) & (phi > 0));
summary.loc_ratio = mean(phi <= 0);
end

function L = local_longest_run(flag)
if isempty(flag)
    L = 0;
    return;
end

flag = flag(:) > 0;
d = diff([0; flag; 0]);
s = find(d == 1);
e = find(d == -1) - 1;

if isempty(s)
    L = 0;
else
    L = max(e - s + 1);
end
end
