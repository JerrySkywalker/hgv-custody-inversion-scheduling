function ctrl = build_control_profile(case_i, cfg)
    %build_control_profile
    % Build open-loop alpha/bank control profile for one case.
    %
    % Stage04G.4a:
    %   - preserve family-based control selection
    %   - optionally add heading-offset-dependent bank bias
    %   - return constant profiles compatible with hgv_vtc_dynamics()
    
        % ------------------------------------------------------------
        % Safe fallback helper
        % ------------------------------------------------------------
        getv = @(s, name, defaultv) local_getfield_or_default(s, name, defaultv);
    
        % ------------------------------------------------------------
        % Base values by family
        % ------------------------------------------------------------
        switch case_i.family
            case 'nominal'
                alpha_deg = getv(cfg.stage02, 'alpha_nominal_deg', getv(cfg.stage02, 'alpha_cmd_deg', 15.0));
                bank_deg  = getv(cfg.stage02, 'bank_nominal_deg',  getv(cfg.stage02, 'bank_cmd_deg',  0.0));
    
            case 'heading'
                alpha_deg = getv(cfg.stage02, 'alpha_heading_deg', getv(cfg.stage02, 'alpha_nominal_deg', getv(cfg.stage02, 'alpha_cmd_deg', 15.0)));
                bank_deg  = getv(cfg.stage02, 'bank_heading_deg',  getv(cfg.stage02, 'bank_nominal_deg',  getv(cfg.stage02, 'bank_cmd_deg',  0.0)));
    
            case 'critical'
                switch case_i.subfamily
                    case 'track_plane_aligned'
                        alpha_deg = getv(cfg.stage02, 'alpha_c1_deg', getv(cfg.stage02, 'alpha_nominal_deg', getv(cfg.stage02, 'alpha_cmd_deg', 15.0)));
                        bank_deg  = getv(cfg.stage02, 'bank_c1_deg',  getv(cfg.stage02, 'bank_nominal_deg',  getv(cfg.stage02, 'bank_cmd_deg',  0.0)));
    
                    case 'small_crossing_angle'
                        alpha_deg = getv(cfg.stage02, 'alpha_c2_deg', getv(cfg.stage02, 'alpha_nominal_deg', getv(cfg.stage02, 'alpha_cmd_deg', 15.0)));
                        bank_deg  = getv(cfg.stage02, 'bank_c2_deg',  getv(cfg.stage02, 'bank_nominal_deg',  getv(cfg.stage02, 'bank_cmd_deg',  0.0)));
    
                    otherwise
                        alpha_deg = getv(cfg.stage02, 'alpha_nominal_deg', getv(cfg.stage02, 'alpha_cmd_deg', 15.0));
                        bank_deg  = getv(cfg.stage02, 'bank_nominal_deg',  getv(cfg.stage02, 'bank_cmd_deg',  0.0));
                end
    
            otherwise
                alpha_deg = getv(cfg.stage02, 'alpha_nominal_deg', getv(cfg.stage02, 'alpha_cmd_deg', 15.0));
                bank_deg  = getv(cfg.stage02, 'bank_nominal_deg',  getv(cfg.stage02, 'bank_cmd_deg',  0.0));
        end
    
        % ------------------------------------------------------------
        % Optional bank bias from heading offset
        % ------------------------------------------------------------
        use_heading_bank_bias = getv(cfg.stage02, 'use_heading_offset_as_bank_seed', false);
        heading_bank_gain_deg = getv(cfg.stage02, 'heading_offset_bank_gain_deg_per_deg', 0.0);
    
        if strcmp(case_i.family, 'heading') && use_heading_bank_bias ...
                && isfield(case_i, 'heading_offset_deg') && isfinite(case_i.heading_offset_deg)
            bank_deg = bank_deg + heading_bank_gain_deg * case_i.heading_offset_deg;
        end
    
        % ------------------------------------------------------------
        % Constant control profile
        % ------------------------------------------------------------
        ctrl = struct();
        ctrl.alpha_deg = alpha_deg;
        ctrl.bank_deg  = bank_deg;
    
        ctrl.alpha = @(t) alpha_deg; %#ok<NASGU>
        ctrl.gamma = @(t) bank_deg;  %#ok<NASGU>
    end
    
    function v = local_getfield_or_default(s, name, defaultv)
        if isstruct(s) && isfield(s, name)
            v = s.(name);
        else
            v = defaultv;
        end
    end

