function m = evaluate_window_margin_stage04(window_case, cfg)
    %EVALUATE_WINDOW_MARGIN_STAGE04
    % Convert worst-window spectrum into margin / pass-fail judgement.
    %
    % D_G = lambda_worst / gamma_req
    % pass if D_G >= 1
    
        gamma_req = cfg.stage04.gamma_req;
        lambda_worst = window_case.lambda_min_worst;
    
        m = struct();
        m.case_id = window_case.case_id;
        m.family = window_case.family;
        m.subfamily = window_case.subfamily;
    
        m.gamma_req = gamma_req;
        m.lambda_worst = lambda_worst;
        m.D_G = lambda_worst / gamma_req;
        m.pass_flag = (m.D_G >= 1);
    
        % Additional optional descriptors
        m.lambda_mean = mean(window_case.lambda_min, 'omitnan');
        m.lambda_best = max(window_case.lambda_min);
        m.t0_worst_s = window_case.t0_worst_s;
    end