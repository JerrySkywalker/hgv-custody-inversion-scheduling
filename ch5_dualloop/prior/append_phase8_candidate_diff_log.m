function append_phase8_candidate_diff_log(cfg, rec)
%APPEND_PHASE8_CANDIDATE_DIFF_LOG
% Append one candidate evaluation record into phase8 debug csv log.

if ~isfield(cfg, 'ch5') || ~isfield(cfg.ch5, 'continuous_prior_debug_enable') || ~cfg.ch5.continuous_prior_debug_enable
    return;
end

if ~isfield(cfg.ch5, 'continuous_prior_debug_csv') || isempty(cfg.ch5.continuous_prior_debug_csv)
    return;
end

csv_path = cfg.ch5.continuous_prior_debug_csv;
csv_dir = fileparts(csv_path);
if ~isempty(csv_dir) && ~exist(csv_dir, 'dir')
    mkdir(csv_dir);
end

need_header = ~exist(csv_path, 'file');

fid = fopen(csv_path, 'a');
assert(fid >= 0, 'Failed to open candidate diff csv: %s', csv_path);

if need_header
    fprintf(fid, ['k,mode,selected_ids,score_ck_base,prior_cost_used,score_total,', ...
        'prior_region_id,prior_M_G_center,lambda_min_geom,min_crossing_angle_deg,', ...
        'baseline_km,fragility_score,gate_reason,is_feasible\n']);
end

selected_ids_str = local_join_ids(rec.selected_ids);

fprintf(fid, '%d,%s,%s,%.12f,%.12f,%.12f,%s,%.12f,%.12f,%.12f,%.12f,%.12f,%s,%d\n', ...
    rec.k, ...
    char(string(rec.mode)), ...
    selected_ids_str, ...
    rec.score_ck_base, ...
    rec.prior_cost_used, ...
    rec.score_total, ...
    char(string(rec.prior_region_id)), ...
    rec.prior_M_G_center, ...
    rec.lambda_min_geom, ...
    rec.min_crossing_angle_deg, ...
    rec.baseline_km, ...
    rec.fragility_score, ...
    char(string(rec.gate_reason)), ...
    rec.is_feasible);

fclose(fid);
end

function s = local_join_ids(ids)
if isempty(ids)
    s = '[]';
    return;
end
ids = ids(:).';
buf = strings(1, numel(ids));
for i = 1:numel(ids)
    buf(i) = string(ids(i));
end
s = "[" + strjoin(buf, ";") + "]";
s = char(s);
end
