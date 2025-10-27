% =================================================================================================
% FUNCTION: PSO_plot_profile
% -------------------------------------------------------------------------------------------------
% DESCRIPTION:
%   This function updates and visualizes the inverted subsurface profile during the Particle 
%   Swarm Optimization (PSO) process. It extracts the current best parameters from the PSO 
%   structure (`optimValues`), reconstructs the corresponding layer model, and plots the 
%   shear-wave velocity profile for the current iteration.
%
% INPUT:
%   optimValues - Structure containing PSO iteration information, including:
%                 .iteration : Current iteration number
%                 .bestx     : Best solution vector at the current iteration
%
% DEPENDENCIES:
%   - PSO_select_variable.m
%   - Temp_params.mat (temporary parameter file generated during inversion)
%
% OUTPUT:
%   None (the function produces plots and visual updates)
%
% NOTES:
%   - This function is typically called automatically during PSO iteration updates.
%   - Ensure that 'Temp_params.mat' exists in the working directory before execution.
%
% -------------------------------------------------------------------------------------------------
% AUTHOR: Mrinal Bhaumik
% SUPERVISOR: Dr. Tarun Naskar
% AFFILIATION: Indian Institute of Technology Madras, India
% DATE: October 2025

function [] = PSO_plot_profile (optimValues)

itr = optimValues.iteration;
BestVal = optimValues.bestx;

global  fullFolderPath
matFilePath     = fullfile(fullFolderPath, 'Temp_params.mat');
Temp_param      = load(matFilePath);
N_layer         = Temp_param.N_layer;
Layer_param     = Temp_param.Layer_param;
initial_param   = Temp_param.initial_param;
Acquisition     = Temp_param.Acquisition;
Tar             = Temp_param.Tar;
HTLM            = Temp_param.HTLM;
[h, vs, nu, rho] = PSO_select_variable (BestVal, N_layer, Layer_param, initial_param);

vp = nu; 
r0 = Acquisition.r0;
dr = Acquisition.dr;
rN = Acquisition.rN;
w  = Tar.w;
d  = HTLM.d;
dh = HTLM.dh;
[v, c_eff] = Active_SWM(vs, vp, rho, h, r0, dr, rN, w, d, dh);

global param
param{1,itr+1} = optimValues.iteration+1;
param{2,itr+1} = optimValues.bestfval;
param{3,itr+1} = h;
param{4,itr+1} = vs;
param{5,itr+1} = nu;
param{6,itr+1} = rho;
param{7,itr+1} = c_eff;
param{8,itr+1} = v(:,1:5);

%% Plot profiles

figure(999);subplot(1,5,4:5); hold on
obj = findobj(gca,'Type','line');
if length(obj) >= 3
    delete(obj(1))
end
if isrow(h)
    h = h';
end
h(isnan(h)) = [];
vs_plot     = repelem(vs, 2);
d_act       = repelem(cumsum(h), 2);
MaxDepth    = h(end) + sum (h);
if isrow(d_act)
    d_act=d_act';
end
d_act       = [0; d_act; MaxDepth];
plot(vs_plot, d_act, '-', 'LineWidth', 1)
axis ij

%% plot dispersion curve
% effective mode

figure(999), subplot(1,5,1:3); hold on

lines = findobj(gca, 'Type', 'line');
errs  = findobj(gca, 'Type', 'errorbar');
obj   = [lines; errs];

if length(obj)>1
    delete(obj(1));
end

plot(w, c_eff, 'or');

end