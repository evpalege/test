% ============================================================
%              СБРОС ПАМЯТИ
% ============================================================

clear;
clc;

% ============================================================
%              1. ЗАГРУЗКА DATA.TXT ИЗ COMSOL
% ============================================================
%
% Столбцы файла:
%
% Xm  Ym  Zm  mfnc.Bx  mfnc.By  mfnc.Bz
%
% Все строки, начинающиеся с %, игнорируются.

filename = 'data.txt';

fid = fopen(filename, 'r');

if fid == -1
    error('Не удалось открыть файл data.txt');
end

C = textscan(fid, '%f %f %f %f %f %f', ...
    'CommentStyle', '%', ...
    'CollectOutput', true);

fclose(fid);

data = C{1};

% ============================================================
%              2. ПРОВЕРКА КОЛИЧЕСТВА ТОЧЕК
% ============================================================

fprintf('Количество точек: %d\n', size(data, 1));

% ============================================================
%              3. РАЗМЕРНОСТЬ СЕТКИ COMSOL
% ============================================================
%
% X = 201 точка
% Y = 101 точка
% Z = 201 точка
%
% Всего:
%
% 201 * 101 * 201 = 4080501

Nx = 201;
Ny = 101;
Nz = 201;

N = Nx * Ny * Nz;

if size(data, 1) ~= N
    error('Ожидалось %d точек, получено %d.', ...
        N, size(data, 1));
end

% ============================================================
%              4. ИЗВЛЕЧЕНИЕ ДАННЫХ COMSOL
% ============================================================
%
% Xm       -> координата X
% Ym       -> координата Y
% Zm       -> координата Z
%
% mfnc.Bx  -> Global_Bx
% mfnc.By  -> Global_By
% mfnc.Bz  -> Global_Bz

Xm = data(:, 1);
Ym = data(:, 2);
Zm = data(:, 3);

Bx = data(:, 4);
By = data(:, 5);
Bz = data(:, 6);

% ============================================================
%              5. ФОРМИРОВАНИЕ 3D-КАРТЫ ПОЛЯ
% ============================================================
%
% COMSOL записывает точки в порядке:
%
% X -> Y -> Z
%
% Поэтому размер:
%
% [Nx Ny Nz] = [201 101 201]

Global_Bx = reshape(Bx, [Nx, Ny, Nz]);
Global_By = reshape(By, [Nx, Ny, Nz]);
Global_Bz = reshape(Bz, [Nx, Ny, Nz]);

% ============================================================
%              6. ФОРМИРОВАНИЕ BREAKPOINTS
% ============================================================
%
% Для Simulink n-D Lookup Table нужны одномерные
% векторы координат.
%
% X: 201 точка
% Y: 101 точка
% Z: 201 точка

x_glob_range = Xm(1:Nx);
y_glob_range = Ym(1:Nx:Nx*Ny);
z_glob_range = Zm(1:Nx*Ny:N);

% Приводим к столбцам

x_glob_range = x_glob_range(:);
y_glob_range = y_glob_range(:);
z_glob_range = z_glob_range(:);

% ============================================================
%              7. ПРОВЕРКА РАЗМЕРОВ
% ============================================================

fprintf('\nРазмеры карты магнитного поля:\n');

fprintf('Global_Bx: ');
disp(size(Global_Bx));

fprintf('Global_By: ');
disp(size(Global_By));

fprintf('Global_Bz: ');
disp(size(Global_Bz));

fprintf('\nРазмеры breakpoint-векторов:\n');

fprintf('x_glob_range: ');
disp(size(x_glob_range));

fprintf('y_glob_range: ');
disp(size(y_glob_range));

fprintf('z_glob_range: ');
disp(size(z_glob_range));

fprintf('\nДиапазоны координат:\n');

fprintf('X: %.6f ... %.6f м\n', ...
    x_glob_range(1), x_glob_range(end));

fprintf('Y: %.6f ... %.6f м\n', ...
    y_glob_range(1), y_glob_range(end));

fprintf('Z: %.6f ... %.6f м\n', ...
    z_glob_range(1), z_glob_range(end));

% ============================================================
%              8. УДАЛЕНИЕ ВСПОМОГАТЕЛЬНЫХ ПЕРЕМЕННЫХ
% ============================================================

clear C data Xm Ym Zm Bx By Bz
clear Nx Ny Nz N fid filename

% ============================================================
%              9. ВИЗУАЛИЗАЦИЯ МАГНИТНОГО ПОЛЯ
% ============================================================

% Шаг прореживания стрелок
%
% 1  = каждая точка
% 5  = каждая 5-я точка
% 10 = каждая 10-я точка

skip = 10;


% ============================================================
%                       СРЕЗ XY
% ============================================================
%
% Фиксируем Z.
%
% Ось X -> горизонтальная
% Ось Y -> вертикальная
%
% Bx -> компонента вдоль X
% By -> компонента вдоль Y

iz = round(length(z_glob_range) / 2);

% Индексы точек
ix_plot = 1:skip:length(x_glob_range);
iy_plot = 1:skip:length(y_glob_range);

% Координаты
X_xy = x_glob_range(ix_plot);
Y_xy = y_glob_range(iy_plot);

% Получаем поле.
%
% Global_Bx имеет размер X x Y x Z
%
% После squeeze:
% Bx_xy = X x Y = 21 x 11
% By_xy = X x Y = 21 x 11

Bx_xy = squeeze(Global_Bx(ix_plot, iy_plot, iz));
By_xy = squeeze(Global_By(ix_plot, iy_plot, iz));

% Для quiver с векторами X и Y
% матрицы U/V должны иметь размер:
%
% length(Y) x length(X)
%
% Поэтому:
%
% 21 x 11 -> 11 x 21

Bx_xy = Bx_xy.';
By_xy = By_xy.';

% Проверка размеров

fprintf('\n================ XY ================\n');

fprintf('X координат: %d\n', length(X_xy));
fprintf('Y координат: %d\n', length(Y_xy));

fprintf('Размер Bx_xy: %d x %d\n', ...
    size(Bx_xy,1), size(Bx_xy,2));

fprintf('Размер By_xy: %d x %d\n', ...
    size(By_xy,1), size(By_xy,2));

% Построение

figure('Color','w');

quiver( ...
    X_xy, ...
    Y_xy, ...
    Bx_xy, ...
    By_xy, ...
    1.5, ...
    'Color','b', ...
    'LineWidth',0.8);

xlabel('X, м');
ylabel('Y, м');

title(sprintf( ...
    'Направление магнитного поля — XY, Z = %.3f м', ...
    z_glob_range(iz)));

axis equal;
grid on;
box on;


% ============================================================
%                       СРЕЗ ZY
% ============================================================
%
% Фиксируем X.
%
% Ось Z -> горизонтальная
% Ось Y -> вертикальная
%
% Bz -> компонента вдоль Z
% By -> компонента вдоль Y

ix = round(length(x_glob_range) / 2);

% Индексы точек
iy_plot = 1:skip:length(y_glob_range);
iz_plot = 1:skip:length(z_glob_range);

% Координаты
Z_zy = z_glob_range(iz_plot);
Y_zy = y_glob_range(iy_plot);

% Получаем поле.
%
% Global_Bz имеет размер X x Y x Z
%
% После фиксации X и squeeze:
%
% Bz_zy = Y x Z = 11 x 21
% By_zy = Y x Z = 11 x 21

Bz_zy = squeeze(Global_Bz(ix, iy_plot, iz_plot));
By_zy = squeeze(Global_By(ix, iy_plot, iz_plot));

% Для quiver:
%
% строки = Y
% столбцы = Z
%
% Поэтому транспонировать НЕ нужно.

% Проверка размеров

fprintf('\n================ ZY ================\n');

fprintf('Z координат: %d\n', length(Z_zy));
fprintf('Y координат: %d\n', length(Y_zy));

fprintf('Размер Bz_zy: %d x %d\n', ...
    size(Bz_zy,1), size(Bz_zy,2));

fprintf('Размер By_zy: %d x %d\n', ...
    size(By_zy,1), size(By_zy,2));

% Построение

figure('Color','w');

quiver( ...
    Z_zy, ...
    Y_zy, ...
    Bz_zy, ...
    By_zy, ...
    1.5, ...
    'Color','r', ...
    'LineWidth',0.8);

xlabel('Z, м');
ylabel('Y, м');

title(sprintf( ...
    'Направление магнитного поля — ZY, X = %.3f м', ...
    x_glob_range(ix)));

axis equal;
grid on;
box on;


% ============================================================
%                         КОНЕЦ
% ============================================================

