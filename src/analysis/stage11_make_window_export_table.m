function export_table = stage11_make_window_export_table(window_table)
%STAGE11_MAKE_WINDOW_EXPORT_TABLE Convert Stage11 window table to CSV-safe form.

    export_table = window_table;
    if ismember('Wr', export_table.Properties.VariableNames)
        export_table.Wr_trace = cellfun(@trace, export_table.Wr);
        export_table.Wr = [];
    end
    if ismember('W_pi', export_table.Properties.VariableNames)
        export_table.W_pi_trace = cellfun(@trace, export_table.W_pi);
        export_table.W_pi = [];
    end
    if ismember('theta_struct', export_table.Properties.VariableNames)
        export_table.theta_struct = [];
    end
end
