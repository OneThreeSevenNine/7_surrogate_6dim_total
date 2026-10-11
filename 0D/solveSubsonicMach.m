function [M,capacityRatio,isValid] = solveSubsonicMach(W,A,Cd,Pt,Tt,gamma,R)
%SOLVESUBSONICMACH Invert the subsonic branch of the mass-flow equation.
Wchoke = Cd*A*Pt/sqrt(Tt)*massFlowParameter(1,gamma,R);
capacityRatio = W/Wchoke;

if W < 0 || A <= 0 || Cd <= 0 || Pt <= 0 || Tt <= 0 || ...
        gamma <= 1 || R <= 0 || capacityRatio > 1 + 1e-8
    M = NaN;
    isValid = false;
    return
end
if W == 0
    M = 0;
    isValid = true;
    return
end

target = W*sqrt(Tt)/(Cd*A*Pt);
fun = @(x) massFlowParameter(x,gamma,R) - target;
M = fzero(fun,[1e-10,1]);
isValid = isfinite(M) && isreal(M) && M >= 0 && M <= 1;
end
