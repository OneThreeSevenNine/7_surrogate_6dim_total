function [pressure_kPa,diagnostic] = surrogate6_solve_root( ...
    model,Nf_rpm,target_pr,warm_pressure_kPa,config)
%SURROGATE6_SOLVE_ROOT Solve for bypass/core static pressure at fixed speed.
target_pr=target_pr(:)';
validateattributes(Nf_rpm,{'double'},{'scalar','real','finite','positive'});
validateattributes(target_pr,{'double'},{'size',[1 2],'real','finite','positive'});
if nargin<4 || isempty(warm_pressure_kPa), warm_pressure_kPa=[]; end
if nargin<5 || isempty(config), config=surrogate6_config(); end

pressure_nodes=unique(model.rbf.X(:,2:3),'rows','stable');
center=(model.rbf.xmin(2:3)+model.rbf.xmax(2:3))/2;
seeds=[center; pressure_nodes];
if ~isempty(warm_pressure_kPa)
    validateattributes(warm_pressure_kPa,{'double'}, ...
        {'size',[1 2],'real','finite','positive'});
    seeds=[warm_pressure_kPa; seeds];
    reference=warm_pressure_kPa;
else
    reference=center;
end
seeds=unique(seeds,'rows','stable');

solutions=zeros(0,2);
solution_iterations=zeros(0,1);
best_q=Inf;
best_p=[NaN NaN];
best_iterations=0;
admissible_seed_count=0;

for iseed=1:size(seeds,1)
    p=seeds(iseed,:);
    [usable,y,J,~]=evaluate_candidate(model,Nf_rpm,p);
    if ~usable, continue; end
    admissible_seed_count=admissible_seed_count+1;

    for iter=0:config.root_max_iterations
        ypr=y(config.pressure_ratio_indices);
        rel=(ypr-target_pr)./target_pr;
        q=max(abs(rel));
        if q<best_q
            best_q=q;
            best_p=p;
            best_iterations=iter;
        end
        if q<=config.root_relative_tolerance
            solutions(end+1,:)=p; %#ok<AGROW>
            solution_iterations(end+1,1)=iter; %#ok<AGROW>
            break
        end
        if iter==config.root_max_iterations, break; end

        Jp=reshape(J(1,config.pressure_ratio_indices,2:3),2,2);
        if any(~isfinite(Jp(:))) || rcond(Jp)<config.min_jacobian_rcond
            break
        end
        dp=-(Jp\(ypr-target_pr).').';
        dp=max(min(dp,config.root_max_step_kPa),-config.root_max_step_kPa);

        accepted=false;
        alpha=1;
        for trial=1:config.root_backtrack_trials
            candidate=p+alpha*dp;
            if all(isfinite(candidate)) && all(candidate>0)
                [candidate_usable,y_candidate,J_candidate,~]= ...
                    evaluate_candidate(model,Nf_rpm,candidate);
                if candidate_usable
                    candidate_pr=y_candidate(config.pressure_ratio_indices);
                    candidate_q=max(abs((candidate_pr-target_pr)./target_pr));
                    if candidate_q<q
                        p=candidate;
                        y=y_candidate;
                        J=J_candidate;
                        accepted=true;
                        break
                    end
                end
            end
            alpha=alpha/2;
        end
        if ~accepted, break; end
    end
end

exact_root_count=size(solutions,1);
used_best_fallback=false;
if isempty(solutions)
    if isfinite(best_q) && best_q<=config.root_fallback_relative_tolerance
        solutions=best_p;
        solution_iterations=best_iterations;
        used_best_fallback=true;
    else
        error('SURROGATE6:RootFailure', ...
            ['No admissible SVM/RBF pressure root converged. Best relative ' ...
             'pressure-ratio residual %.6e exceeds the fallback limit %.6e.'], ...
            best_q,config.root_fallback_relative_tolerance);
    end
end

scale=model.rbf.span(2:3);
distance=sqrt(sum(((solutions-reference)./scale).^2,2));
[~,selected_index]=min(distance);
pressure_kPa=solutions(selected_index,:);
selected_iterations=solution_iterations(selected_index);

[usable,Yfinal,Jfinal,info]=evaluate_candidate(model,Nf_rpm,pressure_kPa);
if ~usable
    error('SURROGATE6:RejectedSolution', ...
        'The selected pressure solution failed the stability or domain gate.');
end

diagnostic.predicted_outputs=Yfinal;
diagnostic.predicted_pr=Yfinal(config.pressure_ratio_indices);
diagnostic.relative_residual=(diagnostic.predicted_pr-target_pr)./target_pr;
diagnostic.max_relative_residual=max(abs(diagnostic.relative_residual));
diagnostic.svm_label=info.stable_label;
diagnostic.svm_score=info.svm_score;
diagnostic.in_training_range=info.in_training_range;
diagnostic.in_training_hull=info.in_training_hull;
diagnostic.rbf_physical_valid=info.physical_valid;
diagnostic.seed_count=size(seeds,1);
diagnostic.admissible_seed_count=admissible_seed_count;
diagnostic.converged_root_count=exact_root_count;
diagnostic.selected_iterations=selected_iterations;
diagnostic.used_best_fallback=used_best_fallback;
diagnostic.fallback_relative_tolerance=config.root_fallback_relative_tolerance;
diagnostic.selected_solution_residual=diagnostic.max_relative_residual;
diagnostic.pressure_jacobian=reshape( ...
    Jfinal(1,config.pressure_ratio_indices,2:3),2,2);
if used_best_fallback
    diagnostic.solution_mode='BEST_STABLE_RESIDUAL_FALLBACK';
else
    diagnostic.solution_mode='EXACT_STABLE_RBF_ROOT';
end
end

function [usable,y,J,info]=evaluate_candidate(model,Nf_rpm,pressure_kPa)
[y,J,info]=surrogate6_predict(model,[Nf_rpm pressure_kPa]);
usable=isscalar(info.stable_label) && info.stable_label==1 && ...
    isscalar(info.physical_valid) && info.physical_valid && ...
    isscalar(info.in_training_range) && info.in_training_range && ...
    isscalar(info.in_training_hull) && info.in_training_hull && ...
    all(isfinite(y(:))) && all(y(:)>0) && all(isfinite(J(:)));
end
