function pack = plot_stage09_DG_stage05_pack(out_or_view, mode_tag)
%PLOT_STAGE09_DG_STAGE05_PACK
% Thin wrapper for DG Stage05-style ninepack plotting.

    if nargin < 2 || isempty(mode_tag)
        mode_tag = 'phase2_DG';
    end

    [metric_view, metric_frontiers, cfg] = local_unpack_inputs(out_or_view);
    pack = plot_stage09_metric_stage05_ninepack(metric_view.DG, metric_frontiers.DG, 'DG', cfg, mode_tag);
end


function [metric_view, metric_frontiers, cfg] = local_unpack_inputs(in)

    if ~isstruct(in)
        error('plot_stage09_DG_stage05_pack:InvalidInput', ...
            'Input must be a struct.');
    end

    if isfield(in, 'metric_view') && isfield(in, 'metric_frontiers') && isfield(in, 'cfg')
        metric_view = in.metric_view;
        metric_frontiers = in.metric_frontiers;
        cfg = in.cfg;
        return;
    end

    if isfield(in, 'views') && isfield(in, 'frontiers') && isfield(in, 'cfg')
        metric_view = in.views;
        metric_frontiers = in.frontiers;
        cfg = in.cfg;
        return;
    end

    error('plot_stage09_DG_stage05_pack:InvalidInput', ...
        ['Input must be either:' newline ...
         '  (1) struct with fields metric_view, metric_frontiers, cfg' newline ...
         '  (2) struct with fields views, frontiers, cfg']);
end
