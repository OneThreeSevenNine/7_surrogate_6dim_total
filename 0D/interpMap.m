function [W,eff,pr] = interpMap(massMap,effMap,prMap,n,R)
% COMPMAP 特性图插值（通过等效率线和β插值得到该设计点对应的质量流量、等熵效率、压比）
%   此处显示详细说明
W = linear_interp(massMap,n,R);
eff = linear_interp(effMap,n,R);
pr = linear_interp(prMap,n,R);
% 限制有意义范围
% if W <= 0 
%     W = 1e-3;
% end
% if eff <= 0 
%     eff = 1e-3;
% end
% if pr <= 1 
%     pr = 1;
% end

% interp2函数
% x = map(1,2:end);
% y = map(2:end,1);
% v = map(2:end,2:end); 
% xq = R;
% yq = n;
% vq = interp2(x,y,v,xq,yq);...,'makima'); %注意第一行为x，第一列为y
end

% 二维线性插值函数（内插和外插），先插值出一行
function  [vq] = linear_interp(table,xq,yq)
x = table(2:end,1); % 二维表的第一列
y = table(1,2:end); % 二维表的第一行
v = table(2:end,2:end); 
xn = length(x);
yn = length(y);
vxq = zeros(1,yn);
for i = 1:xn-1 % 先根据xq插值出一行
    if xq <= x(1)
        for j = 1:yn
            vxq(j) = v(1,j) + (v(2,j) - v(1,j))/(x(2) - x(1))*(xq - x(1));
        end
        break
    elseif xq > x(xn)
        for j = 1:yn
            vxq(j) = v(xn,j) + (v(xn,j) - v(xn-1,j))/(x(xn) - x(xn-1))*(xq - x(xn));
        end
        break
    else
        if (xq > x(i)) && (xq <= x(i+1))
            for  j = 1:yn
                vxq(j) = v(i,j) + (v(i+1,j) - v(i,j))/(x(i+1) - x(i))*(xq - x(i));
            end
        break
        end     
    end
end

for i = 1:yn-1
    if yq <= y(1)
        vq = vxq(1) + (vxq(2) - vxq(1))/(y(2) - y(1))*(yq - y(1));
        break
    elseif yq > y(yn)
        vq = vxq(yn) + (vxq(yn) - vxq(yn-1))/(y(yn) - y(yn-1))*(yq - y(yn));
        break
    else
        if (yq > y(i)) && (yq <= y(i+1))
            vq = vxq(i) + (vxq(i+1) - vxq(i))/(y(i+1) - y(i))*(yq - y(i));
        break
        end        
    end
end
end

% 非线性内插