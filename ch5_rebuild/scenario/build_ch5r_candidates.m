function candidates = build_ch5r_candidates(cfg, truth, satbank)
%BUILD_CH5R_CANDIDATES
% Build visible double-satellite candidate pairs at each time step.

if nargin < 1 || isempty(cfg)
    cfg = default_ch5r_params(false);
end
if nargin < 2 || isempty(truth)
    truth = build_ch5r_truth_from_stage02_engine(cfg);
end
if nargin < 3 || isempty(satbank)
    satbank = build_ch5r_satbank_from_stage03_engine(cfg, truth);
end

traj_case = truth.traj_case;
vis_case = compute_visibility_matrix_stage03(traj_case, satbank, cfg);
los_geom = compute_los_geometry_stage03(vis_case, satbank);

Nt = numel(vis_case.t_s);
pair_bank = cell(Nt, 1);

for k = 1:Nt
    vis_idx = find(vis_case.visible_mask(k, :));
    if numel(vis_idx) < 2
        pair_bank{k} = zeros(0, 2);
        continue;
    end
    pair_bank{k} = nchoosek(vis_idx, 2);
end

candidates = struct();
candidates.source = 'stage03_real_visibility';
candidates.vis_case = vis_case;
candidates.los_geom = los_geom;
candidates.pair_bank = pair_bank;
candidates.t_s = vis_case.t_s(:);
candidates.meta = struct();
candidates.meta.note = 'Visible satellite pairs built from real Stage03 visibility geometry.';
end
