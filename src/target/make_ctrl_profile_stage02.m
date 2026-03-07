function ctrl = make_ctrl_profile_stage02(case_i, cfg)
    %MAKE_CTRL_PROFILE_STAGE02
    % Build open-loop alpha/bank control profile for one case.
    
        switch case_i.family
            case 'nominal'
                alpha_deg = cfg.stage02.alpha_nominal_deg;
                bank_deg  = cfg.stage02.bank_nominal_deg;
    
            case 'heading'
                alpha_deg = cfg.stage02.alpha_heading_deg;
                bank_deg  = cfg.stage02.bank_heading_deg;
    
            case 'critical'
                switch case_i.subfamily
                    case 'C1_track_plane_aligned'
                        alpha_deg = cfg.stage02.alpha_c1_deg;
                        bank_deg  = cfg.stage02.bank_c1_deg;
    
                    case 'C2_small_crossing_angle'
                        alpha_deg = cfg.stage02.alpha_c2_deg;
                        bank_deg  = cfg.stage02.bank_c2_deg;
    
                    otherwise
                        alpha_deg = cfg.stage02.alpha_nominal_deg;
                        bank_deg  = cfg.stage02.bank_nominal_deg;
                end
    
            otherwise
                alpha_deg = cfg.stage02.alpha_nominal_deg;
                bank_deg  = cfg.stage02.bank_nominal_deg;
        end
    
        % First version: constant profile
        ctrl = struct();
        ctrl.alpha_fun = @(t) alpha_deg; %#ok<NASGU>
        ctrl.bank_fun  = @(t) bank_deg;
        ctrl.alpha_deg = alpha_deg;
        ctrl.bank_deg  = bank_deg;
    end