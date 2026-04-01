function txt_path = stage15h_write_summary(out_root, prior_dataset)
if ~exist(out_root, 'dir'); mkdir(out_root); end

txt_path = fullfile(out_root, 'stage15h_kernel_regression_summary.txt');
fid = fopen(txt_path, 'w');
assert(fid >= 0, 'Failed to open summary file.');

n = numel(prior_dataset);
MG = zeros(1,n);
frag = zeros(1,n);
Rgeo = zeros(1,n);

low_n = 0;
mid_n = 0;
high_n = 0;

for i = 1:n
    p = prior_dataset(i).prior;
    MG(i) = p.M_G_center;
    frag(i) = p.fragility_score;
    Rgeo(i) = p.R_geo_est;

    switch char(p.region_id)
        case 'low_M_G'
            low_n = low_n + 1;
        case 'mid_M_G'
            mid_n = mid_n + 1;
        case 'high_M_G'
            high_n = high_n + 1;
    end
end

fprintf(fid, '=== Stage15-H Kernel Regression Summary ===\n');
fprintf(fid, 'num_samples = %d\n', n);
fprintf(fid, '\n');

fprintf(fid, '--- region histogram ---\n');
fprintf(fid, 'low_M_G = %d\n', low_n);
fprintf(fid, 'mid_M_G = %d\n', mid_n);
fprintf(fid, 'high_M_G = %d\n', high_n);
fprintf(fid, '\n');

fprintf(fid, '--- prior stats ---\n');
fprintf(fid, 'M_G_center_min = %.6f\n', min(MG));
fprintf(fid, 'M_G_center_median = %.6f\n', median(MG));
fprintf(fid, 'M_G_center_max = %.6f\n', max(MG));
fprintf(fid, 'fragility_score_min = %.6f\n', min(frag));
fprintf(fid, 'fragility_score_median = %.6f\n', median(frag));
fprintf(fid, 'fragility_score_max = %.6f\n', max(frag));
fprintf(fid, 'R_geo_est_min = %.6f km\n', min(Rgeo));
fprintf(fid, 'R_geo_est_median = %.6f km\n', median(Rgeo));
fprintf(fid, 'R_geo_est_max = %.6f km\n', max(Rgeo));
fprintf(fid, '\n');

fprintf(fid, '--- first 20 samples ---\n');
fprintf(fid, 'sample_id,M_G_center,region_id,fragility_score,R_geo_est,Bxy_nominal_est,Bxy_conservative_est,step_xy_nominal_est,step_xy_conservative_est\n');
m = min(20, n);
for i = 1:m
    p = prior_dataset(i).prior;
    fprintf(fid, '%s,%.6f,%s,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n', ...
        prior_dataset(i).sample_id, ...
        p.M_G_center, char(p.region_id), p.fragility_score, p.R_geo_est, ...
        p.Bxy_nominal_est, p.Bxy_conservative_est, ...
        p.step_xy_nominal_est, p.step_xy_conservative_est);
end

fclose(fid);
end
