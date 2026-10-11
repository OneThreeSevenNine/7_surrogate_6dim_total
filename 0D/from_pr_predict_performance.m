function [inv_results] = from_pr_predict_performance(RAW_DATA, target_PR_core, target_PR_bypass, show_plot)
%% ========================================================================
%  特性逆向预测程序（给定压比反推背压、流量和效率）
% ========================================================================
%  输入参数:
%    RAW_DATA          - 你的仿真结果矩阵 [N x 8]
%                        列顺序: [Ps_core, Ps_bypass, W_core, W_bypass, PR_core, PR_bypass, Eff_core, Eff_bypass]
%    target_PR_core    - 目标输入的内涵压比 (例如: 1.4195)
%    target_PR_bypass  - 目标输入的外涵压比 (例如: 1.2334)
%    show_plot         - 是否绘图可视化 (true 或 false)
%  输出参数:
%    inv_results       - 包含所有反推预测结果的结构体

    if nargin < 4
        show_plot = true; % 默认开启绘图
    end

    %% 1. 提取原始流道气动参数
    % 此时，我们要建立从 [PR_core, PR_bypass] 到其它参数的映射
    Y1 = RAW_DATA(:, 5); % 自变量1：内涵压比 PR_core
    Y2 = RAW_DATA(:, 6); % 自变量2：外涵压比 PR_bypass
    
    X1    = RAW_DATA(:, 1); % 因变量1：内涵静压 Ps_core
    X2    = RAW_DATA(:, 2); % 因变量2：外涵静压 Ps_bypass
    W_c   = RAW_DATA(:, 3); % 因变量3：内涵流量 W_core
    W_b   = RAW_DATA(:, 4); % 因变量4：外涵流量 W_bypass
    Eff_c = RAW_DATA(:, 7); % 因变量5：内涵效率 Eff_core
    Eff_b = RAW_DATA(:, 8); % 因变量6：外涵效率 Eff_bypass

    %% 2. 构建逆向散点插值器 (以双压比为自变量输入)
    % 采用 'linear' 散点插值可以确保逆向求解时，在离散网格边界内具有良好的单调性和稳定性
    F_Ps_c  = scatteredInterpolant(Y1, Y2, X1,    'linear', 'linear');
    F_Ps_b  = scatteredInterpolant(Y1, Y2, X2,    'linear', 'linear');
    F_W_c   = scatteredInterpolant(Y1, Y2, W_c,   'linear', 'linear');
    F_W_b   = scatteredInterpolant(Y1, Y2, W_b,   'linear', 'linear');
    F_Eff_c = scatteredInterpolant(Y1, Y2, Eff_c, 'linear', 'linear');
    F_Eff_b = scatteredInterpolant(Y1, Y2, Eff_b, 'linear', 'linear');

    %% 3. 执行逆向特性工作点反推
    pred_Ps_c  = F_Ps_c(target_PR_core, target_PR_bypass);
    pred_Ps_b  = F_Ps_b(target_PR_core, target_PR_bypass);
    pred_W_c   = F_W_c(target_PR_core, target_PR_bypass);
    pred_W_b   = F_W_b(target_PR_core, target_PR_bypass);
    pred_Eff_c = F_Eff_c(target_PR_core, target_PR_bypass);
    pred_Eff_b = F_Eff_b(target_PR_core, target_PR_bypass);

    %% 4. 打印格式化逆向预测报告
    fprintf('============================================================\n');
    fprintf('     大涵道比涡扇发动机风扇部件压比匹配点逆向特性预测报告\n');
    fprintf('============================================================\n');
    fprintf(' 输入设计点/控制压比:\n');
    fprintf('   - 目标内涵设计压比 (PR_core)   : %.4f\n', target_PR_core);
    fprintf('   - 目标外涵设计压比 (PR_bypass) : %.4f\n', target_PR_bypass);
    fprintf('-----------------[ 逆向反推结果 ]---------------------------\n');
    fprintf('【建议背压设置 (Back Pressure Setting)】:\n');
    fprintf('   - 建议内涵出口静压 (Ps_core)  : %10.4f kPa (%12.2f Pa)\n', pred_Ps_c, pred_Ps_c * 1000);
    fprintf('   - 建议外涵出口静压 (Ps_bypass): %10.4f kPa (%12.2f Pa)\n', pred_Ps_b, pred_Ps_b * 1000);
    fprintf('------------------------------------------------------------\n');
    fprintf('【预期气动性能预测 (Predicted Performance)】:\n');
    fprintf('   - 内涵预期换算流量 (Wcor_core) : %10.4f kg/s\n', pred_W_c);
    fprintf('   - 外涵预期换算流量 (Wcor_bypass): %10.4f kg/s\n', pred_W_b);
    fprintf('   - 内涵预期等熵效率 (Eff_core)  : %10.4f \n',    pred_Eff_c);
    fprintf('   - 外涵预期等熵效率 (Eff_bypass) : %10.4f \n',    pred_Eff_b);
    fprintf('============================================================\n');

    %% 5. 打包输出数据结构体
    inv_results.Ps_core = pred_Ps_c;
    inv_results.Ps_bypass = pred_Ps_b;
    inv_results.W_core = pred_W_c;
    inv_results.W_bypass = pred_W_b;
    inv_results.Eff_core = pred_Eff_c;
    inv_results.Eff_bypass = pred_Eff_b;

    %% 6. 逆向映射空间可视化（以双压比反推内涵背压为例）
    if show_plot
        % 构建压比坐标网格
        [Yq1, Yq2] = meshgrid(linspace(min(Y1), max(Y1), 40), linspace(min(Y2), max(Y2), 40));
        Zq_Ps_c = F_Ps_c(Yq1, Yq2);
        Zq_Ps_b = F_Ps_b(Yq1, Yq2);

        figure('Color', 'w', 'Position', [180, 200, 1100, 460]);

        % 子图1：内涵压比-外涵压比 映射 内涵背压
        subplot(1, 2, 1);
        surf(Yq1, Yq2, Zq_Ps_c, 'FaceAlpha', 0.6, 'EdgeColor', 'none'); hold on;
        colormap('cool'); shading interp;
        plot3(Y1, Y2, X1, 'ko', 'MarkerFaceColor', 'b', 'MarkerSize', 5, 'DisplayName', 'CFD工况散点');
        plot3(target_PR_core, target_PR_bypass, pred_Ps_c, 'rp', 'MarkerSize', 14, 'MarkerFaceColor', 'r', 'DisplayName', '逆向求解落点');
        xlabel('PR_{core}'); ylabel('PR_{bypass}'); zlabel('P_{s,core} (kPa)');
        title('压比解空间 ➔ 内涵静压 P_{s,core}');
        grid on; view(135, 25); legend('Location', 'best');

        % 子图2：内涵压比-外涵压比 映射 外涵背压
        subplot(1, 2, 2);
        surf(Yq1, Yq2, Zq_Ps_b, 'FaceAlpha', 0.6, 'EdgeColor', 'none'); hold on;
        shading interp;
        plot3(Y1, Y2, X2, 'ko', 'MarkerFaceColor', 'g', 'MarkerSize', 5, 'DisplayName', 'CFD工况散点');
        plot3(target_PR_core, target_PR_bypass, pred_Ps_b, 'rp', 'MarkerSize', 14, 'MarkerFaceColor', 'r', 'DisplayName', '逆向求解落点');
        xlabel('PR_{core}'); ylabel('PR_{bypass}'); zlabel('P_{s,bypass} (kPa)');
        title('压比解空间 ➔ 外涵静压 P_{s,bypass}');
        grid on; view(135, 25); legend('Location', 'best');
    end
end