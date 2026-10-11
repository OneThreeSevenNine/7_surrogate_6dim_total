function phi = massFlowParameter(M,gamma,R)
%MASSFLOWPARAMETER Compressible-flow mass-flow parameter.
% W = Cd*A*Pt/sqrt(Tt)*phi(M,gamma,R), with SI units.
phi = sqrt(gamma/R).*M.*(1 + 0.5*(gamma-1).*M.^2).^...
    (-(gamma+1)/(2*(gamma-1)));
end
