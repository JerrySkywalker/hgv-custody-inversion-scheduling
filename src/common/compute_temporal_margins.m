function out = compute_temporal_margins(dt_max_window, dt_req)
%COMPUTE_TEMPORAL_MARGINS Compute bounded and standardized temporal margins.

validateattributes(dt_req, {'numeric'}, {'real', 'finite', 'positive'});
validateattributes(dt_max_window, {'numeric'}, {'real', 'nonnegative'});

DT_bar_window = dt_req ./ (dt_req + dt_max_window);
DT_window = 2 .* DT_bar_window;

out = struct();
out.dt_max_window = dt_max_window;
out.dt_req = dt_req;
out.DT_bar_window = DT_bar_window;
out.DT_window = DT_window;
end
