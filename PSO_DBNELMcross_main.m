
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
numbatches=10;%���ݷֿ���
numcases=48;%ÿ�����ݼ�����������������̫С���������ܳ���������
numdims=size(train,2);%����������ά��
% ѵ������
x=train;%������ת����DBN�����ݸ�ʽ
for i=1:numbatches
    train1=x((i-1)*numcases+1:i*numcases,:);
    batchdata(:,:,i)=train1;
end%���ֺõ�10�����ݶ�����batchdata��
%% rbm����
maxepoch=20;%ѵ��rbm�Ĵ���
hid=4; %��������
hmax=500;hmin=100; %��������ڵ���ȡֵ����
tic;
%%
h=PSO_dbnelm_cross(hid,hmax,hmin,batchdata,train,train_label); %PSO�Ż�������ڵ���
%%
t1=toc
tic;
numpen0=h(1,1); numpen1=h(1,2); numpen2=h(1,3);numpen3=h(1,4); %dbn����������Ľڵ���
disp('����һ��num2str(H)�����������');
clear i 
%% ѵ����1��RBM
fprintf(1,'Pretraining Layer 1 with RBM: %d-%d \n',numdims,numpen0);%6400-500
numhid=numpen0;
restart=1;
rbm1;%ʹ��cd-kѵ��rbm��ע���rbm�Ŀ��Ӳ㲻�Ƕ�ֵ�ģ����������Ƕ�ֵ��
vishid1=vishid;hidrecbiases=hidbiases;
%% ѵ����2��RBM
fprintf(1,'\nPretraining Layer 2 with RBM: %d-%d \n',numpen0,numpen1);%500-200
batchdata=batchposhidprobs;%����һ��RBM��������������Ϊ�ڶ���RBM ������
numhid=numpen1;%��numpen��ֵ����numhid����Ϊ�ڶ���rbm������Ľڵ���
restart=1;
rbm1;
hidpen=vishid; penrecbiases=hidbiases; hidgenbiases=visbiases;
%% ѵ����3��RBM
fprintf(1,'\nPretraining Layer 3 with RBM: %d-%d \n',numpen1,numpen2);%200-100
batchdata=batchposhidprobs;%��Ȼ�����ڶ���RBM�������Ϊ������RBM������
numhid=numpen2;%������������Ľڵ���
restart=1;
rbm1;
hidpen2=vishid; penrecbiases2=hidbiases; hidgenbiases2=visbiases;
%% ѵ����4��RBM
fprintf(1,'\nPretraining Layer 4 with RBM: %d-%d \n',numpen2,numpen3);%200-100
batchdata=batchposhidprobs;%��Ȼ�����ڶ���RBM�������Ϊ������RBM������
numhid=numpen3;%������������Ľڵ���
restart=1;
rbm1;
hidpen3=vishid; penrecbiases3=hidbiases; hidgenbiases3=visbiases;

 %% ѵ������ѧϰ��
 % ѵ�����������
w1=[vishid1; hidrecbiases]; 
w2=[hidpen; penrecbiases]; 
w3=[hidpen2; penrecbiases2];
w4=[hidpen3; penrecbiases3];
digitdata = [x ones(size(x,1),1)];%x��ʾtrain���ݼ�
w1probs = 1./(1 + exp(-digitdata*w1));%
  w1probs = [w1probs  ones(size(x,1),1)];%
w2probs = 1./(1 + exp(-w1probs*w2));%
  w2probs = [w2probs ones(size(x,1),1)];%
w3probs = 1./(1 + exp(-w2probs*w3)); %
  w3probs = [w3probs ones(size(x,1),1)];%
w4probs = 1./(1 + exp(-w3probs*w4)); % 
H = w4probs';  %%������rbm��ʵ�����ֵ��Ҳ��elm������ֵH
lamda=0.001;  %% ����ϵ����0.0007-0.00037֮��ʱ  ���Ծ������81.667%
H=H+1/lamda;  %����regularization factor
T =train_label';            %ѵ������ǩ
T1=ind2vec(T);              %��������Ҫ�Ƚ�Tת������������
OutputWeight=pinv(H') *T1'; 
Y=(H' * OutputWeight)';
temp_Y=zeros(1,size(Y,2));
for n=1:size(Y,2)
    [max_Y,index]=max(Y(:,n));
    temp_Y(n)=index;
end
Y_train=temp_Y;
%Y_train=vec2ind(temp_Y1);
% ѵ����׼ȷ��
train_accuracy=sum(Y_train==T)/length(T)
% ѵ����ʵ�ʷ�����Ԥ�����Ա�
figure(1)
plot(Y_train,'bo');hold on 
plot(T,'r*');

%% ���Լ���ѧϰ��
N2 = size(test,1);
% ���Լ��������
w1=[vishid1; hidrecbiases]; %(784+1*500)
w2=[hidpen; penrecbiases]; %(500+1*500)
w3=[hidpen2; penrecbiases2];%(500+1*2000)
w4=[hidpen3; penrecbiases3];
test1 = [test ones(N2,1)];
w1probs = 1./(1 + exp(-test1*w1));
  w1probs = [w1probs  ones(N2,1)];
w2probs = 1./(1 + exp(-w1probs*w2)); 
  w2probs = [w2probs ones(N2,1)];
w3probs = 1./(1 + exp(-w2probs*w3)); 
  w3probs = [w3probs ones(N2,1)];
w4probs = 1./(1 + exp(-w3probs*w4));  
H1=w4probs';
%��������ϵ��
H1=H1+1/lamda;
TY=(H1' * OutputWeight)';     %   TY: the actual output of the testing data
temp_Y=zeros(1,size(TY,2));
for n=1:size(TY,2)
    [max_Y,index]=max(TY(:,n));
    temp_Y(n)=index;
end
TY1=temp_Y;
% �������
TV=test_label';
% ���Լ�����׼ȷ��
test_accuracy = sum(TV==TY1) / length(TV)
% ���Լ�ʵ�ʷ�����Ԥ�����Ա�
figure(2)
plot(TV,'r*');
hold on
plot(TY1,'bo');
xlabel('���Լ�������')
ylabel('��ǩ����')
title('���Խ׶Σ�ʵ���������������Ĳ�');
legend('��ʵֵ','Ԥ��ֵ')
% ��������ʱ��
t2=toc