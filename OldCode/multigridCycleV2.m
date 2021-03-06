function [p_approx, sW_approx,nit] ...
    = multigridCycleV2(v1,v2,model,p_ad_0,sW_ad_0,tol,maxits,g,dt);
  %% Function description
  %
  % PARAMETERS:
  % model    - System model structure with grid, rock, phases and operator
  %            substructs
  %
  % v1_iter  - Number of presmoothing sweeps
  % v2_iter  - Number of postsmoothing sweeps
  % p_ad     - ADI struct for the pressure
  % s_ad     - ADI struct for the saturation
  % tol      - error tolerance for newton at the most coarse grid
  % maxits   - The maximum number of newton iterations perfomed on the most
  %            coarsed grid
  % g        - gravity constant 
  % dt       - current time step
  %
  % RETURNS:
  % p_ad     - Approximated values of the pressure stored in ADI structure
  % s_ad     - Approximated values of the saturation stored in ADI structure
  % nit      - Number of newton iterations performed at the most coarse grid
  % COMMENTS:
  %   This is currently a linear two-grid cycle
  %
  % SEE ALSO:
  %

  %% Presmoothing
  [p_ad,sW_ad] = newtonTwoPhaseADV2(model,p_ad_0,sW_ad_0,tol,v1,g,dt);
%  p_ad = p_ad_0;
%  sW_ad = sW_ad_0;

  %% Set up of coarse grid
  [coarse_model,coarse_p_ad, coarse_sW_ad, coarse_p_ad_0, coarse_sW_ad_0] ...
    = coarseningV2(model, p_ad, sW_ad,p_ad_0,sW_ad_0);
    
  %% Multigrid core
  [correction_p,correction_sW] ...
      = newtonTwoPhaseADV2(coarse_model,coarse_p_ad,coarse_sW_ad,tol,maxits,g,dt,coarse_p_ad_0, coarse_sW_ad_0);

  %% Interpolating soluton from coarsed grid and compute ccorrected approximation

  [fine_correction_p, fine_correction_sW] = interpolate(coarse_model.G,  ...
        correction_p - coarse_p_ad.val, correction_sW - coarse_sW_ad.val);

  p_ad.val =  p_ad.val + fine_correction_p;
  sW_ad.val = sW_ad.val + fine_correction_sW;

 
%  p_approx = p_ad;
%  sW_approx = sW_ad;
  % Postsmoothing
  [p_approx,sW_approx,nit] = newtonTwoPhaseADV2(model,p_ad,sW_ad,tol,v2,g,dt);
 
%   figure
%     subplot(4, 2, 1); plot(model.G.cells.indexMap,p_ad.val);
%     title('Corrected Pressure')
%     subplot(4, 2, 3); plot(1:coarse_model.G.cells.num,correction_p);
%     title('Correction coarse Pressure')
%     
%     subplot(4, 2, 2); plot(model.G.cells.indexMap,sW_ad.val);
%     title('Saturation')
%     subplot(4, 2, 4); plot(1:coarse_model.G.cells.num,correction_sW);
%     title('Correction coarse Saturation')
%     drawnow   
 
end