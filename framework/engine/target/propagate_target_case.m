function traj = propagate_target_case(case_item, engine_cfg)
%PROPAGATE_TARGET_CASE Propagate one target case trajectory.
% Inputs:
%   case_item  : Stage01/Stage06 case struct
%   engine_cfg : engine configuration tree; defaults to default_params()
%
% Output:
%   traj       : propagated trajectory struct aligned with Stage02 outputs

if nargin < 2 || isempty(engine_cfg)
    engine_cfg = default_params();
end

traj = legacy_propagate_target_case_stage02_impl(case_item, engine_cfg);
end
