# 0D + 稳定分类器 + 六输出 RBF 快速模型

该目录是无需 FineTurbo/CFView 的快速耦合模型。每次外层迭代先运行七变量
0D模型，再在固定风扇转速下反求旁路和核心静压。候选压力必须同时通过
SVM稳定分类、物理有效性、训练范围和训练凸包检查。

## Linux运行

默认部署目录：

```text
/data/user03_ssy/OTW/12_surrogate_6dim_total
```

依赖 MATLAB R2021b 或兼容版本，以及 Statistics and Machine Learning
Toolbox。上传后先执行：

```bash
cd /data/user03_ssy/OTW/12_surrogate_6dim_total
PREFLIGHT_ONLY=1 bash zoom_6dim_total.sh
bash zoom_6dim_total.sh
```

可通过环境变量覆盖设置：

```bash
PROJECT_DIR=/custom/path OUTER_THRESHOLD=0.001 \
MAX_OUTER_ITERATIONS=50 bash zoom_6dim_total.sh
```

结果写入 `6D/runs/run_YYYYMMDD_HHMMSS_PID/`。每轮目录包含0D目标、
RBF匹配结果、代理诊断、四项外层残差和状态文件。

## MATLAB测试

```matlab
cd('/data/user03_ssy/OTW/12_surrogate_6dim_total/6D')
test_surrogate6
```

RBF输入为 `[Nf_rpm, ps_b_kPa, ps_c_kPa]`，输出为
`[w_b, eff_b, pr_b, w_c, eff_c, pr_c]`。模型按训练入口条件使用：
总温约305.5 K、总压约99.29 kPa。
