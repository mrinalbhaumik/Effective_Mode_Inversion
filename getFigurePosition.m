% =================================================================================================
% FUNCTION: getFigurePosition
% -------------------------------------------------------------------------------------------------
% DESCRIPTION:
%   Computes a figure position vector for MATLAB figures based on the screen size. 
%   This allows consistent figure sizing and positioning across different screen resolutions 
%   and ensures that figures are placed at a predictable relative location on the screen.
%
% USAGE:
%   figPos = getFigurePosition(widthScale, heightScale, leftDiv, bottomDiv)
%   set(gcf, 'Position', figPos)
%
% INPUTS:
%   widthScale  - Fraction of screen width (0 < widthScale <= 1), e.g., 0.55 for 55% of screen width
%   heightScale - Fraction of screen height (0 < heightScale <= 1), e.g., 0.4 for 40% of screen height
%   leftDiv     - Divisor for remaining horizontal space (e.g., 5 → 1/5 from left margin)
%   bottomDiv   - Divisor for remaining vertical space (e.g., 3 → 1/3 from bottom margin)
%
% OUTPUT:
%   figPos - 1x4 vector [left bottom width height] suitable for MATLAB figure 'Position' property
%
% NOTES:
%   - Ensures figures are proportionally scaled and consistently placed.
%   - Helpful when creating multiple subplots or GUIs to maintain visual layout consistency.
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

function figPos = getFigurePosition(widthScale, heightScale, leftDiv, bottomDiv)


    if nargin < 4
        error('Usage: getFigurePosition(widthScale, heightScale, leftDiv, bottomDiv)');
    end

    screen_size = get(0, 'ScreenSize');
    fig_width   = screen_size(3) * widthScale;
    fig_height  = screen_size(4) * heightScale;
    fig_left    = (screen_size(3) - fig_width) / leftDiv;
    fig_bottom  = (screen_size(4) - fig_height) / bottomDiv;

    figPos = [fig_left, fig_bottom, fig_width, fig_height];
    PSO_Supporting;
end