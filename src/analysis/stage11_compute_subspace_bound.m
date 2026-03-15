function sub_table = stage11_compute_subspace_bound(input_dataset, weak_table, cfg)
%STAGE11_COMPUTE_SUBSPACE_BOUND Compute L_sub on top of W_pi.

    if nargin < 3 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    WT = input_dataset.window_table;
    n_window = height(WT);
    rows = cell(n_window, 1);
    t_start = tic;

    for i = 1:n_window
        Wr = WT.Wr{i};
        Wr = 0.5 * (Wr + Wr.');
        W_pi = weak_table.W_pi{i};
        W_pi = 0.5 * (W_pi + W_pi.');
        E = Wr - W_pi;
        E = 0.5 * (E + E.');

        [V, D] = eig(W_pi);
        [evals, order] = sort(real(diag(D)), 'ascend');
        V = V(:, order);
        alpha = evals(1);
        beta = evals(min(2, numel(evals)));
        u = V(:,1);
        U = null(u.');
        if isempty(U)
            U = zeros(size(W_pi,1), 0);
        end

        e = real(u.' * E * u);
        g = U.' * E * u;
        E_perp = U.' * E * U;
        g_norm = norm(g, 2);
        if isempty(E_perp)
            E_perp_norm = 0;
        else
            E_perp_norm = norm(E_perp, 2);
        end
        mu_lower = beta - E_perp_norm;
        rho_g = g_norm / (abs(alpha) + abs(beta) + eps);
        L_sub = 0.5 * ((alpha + e) + mu_lower - sqrt((mu_lower - (alpha + e))^2 + 4 * g_norm^2));
        sub_valid = logical(weak_table.partition_valid(i)) && isfinite(alpha) && isfinite(beta) ...
            && isfinite(e) && isfinite(g_norm) && isfinite(E_perp_norm) && isfinite(L_sub);

        rows{i,1} = struct( ... %#ok<AGROW>
            'row_id', WT.row_id(i), ...
            'alpha', alpha, ...
            'beta', beta, ...
            'spectral_gap', beta - alpha, ...
            'eig_gap', beta - alpha, ...
            'e', e, ...
            'e_scalar', e, ...
            'g_norm', g_norm, ...
            'E_perp_norm', E_perp_norm, ...
            'Eperp_norm', E_perp_norm, ...
            'mu_lower', mu_lower, ...
            'mu_bar', mu_lower, ...
            'rho_g', rho_g, ...
            'L_sub', real(L_sub), ...
            'sub_valid', sub_valid);

        if cfg.stage11.log_every_window
            fprintf(['[stage11][sub] theta %d case %s window %d row %d/%d elapsed=%.1fs', newline], ...
                WT.theta_id(i), char(string(WT.case_id(i))), WT.window_id(i), WT.row_id(i), n_window, toc(t_start));
        end
    end

    sub_table = struct2table(vertcat(rows{:}));
end
