function fig = plot_casebank_stage01(casebank, cfg)
%PLOT_CASEBANK_STAGE01 Render the Stage01 scenario figure from a casebank.

    fig = figure('Color', 'w', 'Position', [100,100,960,860]);
    ax = axes(fig);
    hold(ax, 'on');
    grid(ax, 'on');

    R_D  = cfg.stage01.R_D_km;
    R_in = cfg.stage01.R_in_km;

    th = linspace(0, 2*pi, 400);
    plot(ax, R_D*cos(th),  R_D*sin(th),  'LineWidth', 2.2);
    plot(ax, R_in*cos(th), R_in*sin(th), '--', 'LineWidth', 1.8);

    scatter(ax, 0, 0, 70, 'filled');

    for k = 1:numel(casebank.nominal)
        c = casebank.nominal(k);
        p = c.entry_point_enu_km(:).';
        scatter(ax, p(1), p(2), 28, 'filled');

        u = c.heading_unit_enu(:).';
        quiver(ax, p(1), p(2), 1100*u(1), 1100*u(2), 0, ...
            'LineWidth', 1.2, 'MaxHeadSize', 0.45);
    end

    if ~isempty(casebank.heading)
        ids = string({casebank.heading.case_id});
        idx = startsWith(ids, "H01_");
        H = casebank.heading(idx);
        if isempty(H)
            H = casebank.heading(1:min(5, numel(casebank.heading)));
        end
        p = H(1).entry_point_enu_km(:).';
        for i = 1:numel(H)
            u = H(i).heading_unit_enu(:).';
            quiver(ax, p(1), p(2), 1300*u(1), 1300*u(2), 0, ...
                'LineWidth', 1.1, 'MaxHeadSize', 0.45);
        end
    end

    for k = 1:numel(casebank.critical)
        c = casebank.critical(k);
        p = c.entry_point_enu_km(:).';
        u = c.heading_unit_enu(:).';
        quiver(ax, p(1), p(2), 1600*u(1), 1600*u(2), 0, ...
            'LineWidth', 1.8, 'MaxHeadSize', 0.5);
        text(ax, p(1)+120, p(2)+120, strrep(c.case_id, '_', '\_'), 'Interpreter', 'tex');
    end

    axis(ax, 'equal');
    axis_limit_km = 5500;
    if isfield(cfg, 'stage01') && isfield(cfg.stage01, 'axis_limit_km') && ~isempty(cfg.stage01.axis_limit_km)
        axis_limit_km = cfg.stage01.axis_limit_km;
    end
    xlim(ax, [-axis_limit_km, axis_limit_km]);
    ylim(ax, [-axis_limit_km, axis_limit_km]);
    xlabel(ax, 'Regional ENU east (km)', 'Interpreter', 'none');
    ylabel(ax, 'Regional ENU north (km)', 'Interpreter', 'none');

    if isfield(cfg, 'meta') && isfield(cfg.meta, 'scene_mode')
        title(ax, sprintf('Scenario design (%s mode)', cfg.meta.scene_mode), 'Interpreter', 'none');
    end
end
