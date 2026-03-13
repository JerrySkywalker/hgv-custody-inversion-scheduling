function out = run_stage10(cfg, interactive, opts)
%RUN_STAGE10 Official public entry for Stage10.
%
% Usage:
%   out = run_stage10();
%   out = run_stage10(cfg);
%   out = run_stage10(cfg, false);
%   out = run_stage10(cfg, false, struct('entry','D'));
%
% Stage10 entry choices:
%   'all' : run Stage10.A -> F
%   'A'   : truth structure diagnostics
%   'B'   : bcirc prototype construction
%   'B1'  : legal bcirc baseline
%   'C'   : FFT spectral validation
%   'D'   : symmetry-breaking margin
%   'E'   : screening benchmark
%   'E1'  : refined screening rule
%   'F'   : final report pack
%
% Legacy debug flow:
%   'fft_validation_legacy' : old Stage10.1/10.1d route

    proj_root = fileparts(fileparts(mfilename('fullpath')));
    if ~isempty(proj_root)
        addpath(proj_root);
        addpath(fullfile(proj_root, 'run_stages'));
    end
    startup();

    if nargin < 1 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 2 || isempty(interactive)
        interactive = (nargin == 0);
    end
    if nargin < 3 || isempty(opts)
        opts = struct();
    end

    % default official entry
    if ~isfield(opts, 'entry') || isempty(opts.entry)
        if isfield(cfg, 'stage10') && isfield(cfg.stage10, 'entry') && ~isempty(cfg.stage10.entry)
            opts.entry = cfg.stage10.entry;
        else
            opts.entry = 'all';
        end
    end

    [cfg, opts] = rs_cli_configure('stage10', cfg, interactive, opts);
    cfg = stage10F_prepare_cfg(cfg);

    entry = upper(char(string(opts.entry)));

    fprintf('[run_stages] === Stage10 总入口 ===\n');
    fprintf('[run_stages] entry        : %s\n', entry);
    fprintf('[run_stages] case_index   : %d\n', cfg.stage10.case_index);
    fprintf('[run_stages] window_index : %d\n', cfg.stage10.window_index);
    fprintf('[run_stages] theta_source : %s\n', cfg.stage10.theta_source);

    % keep top-level Stage10 fields synchronized to sub-stage configs
    cfg = local_sync_stage10_to_substages(cfg);

    out = struct();

    switch entry
        case 'ALL'
            out.outA  = stage10A_truth_structure_diagnostics(cfg);
            out.outB  = stage10B_build_bcirc_reference(cfg);
            out.outB1 = stage10B1_legalize_bcirc_reference(cfg);
            out.outC  = stage10C_fft_spectral_validation(cfg);
            out.outD  = stage10D_symmetry_breaking_margin(cfg);
            out.outE  = stage10E_screening_acceleration(cfg);
            out.outE1 = stage10E1_screening_refine_rule(cfg);
            out.outF  = stage10F_finalize_report_pack(cfg);

        case 'A'
            out.outA = stage10A_truth_structure_diagnostics(cfg);

        case 'B'
            out.outB = stage10B_build_bcirc_reference(cfg);

        case 'B1'
            out.outB1 = stage10B1_legalize_bcirc_reference(cfg);

        case 'C'
            out.outC = stage10C_fft_spectral_validation(cfg);

        case 'D'
            out.outD = stage10D_symmetry_breaking_margin(cfg);

        case 'E'
            out.outE = stage10E_screening_acceleration(cfg);

        case 'E1'
            out.outE1 = stage10E1_screening_refine_rule(cfg);

        case 'F'
            out.outF = stage10F_finalize_report_pack(cfg);

        case 'FFT_VALIDATION_LEGACY'
            cfg = stage10_prepare_cfg(cfg);
            switch lower(string(cfg.stage10.mode))
                case "single_window_debug"
                    out.legacy = stage10_validate_single_window_fft(cfg);
                case "calibrate_alpha"
                    out.legacy = stage10_calibrate_template_alpha(cfg);
                otherwise
                    error('Unsupported legacy Stage10 mode: %s', string(cfg.stage10.mode));
            end

        otherwise
            error('Unknown Stage10 entry: %s', entry);
    end

    fprintf('[run_stages] === Stage10 完成 ===\n');
end


function cfg = local_sync_stage10_to_substages(cfg)
% keep representative theta / case / window / plotting policy synchronized

    % common representative sample
    common_case_index = cfg.stage10.case_index;
    common_window_index = cfg.stage10.window_index;
    common_theta_source = cfg.stage10.theta_source;
    common_manual_theta = cfg.stage10.manual_theta;
    common_plot = cfg.stage10.make_plot;

    % A
    cfg.stage10A.case_index = common_case_index;
    cfg.stage10A.window_index = common_window_index;
    cfg.stage10A.theta_source = common_theta_source;
    cfg.stage10A.manual_theta = common_manual_theta;
    cfg.stage10A.make_plot = common_plot;

    % B
    cfg.stage10B.case_index = common_case_index;
    cfg.stage10B.window_index = common_window_index;
    cfg.stage10B.theta_source = common_theta_source;
    cfg.stage10B.manual_theta = common_manual_theta;
    cfg.stage10B.make_plot = common_plot;

    % B1
    cfg.stage10B1.case_index = common_case_index;
    cfg.stage10B1.window_index = common_window_index;
    cfg.stage10B1.theta_source = common_theta_source;
    cfg.stage10B1.manual_theta = common_manual_theta;
    cfg.stage10B1.make_plot = common_plot;

    % C
    cfg.stage10C.case_index = common_case_index;
    cfg.stage10C.window_index = common_window_index;
    cfg.stage10C.theta_source = common_theta_source;
    cfg.stage10C.manual_theta = common_manual_theta;
    cfg.stage10C.make_plot = common_plot;

    % D
    cfg.stage10D.case_index = common_case_index;
    cfg.stage10D.window_index = common_window_index;
    cfg.stage10D.theta_source = common_theta_source;
    cfg.stage10D.manual_theta = common_manual_theta;
    cfg.stage10D.make_plot = common_plot;

    % E / E1 / F
    cfg.stage10E.case_index = common_case_index;
    cfg.stage10E.window_index = common_window_index;
    cfg.stage10E.make_plot = common_plot;

    cfg.stage10E1.case_index = common_case_index;
    cfg.stage10E1.window_index = common_window_index;
    cfg.stage10E1.make_plot = common_plot;

    cfg.stage10F.case_index = common_case_index;
    cfg.stage10F.window_index = common_window_index;
    cfg.stage10F.manual_theta = common_manual_theta;
    cfg.stage10F.make_plot = common_plot;

    % threshold synchronization
    cfg.stage10E1.threshold_truth = cfg.stage10E.threshold_truth;
    cfg.stage10E1.threshold_zero  = cfg.stage10E.threshold_zero;
    cfg.stage10E1.threshold_bcirc = cfg.stage10E.threshold_bcirc;

    cfg.stage10F.threshold_truth = cfg.stage10E.threshold_truth;
    cfg.stage10F.threshold_zero  = cfg.stage10E.threshold_zero;
    cfg.stage10F.threshold_bcirc = cfg.stage10E.threshold_bcirc;

    cfg.stage10F.grid_h_km = cfg.stage10E1.grid_h_km;
    cfg.stage10F.grid_i_deg = cfg.stage10E1.grid_i_deg;
    cfg.stage10F.grid_P = cfg.stage10E1.grid_P;
    cfg.stage10F.grid_T = cfg.stage10E1.grid_T;
    cfg.stage10F.grid_F = cfg.stage10E1.grid_F;
end