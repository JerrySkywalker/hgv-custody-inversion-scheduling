function sub_table = stage11_compute_subspace_bound(input_dataset, weak_table, cfg)
%STAGE11_COMPUTE_SUBSPACE_BOUND Compute L_sub on top of W_pi.

    if nargin < 3 || isempty(cfg)
        cfg = default_params();
    end
    cfg = stage11_prepare_cfg(cfg);

    WT = input_dataset.window_table;
    n_window = height(WT);
    rows = cell(n_window, 1);

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
        L_sub = 0.5 * ((alpha + e) + mu_lower - sqrt((mu_lower - (alpha + e))^2 + 4 * g_norm^2));

        rows{i,1} = struct( ... %#ok<AGROW>
            'row_id', WT.row_id(i), ...
            'alpha', alpha, ...
            'beta', beta, ...
            'spectral_gap', beta - alpha, ...
            'e', e, ...
            'g_norm', g_norm, ...
            'E_perp_norm', E_perp_norm, ...
            'mu_lower', mu_lower, ...
            'L_sub', real(L_sub), ...
            'sub_valid', WT.truth_lambda_min(i) + 1e-9 >= real(L_sub));
    end

    sub_table = struct2table(vertcat(rows{:}));
end
