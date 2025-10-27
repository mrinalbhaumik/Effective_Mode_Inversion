
% =================================================================================================
% FUNCTION: PSO_select_variable
% -------------------------------------------------------------------------------------------------
% DESCRIPTION:
%   This function separates the PSO-optimized parameter vector into individual geotechnical 
%   layer properties, including layer thickness (h), shear-wave velocity (Vs), Poisson’s ratio (ν),
%   and density (ρ). The selection and grouping depend on whether each parameter is defined as 
%   'variable' or 'fixed' in the Layer_param structure.
%
% INPUT:
%   h_vs_nu       - Combined parameter vector obtained from the PSO optimization process.
%   N_layer       - Number of layers in the current model.
%   Layer_param   - Structure specifying which parameters are variable or fixed 
%                   (fields: .h, .Vs, .nu, .ro).
%   initial_param - Structure containing initial or fixed parameter values.
%
% OUTPUT:
%   h   - Layer thickness vector.
%   vs  - Shear-wave velocity vector.
%   nu  - Poisson’s ratio vector.
%   rho - Density vector.
%
% DEPENDENCIES:
%   None (independent function, but used within the PSO inversion workflow).
%
% NOTES:
%   - The indexing scheme assumes parameters are concatenated sequentially in the order 
%     [h, Vs, nu, rho].
%   - Ensure the length of 'h_vs_nu' matches the number of variable parameters.
%   - This function is typically called within the PSO plotting and inversion routines.
%
% -------------------------------------------------------------------------------------------------
% AUTHOR: Mrinal Bhaumik
% SUPERVISOR: Dr. Tarun Naskar
% AFFILIATION: Indian Institute of Technology Madras, India
% DATE: October 2025
% =================================================================================================
function [h, vs, nu, rho] = PSO_select_variable (h_vs_nu, N_layer, Layer_param, initial_param)
%% Select the variables
if strcmpi(Layer_param.h, 'variable') && strcmpi(Layer_param.Vs, 'variable') && strcmpi(Layer_param.nu, 'variable') && strcmpi(Layer_param.ro, 'variable')
    h = h_vs_nu(1:N_layer);
    vs = h_vs_nu(N_layer+1 : 2*N_layer+1);
    nu = h_vs_nu(2*N_layer+2 : 3*N_layer+2);
    rho = h_vs_nu(3*N_layer+3 : end);
elseif strcmpi(Layer_param.h, 'variable') && strcmpi(Layer_param.Vs, 'variable') && strcmpi(Layer_param.nu, 'variable')&& strcmpi(Layer_param.ro, 'fixed')
    h = h_vs_nu(1:N_layer);
    vs = h_vs_nu(N_layer+1 : 2*N_layer+1);
    nu = h_vs_nu(2*N_layer+2 : end);
    rho = initial_param.rho_i;
elseif strcmpi(Layer_param.h, 'variable') && strcmpi(Layer_param.Vs, 'variable') && strcmpi(Layer_param.nu, 'fixed')&& strcmpi(Layer_param.ro, 'fixed')
    h = h_vs_nu(1:N_layer);
    vs = h_vs_nu(N_layer+1 : end);
    nu = initial_param.nu_i;
    rho = initial_param.rho_i;
elseif strcmpi(Layer_param.h, 'variable') && strcmpi(Layer_param.Vs, 'variable') && strcmpi(Layer_param.nu, 'fixed')&& strcmpi(Layer_param.ro, 'variable')
    h = h_vs_nu(1:N_layer);
    vs = h_vs_nu(N_layer+1 : 2*N_layer+1);
    nu = initial_param.nu_i;
    rho = h_vs_nu(2*N_layer+2 : end);
elseif strcmpi(Layer_param.h, 'fixed') && strcmpi(Layer_param.Vs, 'variable') && strcmpi(Layer_param.nu, 'variable')&& strcmpi(Layer_param.ro, 'fixed')
    h = initial_param.h_i;
    vs = h_vs_nu(1:N_layer);
    nu =  h_vs_nu(N_layer+1 : end);
    rho = initial_param.rho_i;
elseif strcmpi(Layer_param.h, 'fixed') && strcmpi(Layer_param.Vs, 'variable') && strcmpi(Layer_param.nu, 'fixed')&& strcmpi(Layer_param.ro, 'fixed')
    h = initial_param.h_i;
    vs = h_vs_nu;
    nu = initial_param.nu_i;
    rho = initial_param.rho_i;
end
end