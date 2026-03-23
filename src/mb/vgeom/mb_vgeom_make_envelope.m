function agg_table = mb_vgeom_make_envelope(agg_table, cfg_vgeom)
%MB_VGEOM_MAKE_ENVELOPE Apply cumulative envelopes along Ns for each semantic/i track.

if nargin < 2 || isempty(cfg_vgeom)
    cfg_vgeom = struct();
end
if isempty(agg_table)
    return;
end
if ~logical(local_getfield_or(cfg_vgeom, 'compute_envelope', true))
    return;
end

semantic_values = unique(string(agg_table.semantic), 'stable');
for idx_sem = 1:numel(semantic_values)
    semantic_mask = string(agg_table.semantic) == semantic_values(idx_sem);
    inclinations = unique(agg_table.inclination_deg(semantic_mask));
    for idx_i = 1:numel(inclinations)
        mask = semantic_mask & abs(double(agg_table.inclination_deg) - double(inclinations(idx_i))) < 1e-9;
        sub = agg_table(mask, :);
        if isempty(sub)
            continue;
        end
        [~, ord] = sort(sub.Ns, 'ascend');
        sub = sub(ord, :);
        sub.scene_best_q25_envelope = local_cummax(sub.scene_best_q25);
        sub.scene_best_median_envelope = local_cummax(sub.scene_best_median);
        sub.scene_best_mean_envelope = local_cummax(sub.scene_best_mean);
        agg_table(mask, :) = sub;
    end
end

agg_table = sortrows(agg_table, {'semantic', 'inclination_deg', 'Ns'});
end

function values = local_cummax(values)
running = -inf;
for idx = 1:numel(values)
    if isfinite(values(idx))
        running = max(running, values(idx));
    end
    if isfinite(running)
        values(idx) = running;
    end
end
end

function value = local_getfield_or(S, field_name, fallback)
if isstruct(S) && isfield(S, field_name)
    value = S.(field_name);
else
    value = fallback;
end
end
