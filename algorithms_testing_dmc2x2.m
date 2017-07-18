%% Algorytm DMC 2x2 (benchmark)
clearvars;
close all

% Obiekt regulacji
%      input 1        input 2
Gs = [tf( 1,[.7 1]), tf( 5,[.03 1]);  % output 1
      tf( 1,[.05 1]), tf( 2,[.4 1])]; % output 2
Tp = 0.05;
Gz = c2d(Gs,Tp,'zoh');
ny = 2;
nu = 2;

% Based on STP script, pages 79 (tab. 3.1) and 86 (eq. 3.49)
A = zeros(2,2);
B = zeros(2,2);
for m=1:2
    for n=1:2
        alfa = exp(-1/Gs(m,n).Denominator{1}(1)*Tp);
        B(m,n) = Gs(m,n).Numerator{1}(2)*(1-alfa);
        A(m,n) =                           -alfa ;
    end
end

% Y1/U1=G(1,1) and Y1/U2=G(1,2) => Y1 = G(1,1)*U1 + G(1,2)*U2
for m=1:2
    a(m,:)   = [A(m,1)+A(m,2), A(m,1)*A(m,2)];
    b(m,1,:) = [0, B(m,1), A(m,2)*B(m,1)];
    b(m,2,:) = [0, B(m,2), A(m,1)*B(m,2)];
end
na = size(a,2);
nb = size(b,3);

% Ograniczenia
umax =  1;
umin = -1;

% Odpowied� skokowa 
S = step(Gz(:,:)); % wymiary D x ny x nu
S = shiftdim(S(1:end,:,:),1); % usuwanie pierwszego elementu odpowiedzi 
                              % skokowej -- KONIECZNE dla obiektu bez 
                              % op�nienia (dla obiektu z op�nieniem 
                              % pierwsze zero jest istotne)! zmieniona 
                              % zosta�a kolejno�� indeks�w
                              
D = size(S,3);
D = min(D,200); % nadpisuj� �eby zmniejszy� liczb� oblicze�

% % W�asnor�cznie wyznaczana odpowied� skokowa
% S = zeros(ny,nu,1000);
% for k = 1:size(S,3)
%     % symulacja obiektu regulacji
%     for m=1:ny
%         for n=1:nu
%             for i=1:min(k,nb)
%                 S(m,n,k) = S(m,n,k) + b(m,n,i)*1;
%             end
%             for i=1:min(k-1,na)
%                 S(m,n,k) = S(m,n,k) - a(m,i)*S(m,n,k-i);
%             end         
%         end   
%     end 
% end

%% Og�lne parametry algorytmu
% Horyzonty predykcji i sterowania
N  = 50; 
Nu = 50;

% Pocz�tkowa i ko�cowa chwila symulacji
kp = max(na,nb)+1+1;
kk = 2000;
dk = 200;

% Warto�ci trajektorii zadanej
yzad = zeros(ny,kk);
for k=dk:dk:kk
    for m=1:ny
        yzad(m,(k-(m-1)*dk/ny):end) = rand()-.5;
    end
end

% Macierze Lambda oraz Psi -- wagi funkcji koszt�w
Lambda = eye(Nu*nu)*1.0;
Psi    = eye(N *ny)*1.0;

% Wektory warto�ci sterowania oraz wyj�cia obiektu regulacji
u = zeros(nu,kk);
y = zeros(ny,kk);

%% Macierze wyznaczane offline
% Macierz M
M = cell(N,Nu);
for row = 1:N
   for col = 1:Nu
        if(row-col+1 >= 1)
            M{row,col} = S(:,:,row-col+1);
        else
            M{row,col} = zeros(size(S(:,:,1)));
        end
   end
end
M=cell2mat(M);

% Macierz Mp
Mp = cell(N,(D-1));
for row = 1:N
   for col = 1:(D-1)
        Mp{row,col} = S(:,:,min(row+col,D)) - S(:,:,col);
   end
end
Mp = cell2mat(Mp);

% Macierz K
K = (M'*Psi*M+Lambda)^(-1)*M';

%% Macierze dla wersji minimalistycznej algorytmu
Ku=K*Mp; Ku = Ku(1:nu,:);

Ke=zeros(nu,1);
for n=1:nu
    for m=1:ny
        Ke(n,m) = sum(K(n,m:ny:end));
    end
end
%% Symulacja
for k = kp:kk
    % symulacja obiektu regulacji
    for m=1:ny
        for n=1:nu
            for i=1:nb
                if(k-i>=1)
                    y(m,k) = y(m,k) + b(m,n,i)*u(n,k-i);
                end
            end
        end
        for i=1:na
            if(k-i>=1)
                y(m,k) = y(m,k) - a(m,i)*y(m,k-i);
            end
        end            
    end 
    
    % wprowadzanie zak��ce�
    % for m=1:ny; y(m,k) = y(m,k) + (rand()-.5)/500; end;
     
    % wyznaczanie dUp
    dUpp = zeros(nu,D-1);
    for p = 1:(D-1)
        if(k-p > 0); dUpp(:,p) = u(:,k-p); end
        if(k-p-1 > 0); dUpp(:,p) = dUpp(:,p)-u(:,k-p-1); end
    end
    dUp = reshape(dUpp,[],1);
   
    % wyznaczanie Yzad (sta�e na horyzoncie predykcji)
    Yzad = repmat(eye(ny),N,1)*yzad(:,k); 
   
    % wyznaczanie Y
    Y = repmat(eye(ny),N,1)*y(:,k); 
    
    
    %% wyznaczenie du (klasycznie)
    Y0 = Y+Mp*dUp;
    dU = K*(Yzad-Y0);
    du_no = dU(1:nu);
    
    %% wyznaczenie du (optymalnie)
    du = Ke*(yzad(:,k)-y(:,k)) - Ku*dUp;
    
    du_diff(1:nu,k) = du-du_no;
    
    u(:,k) = u(:,k-1)+du;
    
    for n=1:nu
        if(u(n,k)>umax); u(n,k) = umax; end
        if(u(n,k)<umin); u(n,k) = umin; end
    end
end

%% Rysownie przebieg�w trajektorii wyj�cia, zadanej oraz sterowania
figure;
plot(y'); hold on;
stairs(yzad','k--'); hold off;
title('Warto�ci wyj�ciowe i zadane w czasie');

figure;
stairs(u');
title('Warto�ci sterowania w czasie');

figure;
stairs(du_diff');
title('Warto�ci b��du w czasie');