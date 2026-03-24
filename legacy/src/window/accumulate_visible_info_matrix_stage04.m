function Wr = accumulate_visible_info_matrix_stage04(r_sat, r_tgt, sigma2, eps_reg)
    %ACCUMULATE_VISIBLE_INFO_MATRIX_STAGE04 Sum angle-only info increments for visible satellites.

    if isempty(r_sat)
        Wr = zeros(3,3);
        return;
    end

    los = r_sat - r_tgt;
    rho2 = sum(los.^2, 2);

    valid = isfinite(rho2) & (rho2 > 0);
    if ~any(valid)
        Wr = zeros(3,3);
        return;
    end

    los = los(valid, :);
    rho2 = rho2(valid);

    alpha = 1 ./ (sigma2 * rho2 + eps_reg);
    beta = alpha ./ rho2;

    Wr = sum(alpha) * eye(3) - los.' * (los .* beta);
end
