function cmp = compare_selected_sets_dualloop(trackingC, trackingCK)
%COMPARE_SELECTED_SETS_DUALLOOP
% Compare selected-set trajectories between C and CK.

N = numel(trackingC.selected_sets);
same_mask = false(N,1);
set_size_C = zeros(N,1);
set_size_CK = zeros(N,1);

for k = 1:N
    a = trackingC.selected_sets{k};
    b = trackingCK.selected_sets{k};
    same_mask(k) = isequal(a, b);
    set_size_C(k) = numel(a);
    set_size_CK(k) = numel(b);
end

diff_idx = find(~same_mask);

cmp = struct();
cmp.num_steps = N;
cmp.same_ratio = mean(same_mask);
cmp.diff_count = numel(diff_idx);
cmp.diff_idx = diff_idx;
cmp.same_mask = same_mask;
cmp.set_size_C = set_size_C;
cmp.set_size_CK = set_size_CK;
end
