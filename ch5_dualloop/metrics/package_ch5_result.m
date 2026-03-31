function out = package_ch5_result(caseData, result, tracking, custody)
%PACKAGE_CH5_RESULT  Unified output packager for chapter 5 shell stage.

out = struct();
out.meta = struct();
out.meta.phase_name = caseData.meta.phase_name;
out.meta.timestamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));

out.case_summary = caseData.summary;
out.raw_result = result;
out.tracking = tracking;
out.custody = custody;
end
