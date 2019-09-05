tic;
clear all
close all
format compact 
format long
%% 1.���ݼ���
fprintf(1,'�������� \n');
load('drivFace600');%����1-173Ϊ1�࣬174-343Ϊ2�� 344-510Ϊ3�� 511-600Ϊ4�࣬��ѡ��20%��Ϊ���Լ�
%��һ��173��
[i1 i2]=sort(rand(173,1)); 
train(1:139,:)=input(i2(1:139),:);     train_label(1:139,1)=output(i2(1:139),1);
test(1:34,:)=input(i2(140:173),:);     test_label(1:34,1)=output(i2(140:173),1);
%�ڶ�����170��
[i1 i2]=sort(rand(170,1));
train(140:275,:)=input(173+i2(1:136),:);    train_label(140:275,1)=output(173+i2(1:136),1);
test(35:68,:)=input(173+i2(137:170),:);     test_label(35:68,1)=output(173+i2(137:170),1);
%��������167
[i1 i2]=sort(rand(167,1));
train(276:408,:)=input(343+i2(1:133),:);    train_label(276:408,1)=output(343+i2(1:133),1);
test(69:102,:)=input(343+i2(134:167),:);     test_label(69:102,1)=output(343+i2(134:167),1);
%��4����90
[i1 i2]=sort(rand(90,1));
train(409:480,:)=input(510+i2(1:72),:);    train_label(409:480,1)=output(510+i2(1:72),1);
test(103:120,:)=input(510+i2(73:90),:);     test_label(103:120,1)=output(510+i2(73:90),1); 
clear i1 i2 input output
%%����˳��
k=rand(480,1);[m n]=sort(k);
train=train(n(1:480),:);train_label=train_label(n(1:480),:);
k=rand(120,1);[m n]=sort(k);
test=test(n(1:120),:);test_label=test_label(n(1:120),:);
clear k m n

%no_dims = round(intrinsic_dim(train, 'MLE')); %round��������
%disp(['MLE estimate of intrinsic dimensionality: ' num2str(no_dims)]);
numcases=48;%ÿ�����ݼ�����������
numdims=size(train,2);%���������Ĵ�С
numbatches=10;  %%ԭ����ÿ�����������Ҫ���ڷֿ���

% ѵ������
x=train;%������ת����DBN�����ݸ�ʽ
for i=1:numbatches
    train1=x((i-1)*numcases+1:i*numcases,:);
    batchdata(:,:,i)=train1;
end%���ֺõ�10�����ݶ�����batchdata��

% rbm����
maxepoch=20;%ѵ��rbm�Ĵ���
numhid=500; numpen=200; numpen2=100;%dbn������Ľڵ���
disp('����һ��3�����������');
clear i 
%% 2.ѵ��RBM
fprintf(1,'Pretraining Layer 1 with RBM: %d-%d \n',numdims,numhid);%256-200
restart=1;
rbm;%ʹ��cd-kѵ��rbm��ע���rbm�Ŀ��Ӳ㲻�Ƕ�ֵ�ģ����������Ƕ�ֵ��
vishid1=vishid;hidrecbiases=hidbiases;


fprintf(1,'\nPretraining Layer 2 with RBM: %d-%d \n',numhid,numpen);%200-100
batchdata=batchposhidprobs;%����һ��RBM��������������Ϊ�ڶ���RBM ������
numhid=numpen;%��numpen��ֵ����numhid����Ϊ�ڶ���rbm������Ľڵ���
restart=1;
rbm;
hidpen=vishid; penrecbiases=hidbiases; hidgenbiases=visbiases;

fprintf(1,'\nPretraining Layer 3 with RBM: %d-%d \n',numpen,numpen2);%200-100

batchdata=batchposhidprobs;%��Ȼ�����ڶ���RBM�������Ϊ������RBM������
numhid=numpen2;%������������Ľڵ���
restart=1;
rbm;
hidpen2=vishid; penrecbiases2=hidbiases; hidgenbiases2=visbiases;


%%%% PREINITIALIZE WEIGHTS OF THE DISCRIMINATIVE MODEL%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
w1=[vishid1; hidrecbiases]; 
w2=[hidpen; penrecbiases]; 
w3=[hidpen2; penrecbiases2];%%�����õ�����Ĳ���
digitdata = [x ones(size(x,1),1)];
w1probs = 1./(1 + exp(-digitdata*w1));%
  w1probs = [w1probs  ones(size(x,1),1)];%
w2probs = 1./(1 + exp(-w1probs*w2));%
  w2probs = [w2probs ones(size(x,1),1)];%
w3probs = 1./(1 + exp(-w2probs*w3)); %

H_dbn = w3probs;  %%������rbm��ʵ�����ֵ��Ҳ��elm�����������ֵH

%% ������֤
indices = crossvalind('Kfold',size(H_dbn,1),10);%��ѵ�����ݽ���10�۱���
%[Train, Test] = crossvalind('HoldOut', N, P) % ��ԭʼ���������Ϊ����,һ����Ϊѵ����,һ����Ϊ��֤��
%[Train, Test] = crossvalind('LeaveMOut', N, M) %��M��������֤��Ĭ��MΪ1����һ��������֤
sum_accuracy = 0;
for i = 1:10
    %%
    cross_test = (indices == i); %ÿ��ѭѡȡһ��fold��Ϊ���Լ�
    cross_train = ~cross_test;   %ȡcorss_test�Ĳ�����Ϊѵ��������ʣ��9��fold
    %%
    P_train = H_dbn(cross_train,:)';
    P_test= H_dbn(cross_test,:)';
    T_train= train_label(cross_train,:)';
    T_test=train_label(cross_test,:)';
% ѵ��ELM
lamda=0.001;  %% ����ϵ����0.0007-0.00037֮��ʱ��һ��һ���Գ�����
H1=P_train+1/lamda;% ����regularization factor

T =T_train;            %ѵ������ǩ
T1=ind2vec(T);              %��������Ҫ�Ƚ�Tת������������
OutputWeight=pinv(H1') *T1'; 
Y=(H1' * OutputWeight)';

temp_Y=zeros(1,size(Y,2));
for n=1:size(Y,2)
    [max_Y,index]=max(Y(:,n));
    temp_Y(n)=index;
end
Y_train=temp_Y;
%Y_train=vec2ind(temp_Y1);
train_accuracy=sum(Y_train==T)/length(T);

H2=P_test+1/lamda;
T_cross=(H2' * OutputWeight)';                       %   TY: the actual output of the testing data
temp_Y=zeros(1,size(T_cross,2));
for n=1:size(T_cross,2)
    [max_Y,index]=max(T_cross(:,n));
    temp_Y(n)=index;
end
TY1=temp_Y;
% �������
TV=T_test;
sum_accuracy=sum_accuracy+sum(TV==TY1) / length(TV);
end
per_accuracy_crossvalindation=sum_accuracy/10;
%========================================================
%===================������֤����==========================