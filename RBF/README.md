# 六输出RBF与结果可用性判别器

MATLAB R2021b，SVM需要Statistics and Machine Learning Toolbox。

```matlab
cd('D:\OTW\4-zoom\5_surrogate_6dim\RBF')
model_file = main_rbf6;
test_rbf6(model_file);
% 追加独立CFD到rbf_6_test.txt后，只重新验证：
validate_rbf6(model_file);
s = load(model_file,'model');
[Y,J,info] = surrogate6_predict(s.model,[3865.1,107.4,118.0]);
```

输入为[Nf,ps_b,ps_c]，单位[rpm,kPa,kPa]；输出为[w_b,eff_b,pr_b,w_c,eff_c,pr_c]。
导数J尺寸n×6×3，按原始物理输入计算。标签0返回NaN；域外查询明确标记而不截断。

训练和测试源文件均为标准九列格式，输入固定为rpm、kPa、kPa，不再分段交换背压或换算单位。
训练集固定315点，测试集固定131点；数据构成改变必须显式更新rbf6_config.m。
根目录两个cleaned TXT保留全部样本并增加stable_label，不附原因列。
全部模型、报告、带原因的CSV和PNG保存到results/run_日期时间/。
单独验证保存到对应训练目录内validation_日期时间/，不改模型。

标签规则由训练集前165个可信点冻结。六个转速节点分别取可信稳定点的内外涵流量极值，
上下限各外扩该节点流量跨度的5%，节点之间线性插值。标签1严格要求有限结果、流量位于
插值包络内、0.5<两个效率<1、两个压比>1。3088..4053 rpm之外的训练/验证数据会被拒绝，
预测查询则保留结果但标为不可用。测试数据不参与包络标定。

新模型保存完整流量包络、标签规则和标准数据格式版本，只支持version 3模型。
报告额外保存`label_rule_flow_envelope.csv`；不再比较旧标签或旧模型。
此分类器判断输出是否符合参考性能包络，不直接证明CFD残差收敛；程序通过也不代表已达到替代CFD的精度。
交叉验证用于调参，报告分数不是嵌套验证；追加测试数据不应反复用于调参。

## 131点独立测试

`rbf_6_test.txt`全部131点已经统一为标准九列格式。完整训练和单独验证均重新生成
`rbf_6_test_cleaned.txt`，含全部131行、10列及stable_label。冻结模型验证：

```matlab
out = validate_rbf6(model_file);
```

分类和回归指标对完整131点统一计算，不再拆分原始81点、新增50点或转速区间。
六输出回归只统计实际标签1的CFD点；标签0仍保留原始记录和分类评估。
模型文件和标准源数据不改写。测试点数量改变时需显式更新配置。

旧模型兼容辅助文件`rbf6_rule_from_model.m`和旧results运行目录已不再被当前代码引用，
可在新模型完成验收后由用户手动删除。
