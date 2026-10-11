function [Tout] = Gas2T(GasProperty,far,option)
%GAS2T 由热力性质求温度，牛顿法计算
% 牛顿法初值
T = 800;
% 检查热力性质值是否超过范围201-1999
if GasProperty >= T2Gas(1999, far, option)
    Tout = 1999;
elseif GasProperty <= T2Gas(201, far, option)
    Tout = 201;
else
    i = 0; % 限制迭代次数
    while i <= 99
        i = i + 1;
        if abs (T2Gas(T, far, option) - GasProperty) < 1e-6 % 误差要小，不然熵函数不精确
            Tout = T;
            break;
        else
            righ = T2Gas(T + 1, far, option) - GasProperty;
            left = T2Gas(T - 1, far, option) - GasProperty;
            part = (righ - left) / 2;
            T = T - (T2Gas(T, far, option) - GasProperty) / part;
            % 防止牛顿法步子太大到达边界
            if 201 <= T && T <= 1999
            elseif T < 201
                T = 201;
            elseif T > 1999
                T = 1999;
            else
                T = 1000;
            end
        end
    end
    if i == 100
        Tout = 1000;
    end
end

% if GasProperty >= T2Gas(1999.5, far, option)
%     Tout = 1999.5;
% elseif GasProperty <= T2Gas(200.5, far, option)
%     Tout = 200.5;
% else
%     i = 0; % 限制迭代次数
%     while i <= 99
%         i = i + 1;
%         if abs (T2Gas(T, far, option) - GasProperty) < 1e-6 % 误差要小，不然熵函数不精确
%             Tout = T;
%             break;
%         else
%             righ = T2Gas(T + 0.5, far, option) - GasProperty;
%             left = T2Gas(T - 0.5, far, option) - GasProperty;
%             part = (righ - left) / 1;
%             T = T - (T2Gas(T, far, option) - GasProperty) / part;
%             % 防止牛顿法步子太大到达边界
%             if T < 200.5
%                 T = 200.5;
%             end
%             if T > 1999.5
%                 T = 1999.5;
%             end
%         end
%     end
%     if i == 100
%         Tout = 1000;
%     end
% end

end

