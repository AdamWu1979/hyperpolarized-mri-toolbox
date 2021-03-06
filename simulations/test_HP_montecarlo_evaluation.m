clear all
fitting.NMC = 20;  % use less for quicker testing
flip_scheme = 1;  % see below

% default experiment values

experiment.R1P = 1/25;  experiment.R1L =1/25;  experiment.kPL = 0.02; experiment.std_noise = 0.005;
experiment.Tarrival = 0;  experiment.Tbolus = 8;

for  est_R1L = 0
    for fit_input = 0
        disp('Running Monte Carlo Simulation')
        fit_description = [];
        
        clear params_est params_fixed acq fitting
        
        % default fitting parameters
        R1P_est = 1/25; R1L_est = 1/25; kPL_est = .02;
        params_fixed.R1P = R1P_est;
        params_est.kPL = kPL_est;
        if est_R1L
            fit_description = [fit_description, '  Fitting T1L'];
            params_est.R1L = R1L_est;
            params_est.R1L_lb = 1/35; params_est.R1L_ub = 1/15;
        else
            fit_description = [fit_description, '  Fixed T1L'];
            params_fixed.R1L = R1L_est;
        end
        
 %       params_fixed.L0_start = 0;  % ok to be free parameter?

        % allowing for fit of R1L increases variability substantially
        % R1P minimal change
        % constraining R1L to narrow range maybe reasonable compromise
        
        if fit_input
            fit_description = [fit_description, '  Fitting the input function'];
            fitting.fit_fcn = @fit_pyr_kinetics_and_input;
            Tarrival_est = experiment.Tarrival;    Tbolus_est = experiment.Tbolus;  % ... perfect estimates ... how do they perform with variability?
            Rinj_est = 0.1; % looks reasonable
            params_est.Tarrival = Tarrival_est; params_est.Rinj = Rinj_est; params_est.Tbolus = Tbolus_est;
            params_est.Tarrival_lb = 0; params_est.Tarrival_ub = 12; params_est.Tbolus_lb = 6; params_est.Tbolus_ub = 10;
        else
           fit_description = [fit_description, '  Inputless fitting'];
           fitting.fit_fcn = @fit_pyr_kinetics;
        end
        
        
        switch flip_scheme
            case 1
                % EPI protocol with pyr/lac flips of 10/40 degrees (one pulse per
                % image
                Tacq = 48; acq.TR = 3; acq.N = Tacq/acq.TR;
                R1P = 1/25; R1L = 1/25; KPL = 0.05; std_noise = 0.01;
                acq.flips = repmat([10*pi/180; 40*pi/180], [1 acq.N]);
            case 2
                % 2D dynamic 10/20 flips with 8 phase encodes
                Tacq = 90; acq.TR = 5; acq.N = Tacq/acq.TR;
                Npe = 8; Nall = acq.N * Npe;
                acq.flips(1:2,1:acq.N) = repmat(acos(cos([10*pi/180; 20*pi/180]).^Npe), [1 acq.N]);
            case 3
                % 2D dynamic 10/20 flips with 8 phase encodes
                Tacq = 90; 
                Npe = 8;
                % alternatively, could simulate each TR
                acq.TR = 5/Npe;
                acq.N = Tacq/acq.TR;
                acq.flips = repmat([10*pi/180; 20*pi/180], [1, acq.N]);
        end
        
        
        fitting.params_est = params_est; fitting.params_fixed = params_fixed;
        
        disp(fit_description)
        [results, hdata, hsim ] = HP_montecarlo_evaluation( acq, fitting, experiment );
        hdata.Name = fit_description; hsim.Name =fit_description;
        
    end
end


