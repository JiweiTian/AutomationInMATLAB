clearvars
close all

%% Algorytm DMC 1x1 (benchmark)
% Obiekt regulacji
Gs = tf(1,[.01 1]);
Gz = c2d(Gs,0.1);
a = Gz.Denominator{1}(2);
b = Gz.Numerator{1}(2);

% Odpowied� skokowa
S = step(Gz);
S = S(2:end); % usuwanie pierwszego elementu odpowiedzi skokowej -- KONIECZNE!

% Horyzonty predykcji i sterowania
N = 20; 
Nu = 20;

% Warto�ci trajektorii zadanej
yzad(1:20) = 0;
yzad(100:200) = 1;
yzad(200:400) = -1;
yzad(400:600) = -.1;
yzad(600:800) = .1;
yzad(800:1000) = -.5;

% Pocz�tkowa i ko�cowa chwila symulacji
kp = 2;
kk = length(yzad);

% Macierze Lambda oraz Psi -- wagi funkcji koszt�w
Lambda = eye(Nu);
Psi = eye(N);

% Wektory warto�ci sterowania oraz wyj�cia obiektu regulacji
u = zeros(kk,1);
y = zeros(kk,1);

% Horyzont dynamiki (do wyznaczania dUp)
D = length(S);

%% Symulacja
for k = kp:kk
    y(k) = -a*y(k-1)+b*u(k-1); % symulacja obiektu regulacji
    
    Yzad = ones(N,1)*yzad(k); % Yzad sta�e na horyzoncie predykcji
%     Yzad = yzad(min(k+(1:N),kk)); % Yzad zmienne na horyzoncie predykcji
    Y = y(k);
    dUp = zeros(D-1,1);
    for p = 1:(D-1)
        if(k-p > 0); dUp(p) = u(k-p); end
        if(k-p-1 > 0); dUp(p) = dUp(p)-u(k-p-1); end
    end
    
    du = dmc_1x1(S,N,Nu,Lambda,Psi,dUp,Y,Yzad); % algorytm DMC 1x1
    
    u(k) = u(k-1)+du;
end

%% Rysownie przebieg�w trajektorii wyj�cia, zadanej oraz sterowania
figure;
plot(y); hold on;
stairs(yzad,'k--'); hold off;

figure;
stairs(u);