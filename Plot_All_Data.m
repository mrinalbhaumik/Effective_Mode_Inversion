% =================================================================================================
% SCRIPT: Plot_Inversion_Profiles
% -------------------------------------------------------------------------------------------------
% DESCRIPTION:
%   Loads the inversion results for different layer configurations and trial runs, organizes 
%   the profiles based on calculated misfit, removes duplicate profiles, and plots the best 
%   profiles for visualization. Designed for PSO-based effective mode inversion results.
%
% USAGE:
%   Run this script after completing the PSO inversion runs for the specified target curve.
%
% INPUTS:
%   - Name            : Name of the folder containing inversion results (e.g., 'Target curve- HVL_10m')
%   - Trial_numb      : Array of trial numbers for each layer configuration
%   - h_count         : Array specifying the number of layers to consider
%   - N_best_profile  : Number of best profiles to plot based on misfit
%   - max_fit         : Maximum allowed misfit percentage for plotting
%   - Dmax            : Depth parameter for Vs_30 calculation
%   - dh_int          : Depth resolution for median profile plotting
%
% OUTPUT:
%   - Combined profiles are organized and best profiles are plotted.
%
% DEPENDENCIES:
%   - combine_profiles.m
%   - Plot_Profiles.m
%   - input_params.mat (contains PSO and target curve parameters)
%
% NOTES:
%   - Ensure the folder specified by 'Name' contains all relevant trial results and 'input_params.mat'.
%   - Adds the folder to MATLAB path automatically.
%
% -------------------------------------------------------------------------------------------------
% AUTHOR: Mrinal Bhaumik
% SUPERVISOR: Dr. Tarun Naskar
% AFFILIATION: Indian Institute of Technology Madras, India
% DATE: October 2025
% =================================================================================================
clc
clear
close all
Name = 'Target curve- HVL_10m';

%% Input

Trial_numb              = 1:2;      % Number of trial runs for each layer configuration
h_count                 = [7 8];    % Layer counts to consider
N_best_profile          = 100;      % Number of best profiles to plot
max_fit                 = 2;        % Maximum allowed misfit (%)  
Dmax                    = 30;       % Depth to plot
dh_int                  = 0.1;      % Depth resolution for median profile plotting

Model_count             = length(h_count);
addpath(Name);

load('input_params.mat');

%% ------------------------------------------------------------------------
% Combine all profiles from different trials and layer configurations
% -------------------------------------------------------------------------
% This step removes duplicate profiles and organizes profiles based on misfit

[combined_vs, combined_misfit, combined_h, combined_nu, combined_disp,...,
    best_vs, best_h, best_misfit] = combine_profiles(Name, h_count, Trial_numb, Model_count);

%% ------------------------------------------------------------------------
% Plot the best profiles based on misfit
% -------------------------------------------------------------------------

Plot_Profiles(combined_misfit, N_best_profile, max_fit, dh_int, Dmax, combined_h, combined_vs, combined_disp, Tar);


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      Functions            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [combined_vs, combined_misfit, combined_h, combined_nu, combined_disp,...,
    best_vs, best_h, best_misfit] = combine_profiles(Name, LR, Trial_num, Model_count)

    combined_vs     = []; 
    combined_misfit = []; 
    combined_h      = []; 
    combined_nu     = [];
    best_misfit     = []; 
    best_vs         = []; 
    best_h          = [];
    combined_disp   = [];

    for jj = 1 : Model_count

        lr = LR(jj); 

        for trial = 1:100
            f = [Name, '_h_count_', num2str(lr), '_trial_', num2str(trial), '.mat'];
            if exist(f, 'file')
                load(f);
                break;
            end
        end


        All_misfit  = zeros(1, 10);
        All_vs      = zeros(N_layer+1, 10);
        All_nu      = zeros(N_layer+1, 10);
        All_h       = zeros(N_layer, 10);
        disp_size   = length(param{7,1});
        All_disp    = zeros(disp_size, 10);
        kk          = 1;

        for trial = Trial_num

            filename = [Name, '_h_count_', num2str(lr), '_trial_', num2str(trial), '.mat'];
            try
                load(filename);
            catch
                % warning('File not found: %s. Skipping to next trial.', filename);
                disp(['File not found: ', filename, '. Skipping to next trial.']);
                continue;
            end
            % Check if 'itr' exists and is zero
            if ~exist('itr', 'var') || itr == 0
                disp(['Empty itr in file: ', filename, '. Skipping to next trial.']);
                continue;
            end


            % itr = min(itr, 100); %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            misfit = 0; 
            vs = zeros(N_layer+1, 5); 
            h = zeros(N_layer, 5); 
            nu = zeros(N_layer+1, 5); 
            disp_curve = zeros(disp_size, 5);

            for ii = 1 : itr
                misfit(ii) = param{2, ii}; 
                disp_curve(:, ii) = param{7, ii};
                h(:, ii)   = param{3, ii};
                vs(:, ii)  = param{4, ii};
                nu(:, ii)  = param{5, ii};
            end

            % Remove duplicate misfit entries
            [~, ia, ~] = unique(misfit);
            misfit     = misfit(ia);
            vs         = vs(:, ia);
            h          = h(:, ia);
            nu         = nu(:, ia);
            disp_curve = disp_curve(:, ia);

            % Store all trials' results
            len = length(misfit);
            All_misfit(kk:kk+len-1) = misfit;
            All_vs(1:size(vs,1), kk:kk+len-1)  = vs;
            All_h(1:size(h,1), kk:kk+len-1)   = h;
            All_nu(1:size(nu,1), kk:kk+len-1)  = nu;
            All_disp(1:size(disp_curve,1), kk:kk+len-1)= disp_curve;

            kk = kk + len;
        end

        % Sort and retain best profiles
        [All_misfit, index] = sort(All_misfit, 'descend');
        N_best = length(index) - 1;
        All_misfit = All_misfit(end - N_best : end);
        index = index(end - N_best : end);

        All_vs   = All_vs(:, index);
        All_h    = All_h(:, index);
        All_nu   = All_nu(:, index);
        All_disp = All_disp(:, index);

        % Save best profile
        best_misfit = [best_misfit  All_misfit(end)];
        best_vs     = [best_vs num2cell(All_vs(:, end), 1)];
        best_h      = [best_h  num2cell(All_h(:, end), 1)];

        % Combine all
        combined_misfit = [combined_misfit  All_misfit];
        combined_vs     = [combined_vs num2cell(All_vs, 1)];
        combined_h      = [combined_h  num2cell(All_h, 1)];
        combined_nu     = [combined_nu num2cell(All_nu, 1)];
        combined_disp   = [combined_disp num2cell(All_disp, 1)];

    end
end



function[Vs_best, h_inter, Vs_medi] = Plot_Profiles(combined_misfit, N_best_profile, max_fit, dh_int, Dmax,...
    combined_h, combined_vs, combined_disp, Tar, varargin)

[combined_misfit1, index1]  = sort(combined_misfit,'descend');

misfit_upto_n               = combined_misfit1 < max_fit;
combined_misfit1            = combined_misfit1 (misfit_upto_n); 
N_plot                      = min(length(combined_misfit1), N_best_profile); 
combined_misfit1            = combined_misfit1(end - N_plot+1 : end);
index1                      = index1(end - N_plot + 1:end);
h_inter                     = 0 : dh_int : Dmax; 
v_inter                     = zeros(length(combined_misfit1), length(h_inter));

Num     = length(combined_misfit1);
vec     = [100; 80; 30; 5; 0.5; 0];
cmap    = load('cmap7.mat');
map     = interp1(vec,cmap.cmap,linspace(100,0,Num),'pchip');
figure
for nn = 1 : 1 : Num

    h_i     = combined_h{index1(nn)};
    vs_i    = combined_vs{index1(nn)};
    if isrow(h_i)
        h_i = h_i';
    end
    h_i(isnan(h_i)) = [];
    h_i(h_i == 0) = [];
    vs_i(vs_i == 0) = [];

    % v_inter(nn,:) = interp1([0;cumsum(h_i)],vs_i,h_inter,'previous','extrap');

    try
        v_inter(nn,:) = interp1([0; cumsum(h_i)], vs_i, h_inter, 'previous', 'extrap');
    catch ME
        disp('Error caught: Data doesnt exists');
        disp(ME.message);
        keyboard  % Execution will pause here so you can inspect variables
    end


    hold on; plot(v_inter(nn,:), h_inter, '-','LineWidth', 1.5, 'color',map(nn,:));
end

Vs_medi = median(v_inter,1);
Vs_medi = Vs_medi'; h_inter = h_inter';


hold on; plot(Vs_medi,h_inter,'-y','LineWidth', 2);

hold on; plot(v_inter(Num,:), h_inter, '-r','LineWidth', 2);
Vs_best = v_inter(Num,:)';

colormap(map);
c = colorbar;
c.Label.String = 'Misfit (%)';
c.Ticks = 0:0.25:1;
Y = prctile(combined_misfit1,0:25:100);
Y = round(Y,2);
c.TickLabels = Y(end:-1:1);

axis ij, box on
xlabel('Shear wave velocity (m/s)');
ylabel('Depth (m)'); ylim([0 Dmax]); 
set(gca,'fontweight','normal','fontname','times','TickDir','out','FontSize', 10.9);
% title('N best profiles (median: green)')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Plot dispersion curves

f     = Tar.w;
figure
for nn = 1 : 1 : Num
    Vr    = combined_disp{index1(nn)};
    hold on; plot(f,Vr, '-','LineWidth', 2, 'color',map(nn,:));
end

hold on; errorbar(f, Tar.v_f, Tar.std, '-g', 'LineWidth', 1, 'MarkerSize', 2, 'CapSize', 3);

colormap(map);
c = colorbar;
c.Label.String = 'Misfit (%)';
c.Ticks = 0:0.25:1;
Y = prctile(combined_misfit1,0:25:100);
Y = round(Y,2); Y(end) = round(Y(end));
c.TickLabels = Y(end:-1:1);
 box on
xlabel('Frequency (Hz)');
ylabel('Phase velocity (m/s)'); 
set(gca,'fontweight','normal','fontname','times','TickDir','out','FontSize', 10.9);
set(gca, 'XScale', 'log')

end
%%

