% =================================================================================================
% FUNCTION: PSO_fun
% -------------------------------------------------------------------------------------------------
% DESCRIPTION:
%   This function serves as a custom plotting and monitoring callback for the PSO inversion process.
%   It tracks and visualizes the best objective (misfit) value at each iteration, helping assess 
%   the convergence behavior of the swarm. The function can also be extended to trigger early 
%   stopping or additional post-processing steps based on the optimization state.
%
% INPUT:
%   optimValues - Structure containing current PSO optimization information:
%                   .funccount       : Number of function evaluations
%                   .bestx           : Current best solution vector
%                   .bestfval        : Objective function value at bestx
%                   .iteration       : Current iteration number
%                   .meanfval        : Mean objective function value of all swarm particles
%                   .stalliterations : Iterations since last improvement
%                   .swarm           : Positions of all swarm particles
%                   .swarmfvals      : Objective values for all swarm particles
%
%   state        - Current PSO state, indicating when this callback is executed:
%                   'init' : Called at the beginning of optimization
%                   'iter' : Called at each iteration
%                   'done' : Called after the final iteration
%
% OUTPUT:
%   stop - Logical flag (true/false). When set to true, stops the PSO execution.
%
% DEPENDENCIES:
%   - Designed for use within MATLAB’s built-in PARTICLESWARM optimizer.
%
% NOTES:
%   - The function can be modified to plot additional diagnostics such as parameter evolution,
%     swarm diversity, or convergence rate.
%   - Typically, this callback is passed as a handle to the PSO options structure:
%         options.PlotFcn = @PSO_fun;
%
% -------------------------------------------------------------------------------------------------
% AUTHOR: Mrinal Bhaumik
% SUPERVISOR: Dr. Tarun Naskar
% AFFILIATION: Indian Institute of Technology Madras, India
% DATE: October 2025
% =================================================================================================
function stop = PSO_fun(optimValues,state)
%PSWPLOTBESTF Plot best function value.
%
%   STOP = PSWPLOTBESTF(OPTIMVALUES, STATE) plots OPTIMVALUES.BESTFVAL
%   against OPTIMVALUES.ITERATION. This function is called from
%   PARTICLESWARM with the following inputs:
%
%   OPTIMVALUES: Information after the current local solver call.
%          funccount: number of function evaluations
%              bestx: best solution found so far
%           bestfval: function value at bestx
%          iteration: iteration number
%           meanfval: average function value of swarm particles
%    stalliterations: number of iterations since improvement in the 
%                     objective function value stopped
%              swarm: the position of the swarm particles
%         swarmfvals: objective function value of swarm particles
% 
%   STATE: Current state in which plot function is called. 
%          Possible values are:
%             init: initialization state 
%             iter: iteration state 
%             done: final state
%
%   STOP: A boolean to stop the algorithm.
%
%   See also PARTICLESWARM

%   Copyright 2014 The MathWorks, Inc.

% Initialize stop boolean to false.
stop = false;
switch state
    case 'init'
        plotBest = plot(optimValues.iteration,optimValues.bestfval, '.-b');
        set(plotBest,'Tag','psoplotbestf');
        xlabel('Iteration','interp','none');
        ylabel('Function value','interp','none')
        title(sprintf('Best Function Value: %g',optimValues.bestfval),'interp','none');
    case 'iter'
        plotBest = findobj(get(gca,'Children'),'Tag','psoplotbestf');
        newX = [get(plotBest,'Xdata') optimValues.iteration];
        newY = [get(plotBest,'Ydata') optimValues.bestfval];
        set(plotBest,'Xdata',newX, 'Ydata',newY);
        set(get(gca,'Title'),'String',sprintf('Best Function Value: %g',optimValues.bestfval));
    case 'done'
        % No clean up tasks required for this plot function.        
end

PSO_plot_profile (optimValues);
end
