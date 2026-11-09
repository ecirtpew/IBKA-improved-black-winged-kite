%  %  Main paper:                                                                                        
%  E. Tanyildizi, G. Demir, "Golden Sine Algorithm: A Novel Math-Inspired Algorithm," Advances in Electrical and Computer Engineering, vol.17, no.2, pp.71-78, 2017, doi:10.4316/AECE.2017.02010
%__________________________________________
% func_obj = @CostFunction
% dim = number of your variables
% Max_iteration = maximum number of iterations
% Population = number of search agents
% Lb=Lower bound
% Ub=Upper bound


% To run GoldSA: [Best_value,Best_pos]=GoldSA(Population,Max_iteration,Lb,Ub,dim,func_obj)
%______________________________________________________________________________________________
function [GoldSA_value,GoldSA_position,Convergence_curve]=GoldSA(N,Max_iteration,Lb,Ub,dim,func_obj)

% display('GoldSA is optimizing your problem');

%Initialize the set of random solutions
X=initialization(N,dim,Ub,Lb);

GoldSA_position=zeros(1,dim);
GoldSA_value=inf;
Convergence_curve=zeros(1,Max_iteration);

Destination_values = zeros(1,size(X,1));

% Calculate the fitness of the first set and find the best one
for i=1:size(X,1)
    Destination_values(1,i)=func_obj(X(i,:));
    if i==1
        GoldSA_position=X(i,:);
        GoldSA_value=Destination_values(1,i);
    elseif Destination_values(1,i)<GoldSA_value
        GoldSA_position=X(i,:);
        GoldSA_value=Destination_values(1,i);
    end
 
end

a=-pi;                           
b=pi;
gold=double((sqrt(5)-1)/2);      % golden proportion coefficient, around 0.618
x1=a+(1-gold)*(b-a);          
x2=a+gold*(b-a);

%Main loop
t=2; 
while t<=Max_iteration
       
    
    % Update the position of solutions with respect to objective
    for i=1:size(X,1) % in i-th solution
        r=rand;
        r1=(2*pi)*r;
        r2=r*pi; 
        for j=1:size(X,2) % in j-th dimension
           
            X(i,j)= X(i,j)*abs(sin(r1)) - r2*sin(r1)*abs(x1*GoldSA_position(j)-x2*X(i,j));
            
        end
    end
    
    for i=1:size(X,1)
        
        % Check if solutions go outside the search spaceand bring them back
        Boundary_Ub=X(i,:)>Ub;
        Boundary_Lb=X(i,:)<Lb;
        X(i,:)=(X(i,:).*(~(Boundary_Ub+Boundary_Lb)))+Ub.*Boundary_Ub+Lb.*Boundary_Lb;
        
        % Calculate the objective values
        Destination_values(1,i)=func_obj(X(i,:));
        
        % Update the destination if there is a better solution
        if Destination_values(1,i)<GoldSA_value
            GoldSA_position=X(i,:);
            GoldSA_value=Destination_values(1,i);
            b=x2;
            x2=x1;
            x1=a+(1-gold)*(b-a);
        else
            a=x1;
            x1=x2;
            x2=a+gold*(b-a);
            
        end
        
        if x1==x2
            a=-pi*rand; 
            b=pi*rand;
            x1=a+(1-gold)*(b-a); 
            x2=a+gold*(b-a);
            
        end
        
    end
    
 
    
    % Display the iteration and best optimum obtained so far
%     if mod(t,50)==0
%         display(['At iteration ', num2str(t), ' the optimum is ', num2str(GoldSA_value)]);
%       
%     end
    
    % Increase the iteration counter
    Convergence_curve(t)=GoldSA_value;
    t=t+1;
end