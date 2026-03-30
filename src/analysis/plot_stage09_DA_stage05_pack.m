function pack = plot_stage09_DA_stage05_pack(out_or_view, mode_tag)
%PLOT_STAGE09_DA_STAGE05_PACK
% Thin wrapper for DA Stage05-style ninepack plotting.

    if nargin < 2 || isempty(mode_tag)
        mode_tag = 'phase2_DA';
    end

    [metric_view, metric_frontiers, cfg] = local_unpack_inputs(out_or_view);
    pack = plot_stage09_metric_stage05_ninepack(metric_view.DA, metric_frontiers.DA, 'DA', cfg, mode_tag);
end


function [metric_view, metric_frontiers, cfg] = local_unpack_inputs(in)

    if ~isstruct(in)
        error('plot_stage09_DA_stage05_pack:InvalidInput', ...
            'Input must be a struct.');
    end

    if isfield(in, 'metric_view') && isfield(in, 'metric_frontiers')
        metric_view = in.metric_view;
        metric_frontiers = in.metric_frontiers;
    elseif isfield(in, 'views') && isfield(in, 'frontiers')
        metric_view = in.views;
        metric_frontiers = in.frontiers;
    else
        error('plot_stage09_DA_stage05_pack:InvalidInput', ...
            ['Input must contain either:' newline ...
             '  (1) metric_view + metric_frontiers' newline ...
             '  (2) views + frontiers']);
    end

    cfg = local_pick_cfg(in);
end


function cfg = local_pick_cfg(in)

    if isfield(in, 'cfg') && isstruct(in.cfg)
        cfg = in.cfg;
        return;
    end

    if isfield(in, 's5') && isstruct(in.s5) && isfield(in.s5, 'cfg') && isstruct(in.s5.cfg)
        cfg = in.s5.cfg;
        return;
    end

    if isfield(in, 's4') && isstruct(in.s4) && isfield(in.s4, 'cfg') && isstruct(in.s4.cfg)
        cfg = in.s4.cfg;
        return;
    end

    if isfield(in, 's1') && isstruct(in.s1) && isfield(in.s1, 'cfg') && isstruct(in.s1.cfg)
        cfg = in.s1.cfg;
        return;
    end

    error('plot_stage09_DA_stage05_pack:MissingCfg', ...
        ['Unable to locate cfg in input struct.' newline ...
         'Checked: cfg, s5.cfg, s4.cfg, s1.cfg']);
end
