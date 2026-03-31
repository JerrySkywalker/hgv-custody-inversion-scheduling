function lines = summarize_ch5_case(caseData)
%SUMMARIZE_CH5_CASE  Convert chapter 5 smoke case to printable text lines.

lines = {
    '=== Chapter 5 Phase 0 Case Summary ==='
    ['Phase: ', caseData.meta.phase_name]
    ['Created: ', caseData.meta.timestamp]
    ['Target: ', caseData.target.name]
    ['Constellation: ', caseData.constellation.name]
    ['Sensor: ', caseData.sensor.name]
    ['Time span: ', num2str(caseData.summary.time_start), ' -> ', num2str(caseData.summary.time_end), ' s']
    ['dt: ', num2str(caseData.summary.dt), ' s']
    ['Num steps: ', num2str(caseData.summary.num_steps)]
    ['Num sats: ', num2str(caseData.summary.num_sats)]
    ['Candidate count min/max/mean: ', ...
        num2str(caseData.summary.min_candidate_count), ' / ', ...
        num2str(caseData.summary.max_candidate_count), ' / ', ...
        num2str(caseData.summary.mean_candidate_count, '%.3f')]
    'Status: Phase 0 smoke ready'
    };
end
