function out = diagnose_ch5b_trajectory_differences(sample_ids)
%DIAGNOSE_CH5B_TRAJECTORY_DIFFERENCES Compare full trajectories sample by sample.
%
% Output:
%   - max absolute differences for h(t), v(t)
%   - max norm difference for ENU / ECI positions
%   - final-state differences

cfg = default_ch5b_params();
registry = build_trajectory_registry(cfg);

if nargin < 1 || isempty(sample_ids)
    sample_ids = {'N01', 'N02', 'C1_track_plane_aligned'};
end

traj_samples = cell(1, numel(sample_ids));
for i = 1:numel(sample_ids)
    traj_samples{i} = resolve_trajectory_sample(registry, sample_ids{i}, cfg);
end

pairs = nchoosek(1:numel(traj_samples), 2);
pair_results = struct([]);

for k = 1:size(pairs,1)
    i = pairs(k,1);
    j = pairs(k,2);

    A = traj_samples{i};
    B = traj_samples{j};

    n = min(numel(A.traj.t_s), numel(B.traj.t_s));

    hA = A.traj.h_km(1:n);
    hB = B.traj.h_km(1:n);

    vA = A.traj.v_mps(1:n);
    vB = B.traj.v_mps(1:n);

    enuA = A.traj.r_enu_km(1:n,:);
    enuB = B.traj.r_enu_km(1:n,:);

    eciA = A.traj.r_eci_km(1:n,:);
    eciB = B.traj.r_eci_km(1:n,:);

    pair_results(k).sample_a = A.sample_id; %#ok<AGROW>
    pair_results(k).sample_b = B.sample_id; %#ok<AGROW>
    pair_results(k).n_common = n; %#ok<AGROW>
    pair_results(k).max_abs_dh_km = max(abs(hA - hB)); %#ok<AGROW>
    pair_results(k).max_abs_dv_mps = max(abs(vA - vB)); %#ok<AGROW>
    pair_results(k).max_enu_diff_km = max(vecnorm(enuA - enuB, 2, 2)); %#ok<AGROW>
    pair_results(k).max_eci_diff_km = max(vecnorm(eciA - eciB, 2, 2)); %#ok<AGROW>
    pair_results(k).final_h_diff_km = abs(A.traj.h_km(end) - B.traj.h_km(end)); %#ok<AGROW>
    pair_results(k).final_v_diff_mps = abs(A.traj.v_mps(end) - B.traj.v_mps(end)); %#ok<AGROW>
end

out = struct();
out.sample_ids = sample_ids;
out.pair_results = pair_results;

disp('=== diagnose_ch5b_trajectory_differences ===');
disp(struct2table(pair_results));

end
