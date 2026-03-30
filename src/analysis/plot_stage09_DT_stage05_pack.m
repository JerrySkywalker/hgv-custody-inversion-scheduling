function outpack = plot_stage09_DT_stage05_pack(out, mode_tag)
%PLOT_STAGE09_DT_STAGE05_PACK
% Thin wrapper: build views/frontiers and draw DT Stage05-style ninepack.

    if nargin < 2 || isempty(mode_tag)
        mode_tag = 'phase2';
    end

    if ~isfield(out, 's4') || ~isfield(out.s4, 'cfg')
        error('plot_stage09_DT_stage05_pack:MissingCfg', 'out.s4.cfg is required.');
    end

    cfg = out.s4.cfg;
    views = build_stage09_metric_views(out, mode_tag);
    frontiers = build_stage09_metric_frontiers(views, cfg, mode_tag);

    outpack = plot_stage09_metric_stage05_ninepack(views.DT.table, frontiers.DT, 'DT', cfg, mode_tag);
    outpack.views = views.DT;
    outpack.frontiers = frontiers.DT;
end
