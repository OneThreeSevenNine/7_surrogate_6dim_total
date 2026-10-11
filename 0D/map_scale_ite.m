function [massMap, effMap, prMap] = map_scale_ite(massMap,effMap,prMap,scale)
%MAPSCALE 特性图缩放
% 缩放流量、效率、压比
massMap(2:end,2:end) = massMap(2:end,2:end)*scale(1);
effMap(2:end,2:end) = effMap(2:end,2:end) + scale(2);
prMap(2:end,2:end) = (prMap(2:end,2:end) - 1)*scale(3) + 1;
% 缩放转速（因为转速是通过等值线来表示的，所以计算换算转速）
massMap(2:end,1) = massMap(2:end,1)/scale(4);
effMap(2:end,1) = effMap(2:end,1)/scale(4);
prMap(2:end,1) = prMap(2:end,1)/scale(4);
% fprintf("scale(2,3):%.4f %.4f \n",scale(2:3))
end

