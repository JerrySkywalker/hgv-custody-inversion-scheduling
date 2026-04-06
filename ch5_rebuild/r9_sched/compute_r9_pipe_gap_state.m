function gap = compute_r9_pipe_gap_state(P)
%COMPUTE_R9_PIPE_GAP_STATE
% Extract the dominant trajectory-pipe direction from position covariance.

Ppos = 0.5 * (P(1:3,1:3) + P(1:3,1:3)');
[V,D] = eig(Ppos);
[dmax, idx] = max(real(diag(D)));
u = real(V(:,idx));
u = u / max(norm(u), 1e-12);

gap = struct();
gap.u_pos = u;
gap.pipe_radius2 = max(dmax, 0);
gap.Ppos = Ppos;
end
