% test the class SoccerTester
clear all;
close all;
clc;
addpath('Player/');
addpath('Domain/');
s = RandStream('mt19937ar','seed',1);
RandStream.setGlobalStream(s);
% kk= randsrc(1,1,[1:5]);

boardH = 4;
boardW = 5;
numStates = ( boardH * boardW )*( boardH * boardW -1)*2;
numActions = 5;
drawProbability = 0;
StepCntTotal = 1000000;
decay = 10^(-2/StepCntTotal);
expl = 0.2;
TestEpi = 10000;

% choose the player type
%minimaxQPlayer(numStates,numActionsA,numActionsB,decay,expl,gamma)
load ./SavedPlayers/Aplayer_MR_trained1E7;
playerB = RandomPlayer(numActions);
game = soccer('h',boardH,'w',boardW,'drawProbability',drawProbability);
tester = SoccerTester(game,StepCntTotal);
wins = tester.testPerformance(playerA,playerB,TestEpi);
tester.plotwinResult(wins);
