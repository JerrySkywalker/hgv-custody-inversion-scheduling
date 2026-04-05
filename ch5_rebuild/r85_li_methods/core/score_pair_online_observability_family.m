function [score, J_pair] = score_pair_online_observability_family(ch5case, pair, k_now)
%SCORE_PAIR_ONLINE_OBSERVABILITY_FAMILY
% Online observability-family score:
%   maximize lambda_min(J_pair(k_now))
%
% Return J_pair as well so selection_trace is ready for eval_window_information.

[sat_pos, x_truth] = local_resolve_case_data(ch5case);

rs1 = sat_pos(k_now,:,pair(1));
rs2 = sat_pos(k_now,:,pair(2));
rt  = x_truth(k_now,1:3);

J_pair = local_build_J_pair_from_geometry(rs1, rs2, rt);
score = min(eig(J_pair));

end

function [sat_pos, x_truth] = local_resolve_case_data(ch5case)
sat_pos = ch5case.satbank.r_eci_km;
if ndims(sat_pos) == 3 && size(sat_pos,2) == 3
elseif ndims(sat_pos) == 3 && size(sat_pos,1) == 3
    sat_pos = permute(sat_pos, [2 1 3]);
elseif ndims(sat_pos) == 3 && size(sat_pos,3) == 3
    sat_pos = permute(sat_pos, [1 3 2]);
else
    error('Unexpected satbank.r_eci_km shape.');
end

x_truth = ch5case.truth.X(:,1:6);
end

function J_pair = local_build_J_pair_from_geometry(rs1, rs2, rt)
u1 = (rt(:)-rs1(:)); u1 = u1 / norm(u1);
u2 = (rt(:)-rs2(:)); u2 = u2 / norm(u2);

H1 = eye(3) - u1*u1.';
H2 = eye(3) - u2*u2.';
R = 1e-4 * eye(3);

J_pair = H1.'*(R\H1) + H2.'*(R\H2);
J_pair = 0.5 * (J_pair + J_pair.');
end
