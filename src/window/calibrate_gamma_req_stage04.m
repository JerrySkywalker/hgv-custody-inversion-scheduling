function gamma_meta = calibrate_gamma_req_stage04(winbank, cfg)
    %CALIBRATE_GAMMA_REQ_STAGE04
    % Calibrate Stage04 margin threshold gamma_req from current winbank.
    %
    % Supported modes:
    %   'fixed'            : gamma_req = cfg.stage04.gamma_req_fixed
    %   'nominal_quantile' : gamma_req = quantile(lambda_worst of nominal family, q)
    %
    % Output:
    %   gamma_meta.gamma_req
    %   gamma_meta.mode
    %   gamma_meta.source_family
    %   gamma_meta.quantile
    %   gamma_meta.sample_size
    %   gamma_meta.sample_min
    %   gamma_meta.sample_median
    %   gamma_meta.sample_max
    
        mode = string(cfg.stage04.gamma_mode);
    
        gamma_meta = struct();
        gamma_meta.mode = char(mode);
        gamma_meta.source_family = '';
        gamma_meta.quantile = NaN;
        gamma_meta.sample_size = 0;
        gamma_meta.sample_min = NaN;
        gamma_meta.sample_median = NaN;
        gamma_meta.sample_max = NaN;
    
        switch mode
            case "fixed"
                gamma_req = cfg.stage04.gamma_req_fixed;
                gamma_req = max(gamma_req, cfg.stage04.gamma_floor);
    
                gamma_meta.gamma_req = gamma_req;
                gamma_meta.source_family = 'fixed';
                gamma_meta.quantile = NaN;
    
            case "nominal_quantile"
                assert(isfield(winbank, 'nominal') && ~isempty(winbank.nominal), ...
                    'calibrate_gamma_req_stage04:MissingNominal', ...
                    'winbank.nominal is empty. Cannot calibrate gamma from nominal family.');
    
                lambda_nom = arrayfun(@(s) s.summary.lambda_min_worst, winbank.nominal);
                lambda_nom = lambda_nom(:);
                lambda_nom = lambda_nom(isfinite(lambda_nom));
    
                assert(~isempty(lambda_nom), ...
                    'calibrate_gamma_req_stage04:EmptyNominalSpectrum', ...
                    'No finite nominal lambda_worst samples available.');
    
                q = cfg.stage04.gamma_quantile;
                q = min(max(q, 0), 1);
    
                gamma_req = quantile(lambda_nom, q);
                gamma_req = max(gamma_req, cfg.stage04.gamma_floor);
    
                gamma_meta.gamma_req = gamma_req;
                gamma_meta.source_family = 'nominal';
                gamma_meta.quantile = q;
                gamma_meta.sample_size = numel(lambda_nom);
                gamma_meta.sample_min = min(lambda_nom);
                gamma_meta.sample_median = median(lambda_nom);
                gamma_meta.sample_max = max(lambda_nom);
    
            otherwise
                error('calibrate_gamma_req_stage04:UnknownMode', ...
                    'Unsupported gamma_mode: %s', char(mode));
        end
    end