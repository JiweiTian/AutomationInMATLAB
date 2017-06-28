%% Skrypt do sprawdzania projektu 1 z STP

%% Tre�� zadania
% _Obiekt dynamiczny opisany jest transmitancj� ci�g��_
%
% $$ G(s) = \frac{(s-z_0)(s-z_1)}{(s-b_0)(s-b_1)(s-b_2)} $$
%
% Tre�ci zada� projektowych r�ni� si� zerami ($z_0$, $z_1$), biegunami 
% ($b_0$, $b_1$, $b_2$) i warunkiem pocz�tkowym symulacji, np.:
zerac    = [-1, -10];      % [z_0, z_1]
biegunyc = [11, -12, -13]; % [b_0, b_1, b_2]
x0       = [-1 -2 5]';     % 

%% Zadanie 1
% _Wyznaczy� transmitancj� dyskretn� $G(z)$ . Zastosowa� okres pr�bkowania 
% $0.5$ sek. i ekstrapolator zerowego rz�du. Okre�li� zera i bieguny 
% transmitancji ci�g�ej i dyskretnej._
%
% Rozwi�zanie dotycz�ce cz�ci ci�g�ej mo�na odczyta� z transmitancji z
% opisu zadania. Aby uczyni� to samo dla transmitancji dyskretnej mo�na
% albo przekszta�ci� bieguny przy u�yciu funkcji exponent, albo
% przekszta�ci� transmitancj� ci�g�� na dyskretn� i odczyta� je z wyniku
Tp = 0.5;
Gs = tf(poly(zerac), poly(biegunyc));

Gz = c2d(Gs, Tp, 'zoh');

Kc = prod(-zerac)/prod(-biegunyc);
zerad = exp(zerac*Tp);
biegunyd = exp(biegunyc*Tp);
Kd = prod(1-zerad)/prod(1-biegunyd);
K  = Kc/Kd;
Gz2 = K*tf(poly(zerad),poly(biegunyd),Tp);

%% Zadanie 2

%% Zadanie 3

%% Zadanie 4

%% Zadanie 5

%% Zadanie 6
