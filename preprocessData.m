% =================================================================================================
% FUNCTION: preprocessData
% -------------------------------------------------------------------------------------------------
% DESCRIPTION:
%   This function preprocesses the observed dispersion or slowness data. It converts slowness 
%   measurements to velocity if necessary, handles the standard deviation column, and optionally 
%   resamples or filters the data. It is intended for preparing input data for PSO-based inversion.
%
% INPUTS:
%   Data             - Nx2 or Nx3 matrix containing:
%                        [frequency, velocity_or_slowness, (optional) std]
%   Include_min_COV  - Boolean flag to determine whether to include data points with minimum coefficient of variation.
%   Resample         - Boolean flag indicating whether to resample the data.
%   Number           - If resampling, the number of points to interpolate to.
%
% OUTPUTS:
%   Data - Nx3 matrix containing:
%            [frequency, velocity, std]
%          - Slowness values (if present) are converted to velocity.
%          - Standard deviation column is preserved or adjusted.
%
% NOTES:
%   - Slowness values are assumed to be <1 (in s/m units). Conversion is applied automatically.
%   - The function supports optional filtering, resampling, and inclusion/exclusion based on COV.
%   - Typically called before inversion to prepare target or measured data.
%
% DEPENDENCIES:
%   None (self-contained preprocessing routine)
%
% -------------------------------------------------------------------------------------------------
% AUTHOR: Mrinal Bhaumik
% SUPERVISOR: Dr. Tarun Naskar
% AFFILIATION: Indian Institute of Technology Madras, India
% DATE: October 2025
% =================================================================================================%% Functions

function Data = preprocessData(Data, Include_min_COV, Resample, Number)

    isSlowness = any(Data(:, 2) < 1);
    if isSlowness
        % Convert slowness to velocity
        Data(:, 2) = 1 ./ Data(:, 2);
    end

    [~, numCols] = size(Data);
    if numCols >= 3
        % If std exists, convert it if originally slowness
        if isSlowness
            v_f = Data(:, 2);  % Use original slowness values
            COV = Data(:,3);
            if COV > 1
                slowness    = 1./v_f;
                COV_true    = COV-sqrt(COV.^2-2*COV+2);
                Slow_std    = slowness .* COV_true;
                std     = Slow_std .* v_f.^2;
            else
                std         = COV.*v_f.^2;
            end
            Data(:, 3) = std ;
        end
    elseif ~isempty(Include_min_COV)
        
        covDefault = Include_min_COV;
        stdCol = Data(:, 2) * covDefault;
        Data = [Data, stdCol];
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RESAMPLELOGSCALE Resamples the data in log-frequency scale
PSO_Supporting;
if ~strcmpi(Resample, 'yes')
    return;  % No resampling needed
end
if isempty(Number)
    disp('Resample "Number" is missing, considering default 40 samples')
    Number = 40;
end

freq     = Data(:, 1);  % original frequency
velocity = Data(:, 2);
stdDev   = Data(:, 3);

% Ensure data is sorted
[freq, sortIdx] = sort(freq);
velocity = velocity(sortIdx);
stdDev   = stdDev(sortIdx);

% Check for positive frequencies
if any(freq <= 0)
    error('Frequencies must be positive for log-scale resampling.');
end


% Generate log-spaced frequency vector
logFreq = logspace(log10(min(freq)), log10(max(freq)), Number)';

% Interpolate using shape-preserving piecewise cubic interpolation
velocityInterp = interp1(freq, velocity, logFreq, 'pchip');
stdInterp      = interp1(freq, stdDev,   logFreq, 'pchip');

% Return resampled data
Data = [logFreq, velocityInterp, stdInterp];

end
