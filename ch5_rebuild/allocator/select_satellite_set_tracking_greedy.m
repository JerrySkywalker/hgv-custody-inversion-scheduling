function selection = select_satellite_set_tracking_greedy(policy, k)
%SELECT_SATELLITE_SET_TRACKING_GREEDY  Return greedy selection at time index k.

if nargin < 1 || isempty(policy)
    error('policy is required.');
end
if nargin < 2 || isempty(k)
    k = 1;
end

if ~isfield(policy, 'schedule') || isempty(policy.schedule)
    error('policy.schedule is missing or empty.');
end

k = max(1, min(k, numel(policy.schedule)));

selection = struct();
selection.k = k;
selection.theta = policy.schedule{k};
selection.name = 'tracking_greedy_selection';
selection.meta = struct();
selection.meta.source = mfilename;
end
