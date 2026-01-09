
% =====================================================================================================================================
% ================================== Particle Swarm Optimization (PSO) for Effective Mode Inversion ====================================
% =====================================================================================================================================
% 
% AUTHORS:
%   Mrinal Bhaumik (mrinal.bhaumik2012@gmail.com)
%   Dr. Tarun Naskar (tarunnaskar@civil.iitm.ac.in)
%
%   This is a MATLAB package for active surface wave inversion using effective mode. It was developed by
%   Mrinal Bhaumik under the supervision of Dr. Tarun Naskar at The Indian
%   Institute of Technology Madras, India.
%
% DATE:
%   October 5, 2025
%
% VERSION:
%   1.0.0
%
% DESCRIPTION:
%   This MATLAB package implements a Particle Swarm Optimization (PSO)-based inversion algorithm 
%   for layered media using the Effective Mode approach. The method allows estimation of subsurface 
%   shear-wave velocity profiles from active surface-wave dispersion data. 
%
%   The code supports:
%       - Single or multiple PSO runs for inversion
%       - Optional refinement or continuation stages
%       - User-controlled or automated convergence criteria
%       - Parallel computation for large model spaces
%
% CITATION:
%   If you use this package in your research or consulting work, please cite the following publications:
%
%   [1] Bhaumik, M., & Naskar, T. (2025). "Effective-Mode Analysis of Elastic Waves".
%       Géotechnique. https://doi.org/xxxxxxxxx
%
%   [2] Bhaumik, M., & Naskar, T. (2024). "Active Sourced Wavefield Modeling for Layered Half-Space".
%       Journal of Geotechnical and Geoenvironmental Engineering.
%       https://doi.org/10.1061/JGGEFK.GTENG-12763
%
%
% REQUIRED TOOLBOXES:
%   - Optimization Toolbox 
%   - Statistics and Machine Learning Toolbox 
%   - Parallel Computing Toolbox 
%   - Global Optimization Toolbox
%
%   (Tip: Run "GetToolboxInformation.m" to check if all required toolboxes are installed.)
%
%
% DECLARATION:
%   © 2025 Mrinal Bhaumik & Tarun Naskar
%   Permission is granted to use, copy, modify, and distribute this software for any purpose,
%   provided that this notice appears in all copies.
%
%   This package will be **monitored, maintained, and upgraded** by the authors over time 
%   to ensure continued functionality, compatibility, and performance improvements.
%
%   The authors provide no warranty; use at your own risk.
%
% CONTACT / SUPPORT:
%   - Mrinal Bhaumik:  mrinal.bhaumik2012@gmail.com
%   - Dr. Tarun Naskar: tarunnaskar@civil.iitm.ac.in
%
%   For issues, feedback, collaboration opportunities, or any explanation or suggestions, 
%   please feel free to reach out via email. We welcome discussion and user input 
%   to further improve this package.
%
% IMPORTANT NOTE ON PERFORMANCE:
%   The performance and accuracy of the inversion heavily depend on the model parameterization. 
%   It is strongly recommended to experiment with different parameterizations and perform 
%   multiple trial runs to achieve stable and geophysically meaningful results.

% ====================================================================================================================================
clc
clear
close all
disp('Running particleSwarm')

% =====================================================================================================================================
% ============================================================= Input =================================================================
% =====================================================================================================================================
%%
global name fullFolderPath 

%% Basic Input Parameters ===============================================================================================================

% Import target curve: (.txt, .xlsx, .csv)
% Col-1:Frequency; Col-2:Phase velocity/slowness; Col-3: std_dev (optional)

[filepath, name, ext]   = fileparts('Example_Target1_24Ch@1m_10m_Offset.txt'); 
filePath                = fullfile(filepath, [name, ext]);
Data                    = readmatrix(filePath);

% Preprocess data: 
% Convert slowness to velocity, handle std, resample if required.
Include_min_COV         = [];           % Include minimum COV(e.g, 0.05,0.1), if not keep it empty.
Resample                = "no";         % Set "yes" for log-scale resampling. Set to "no" if resampling not needed
Number                  = [];           % if 'Resample' is 'yes', Set number of log samples
Data                    = preprocessData(Data, Include_min_COV, Resample, Number); 

% Acquisition parameters

Acquisition.dr          = 1;            % Sensor spacing (m)
Acquisition.rN          = 24;           % Number of receiver
Acquisition.r0          = 10;           % source to 1st sensor distance (m)

%% Advanced Input Parameters ===============================================================================================================

% Optimization running Parameters

Trial_num_index         = [1 2];        % number of trial for each layering parameter:[1 2 3..] 
Max_itr                 = 100;          % numnber of iteration (100 is a good number)
SwarmCount              = 100;           % Number of particles (swarm size: 50-100 is good number)
Tolerance               = 10^-4;        % Tolerance for convergence (when the change in solution is smaller than this, stop)
Tolerance_iteration     = 30;           % Number of iterations with no significant improvement before stopping
% A refinement run is an optional second phase in Particle Swarm Optimizatimization used to fine-tune the solution after
% the main optimization has converged.
continueRefinement      = true;        % Refinement Run,'true/ 'false'
Refinement_runs         = 1;            % if true ,Number of refinement runs after initial PSO
Refinement_itr          = 50;           % if true, Max iterations per refinement run
RunType                 = 'auto';       % if true, 'manual', or 'auto'
% manual: After each refinement phase, the program pauses and asks the user whether to continue.
% auto : The algorithm proceeds automatically through all runs (main and refinement) without user interaction.


% Layer parameter settings (expand the description below for detail)

Layer_param.h           = 'variable';   % 'variable' or 'fixed'
Layer_param.h_range     = 'LN_based';   % If 'h' is 'variable': choose 'LR_based' (Layer Ratio) or 'LN_based' (Layer by Number)
Layer_param.fixed       = 'increasing'; % If 'h' is 'fixed': choose layering type:'increasing' or 'equal'
Layer_param.h_count     = [1 2];        % If 'h' is 'variable': [LRs: Ex. 1.5 2 3], [LNs: Ex. 4 5... + H.S]; If 'fixed': [LNs] as the number of layers
Layer_param.Vs          = 'variable';   % Always: 'variable'
Layer_param.Vs_range    = 'Auto';       % numeric bounds:Ex.[150 800] or use: 'Auto'
Layer_param.nu          = 'fixed';      % 'variable' or 'fixed'
Layer_param.nu_range    =  [0.33];      % fixed at: 0.XX, or use : [0.25 0.35]; for variable range
Layer_param.ro          = 'fixed';      % 'variable' or 'fixed'
Layer_param.ro_range    = [1800];       % fixed at : XXXX, or use :[1700 2000]; for variable range
Layer_param.Vs_reversal = 0.1;          % allowable fractional Vs drop (if any)
Layer_param.Vs_halfspace_max = 'yes';   % Half-space velocity allways maximum, 'yes'/'no'
Layer_param.DCR_range   = [2 3];        % DCR: Depth conversion ratio, D_max = max_wavelength / DCR;
% Read description ---------------------------------------
%  Layer Thickness (h) Settings
% Layer_param.h
%   'variable' – Layer thickness values are optimized by PSO.
%   'fixed'    – Layer thicknesses remain constant.
%
% Layer_param.h_range
%   If h = 'variable', this determines *how* the thickness varies:
%     'LN_based' – "Layer Number"-based control:
%                  the number of layers is specified in 'h_count',
%                  and their thicknesses are automatically adjusted
%                  to match the total model depth.
%     'LR_based' – "Layer Ratio"-based control: (Cox and Teague - 2016)
%                  thickness ratios between consecutive layers are
%                  defined in h_count (e.g., [1.5 2 3] means the
%                  lower layers are proportionally thicker).
%
% Layer_param.fixed
%   Used only when h = 'fixed':
%     'increasing' – Each layer thickness increases with depth.
%     'equal'      – All layers have equal thickness.
%
% Layer_param.h_count
%   Defines the number or ratios of layers depending on the mode:
%     - If h = 'variable' and h_range = 'LN_based':
%           h_count = [4 5 6]  → Try models with 4, 5, and 6 layers.
%     - If h = 'variable' and h_range = 'LR_based':
%           h_count = [1.5 2 3] → Define layer thickness ratios.
%     - If h = 'fixed':
%           h_count = [5] → Use a fixed 5-layer model.
%
% Example: 1
%   Layer_param.h       = 'variable';
%   Layer_param.h_range = 'LN_based';
%   Layer_param.h_count = [5]; % Supports multiple values: [5 6 7]
% Example: 2
%   Layer_param.h       = 'variable';
%   Layer_param.h_range = 'LR_based';
%   Layer_param.h_count = [1.5]; % Supports multiple values: [1.5 2 3]
% When multiple values are provided, the code runs in a loop and saves all
% corresponding results.
% -------------------------------------------------------------
% Shear-Wave Velocity (Vs) Settings
%
% Layer_param.Vs
%   'variable' – Vs values are optimized during the PSO process.
%
% Layer_param.Vs_range
%   Defines the search range or constraint for Vs values:
%     - Numeric range (e.g., [150 800]) → Vs can vary within these bounds.
%     - 'Auto' → Automatically estimated from input data or depth trends.
%
% Layer_param.Vs_halfspace_max
%   Ensures the half-space (bottom layer) has the maximum Vs value.
%     'yes' → Force half-space Vs ≥ all other layers.
%     'no'  → Allow the half-space Vs to vary freely.
%
% The function, "PSO_Objective.m" contain objective function. The user can
% define new objective function by their choice.
% -------------------------------------------------------------

% Note::'Vs_reversal' ensures that the velocity drop between layers is not too abrupt. 
% Example, Vs(1) = 400 m/s, Vs_reversal = 0.1. So, minimum allowable Vs(2) = 400-0.1*400 = 360 m/s
% If there is no indication of velocity reversal, keep this value small.

% Forward model parameters

HTLM.d                  = 7;            % Default (Order of polynomial; maximum 15);
HTLM.dh                 = 10;           % Default

%% Save parameters =====================================================================================================================

% Target Setup

w = Data(:,1); v_f = Data(:,2); lambda = v_f./w;
Tar = struct(); Tar.w = w; Tar.v_f = v_f;  Tar.lambda = lambda;
[~, numCols] = size(Data);
if numCols >= 3; v_std = Data(:,3); Tar.std = v_std; end

% Create a new folder using the name of the file (if it doesn't exist), and
% save the detail

if ~exist(name, 'dir'); mkdir(name); end
folderName              = name;                                                                                
fullFolderPath          = fullfile(pwd(), folderName);

save(fullfile(fullFolderPath, 'TargetFile.mat'), 'Data');
save(fullfile(fullFolderPath, 'input_params.mat'), 'Tar','Acquisition','Layer_param','HTLM');
PSO_Supporting;

% ======================================================================================================================================
% ===================================================== Run PSO in a loop ===============================================================
% ======================================================================================================================================

for ii = 1 : numel(Layer_param.h_count)

    h_count  = Layer_param.h_count(ii);

    for trial = Trial_num_index

        % Plot
        figure(999); 
        figPos = getFigurePosition(0.55, 0.4, 5, 3); set(gcf, 'Position', figPos);
        subplot(1, 5, 1:3); 
        if numCols >= 3; errorbar(w, v_f, v_std, 'k.-', 'LineWidth', 1, 'MarkerSize', 6, 'CapSize', 4); else
        plot(w, v_f, 'k.-', 'LineWidth', 1, 'MarkerSize', 10); end
        ylabel('Phase velocity (m/s)'); xlabel('Frequency (Hz)'); hold off
        if strcmpi(Resample, 'yes'); set(gca, 'XScale', 'log'); end

        % Other global search algorithms
        [initial_param, lbinfo, ubinfo, N_layer] = PSO_GetInitialModel(ii, Tar, Layer_param);
        save(fullfile(fullFolderPath, 'Temp_params.mat'), 'Tar','Acquisition','Layer_param','HTLM', 'initial_param', 'lbinfo', 'ubinfo','N_layer');
        init_var            = initial_param.all;      % initial parameters
        disp(['running_',name,'_h_count_',num2str(h_count),'_trial_',num2str(trial)']);

        ObjectiveFunction   = @(h_vs_nu)PSO_Objective(h_vs_nu, N_layer, initial_param, Layer_param, Acquisition, HTLM, Tar);

        % Upper and lower bound
        lb              = lbinfo.all;
        ub              = ubinfo.all;
        nvar            = length(lb);

        %%%%%%%%% Particle swarm %%%%%%%%%%%%
        global param count ; param = cell(7, Max_itr+1); count = 0;

        options = optimoptions('particleswarm','SwarmSize',SwarmCount, 'MaxIterations', Max_itr,...
            'PlotFcn',@PSO_fun, 'InitialSwarmMatrix', init_var,'MinNeighborsFraction',0.9,'UseParallel', false,...
            'MaxStallIterations',Tolerance_iteration, 'FunctionTolerance',Tolerance,'SelfAdjustmentWeight', 1.5, 'SocialAdjustmentWeight', 1.5);

        % Higher 'SocialAdjustmentWeight' and 'SelfAdjustmentWeight': more exploitation; lower value more exploration, default:1.49

        % INITIAL PSO RUN ===========================================================================================

        tic
        [vs_cal, fval, exitflag, output] = particleswarm(ObjectiveFunction, nvar, lb, ub, options);
        itr     = output.iterations;
        param1  = param(:,1:itr); itr1    = itr;

        % REFINEMENT RUNS ===========================================================================================
        
        run = 0;
        while continueRefinement && run < Refinement_runs
            run = run + 1;
            if strcmpi(RunType, 'manual')
                prompt = sprintf('Initial PSO/refinement run %d complete. Do you want to continue refining? (y/n): ', run);
                answer = input(prompt, 's');
            elseif strcmpi(RunType, 'auto')
                answer = 'y';
            end

            if strcmpi(answer, 'y') || strcmpi(answer, 'yes')

                disp(['>> Starting refinement run ', num2str(run)]);

                ObjectiveFunction = @(h_vs_nu) PSO_Objective(h_vs_nu, N_layer, initial_param, Layer_param, Acquisition, HTLM, Tar);
                options = optimoptions('particleswarm','SwarmSize',SwarmCount, 'MaxIterations', Refinement_itr,...
                    'PlotFcn',@PSO_fun, 'InitialSwarmMatrix', vs_cal,'MinNeighborsFraction',1,'UseParallel', true,'MaxStallIterations',Tolerance_iteration);
                options.InertiaRange = [0.4, 0.8];

                [vs_cal, fval, exitflag, output] = particleswarm(ObjectiveFunction, nvar, lb, ub, options);

                itr = output.iterations;
                param2 = param(:,1:itr);
                param2 = [param1, param2];

                itr1 = itr1 + itr;
                param1 = param2;

            end
        end

        itr   = itr1;
        param = param1;

        toc

        % Final Save

        save(fullfile(fullFolderPath,[name,'_h_count_', num2str(h_count),'_trial_', num2str(trial),'.mat']),'itr','N_layer','param','vs_cal','Data');
        close all

    end
end

% =========================================================================================================================================================
% ============================================================ END ========================================================================================
% =========================================================================================================================================================





