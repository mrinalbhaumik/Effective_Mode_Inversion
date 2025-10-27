

% =================================================================================================
% FUNCTION: PSO_Objective
% -------------------------------------------------------------------------------------------------
% DESCRIPTION:
%   This function defines the objective (cost) function used in the Particle Swarm Optimization (PSO)
%   inversion process. It computes the misfit between the modeled effective-mode dispersion curve and 
%   the target (observed) dispersion data. The PSO algorithm minimizes this misfit to estimate the 
%   subsurface model parameters (Vs, h, ν, ρ).
%
% INPUT:
%   h_vs_nu       - Combined parameter vector representing the current particle position 
%                   in the PSO search space.
%   N_layer       - Number of layers in the inversion model.
%   initial_param - Structure containing fixed or initial parameter values.
%   Layer_param   - Structure defining which parameters are variable or fixed, and inversion constraints.
%   Acquisition   - Structure containing acquisition geometry (r0, dr, rN).
%   HTLM          - Structure containing numerical model setup (e.g., discretization depth and step size).
%   Tar           - Structure containing target dispersion data and related parameters 
%                   (fields: w, v_f, std).
%
% OUTPUT:
%   y - Objective function value (misfit) for the given parameter set.
%
% DEPENDENCIES:
%   - PSO_select_variable.m
%   - Active_SWM.m 
%
% NOTES:
%   - A large penalty (1e6) is applied if:
%       (1) The shear-wave velocity of the half-space is less than the maximum of the overlying layers.
%       (2) The drop in Vs between consecutive layers exceeds the Vs_reversal limit.
%   - The cost function is minimized by PSO to obtain the best-fit model.
%   - Ensure that the input structures (Acquisition, HTLM, Tar) are correctly defined before execution.
%
% -------------------------------------------------------------------------------------------------
% AUTHOR: Mrinal Bhaumik
% SUPERVISOR: Dr. Tarun Naskar
% AFFILIATION: Indian Institute of Technology Madras, India
% DATE: October 2025
% =================================================================================================

function [y] = PSO_Objective(h_vs_nu, N_layer, initial_param, Layer_param, Acquisition, HTLM, Tar)

[h, vs, nu, rho] = PSO_select_variable (h_vs_nu, N_layer, Layer_param, initial_param);
%%
vp          = nu;
r0          = Acquisition.r0;
dr          = Acquisition.dr;
rN          = Acquisition.rN;
w           = Tar.w;
v_f         = Tar.v_f;
if isfield(Tar, 'std'); std_vel = Tar.std; else
std_vel = []; end
d           = HTLM.d;
dh          = HTLM.dh;
Vs_reversal = Layer_param.Vs_reversal;
Vs_halfspace_max = Layer_param.Vs_halfspace_max;

if strcmpi(Vs_halfspace_max, 'yes') && vs(end) < max(vs(1:end-1))
    y = 1e6;  % Apply a penalty
elseif any(diff(vs) < -Vs_reversal * vs(1:end-1))  % Check if the drop exceeds Vs_reversal limit
    y = 1e6;  % Apply a penalty
else

    [~, c_eff] = Active_SWM(vs, vp, rho, h, r0, dr, rN, w', d, dh);
    D_R        = c_eff;

    % misfit error

    if ~isrow(v_f)
        v_f = v_f';
    end
    if ~isrow(D_R )
        D_R  = D_R';
    end

    % Define misfit error here (Change it according to the requirement)

    if ~isempty(std_vel)
       elem_1  = ((D_R-v_f).^2)';
       y = sqrt( sum(elem_1 ./ std_vel.^2) / length(v_f) );
    else
       % L2 norm

       % elem_1  = ((D_R-v_f).^2);
       % y = sqrt(sum(elem_1(:)) / length(v_f) );

       % L1 norm

       elem_1  = abs(D_R-v_f)./v_f;
       y       = 100 * sum(elem_1) / length(v_f) ;
    end

end

end