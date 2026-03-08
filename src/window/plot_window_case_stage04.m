function fig = plot_window_case_stage04(window_case, cfg)
    %PLOT_WINDOW_CASE_STAGE04 Plot lambda_min(Wr) over sliding windows.
    %
    % Stage04G.6:
    %   - prefer exact t0_s from window_grid
    %   - fallback to start_idx/dt only if needed
    %   - optionally draw gamma_req threshold
    %   - title updated to emphasize worst-window scan
    %
    % Input:
    %   window_case : struct returned by scan_worst_window_stage04
    %   cfg         : configuration struct
    %
    % Output:
    %   fig         : figure handle
    
        fig = figure('Color', 'w', 'Position', [100,100,920,420]);
    
        % ------------------------------------------------------------
        % Robust time-axis selection
        % ------------------------------------------------------------
        if isfield(window_case, 'window_grid') && isfield(window_case.window_grid, 't0_s') ...
                && ~isempty(window_case.window_grid.t0_s)
            t0_s = window_case.window_grid.t0_s;
        elseif isfield(window_case, 'window_grid') ...
                && isfield(window_case.window_grid, 'start_idx') ...
                && isfield(window_case.window_grid, 'dt')
            % legacy fallback
            t0_s = (window_case.window_grid.start_idx(:) - 1) * window_case.window_grid.dt;
        else
            error('plot_window_case_stage04:MissingTimeAxis', ...
                'window_case.window_grid is missing both t0_s and (start_idx, dt).');
        end
    
        % ensure column vectors for plotting consistency
        t0_s = t0_s(:);
        lambda_min = window_case.lambda_min(:);
    
        % ------------------------------------------------------------
        % Main curve
        % ------------------------------------------------------------
        plot(t0_s, lambda_min, 'LineWidth', 1.5);
        hold on;
        grid on;
    
        % ------------------------------------------------------------
        % Worst window marker
        % ------------------------------------------------------------
        if isfield(window_case, 't0_worst_s') && isfinite(window_case.t0_worst_s)
            xline(window_case.t0_worst_s, '--', 'LineWidth', 1.2);
        elseif isfield(window_case, 'idx_worst') && ~isempty(window_case.idx_worst) ...
                && window_case.idx_worst >= 1 && window_case.idx_worst <= numel(t0_s)
            xline(t0_s(window_case.idx_worst), '--', 'LineWidth', 1.2);
        end
    
        % ------------------------------------------------------------
        % Optional gamma requirement line
        % ------------------------------------------------------------
        if isfield(cfg, 'stage04') && isfield(cfg.stage04, 'gamma_req') ...
                && ~isempty(cfg.stage04.gamma_req) && isfinite(cfg.stage04.gamma_req)
            yline(cfg.stage04.gamma_req, ':', 'LineWidth', 1.2);
        end
    
        % ------------------------------------------------------------
        % Labels / title
        % ------------------------------------------------------------
        xlabel('window start time t_0 (s)', 'Interpreter', 'none');
        ylabel('\lambda_{min}(W_r)', 'Interpreter', 'tex');
    
        if isfield(window_case, 'case_id')
            ttl = sprintf('Worst-window scan: %s', window_case.case_id);
        else
            ttl = 'Worst-window scan';
        end
        title(ttl, 'Interpreter', 'none');
    
        % ------------------------------------------------------------
        % Cosmetic axis padding
        % ------------------------------------------------------------
        if ~isempty(t0_s)
            xlim([min(t0_s), max(t0_s)]);
        end
    end