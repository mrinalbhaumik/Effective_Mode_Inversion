
% =================================================================================================
% FUNCTION: PSO_GetInitialModel
% -------------------------------------------------------------------------------------------------
% DESCRIPTION:
%   This function generates the initial layered model for the PSO inversion process. It defines 
%   the starting parameters, lower and upper bounds, and the number of layers based on the target 
%   dispersion data and layer parameterization settings. The initialization ensures a feasible 
%   and geophysically reasonable search space for the optimization.
%
% INPUT:
%   ii           - Model index or iteration counter (used for controlled randomization or multiple runs).
%   Tar          - Structure containing target (observed) dispersion information.
%                   Fields used: lambda (dominant wavelengths).
%   Layer_param  - Structure containing layer parameterization details and inversion constraints.
%                   Fields used: DCR_range, and others depending on parameterization scheme.
%
% OUTPUT:
%   initial_param - Structure containing initial model parameters (e.g., h_i, Vs_i, nu_i, rho_i).
%   lbinfo        - Lower bounds for all model parameters (vector or structure format).
%   ubinfo        - Upper bounds for all model parameters (vector or structure format).
%   N_layer       - Number of layers in the model determined for the given trial.
%
% DEPENDENCIES:
%   None (self-contained), but typically called within PSO setup or initialization scripts.
%
% NOTES:
%   - The parameter 'lambda' from Tar is used to estimate the maximum model depth and layer thickness.
%   - A random factor within Layer_param.DCR_range introduces variability in the initial model generation.
%   - This helps maintain model diversity in the PSO population and prevents premature convergence.
%
% -------------------------------------------------------------------------------------------------
% AUTHOR: Mrinal Bhaumik
% SUPERVISOR: Dr. Tarun Naskar
% AFFILIATION: Indian Institute of Technology Madras, India
% DATE: October 2025
% =================================================================================================
function[initial_param, lbinfo, ubinfo, N_layer] = PSO_GetInitialModel(ii, Tar, Layer_param)

lambda = Tar.lambda;

min_val         = min(Layer_param.DCR_range);
max_val         = max(Layer_param.DCR_range);
random_number   = min_val + (max_val - min_val) * rand;
d_max_limit     = max(lambda) / random_number;
PSO_Supporting();
%% Upper and Lower limit

lbinfo.all = [];
ubinfo.all = [];

%  layer thickness limits __________________________

if strcmpi(Layer_param.h, 'variable')

    if strcmpi(Layer_param.h_range, 'LR_based')

        LR = Layer_param.h_count(ii);
        d_min       = zeros(1,1);
        d_max       = zeros(1,1);
        d_max_cal   = 0;
        i           = 1;
        while d_max_cal < d_max_limit

            % D_min
            if i==1
                d_min(i) = min(lambda) / 3;
            else
                d_min(i) = d_max(i-1);
            end

            % D_max
            if i==1
                d_max(i)    = min(lambda)/2;
            elseif i==2
                d_max(i)    = d_min(i) + LR * min(lambda)/2;
            else
                d_max_cal   = d_min(i) + LR * (d_max(i-1) - d_min(i-1));
                % d_max(i) = min(d_max_cal, d_max_limit);
                if d_max_cal > d_max_limit
                    d_max(i-1)    = d_max_limit;
                    d_min(i) = [];
                else
                    d_max(i)    = d_max_cal;
                end
            end

            i = i + 1;
        end

        lb_h1 = [d_min(1) diff(d_min)];
        ub_h1 = [d_max(1) diff(d_max)];

        lb_h = min(lb_h1, ub_h1);
        ub_h = max(lb_h1, ub_h1);

        N_layer = length(lb_h);

        lbinfo.h   = lb_h;
        ubinfo.h   = ub_h;
        lbinfo.all = [lbinfo.all lb_h];
        ubinfo.all = [ubinfo.all ub_h];

    elseif strcmpi(Layer_param.h_range, 'LN_based')

        N_layer    = Layer_param.h_count(ii);
        lb_h       = repelem(min(lambda)/2, N_layer);
        ub_h       = repelem(min(d_max_limit ./ N_layer, 10), N_layer); % Change it later

        lbinfo.h   = lb_h;
        ubinfo.h   = ub_h;
        lbinfo.all = [lbinfo.all lb_h];
        ubinfo.all = [ubinfo.all ub_h];

    else
        error('Correctly choose the h_range option, either LR_based or LN_based')
    end

elseif strcmpi(Layer_param.h, 'fixed')
    N_layer = Layer_param.h_count;
else
    error('Correctly choose the h parameter, either variable or fixed')
end


%  layer Vs limits __________________________
v_f        = Tar.v_f;
lb_vs      = min(v_f) * 0.5;
ub_vs      = max(v_f) * 2.5;
lb_vs      = lb_vs.* ones(1, N_layer+1);
ub_vs      = ub_vs.* ones(1, N_layer+1);
if numel(Layer_param.Vs_range)==2 % if the Vs range is provided
    lb_vs(:) = min(Layer_param.Vs_range);
    ub_vs(:) = max(Layer_param.Vs_range);
end

lbinfo.vs  = lb_vs;
ubinfo.vs  = ub_vs;
lbinfo.all = [lbinfo.all lb_vs];
ubinfo.all = [ubinfo.all ub_vs];

% Poisson's ratio limit _____________________________________
if strcmpi(Layer_param.nu, 'variable')
    lb_nu = min(Layer_param.nu_range) .* ones(1, N_layer+1);
    ub_nu = max(Layer_param.nu_range) .* ones(1, N_layer+1);

    lbinfo.nu  = lb_nu;
    ubinfo.nu  = ub_nu;
    lbinfo.all = [lbinfo.all lb_nu];
    ubinfo.all = [ubinfo.all ub_nu];
end

% Density limits _____________________________________
if strcmpi(Layer_param.ro, 'variable')
    lb_rho = min(Layer_param.ro_range) .* ones(1, N_layer+1);
    ub_rho = max(Layer_param.ro_range) .* ones(1, N_layer+1);

    lbinfo.nu  = lb_rho;
    ubinfo.nu  = ub_rho;
    lbinfo.all = [lbinfo.all lb_rho];
    ubinfo.all = [ubinfo.all ub_rho];
end

%% Initial model
initial_param.all = [];
% Initial layer thickness __________________________

if strcmpi(Layer_param.h, 'fixed')

    if strcmpi(Layer_param.fixed, 'increasing')
        N_layer = Layer_param.h_count(ii);
        % Based on depth conversion ratio (DCR)
        LR           = unifrnd(1.25, 2, 1, 1);
        DCR          = (LR ^ (N_layer + 1) - LR) / ((LR-1) * LR);
        h1           = (1 / DCR) * d_max_limit;
        h_i          = [1, LR * ones(1, N_layer-1)];
        h_i          = h1.* cumprod(h_i);
    elseif strcmpi(Layer_param.fixed, 'equal')
        N_layer = Layer_param.h_count(ii);
        h_i = repelem(d_max_limit/N_layer, N_layer);
    else
        error('Correctly choose the type of layer for fixed h, either increasing or equal')
    end

elseif strcmpi(Layer_param.h, 'variable')

    % if strcmpi(Layer_param.h_range, 'LR_based')

        % Based on depth conversion ratio (DCR)
        LR           = unifrnd(2, 3, 1, 1);
        DCR          = (LR ^ (N_layer + 1) - LR) / ((LR-1) * LR);
        h1           = (1 / DCR) * d_max_limit;
        h_i          = [1, LR * ones(1, N_layer-1)];
        h_i          = h1.* cumprod(h_i);
        initial_param.all = [initial_param.all h_i];
    % elseif strcmpi(Layer_param.h_range, 'LN_based')

        % h_i = repelem(d_max_limit/N_layer, N_layer);
        % initial_param.all = [initial_param.all h_i];
    % else
    %     error('Correctly choose the h_range option, either LR_based or LN_based')
    % end

else
    error('Correctly choose the h type, either fixed or variable')
end

d_i = cumsum(h_i);
PSO_Supporting;
% Initial Vs_____________________________________

    function v = make_unique(v)
        [s, j] = sort(v(:));
        s = s + 0.1 * (0:length(s)-1)';
        v(j) = s;
    end

lambda = make_unique(lambda);
vs_i         = interp1(lambda, v_f, d_i*2.5, 'linear', 'extrap'); % adjust the value to get a closer initial model
vs_i_HS      = 1.5 * max(vs_i) ;
vs_i         = [vs_i vs_i_HS];
initial_param.all = [initial_param.all vs_i];

% Initial Poisson's ratio _____________________________________
if strcmpi(Layer_param.nu, 'fixed')
    nu_i = repelem(Layer_param.nu_range(1), N_layer+1);
elseif strcmpi(Layer_param.nu, 'variable')
    if length(Layer_param.nu_range)<2
        error('Correctly select the nu range')
    end
    nu_i  = unifrnd(Layer_param.nu_range(1), Layer_param.nu_range(2), 1, N_layer+1);
    initial_param.all = [initial_param.all nu_i];
else
    error('Correctly select the nu type, either fixed or variable')
end

% Initial density _____________________________________
if strcmpi(Layer_param.ro, 'fixed')
    rho_i = repelem(Layer_param.ro_range, N_layer+1);
elseif strcmpi(Layer_param.ro, 'variable')
    if length(Layer_param.ro_range)<2
        error('Correctly select the density range')
    end
    rho_i  = unifrnd(Layer_param.ro_range(1), Layer_param.ro_range(2), 1, N_layer+1);
    initial_param.all = [initial_param.all rho_i];
else
    error('Correctly select the density type, either fixed or variable')
end

initial_param.h_i   = h_i;
initial_param.Vs_i  = vs_i;
initial_param.nu_i  = nu_i;
initial_param.rho_i = rho_i;

%% Plot limits

figure(999);
subplot(1,5,4:5); hold on;
plot([lb_vs(1) lb_vs(1)], [0 d_max_limit],'--','LineWidth', 1)
hold on; plot([ub_vs(1) ub_vs(1)], [0 d_max_limit],'--','LineWidth', 1)
axis ij; ylabel('Depth (m)') ; xlabel('Shear wave velocity (m/s)')


end