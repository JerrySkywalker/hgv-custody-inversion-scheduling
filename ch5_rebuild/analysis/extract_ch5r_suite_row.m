function row = extract_ch5r_suite_row(method_tag, requested_case_id, outx)
%EXTRACT_CH5R_SUITE_ROW
% Extract a unified summary row from a Phase runner output.

stateS = derive_ch5r_state_ratios(outx);

row = struct();
row.method = string(method_tag);
row.requested_case_id = string(requested_case_id);
row.actual_case_id = string(local_get_field(outx, {'case','target_case','case_id'}, ""));
row.family = string(local_get_field(outx, {'case','target_case','family'}, ""));
row.window_mode = string(local_get_field(outx, {'case','window','mode'}, ""));
row.window_length_s = local_get_field(outx, {'case','window','length_s'}, NaN);

row.valid_steps = local_get_field(outx, {'result','bubble_metrics','total_valid_steps'}, NaN);
row.valid_time_s = local_get_field(outx, {'result','bubble_metrics','total_valid_time_s'}, NaN);
row.bubble_steps = local_get_field(outx, {'result','bubble_metrics','bubble_steps'}, NaN);
row.bubble_time_s = local_get_field(outx, {'result','bubble_metrics','bubble_time_s'}, NaN);
row.bubble_fraction = local_get_field(outx, {'result','bubble_metrics','bubble_fraction'}, NaN);
row.longest_bubble_time_s = local_get_field(outx, {'result','bubble_metrics','longest_bubble_time_s'}, NaN);
row.max_bubble_depth = local_get_field(outx, {'result','bubble_metrics','max_bubble_depth'}, NaN);
row.mean_bubble_depth = local_get_field(outx, {'result','bubble_metrics','mean_bubble_depth'}, NaN);

row.switch_count = local_get_field(outx, {'result','cost_metrics','switch_count'}, NaN);
row.resource_score = local_get_field(outx, {'result','cost_metrics','resource_score'}, NaN);

row.SC_steps = stateS.sc_steps;
row.DC_steps = stateS.dc_steps;
row.LoC_steps = stateS.loc_steps;
row.SC_ratio = stateS.sc_ratio;
row.DC_ratio = stateS.dc_ratio;
row.LoC_ratio = stateS.loc_ratio;

row.mean_rmse_pos_km = NaN;
row.final_rmse_pos_km = NaN;

if strcmpi(method_tag, 'R4')
    row.mean_rmse_pos_km = local_get_field(outx, {'result','r4_tracking','mean_rmse_pos_km'}, NaN);
    row.final_rmse_pos_km = local_get_field(outx, {'result','r4_tracking','final_rmse_pos_km'}, NaN);
elseif strcmpi(method_tag, 'R5')
    row.mean_rmse_pos_km = local_get_field(outx, {'result','r5_tracking','mean_rmse_pos_km'}, NaN);
    row.final_rmse_pos_km = local_get_field(outx, {'result','r5_tracking','final_rmse_pos_km'}, NaN);
elseif strcmpi(method_tag, 'R9')
    row.mean_rmse_pos_km = local_get_field(outx, {'result','r9_tracking','mean_rmse_pos_km'}, NaN);
    row.final_rmse_pos_km = local_get_field(outx, {'result','r9_tracking','final_rmse_pos_km'}, NaN);
elseif strcmpi(method_tag, 'R10')
    row.mean_rmse_pos_km = local_get_field(outx, {'result','r10_tracking','mean_rmse_pos_km'}, NaN);
    row.final_rmse_pos_km = local_get_field(outx, {'result','r10_tracking','final_rmse_pos_km'}, NaN);
end

row.ok = logical(local_get_field(outx, {'ok'}, false));
row.mat_file = string(local_get_field(outx, {'paths','mat_file'}, ""));
row.artifact_tag = string(local_get_field(outx, {'paths','artifact_tag'}, ""));
end

function value = local_get_field(S, path_cells, default_value)
value = default_value;
try
    cur = S;
    for i = 1:numel(path_cells)
        key = path_cells{i};
        if isstruct(cur) && isfield(cur, key)
            cur = cur.(key);
        else
            return;
        end
    end
    value = cur;
catch
    value = default_value;
end
end
