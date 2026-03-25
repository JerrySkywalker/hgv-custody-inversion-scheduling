function geometry_series = compute_geometry_series(vis_case, satbank)
%COMPUTE_GEOMETRY_SERIES Compute per-time geometry statistics for one case.
% Inputs:
%   vis_case         : visibility-case struct
%   satbank          : propagated constellation bank
%
% Output:
%   geometry_series  : LOS geometry series aligned with Stage03 outputs

geometry_series = legacy_compute_los_geometry_stage03_impl(vis_case, satbank);
end
