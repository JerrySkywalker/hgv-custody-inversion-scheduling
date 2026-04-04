
notes_parameter_bootstrap
bootstrap 总映射

B : (Stage04 outputs, Stage05 outputs, Stage02/03 defaults) ->
(theta_star, theta_plus, sensor_profile, target_case, gamma_req)

本阶段选型规则
1. theta_star

优先从 Stage05 可行解表中选取：

先最小 Ns = P*T
再最大 D_G_min
再最大 pass_ratio
2. theta_plus

在 theta_star 基础上选择一个轻度冗余增强构型：

Ns > Ns_star
优先最接近 Ns_star
同层再按 D_G_min / pass_ratio 选优
3. sensor_profile

R0 暂不引入第五章新传感器组，直接继承第四章 baseline 口径：

sigma_angle
off-nadir / FOV / range 等由现有默认参数给出
4. representative target case

默认采用第四章 nominal family 代表工况：

优先 cfg.stage04.example_case_id
否则回退到 N01
5. gamma_req

优先顺序：

从 Stage04 cache 中读取
回退到 cfg.stage04.gamma_floor
再回退到 cfg.stage04.gamma_req_fixed
