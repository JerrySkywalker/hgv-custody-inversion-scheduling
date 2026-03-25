function vis_case = compute_visibility_matrix(traj_case, satbank, engine_cfg)
%COMPUTE_VISIBILITY_MATRIX Compute target-satellite visibility for one case.
% Inputs:
%   traj_case  : struct with fields .case and .traj
%   satbank    : propagated constellation bank
%   engine_cfg : engine configuration tree; defaults to default_params()
%
% Output:
%   vis_case   : visibility-case struct aligned with Stage03 outputs

if nargin < 3 || isempty(engine_cfg)
    engine_cfg = default_params();
end

vis_case = legacy_compute_visibility_matrix_stage03_impl(traj_case, satbank, engine_cfg);
end
