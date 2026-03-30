function pack = plot_stage09_joint_stage05_pack(out_or_view, mode_tag)
%PLOT_STAGE09_JOINT_STAGE05_PACK
% Thin wrapper for joint Stage05-style ninepack plotting.

    if nargin < 2 || isempty(mode_tag)
        mode_tag = 'phase2_joint';
    end

    [metric_view, metric_frontiers, cfg] = local_unpack_inputs(out_or_view);
    pack = plot_stage09_metric_stage05_ninepack(metric_view.joint, metric_frontiers.joint, 'DG', cfg, mode_tag);
end


function [metric_view, metric_frontiers, cfg] = local_unpack_inputs(in)

    if isstruct(in) && isfield(in, 'metric_view') && isfield(in, 'metric_frontiers') && isfield(in, 'cfg')
        metric_view = in.metric_view;
        metric_frontiers = in.metric_frontiers;
        cfg = in.cfg;
        return;
    end

    error('plot_stage09_joint_stage05_pack:InvalidInput', ...
        'Input must be the output struct from manual_smoke_stage09_phase1_metric_views.');
end
