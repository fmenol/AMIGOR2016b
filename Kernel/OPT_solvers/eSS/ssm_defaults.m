% $Header: svn://.../trunk/AMIGO2R2016/Kernel/OPT_solvers/eSS/ssm_defaults.m 1091 2013-11-13 15:36:32Z attila $
function [default]=ssm_defaults

%Assings default values for all the options

%User options
default.log_var                   =       [];              %Logarithmic interval division on variable i
default.maxeval                   =       1000;            %Maximum number of function evaluations
default.maxtime                   =       60;              %Maximum CPU time
default.iterprint                 =       1;               %Print each iteration on screen
default.plot                      =       0;               %Plots convergence curves
default.weight                    =       1e6;             %Weight that multiplies the penalty term added to the objective function in constrained problems
default.tolc                      =       1e-5;            %Maximum absolute violation of the constraints
default.prob_bound                =       0.5;             %Probability of biasing the search towards the bounds
default.strategy                  =       0;               %Search Strategy
default.inter_save                =       0;               %Saves results in a report in intermediate iterations



%Global options
default.dim_refset                =       'auto';         %Number of elements in Refset
default.ndiverse                  =       'auto';         %Number of solutions generated by the diversificator
default.initiate                  =       1;              %Type of Refset initialization
default.combination               =       1;              %Type of combination
default.regenerate                =       3;              %Type of Refset regeneration
default.delete                    =       'standard';     %Number of deleted elements when regeneration
default.intens                    =       10;             %Iteration interval between intensification
default.tolf                      =       1e-4;           %Function tolerance for joining the Refset
default.diverse_criteria          =       1;              %Criteria for diversification in the Refset (1=euclidean distance, 2=tolerances)
default.tolx                      =       1e-3;           %Variable tolerance for joining the Refset
default.n_stuck                   =       0;             %Number of consecutive iterations without significant improvement before the search stops.



%Local options
default.local.solver              =       'fmincon';      %Choose local solver
default.local.tol                 =       2;              %Level of tolerance in local search
default.local.iterprint           =       0;              %Print each iteration on screen
default.local.n1                  =       'default';      %Number of iterations before applying local search for the 1st time
default.local.n2                  =       'default';      %Number of minimum iterations of global search between 2 local calls
default.local.balance            =        0.5;            %BalancesBalances between quality (=0) and diversity (=1) for choosing initial points for the local search
default.local.finish              =       [];             %Applies local search to the best solution found once the optimization if finished
default.local.bestx               =       0;              %When activated (i.e. =1) only applies local search to the best solution found to date, ignoring filters
default.local.merit_filter        =       1;              %Merit filter activation
default.local.distance_filter     =       1;              %Distance filter activation
default.local.thfactor            =       0.2;            %Merit filter relaxation parameter
default.local.maxdistfactor       =       0.2;            %Distance filter relaxation parameter
default.local.wait_maxdist_limit  =       20;             %Apply distance filter relaxation after this number of function evaluations without success in passing filter
default.local.wait_th_limit       =       20;             %Apply merit filter relaxation after this number of function evaluations without success in passing filter

% local solver nl2sol options
default.local.nl2sol.grad                = 'internalFD';             %Gradient computation of the Residuals 'internalFiniteDifference', MKLJac, AMIGO's or userdefined
default.local.nl2sol.maxiter             =      500;
default.local.nl2sol.maxfeval            =      550;
default.local.nl2sol.display             =        1;
default.local.nl2sol.tolrfun             =     1e-6;
default.local.nl2sol.tolafun             =     1e-6;
default.local.nl2sol.iterfun             =       [];     
default.local.nl2sol.objrtol			 =     1e-5;
% local solver lbfgsb options
default.local.lbfgsb.grad                = 'mklJac';             %Gradient computation of the Residuals 'internalFiniteDifference', MKLJac, AMIGO's or userdefined
default.local.lbfgsb.maxiter             =     300;
default.local.lbfgsb.display             =        1;
default.local.lbfgsb.tolrfun             =     1e-6;
default.local.lbfgsb.iterfun             =       [];     
