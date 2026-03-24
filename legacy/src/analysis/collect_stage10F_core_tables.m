function core = collect_stage10F_core_tables(cfg)
%COLLECT_STAGE10F_CORE_TABLES
% Run representative Stage10.A-D and Stage10.E.1, collect core summary tables.

    cfg = stage10F_prepare_cfg(cfg);

    % ------------------------------------------------------------
    % Representative single-sample chain
    % ------------------------------------------------------------
    cfgA = cfg;
    cfgA.stage10A.run_tag = [cfg.stage10F.run_tag '_A'];
    cfgA.stage10A.case_index = cfg.stage10F.case_index;
    cfgA.stage10A.window_index = cfg.stage10F.window_index;
    cfgA.stage10A.anchor_mode = cfg.stage10F.anchor_mode;
    cfgA.stage10A.manual_anchor_plane = cfg.stage10F.manual_anchor_plane;
    cfgA.stage10A.theta_source = 'manual';
    cfgA.stage10A.manual_theta = cfg.stage10F.manual_theta;
    cfgA.stage10A.make_plot = false;
    cfgA.stage10A.write_csv = false;
    cfgA.stage10A.save_mat_cache = false;
    outA = stage10A_truth_structure_diagnostics(cfgA);

    cfgB = cfg;
    cfgB.stage10B.run_tag = [cfg.stage10F.run_tag '_B'];
    cfgB.stage10B.case_index = cfg.stage10F.case_index;
    cfgB.stage10B.window_index = cfg.stage10F.window_index;
    cfgB.stage10B.anchor_mode = cfg.stage10F.anchor_mode;
    cfgB.stage10B.manual_anchor_plane = cfg.stage10F.manual_anchor_plane;
    cfgB.stage10B.theta_source = 'manual';
    cfgB.stage10B.manual_theta = cfg.stage10F.manual_theta;
    cfgB.stage10B.bcirc_firstcol_source = cfg.stage10F.prototype_source;
    cfgB.stage10B.truth_reduced_source = cfg.stage10F.prototype_source;
    cfgB.stage10B.make_plot = false;
    cfgB.stage10B.write_csv = false;
    cfgB.stage10B.save_mat_cache = false;
    outB = stage10B_build_bcirc_reference(cfgB);

    cfgB1 = cfg;
    cfgB1.stage10B1.run_tag = [cfg.stage10F.run_tag '_B1'];
    cfgB1.stage10B1.case_index = cfg.stage10F.case_index;
    cfgB1.stage10B1.window_index = cfg.stage10F.window_index;
    cfgB1.stage10B1.anchor_mode = cfg.stage10F.anchor_mode;
    cfgB1.stage10B1.manual_anchor_plane = cfg.stage10F.manual_anchor_plane;
    cfgB1.stage10B1.theta_source = 'manual';
    cfgB1.stage10B1.manual_theta = cfg.stage10F.manual_theta;
    cfgB1.stage10B1.prototype_source = cfg.stage10F.prototype_source;
    cfgB1.stage10B1.make_plot = false;
    cfgB1.stage10B1.write_csv = false;
    cfgB1.stage10B1.save_mat_cache = false;
    outB1 = stage10B1_legalize_bcirc_reference(cfgB1);

    cfgC = cfg;
    cfgC.stage10C.run_tag = [cfg.stage10F.run_tag '_C'];
    cfgC.stage10C.case_index = cfg.stage10F.case_index;
    cfgC.stage10C.window_index = cfg.stage10F.window_index;
    cfgC.stage10C.anchor_mode = cfg.stage10F.anchor_mode;
    cfgC.stage10C.manual_anchor_plane = cfg.stage10F.manual_anchor_plane;
    cfgC.stage10C.theta_source = 'manual';
    cfgC.stage10C.manual_theta = cfg.stage10F.manual_theta;
    cfgC.stage10C.prototype_source = cfg.stage10F.prototype_source;
    cfgC.stage10C.make_plot = false;
    cfgC.stage10C.write_csv = false;
    cfgC.stage10C.save_mat_cache = false;
    outC = stage10C_fft_spectral_validation(cfgC);

    cfgD = cfg;
    cfgD.stage10D.run_tag = [cfg.stage10F.run_tag '_D'];
    cfgD.stage10D.case_index = cfg.stage10F.case_index;
    cfgD.stage10D.window_index = cfg.stage10F.window_index;
    cfgD.stage10D.anchor_mode = cfg.stage10F.anchor_mode;
    cfgD.stage10D.manual_anchor_plane = cfg.stage10F.manual_anchor_plane;
    cfgD.stage10D.theta_source = 'manual';
    cfgD.stage10D.manual_theta = cfg.stage10F.manual_theta;
    cfgD.stage10D.prototype_source = cfg.stage10F.prototype_source;
    cfgD.stage10D.make_plot = false;
    cfgD.stage10D.write_csv = false;
    cfgD.stage10D.save_mat_cache = false;
    outD = stage10D_symmetry_breaking_margin(cfgD);

    % ------------------------------------------------------------
    % Small-grid refined screening benchmark
    % ------------------------------------------------------------
    cfgE1 = cfg;
    cfgE1.stage10E1.run_tag = [cfg.stage10F.run_tag '_E1'];
    cfgE1.stage10E1.case_index = cfg.stage10F.case_index;
    cfgE1.stage10E1.window_index = cfg.stage10F.window_index;
    cfgE1.stage10E1.anchor_mode = cfg.stage10F.anchor_mode;
    cfgE1.stage10E1.manual_anchor_plane = cfg.stage10F.manual_anchor_plane;
    cfgE1.stage10E1.prototype_source = cfg.stage10F.prototype_source;
    cfgE1.stage10E1.grid_h_km = cfg.stage10F.grid_h_km;
    cfgE1.stage10E1.grid_i_deg = cfg.stage10F.grid_i_deg;
    cfgE1.stage10E1.grid_P = cfg.stage10F.grid_P;
    cfgE1.stage10E1.grid_T = cfg.stage10F.grid_T;
    cfgE1.stage10E1.grid_F = cfg.stage10F.grid_F;
    cfgE1.stage10E1.threshold_truth = cfg.stage10F.threshold_truth;
    cfgE1.stage10E1.threshold_zero = cfg.stage10F.threshold_zero;
    cfgE1.stage10E1.threshold_bcirc = cfg.stage10F.threshold_bcirc;
    cfgE1.stage10E1.make_plot = false;
    cfgE1.stage10E1.write_csv = false;
    cfgE1.stage10E1.save_mat_cache = false;
    outE1 = stage10E1_screening_refine_rule(cfgE1);

    core = struct();
    core.outA = outA;
    core.outB = outB;
    core.outB1 = outB1;
    core.outC = outC;
    core.outD = outD;
    core.outE1 = outE1;
end