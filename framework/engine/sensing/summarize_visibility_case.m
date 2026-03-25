function summary = summarize_visibility_case(vis_case, geometry_series)
%SUMMARIZE_VISIBILITY_CASE Summarize one visibility/geometry case.
% Inputs:
%   vis_case         : visibility-case struct
%   geometry_series  : geometry-series struct
%
% Output:
%   summary          : per-case summary struct

summary = legacy_summarize_visibility_case_stage03_impl(vis_case, geometry_series);
end
