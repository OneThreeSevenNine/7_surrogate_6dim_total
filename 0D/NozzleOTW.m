function [Tout,V,Wout,Fgross,Mexit,isChoked,Ps] = ...
    NozzleOTW(A,CD,CFG,Ps0,far,Pin,Tin)
%NOZZLEOTW Convergent mixed nozzle at the supplied area, CD, and CFG.
Tout = Tin;
Cp = T2Gas(Tout,far,1);
R = T2Gas(Tout,far,4);
gamma = Cp/(Cp-R);
criticalRatio = ((gamma+1)/2)^(gamma/(gamma-1));
availableRatio = Pin/Ps0;

if availableRatio >= criticalRatio
    Mexit = 1;
    Ps = Pin/criticalRatio;
    isChoked = true;
else
    Ps = Ps0;
    Mexit = sqrt(max(0,2/(gamma-1)*(availableRatio^((gamma-1)/gamma)-1)));
    isChoked = false;
end

Ts = Tout/(1 + 0.5*(gamma-1)*Mexit^2);
V = Mexit*sqrt(gamma*R*Ts);
Wout = CD*A*Pin/sqrt(Tin)*massFlowParameter(Mexit,gamma,R);
Fgross = CFG*(Wout*V + (Ps-Ps0)*A);
end
