function [cfg, opts] = rs_cli_configure(stage_name, cfg, interactive, opts)
%RS_CLI_CONFIGURE
% CLI helper for run_stages.
%
% Usage:
%   [cfg, opts] = rs_cli_configure('stage05', cfg, true)
%   [cfg, opts] = rs_cli_configure('stage09', cfg, true, opts)
%
% Behavior:
%   - if interactive=false, returns cfg unchanged
%   - if interactive=true, asks stage-specific key parameters
%   - pressing Enter keeps the default

    if nargin < 2 || isempty(cfg)
        cfg = default_params();
    end
    if nargin < 3 || isempty(interactive)
        interactive = true;
    end
    if nargin < 4 || isempty(opts)
        opts = struct();
    end

    if ~interactive
        return;
    end

    stage_name = lower(string(stage_name));

    fprintf('\n[run_stages][CLI] ===== 配置 %s =====\n', stage_name);
    fprintf('[run_stages][CLI] 直接回车表示保留默认值。\n');

    switch stage_name
        case "stage00"
            cfg.random.seed = ask_scalar('random.seed', cfg.random.seed);

        case "stage01"
            cfg.stage01.R_D_km = ask_scalar('stage01.R_D_km', cfg.stage01.R_D_km);
            cfg.stage01.R_in_km = ask_scalar('stage01.R_in_km', cfg.stage01.R_in_km);
            cfg.stage01.num_nominal_entry_points = ask_scalar( ...
                'stage01.num_nominal_entry_points', cfg.stage01.num_nominal_entry_points);
            cfg.stage01.heading_offsets_deg = ask_vector( ...
                'stage01.heading_offsets_deg', cfg.stage01.heading_offsets_deg);

        case "stage02"
            cfg.stage02.v0_mps = ask_scalar('stage02.v0_mps', cfg.stage02.v0_mps);
            cfg.stage02.h0_m = ask_scalar('stage02.h0_m', cfg.stage02.h0_m);
            cfg.stage02.Tmax_s = ask_scalar('stage02.Tmax_s', cfg.stage02.Tmax_s);
            cfg.stage02.Ts_s = ask_scalar('stage02.Ts_s', cfg.stage02.Ts_s);

        case "stage03"
            cfg.stage03.h_km = ask_scalar('stage03.h_km', cfg.stage03.h_km);
            cfg.stage03.i_deg = ask_scalar('stage03.i_deg', cfg.stage03.i_deg);
            cfg.stage03.P = ask_scalar('stage03.P', cfg.stage03.P);
            cfg.stage03.T = ask_scalar('stage03.T', cfg.stage03.T);
            cfg.stage03.F = ask_scalar('stage03.F', cfg.stage03.F);
            cfg.stage03.max_range_km = ask_scalar('stage03.max_range_km', cfg.stage03.max_range_km);
            cfg.stage03.max_offnadir_deg = ask_scalar('stage03.max_offnadir_deg', cfg.stage03.max_offnadir_deg);

        case "stage04"
            cfg.stage04.Tw_s = ask_scalar('stage04.Tw_s', cfg.stage04.Tw_s);
            cfg.stage04.window_step_s = ask_scalar('stage04.window_step_s', cfg.stage04.window_step_s);
            cfg.stage04.sigma_angle_deg = ask_scalar('stage04.sigma_angle_deg', cfg.stage04.sigma_angle_deg);
            cfg.stage04.gamma_mode = ask_choice( ...
                'stage04.gamma_mode', cfg.stage04.gamma_mode, {'nominal_quantile','fixed'});
            if strcmpi(cfg.stage04.gamma_mode, 'nominal_quantile')
                cfg.stage04.gamma_quantile = ask_scalar('stage04.gamma_quantile', cfg.stage04.gamma_quantile);
            else
                cfg.stage04.gamma_req_fixed = ask_scalar('stage04.gamma_req_fixed', cfg.stage04.gamma_req_fixed);
            end

        case "stage05"
            cfg.stage05.h_fixed_km = ask_scalar('stage05.h_fixed_km', cfg.stage05.h_fixed_km);
            cfg.stage05.i_grid_deg = ask_vector('stage05.i_grid_deg', cfg.stage05.i_grid_deg);
            cfg.stage05.P_grid = ask_vector('stage05.P_grid', cfg.stage05.P_grid);
            cfg.stage05.T_grid = ask_vector('stage05.T_grid', cfg.stage05.T_grid);
            cfg.stage05.use_parallel = ask_yesno('stage05.use_parallel', cfg.stage05.use_parallel);
            cfg.stage05.use_early_stop = ask_yesno('stage05.use_early_stop', cfg.stage05.use_early_stop);

        case "stage06"
            cfg.stage06.active_heading_set_name = ask_choice( ...
                'stage06.active_heading_set_name', cfg.stage06.active_heading_set_name, {'small','full','custom'});
            if strcmpi(cfg.stage06.active_heading_set_name, 'custom')
                cfg.stage06.active_heading_offsets_custom_deg = ask_vector( ...
                    'stage06.active_heading_offsets_custom_deg', cfg.stage06.active_heading_offsets_custom_deg);
            end
            cfg.stage06.use_parallel = ask_yesno('stage06.use_parallel', cfg.stage06.use_parallel);
            cfg.stage06.use_early_stop = ask_yesno('stage06.use_early_stop', cfg.stage06.use_early_stop);

        case "stage07"
            cfg.stage07.reference_selection_rule = ask_choice( ...
                'stage07.reference_selection_rule', cfg.stage07.reference_selection_rule, ...
                {'frontier_near_feasible','min_Ns_then_max_DG'});
            cfg.stage07.heading_scan.step_deg = ask_scalar('stage07.heading_scan.step_deg', cfg.stage07.heading_scan.step_deg);
            cfg.stage07.danger.coverage_good_threshold = ask_scalar( ...
                'stage07.danger.coverage_good_threshold', cfg.stage07.danger.coverage_good_threshold);
            cfg.stage07.danger.angle_bad_threshold_deg = ask_scalar( ...
                'stage07.danger.angle_bad_threshold_deg', cfg.stage07.danger.angle_bad_threshold_deg);

        case "stage08"
            cfg.stage08.active_tw_grid_name = ask_choice( ...
                'stage08.active_tw_grid_name', cfg.stage08.active_tw_grid_name, {'baseline','dense','custom'});
            if strcmpi(cfg.stage08.active_tw_grid_name, 'custom')
                cfg.stage08.Tw_grid_custom_s = ask_vector('stage08.Tw_grid_custom_s', cfg.stage08.Tw_grid_custom_s);
            end
            cfg.stage08.smallgrid.feasibility_profile = ask_choice( ...
                'stage08.smallgrid.feasibility_profile', cfg.stage08.smallgrid.feasibility_profile, ...
                {'relaxed','medium','strict'});
            cfg.stage08.smallgrid.max_config_count = ask_scalar( ...
                'stage08.smallgrid.max_config_count', cfg.stage08.smallgrid.max_config_count);

        case "stage09"
            cfg.stage09.scheme_type = ask_choice( ...
                'stage09.scheme_type', cfg.stage09.scheme_type, {'validation_small','full_main','custom'});
            cfg.stage09.use_early_stop = ask_yesno('stage09.use_early_stop', cfg.stage09.use_early_stop);
            cfg.stage09.scan_log_every = ask_scalar('stage09.scan_log_every', cfg.stage09.scan_log_every);

            if strcmpi(cfg.stage09.scheme_type, 'custom')
                cfg.stage09.search_domain.h_grid_km = ask_vector( ...
                    'stage09.search_domain.h_grid_km', cfg.stage09.search_domain.h_grid_km);
                cfg.stage09.search_domain.i_grid_deg = ask_vector( ...
                    'stage09.search_domain.i_grid_deg', cfg.stage09.search_domain.i_grid_deg);
                cfg.stage09.search_domain.P_grid = ask_vector( ...
                    'stage09.search_domain.P_grid', cfg.stage09.search_domain.P_grid);
                cfg.stage09.search_domain.T_grid = ask_vector( ...
                    'stage09.search_domain.T_grid', cfg.stage09.search_domain.T_grid);
                cfg.stage09.casebank_mode = ask_choice( ...
                    'stage09.casebank_mode', cfg.stage09.casebank_mode, {'validation_small','full74','custom'});
            end

            if ~isfield(opts, 'stage09_run_validate_kernel')
                opts.stage09_run_validate_kernel = false;
            end
            if ~isfield(opts, 'stage09_run_validate_single')
                opts.stage09_run_validate_single = false;
            end
            if ~isfield(opts, 'stage09_run_plot_after_scan')
                opts.stage09_run_plot_after_scan = true;
            end

            opts.stage09_run_validate_kernel = ask_yesno( ...
                'stage09_run_validate_kernel', opts.stage09_run_validate_kernel);
            opts.stage09_run_validate_single = ask_yesno( ...
                'stage09_run_validate_single', opts.stage09_run_validate_single);
            opts.stage09_run_plot_after_scan = ask_yesno( ...
                'stage09_run_plot_after_scan', opts.stage09_run_plot_after_scan);

        otherwise
            fprintf('[run_stages][CLI] %s 没有额外交互项，使用默认 cfg。\n', stage_name);
    end

    fprintf('[run_stages][CLI] ===== %s 配置完成 =====\n\n', stage_name);
end


function v = ask_scalar(name, default_val)
    s = input(sprintf('%s [%g]: ', name, default_val), 's');
    if isempty(strtrim(s))
        v = default_val;
    else
        v = str2double(s);
        if isnan(v)
            warning('%s 输入非法，保留默认值。', name);
            v = default_val;
        end
    end
end

function v = ask_vector(name, default_val)
    s = input(sprintf('%s %s: ', name, mat2str(default_val)), 's');
    if isempty(strtrim(s))
        v = default_val;
    else
        tmp = str2num(s); %#ok<ST2NM>
        if isempty(tmp)
            warning('%s 输入非法，保留默认值。', name);
            v = default_val;
        else
            v = tmp;
        end
    end
end

function v = ask_choice(name, default_val, choices)
    prompt = sprintf('%s [%s] options=%s: ', name, char(string(default_val)), strjoin(choices, '/'));
    s = input(prompt, 's');
    if isempty(strtrim(s))
        v = char(string(default_val));
    else
        s = strtrim(s);
        if any(strcmpi(s, choices))
            v = s;
        else
            warning('%s 输入非法，保留默认值。', name);
            v = char(string(default_val));
        end
    end
end

function v = ask_yesno(name, default_val)
    if default_val
        d = 'y';
    else
        d = 'n';
    end
    s = input(sprintf('%s [y/n, default=%s]: ', name, d), 's');
    if isempty(strtrim(s))
        v = logical(default_val);
    else
        s = lower(strtrim(s));
        if any(strcmp(s, {'y','yes','1'}))
            v = true;
        elseif any(strcmp(s, {'n','no','0'}))
            v = false;
        else
            warning('%s 输入非法，保留默认值。', name);
            v = logical(default_val);
        end
    end
end