classdef SoccerTester < handle
    %SOCCERTESTER tester class, test the two players in one game
    
    properties
        game = [];
        StepCntTotal ;
        state_see_set;
        state_see_num;
        Pi_see;
        action_see;
    end
    
    methods
        
        function obj = SoccerTester(game,StepCntTotal)
            obj.game = game;       
            obj.StepCntTotal = StepCntTotal;
            obj.state_see_set = [4,5,12,13,23,24,25,26,44,46,50,52,57,63];
            obj.state_see_num = length(obj.state_see_set);
            obj.Pi_see = cell(obj.state_see_num,1);
            for i = 1:obj.state_see_num
                obj.Pi_see{i}=zeros(5,StepCntTotal);
            end
        end
        
        function record(obj,Player,step)
            for i = 1:obj.state_see_num
                obj.Pi_see{i}(:,step)= transpose(Player.Pi(obj.state_see_set(i),:));
            end   
        end
        
        function plotPolicy(obj)
            for i = 1:obj.state_see_num
                figure;
                for k=1:5
                    subplot(5,1,k);
                    pi_see = obj.Pi_see{i}(k,:);
                    plot(pi_see);
                    title(['state:',num2str(obj.state_see_set(i)),' action:',num2str(k)]);
                end
                
            end
        end
        
        
        function Reward = resultToReward( obj, result)   % from playround result to reward
            if result >= 0
                Reward = 2*result-1;
            else
                Reward = 0;
            end    
        end
        
        function displayResult(obj,result)
            switch result
                case -2
                    fprintf('该episode平局\n');
                case -1
                    fprintf('该episode尚未结束\n');
                case 0
                    fprintf('该episode B获胜\n');
                case 1
                    fprintf('该episode A获胜\n');
            end
        end
        
        function state=boardToState( obj )
            xA = obj.game.positions{1}(1);
            yA = obj.game.positions{1}(2);
            xB = obj.game.positions{2}(1);
            yB = obj.game.positions{2}(2);
            sA = yA * obj.game.w + xA;
            sB = yB * obj.game.w + xB;
            if sB > sA
                sB = sB-1;
            end
            state = (sA * (obj.game.w * obj.game.h-1) + sB)+( obj.game.w * obj.game.h)*...
                (obj.game.w * obj.game.h -1)*obj.game.ballowner+1;
        end
        
        function [positionA,positionB,ballowner] = stateToBoard( obj,state )
           state = state - 1;
            ballowner = floor(state/((obj.game.w*obj.game.h)*(obj.game.w*obj.game.h-1)));
           stateP = state-ballowner*((obj.game.w*obj.game.h)*(obj.game.w*obj.game.h-1));
           sA = floor(stateP/(obj.game.w*obj.game.h-1));
           sB = stateP-sA*(obj.game.w*obj.game.h-1);
           if sB>=sA
               sB = sB+1;
           end
           yA = floor(sA/obj.game.w);
           xA = sA - yA*obj.game.w;
           yB = floor(sB/obj.game.w);
           xB = sB - yB*obj.game.w;
           positionA = [xA,yA];
           positionB = [xB,yB];          
        end
        
        function wins = train(obj,playerA,playerB)
            wins = [];
            step = 0;
            i = 0;
            obj.game.restart();
%             obj.game.draw();
            while  step <=obj.StepCntTotal
                if mod(step,obj.StepCntTotal/10000)==0
                    disp('------------------------------------');
                    fprintf('%4f%%\n',step*100/obj.StepCntTotal);
                    fprintf('第%d次 episode已完成，累积%d次step\n',i,step)
                    disp(['当前时间',datestr(now)]);                   
                end                
                state = obj.boardToState();
                actionA = playerA.chooseAction(state);
                actionB = playerB.chooseAction(state);
                result = obj.game.playRound(actionA,actionB);
%                 if step<=2000
%                  fprintf('actionA:%d  actionB:%d\n',actionA,actionB);   
%                 obj.game.draw();
%                 end
                reward = obj.resultToReward(result);
                newstate = obj.boardToState();
                playerA.UpdatePolicy(state,newstate,[actionA,actionB],reward);
                playerB.UpdatePolicy(state,newstate,[actionB,actionA],-reward);
                step = step+1;
                obj.record(playerA,step);
                if obj.game.EndEpisode
                    i = i+1;              
                    wins = [wins,result];
                    obj.game.restart();
%                     obj.game.draw();
                end
                if(mod(step,obj.StepCntTotal/100)==0)
                    SavedName = ['./SavedPlayers/Aplayer_MR_trained',num2str(step)];
                    eval(['save ',SavedName,' playerA']);
                end
            end
        end
        
        function wins = testPerformance(obj,playerA,playerB,TestEpi)
            wins = zeros(1,TestEpi);
            playerA.learning = 0;
            for i = 1:TestEpi
                if mod(i,(TestEpi/2))==0
                    disp('------------------------------------');
                    fprintf('%4f%%\n',i*100/TestEpi);
                    fprintf('第%d次 episode已完成\n',i)
                    disp(['当前时间',datestr(now)]);    
                end
                obj.game.restart();
                result = -1;
                while result == -1
                    state = obj.boardToState();
                    actionA = playerA.chooseAction(state);
                    actionB = playerB.chooseAction(state);
                    result = obj.game.playRound(actionA,actionB); 
                end
                wins(i)=result;
            end           
        end
            
        
        function [winRate] = plotwinResult(obj , wins)  % draw the win result
            len = length(wins);
            winResultCum = zeros(3,len);
            for i = 1:len
                winResultCum(1,i) = sum(wins(1:i)==1);  %  A wins
                winResultCum(2,i) = sum(wins(1:i)==0);  % B wins
                winResultCum(3,i) = sum(wins(1:i)==-2);  %draw
            end
           winRate =  winResultCum(1,len)/len;
%            figure;
%            plot(winResultCum(1,:),'r');
%            hold on;
%            plot(winResultCum(2,:),'b');
%            legend('Awin','Bwin');
           fprintf('Result:In %d episodes\n',len);
           fprintf('Awin:%d (%5f%%)\n',winResultCum(1,len),100*winResultCum(1,len)/len);
           fprintf('Bwin:%d (%5f%%)\n',winResultCum(2,len),100*winResultCum(2,len)/len);
           fprintf('draw:%d (%5f%%)\n',winResultCum(3,len),100*winResultCum(3,len)/len);
        end
    end
    
end


