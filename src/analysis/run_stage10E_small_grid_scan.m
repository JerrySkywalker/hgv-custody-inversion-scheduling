function [scan_table, detail_list] = run_stage10E_small_grid_scan(cfg)
%RUN_STAGE10E_SMALL_GRID_SCAN
% Run Stage10.D repeatedly on a small theta grid for one fixed case/window.

    cfg = stage10E_prepare_cfg(cfg);

    rows = {};
    detail_list = {};

    h_grid = cfg.stage10E.grid_h_km(:).';
    i_grid = cfg.stage10E.grid_i_deg(:).';
    P_grid = cfg.stage10E.grid_P(:).';
    T_grid = cfg.stage10E.grid_T(:).';
    F_fix = cfg.stage10E.grid_F;

    idx = 0;
    for ih = 1:numel(h_grid)
        for ii = 1:numel(i_grid)
            for ip = 1:numel(P_grid)
                for it = 1:numel(T_grid)
                    idx = idx + 1;

                    cfgD = cfg;
                    cfgD.stage10D.case_index = cfg.stage10E.case_index;
                    cfgD.stage10D.window_index = cfg.stage10E.window_index;
                    cfgD.stage10D.anchor_mode = cfg.stage10E.anchor_mode;
                    cfgD.stage10D.manual_anchor_plane = cfg.stage10E.manual_anchor_plane;
                    cfgD.stage10D.prototype_source = cfg.stage10E.prototype_source;

                    cfgD.stage10D.theta_source = 'manual';
                    cfgD.stage10D.manual_theta.h_km = h_grid(ih);
                    cfgD.stage10D.manual_theta.i_deg = i_grid(ii);
                    cfgD.stage10D.manual_theta.P = P_grid(ip);
                    cfgD.stage10D.manual_theta.T = T_grid(it);
                    cfgD.stage10D.manual_theta.F = F_fix;

                    cfgD.stage10D.make_plot = false;
                    cfgD.stage10D.write_csv = false;
                    cfgD.stage10D.save_mat_cache = false;
                    cfgD.stage10D.run_tag = sprintf('grid_%03d', idx);

                    outD = stage10D_symmetry_breaking_margin(cfgD);
                    S = outD.summary_table;

                    lambda_truth = S.lambda_full_eff(1);
                    lambda_zero = S.lambda_zero_mode(1);
                    lambda_bcirc = S.lambda_min_bcirc(1);
                    eps2 = S.eps_sb_2(1);

                    truth_pass = lambda_truth >= cfg.stage10E.threshold_truth;
                    zero_pass = lambda_zero >= cfg.stage10E.threshold_zero;
                    bcirc_pass = lambda_bcirc >= cfg.stage10E.threshold_bcirc;

                    switch lower(string(cfg.stage10E.two_stage_rule))
                        case "zero_pass_and_bcirc_nonnegative"
                            two_stage_pass = zero_pass && bcirc_pass;
                        case "zero_pass_only"
                            two_stage_pass = zero_pass;
                        otherwise
                            error('Unknown two_stage_rule.');
                    end

                    rows{idx,1} = struct( ... %#ok<AGROW>
                        'h_km', h_grid(ih), ...
                        'i_deg', i_grid(ii), ...
                        'P', P_grid(ip), ...
                        'T', T_grid(it), ...
                        'F', F_fix, ...
                        'Ns', P_grid(ip)*T_grid(it), ...
                        'lambda_truth', lambda_truth, ...
                        'lambda_zero', lambda_zero, ...
                        'lambda_bcirc', lambda_bcirc, ...
                        'eps_sb_2', eps2, ...
                        'truth_pass', truth_pass, ...
                        'zero_pass', zero_pass, ...
                        'bcirc_pass', bcirc_pass, ...
                        'two_stage_pass', two_stage_pass, ...
                        'zero_hit', S.zero_hit(1), ...
                        'bcirc_hit', S.bcirc_hit(1), ...
                        'gap_full_zero', S.gap_full_zero(1), ...
                        'gap_full_bcirc', S.gap_full_bcirc(1), ...
                        'gap_zero_bcirc', S.gap_zero_bcirc(1));

                    detail_list{idx,1} = outD; %#ok<AGROW>
                end
            end
        end
    end

    scan_table = struct2table(vertcat(rows{:}));
    scan_table = sortrows(scan_table, {'Ns','h_km','i_deg','P','T'}, {'ascend','ascend','ascend','ascend','ascend'});
end