function outpack = plot_stage09_DG_stage05_pack(out, mode_tag)
%PLOT_STAGE09_DG_STAGE05_PACK
% Thin wrapper: build views/frontiers and draw DG Stage05-style ninepack.

    if nargin < 2 || isempty(mode_tag)
        mode_tag = 'phase2';
    end

    if ~isfield(out, 's4') || ~isfield(out.s4, 'cfg')
        error('plot_stage09_DG_stage05_pack:MissingCfg', 'out.s4.cfg is required.');
    end

    cfg = out.s4.cfg;
    views = build_stage09_metric_views(out, mode_tag);
    frontiers = build_stage09_metric_frontiers(views, cfg, mode_tag);

    outpack = plot_stage09_metric_stage05_ninepack(views.DG.table, frontiers.DG, 'DG', cfg, mode_tag);
    outpack.views = views.DG;
    outpack.frontiers = frontiers.DG;
end
