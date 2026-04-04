
Phase R0 scope
目标

Phase R0 只完成两件事：

建立第五章新目录 ch5_rebuild/
建立参数 bootstrap 入口，把第四章静态设计结果映射为第五章主工况初始化参数
R0 输入源
default_params.m
Stage04 cache
Stage05 cache
Stage02/03 相关默认场景参数
R0 输出

统一输出 bundle，至少包含：

bundle.stage04
bundle.stage05
bundle.theta_star
bundle.theta_plus
bundle.sensor_profile
bundle.target_case
bundle.gamma_req
约束
不修改 Stage04 / Stage05 核心算法
不修改旧 ch5_dualloop 入口
不在本阶段引入复杂 runner 体系
