function export_table = stage11_make_case_export_table(case_table)
%STAGE11_MAKE_CASE_EXPORT_TABLE Convert Stage11 case table to CSV-safe form.

    export_table = case_table;
    if ismember('theta_struct', export_table.Properties.VariableNames)
        export_table.theta_struct = [];
    end
    if ismember('window_index_list', export_table.Properties.VariableNames)
        export_table.window_count = cellfun(@numel, export_table.window_index_list);
        export_table.window_index_list = [];
    end
end
