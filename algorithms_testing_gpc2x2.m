clear all;
clearvars
global N a b na nb nu ny
close all

%% Algorytm DMC 2x2 (benchmark)
% Obiekt regulacji
%      input 1        input 2
Gs = [tf( 1,[.7 1]), tf( 5,[.3 1]);  % output 1
      tf( 1,[.5 1]), tf( 2,[.4 1])]; % output 2
Tp = 0.05;
Gz = c2d(Gs,Tp,'zoh');
ny = 2;
nu = 2;

% Based on STP script, pages 79 (tab. 3.1) and 86 (eq. 3.49)
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

umax =  1;
umin = -1;

% Horyzonty predykcji i sterowania
N  = 5; 
Nu = 2;

% Warto�ci trajektorii zadanej
yzad(1:ny,1:2000) =  .0;
yzad(1,   1: end) = -.8; yzad(2, 200: end) = -.1;
yzad(1, 400: end) = -.1; yzad(2, 600: end) = -.2;
yzad(1, 800: end) = -.3; yzad(2,1000: end) =  .1;
yzad(1,1200: end) =  .0; yzad(2,1400: end) =  .0;
yzad(1,1600: end) = -.2; yzad(2,1800: end) =  .2;

% Pocz�tkowa i ko�cowa chwila symulacji
kp = max(na,nb)+1+1;
kk = size(yzad,2);

% Macierze Lambda oraz Psi -- wagi funkcji koszt�w (sta�e na horyzoncie
% predykcji/sterowania i r�wne dla ka�dego wyj�cia/wej�cia)
Lambda = eye(Nu*nu);
Psi    = eye(N *ny);

% Wektory warto�ci sterowania oraz wyj�cia obiektu regulacji
u = zeros(nu,kk);
y = zeros(ny,kk);

% W�asnor�cznie wyznaczana odpowied� skokowa
S = zeros(ny,nu,N);
for k = 1:size(S,3)
    % symulacja obiektu regulacji
    for m=1:ny
        for n=1:nu
            for i=1:min(k,nb)
                S(m,n,k) = S(m,n,k) + b(m,n,i)*1;
            end
            for i=1:min(k-1,na)
                S(m,n,k) = S(m,n,k) - a(m,i)*S(m,n,k-i);
            end         
        end   
    end 
end

M = cell(N,Nu);

% Matrix M
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

K = (M'*Psi*M+Lambda)^(-1)*M';
Knu = K(1:nu,:);

Kyzad = sum(Knu,2);
Ku = zeros(nu,nu,nb);   % r,n,j -> nu x nu x nb
Ky = zeros(nu,ny,na+1); % r,m,j -> nu x ny x (na+1)
% r -- numer sygna�u steruj�cego, kt�rego przyrost jest wyliczany
% n -- numer sygna�u steruj�cego
% m -- numer sygna�u wyj�ciowego
% j -- dynamika sygna�u wej�ciowego/wyj�ciowego

% Kolejno�� nie jest przypadkowa!
fun_f(1,1,1);
fun_g(1,1,1,1);
fun_e(1,1,1,1);

%% Tutaj wyznaczanie parametr�w Ku, Ky
for r=1:nu
    for n=1:nu
        for j=1:nb
            Ku(r,n,j) = 0;
            for p=1:N
                for m=1:ny
                    s=(p-1)*ny+m;
                    Ku(r,n,j) = Ku(r,n,j) - K(r,s)*fun_e(p,j,m,n);
                end
            end
        end
    end
end
for r=1:nu
    for m=1:ny
        for j=0:na
            Ky(r,m,j+1) = 0;
            for p=1:N
                s=(p-1)*ny+m;
                Ky(r,m,j+1) = Ky(r,m,j+1) - K(r,s)*fun_f(p,j,m);
            end
        end
    end
end
for r=1:nu
    for m=1:ny
        Kyzad(r,m) = 0;
        for p=1:N
            s=(p-1)*ny+m;
            Kyzad(r,m) = Kyzad(r,m) + K(r,s);
        end
    end
end

%% Symulacja
% wb = waitbar(0,'Simulation progress...');
for k = 10:kk
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
        %y(m,k) = y(m,k) + (rand()-.5)/500;
    end 
    
    % Wyznaczanie ymod
    ymod = zeros(ny,1);
    for m=1:ny
        for n=1:nu
            for i=1:nb
                if(k-i>=1)
                    ymod(m) = ymod(m) + b(m,n,i)*u(n,k-i);
                end
            end
        end
        for i=1:na
            if(k-i>=1)
                ymod(m) = ymod(m) - a(m,i)*y(m,k-i);
            end
        end            
    end 
    
    % Wyznaczanie d
    d = y(:,k)-ymod;
    
    % Wyznaczanie Y0
    Y0=zeros(ny,N);
    for m=1:ny
        for p=1:N
            Y0(m,p) = d(m);
            for n=1:nu
                for i=1:nb
                    if(-i+p<=-1)
                        Y0(m,p) = Y0(m,p) + b(m,n,i)*u(n,k-i+p);
%                         fprintf('Y0(%d,%d) += b(%d,%d,%d)*u(%d,%d) = %f*%f;\n',m,p,m,n,i,n,k-i+p,b(m,n,i),u(n,k-i+p));
                    else
                        Y0(m,p) = Y0(m,p) + b(m,n,i)*u(n,k-1);
%                         fprintf('Y0(%d,%d) += b(%d,%d,%d)*u(%d,%d) = %f*%f;\n',m,p,m,n,i,n,k-1,b(m,n,i),u(n,k-1));
                    end
                end
            end
            for i=1:na
                if(-i+p<=0)
                    Y0(m,p) = Y0(m,p) - a(m,i)*y(m,k-i+p);
%                     fprintf('Y0(%d,%d) -= a(%d,%d)*y(%d,%d) = %f*%f;\n',m,p,m,i,m,k-i+p,a(m,i),y(m,k-i+p));
                else
                    Y0(m,p) = Y0(m,p) - a(m,i)*Y0(m,-i+p);
%                     fprintf('Y0(%d,%d) -= a(%d,%d)*Y0(%d,%d) = %f*%f;\n',m,p,m,i,m,-i+p,a(m,i),Y0(m,-i+p));
                end
            end            
        end
    end
    
    Y0 = reshape(Y0,[],1);
    
    Yzad = repmat(eye(ny),N,1)*yzad(:,k); % Yzad sta�e na horyzoncie predykcji
%     Yzad = reshape(yzad(:,min(k+(1:N),kk)),[],1); % Yzad zmienne na horyzoncie predykcji
     
    du = zeros(2,1);
    for r=1:nu
        for m=1:ny
            du(r) = du(r) + Kyzad(r,m)*yzad(m,k);
        end
        for n=1:nu
            for j=1:nb
                du(r) = du(r) + Ku(r,n,j)*u(n,k-j);
            end
        end
        for m=1:ny
            for j=0:na
                du(r) = du(r) + Ky(r,m,j+1)*y(m,k-j);
            end
        end
    end
    %du = Knu*(Yzad-Y0);
    u(:,k) = u(:,k-1)+du;
    for n=1:nu
        if(u(n,k)>umax); u(n,k) = umax; end
        if(u(n,k)<umin); u(n,k) = umin; end
    end
%     waitbar(k/kk,wb);
end
% close(wb)

%% Rysownie przebieg�w trajektorii wyj�cia, zadanej oraz sterowania
figure;
plot(y'); hold on;
stairs(yzad','k--'); hold off;

figure;
stairs(u');




%% Funkcje do wyznaczania minimalnej postaci algorytmu GPC
function out = fun_e(p,j,m,n)
    % warto�ci N, a, b, na, nb musz� ju� by� w workspace'ie
    global N a b na nb nu ny 
    persistent E o
    
    if(isempty(E))
        o = 0;
        E=cell(ny,nu,N,nb+o);
        for m=1:ny; for n=1:nu; for p=1:N; for j=(1-o):nb; fun_e(p,j,m,n); end; end; end; end
    end
    if(~isempty(E{m,n,p,j+o}))
        out = E{m,n,p,j+o};
    else
        if(j==1 && nb==1)
            out = 0;
        elseif(j==1 && nb>1)
            out = fun_g(p,j,m,n);
        elseif(j>=2 && j<=(nb-1) && j<nb && nb>1)
            out = fun_g(p,j,m,n) - fun_g(p,j-1,m,n);
        elseif(j==nb && nb>1)
            out = -fun_g(p,j-1,m,n);
        else
            disp(N);disp(a);disp(b);disp(na);disp(nb);disp(nu);disp(ny);
            disp(p);disp(j);disp(m);disp(n);
            %disp(E);disp(o);
            error('Error!');
        end
        E{m,n,p,j+o} = out;
    end
end

function out = fun_f(p,j,m)
    global N a b na nb ny nu
    persistent F o
    
    if(isempty(F))
        o = 1;
        F=cell(ny,N,na+o);
        for m=1:ny; for p=1:N; for j=(1-o):na; fun_f(p,j,m); end; end; end
    end
    if(~isempty(F{m,p,j+o}))
        out = F{m,p,j+o};
    else
        if(p == 1)
            if(j==0)
                out = 1 - a(m,1);
            elseif(j>=1 && j<=(na-1))
                out = a(m,j)-a(m,j+1);
            elseif(j==na)
                out = a(m,j);
            else
                disp(N);disp(a);disp(b);disp(na);disp(nb);disp(nu);disp(ny);disp(F);disp(o);error('Error!');
            end
        elseif(p>=2 && p<=N)
            if(j>=0 && j<=(na-1))
                out = fun_f(p-1,0,m)*fun_f(1,j,m)+fun_f(p-1,j+1,m);
            elseif(j==na)
                out = fun_f(p-1,0,m)*fun_f(1,j,m);
            else
                disp(N);disp(a);disp(b);disp(na);disp(nb);disp(nu);disp(ny);disp(F);disp(o);error('Error!');
            end
        else
            disp(N);disp(a);disp(b);disp(na);disp(nb);disp(nu);disp(ny);disp(F);disp(o);error('Error!');
        end
        F{m,p,j+o} = out;
    end
end

function out = fun_g(p,j,m,n)
    % warto�ci N, a, b, na, nb musz� ju� by� w workspace'ie
    global N a b na nb nu ny
    persistent G o
    
    if(isempty(G))
        o = N;
        G=cell(ny,nu,N,nb-1+o);
        for m=1:ny; for n=1:nu; for p=1:N; for j=(1-p):(nb-1); fun_g(p,j,m,n); end; end; end; end
    end
    if(~isempty(G{m,n,p,j+o}))
        out = G{m,n,p,j+o};
    else
        if(p == 1)
            if(j>=0 && j<=(nb-1))
                out = b(m,n,j+1);
            else
                disp(N);disp(a);disp(b);disp(na);disp(nb);disp(nu);disp(ny);disp(G);disp(o);error('Error!');
            end
        elseif(p>=2 && p<=N)
            if(j>=(1-p) && j<=(-1))
                out = fun_g(p-1,j+1,m,n);
            elseif(j>=0 && j<=(nb-2))
                out = fun_f(p-1,0,m)*fun_g(1,j,m,n)+fun_g(p-1,j+1,m,n);
            elseif(j==(nb-1))
                out = fun_f(p-1,0,m)*fun_g(1,j,m,n);
            else
                disp(N);disp(a);disp(b);disp(na);disp(nb);disp(nu);disp(ny);disp(G);disp(o);error('Error!');
            end
        else
            disp(N);disp(a);disp(b);disp(na);disp(nb);disp(nu);disp(ny);disp(G);disp(o);error('Error!');
        end
        G{m,n,p,j+o} = out;
    end
end