
close all; 
clc; 
clear all; 

nB = 100;  
nA = 5; 
nP = 100; 
sigma = 1.0; 

realA=-2:2;

randn('seed',0); 
for qi=1:nB
    for qj=1:nA
        mu(qi,qj)=realA(qj);
    end
end
 qStarMeans = mvnrnd( mu, eye(nA) ); 

% qStarMeans(:,i)=mvnrnd( reala(i), eye(nA) );    
% generate the TRUE reward Q^{\star}: 
%  qStarMeans = mvnrnd( zeros(nB,nA), eye(nA) ); 
%  qadd = mvnrnd( zeros(nB,nA), eye(nA) );
% rr=randn(nB,nA);
% for qi=1:nB
%     for qj=1:nA
%         pqStarMeans(qi,qj)=realA(qj);
%     end
% end
% qStarMeans = mvnrnd( pqStarMeans, eye(nA) );
epsArray = [ 0, 0.01, 0.1 ]; 

% assume we have at least ONE draw from each "arm" (initialize with use the qStarMeans matrix):
qT0 = mvnrnd( qStarMeans, eye(nA) );

avgReward    = zeros(length(epsArray),nP); 
perOptAction = zeros(length(epsArray),nP); 
cumReward    = zeros(length(epsArray),nP); 
cumProb      = zeros(length(epsArray),nP); 
for ei=1:length(epsArray), 
  tEps = epsArray(ei); 

  %qT = qT0;  % <- initialize to one draw per arm 
  qT = zeros(size(qT0));  % <- initialize to zero draws per arm (no knowledge)
  qN = ones( nB, nA ); % keep track of the number draws on this arm 
  qS = qT;             % keep track of the SUM of the rewards (qT = qS./qN) 

  allRewards      = zeros(nB,nP); 
  pickedMaxAction = zeros(nB,nP); 
  for bi=1:nB, % pick a bandit
    for pi=1:nP, % make a play
      % determine if this move is exploritory or greedy: 
      if( rand(1) <= tEps ) % pick a RANDOM arm: 
        [dum,arm] = histc(rand(1),linspace(0,1+eps,nA+1)); clear dum; 
      else                  % pick the GREEDY arm:
        [dum,arm] = max( qT(bi,:) ); clear dum; 
      end
      % determine if the arm selected is the best possible: 
      [dum,bestArm] = max( qStarMeans(bi,:) ); 
      if( arm==bestArm ) pickedMaxAction(bi,pi) = 1; end
      % get the reward from drawing on that arm: 
      reward = qStarMeans(bi,arm) + sigma*randn(1); 
      allRewards(bi,pi) = reward; 
      % update qN,qS,qT: 
      if pi>1
      qT(bi,arm) = qT(bi,oldarm)+0.1*(reward-qT(bi,oldarm));
      else
      qT(bi,arm) = 0.1*(reward);    
      end
      oldarm=arm;
    end
  end

  avgRew          = mean(allRewards,1);
  avgReward(ei,:) = avgRew(:).'; 
  percentOptAction   = mean(pickedMaxAction,1);
  perOptAction(ei,:) = percentOptAction(:).';
  csAR            = cumsum(allRewards,2); % do a cummulative sum across plays for each bandit
  csRew           = mean(csAR,1);
  cumReward(ei,:) = csRew(:).';
  csPA          = cumsum(pickedMaxAction,2)./cumsum(ones(size(pickedMaxAction)),2);
  csProb        = mean(csPA,1);
  cumProb(ei,:) = csProb(:).';
end

fig=figure(1);
set(fig,'Position',[300 600 800 500]);
ha = tight_subplot(2,2,[.07 .07],[.1 .07],[.07 .07]);

axes(ha(1))
clrStr = 'brk'; all_hnds = []; 
for ei=1:length(epsArray),
  %all_hnds(ei) = plot( [ 0, avgReward(ei,:) ], [clrStr(ei)] ); 
  all_hnds(ei) = plot( 1:nP, avgReward(ei,:), [clrStr(ei),'-'] ); 
  hold on;
end 
grid on; 
 ylabel( 'Average Reward' ); 
 ylim([0 2.5])

axes(ha(2))
clrStr = 'brk'; all_hnds = []; 
for ei=1:length(epsArray),
  %all_hnds(ei) = plot( [ 0, avgReward(ei,:) ], [clrStr(ei)] ); 
  all_hnds(ei) = plot( 1:nP, perOptAction(ei,:), [clrStr(ei),'-'] ); 
  hold on;
end 
grid on; 
 ylabel( '% Optimal Action' );


axes(ha(3))
clrStr = 'brk'; all_hnds = []; 
for ei=1:length(epsArray),
  all_hnds(ei) = plot( 1:nP, cumReward(ei,:), [clrStr(ei),'-'] ); 
  hold on;
end 
legend( all_hnds, { '0.1', '1', '10' }, 'Location', 'Northwest' ); 
grid on; 
xlabel( 'plays' ); ylabel( 'Cummulative Average Reward' ); 
ylim([0 500])

axes(ha(4))
clrStr = 'brk'; all_hnds = []; 
for ei=1:length(epsArray),
  all_hnds(ei) = plot( 1:nP, cumProb(ei,:), [clrStr(ei),'-'] ); 
  hold on;
end 
grid on; 
xlabel( 'plays' ); ylabel( 'Cummulative % Optimal Action' );

set(gcf, 'PaperPositionMode','auto');
set(gcf,'render','painter')
set(gcf,'color','w');
p1=['./no3_1.png'] ;  
frame = getframe(1);
im = frame2im(frame);
[imind,cm] = rgb2ind(im,256);
imwrite(imind,cm,p1,'png');
