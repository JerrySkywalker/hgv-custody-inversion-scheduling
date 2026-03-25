function boundary_result = ch4_small_formal_boundary_summary_service(truth_result)
tbl = truth_result.table;
boundary_result = summarize_boundary(tbl);
end
