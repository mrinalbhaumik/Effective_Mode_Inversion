% =================================================================================================
% SCRIPT: Toolbox_Check
% -------------------------------------------------------------------------------------------------
% DESCRIPTION:
%   Checks for the presence of all required MATLAB toolboxes for running the PSO-based 
%   effective mode inversion package. If a toolbox is missing, a warning is displayed along 
%   with instructions to install it.
%
% USAGE:
%   Run this script before executing any PSO inversion routines to ensure all dependencies are met.
%
% REQUIRED TOOLBOXES:
%   - MATLAB (core)
%   - Optimization Toolbox
%   - Statistics and Machine Learning Toolbox
%   - Parallel Computing Toolbox
%   - Global Optimization Toolbox
%
% OUTPUT:
%   - Warnings for any missing toolboxes
%   - Confirmation message if all required toolboxes are installed
%
% NOTES:
%   - Toolbox names are checked using `ver()` function.
%   - If missing, installation instructions are printed for convenience.
%
% DEPENDENCIES:
%   None (self-contained)
%
% -------------------------------------------------------------------------------------------------
% AUTHOR: Mrinal Bhaumik
% SUPERVISOR: Dr. Tarun Naskar
% AFFILIATION: Indian Institute of Technology Madras, India
% DATE: October 2025
% =================================================================================================
clc
clear;

% Get installed products
installedProducts = {ver().Name};   

requiredToolboxes = {...
    'MATLAB', ...
    'Optimization Toolbox', ...
    'Statistics and Machine Learning Toolbox', ...
    'Parallel Computing Toolbox', ...
    'Global Optimization Toolbox'};

for k = 1:length(requiredToolboxes)
    if ~any(contains(installedProducts, requiredToolboxes{k}))
        warning(['Required toolbox missing: ', requiredToolboxes{k}, ...
                 '. Please install it to run this script.']);
        fprintf('You can install it via MATLAB Add-On Explorer or use:\n');
        fprintf(' >> matlab.addons.install(''%s.mltbx'')  %% if you have the installer file\n\n', requiredToolboxes{k});
    end
end

disp('All required toolboxes are installed (if no warnings).');
