function calib = stage15h_get_geometry_calibration()
% Stage15-H:
% 固化第三章实验0给出的几何标定量。
%
% 这些值来自 outputs/cpt3/exp0_local_pair_geom 的稳定结果，
% 后续 Stage15-H/J 只依赖本函数，不直接读取 txt summary。

calib = struct();

% 第三章实验0：理论参考锚点
calib.baseline_anchor_km = [514.462, 1108.513, 1611.071];

% 第三章实验0：M_G 阈值
calib.M_G_thr_12 = 115.411378;
calib.M_G_thr_23 = 198.489832;

% 推荐目标高度、速度锚点
calib.h_tgt_anchor_km = [30, 40, 50];
calib.v_anchor_kmps   = [4.00, 4.25, 4.50, 4.75, 5.00];

% 可信 R_geo 统计（middle/high M_G only）
calib.R_geo_trusted_min_km    = 180.278;
calib.R_geo_trusted_median_km = 223.607;
calib.R_geo_trusted_max_km    = 300.000;

% 推荐盒尺度范围
calib.Bxy_nominal_range_km      = [73.607, 203.607];
calib.Bxy_conservative_range_km = [30.278, 160.278];
calib.Bz_half_km                = 10.000;

% 推荐步长
calib.step_xy_conservative_km = 45.069;
calib.step_xy_nominal_km      = 55.902;

% 区域标签（内部使用）
calib.region_names = {'low_M_G','mid_M_G','high_M_G'};
end
