unit KraftConvert;


interface

uses
 kraft, raylib, raymath,  Classes, SysUtils;

// Функции преобразования между Kraft и Raylib
function KraftMatrixToRaylibMatrix(const AKraftMatrix: TKraftMatrix4x4): TMatrix;
function RaylibMatrixToKraftMatrix(const ARaylibMatrix: TMatrix): TKraftMatrix4x4;
function KraftVector3ToRaylibVector3(const AKraftVector: TKraftVector3): TVector3;
function RaylibVector3ToKraftVector3(const ARaylibVector: TVector3): TKraftVector3;
function KraftQuaternionToRaylibQuaternion(const AKraftQuaternion: TKraftQuaternion): TQuaternion;
function RaylibQuaternionToKraftQuaternion(const ARaylibQuaternion: TQuaternion): TKraftQuaternion;
function KraftMatrix3x3ToQuaternion(const AMatrix: TKraftMatrix3x3): TQuaternion;
function QuaternionToKraftMatrix3x3(const AQuaternion: TQuaternion): TKraftMatrix3x3;
function KraftMatrix4x4ToQuaternion(const AMatrix: TKraftMatrix4x4): TQuaternion;


implementation

{ Функции преобразования }

function KraftMatrixToRaylibMatrix(const AKraftMatrix: TKraftMatrix4x4): TMatrix;
begin
  Result.m0 := AKraftMatrix[0, 0];
  Result.m1 := AKraftMatrix[0, 1];
  Result.m2 := AKraftMatrix[0, 2];
  Result.m3 := AKraftMatrix[0, 3];

  Result.m4 := AKraftMatrix[1, 0];
  Result.m5 := AKraftMatrix[1, 1];
  Result.m6 := AKraftMatrix[1, 2];
  Result.m7 := AKraftMatrix[1, 3];

  Result.m8 := AKraftMatrix[2, 0];
  Result.m9 := AKraftMatrix[2, 1];
  Result.m10 := AKraftMatrix[2, 2];
  Result.m11 := AKraftMatrix[2, 3];

  Result.m12 := AKraftMatrix[3, 0];
  Result.m13 := AKraftMatrix[3, 1];
  Result.m14 := AKraftMatrix[3, 2];
  Result.m15 := AKraftMatrix[3, 3];
end;

function RaylibMatrixToKraftMatrix(const ARaylibMatrix: TMatrix): TKraftMatrix4x4;
begin
  Result[0, 0] := ARaylibMatrix.m0;
  Result[0, 1] := ARaylibMatrix.m1;
  Result[0, 2] := ARaylibMatrix.m2;
  Result[0, 3] := ARaylibMatrix.m3;

  Result[1, 0] := ARaylibMatrix.m4;
  Result[1, 1] := ARaylibMatrix.m5;
  Result[1, 2] := ARaylibMatrix.m6;
  Result[1, 3] := ARaylibMatrix.m7;

  Result[2, 0] := ARaylibMatrix.m8;
  Result[2, 1] := ARaylibMatrix.m9;
  Result[2, 2] := ARaylibMatrix.m10;
  Result[2, 3] := ARaylibMatrix.m11;

  Result[3, 0] := ARaylibMatrix.m12;
  Result[3, 1] := ARaylibMatrix.m13;
  Result[3, 2] := ARaylibMatrix.m14;
  Result[3, 3] := ARaylibMatrix.m15;
end;

function KraftVector3ToRaylibVector3(const AKraftVector: TKraftVector3): TVector3;
begin
  Result.x := AKraftVector.xyz[0];
  Result.y := AKraftVector.xyz[1];
  Result.z := AKraftVector.xyz[2];
end;

function RaylibVector3ToKraftVector3(const ARaylibVector: TVector3): TKraftVector3;
begin
  Result.xyz[0] := ARaylibVector.x;
  Result.xyz[1] := ARaylibVector.y;
  Result.xyz[2] := ARaylibVector.z;
end;

function KraftQuaternionToRaylibQuaternion(const AKraftQuaternion: TKraftQuaternion): TQuaternion;
begin
  Result.x := AKraftQuaternion.x;
  Result.y := AKraftQuaternion.y;
  Result.z := AKraftQuaternion.z;
  Result.w := AKraftQuaternion.w;
end;

function RaylibQuaternionToKraftQuaternion(const ARaylibQuaternion: TQuaternion): TKraftQuaternion;
begin
  Result.x := ARaylibQuaternion.x;
  Result.y := ARaylibQuaternion.y;
  Result.z := ARaylibQuaternion.z;
  Result.w := ARaylibQuaternion.w;
end;

function KraftMatrix3x3ToQuaternion(const AMatrix: TKraftMatrix3x3): TQuaternion;
var
  Trace, S: Single;
begin
  Trace := AMatrix[0, 0] + AMatrix[1, 1] + AMatrix[2, 2];

  if Trace > 0 then
  begin
    S := 0.5 / Sqrt(Trace + 1.0);
    Result.w := 0.25 / S;
    Result.x := (AMatrix[2, 1] - AMatrix[1, 2]) * S;
    Result.y := (AMatrix[0, 2] - AMatrix[2, 0]) * S;
    Result.z := (AMatrix[1, 0] - AMatrix[0, 1]) * S;
  end
  else if (AMatrix[0, 0] > AMatrix[1, 1]) and (AMatrix[0, 0] > AMatrix[2, 2]) then
  begin
    S := 2.0 * Sqrt(1.0 + AMatrix[0, 0] - AMatrix[1, 1] - AMatrix[2, 2]);
    Result.w := (AMatrix[2, 1] - AMatrix[1, 2]) / S;
    Result.x := 0.25 * S;
    Result.y := (AMatrix[0, 1] + AMatrix[1, 0]) / S;
    Result.z := (AMatrix[0, 2] + AMatrix[2, 0]) / S;
  end
  else if (AMatrix[1, 1] > AMatrix[2, 2]) then
  begin
    S := 2.0 * Sqrt(1.0 + AMatrix[1, 1] - AMatrix[0, 0] - AMatrix[2, 2]);
    Result.w := (AMatrix[0, 2] - AMatrix[2, 0]) / S;
    Result.x := (AMatrix[0, 1] + AMatrix[1, 0]) / S;
    Result.y := 0.25 * S;
    Result.z := (AMatrix[1, 2] + AMatrix[2, 1]) / S;
  end
  else
  begin
    S := 2.0 * Sqrt(1.0 + AMatrix[2, 2] - AMatrix[0, 0] - AMatrix[1, 1]);
    Result.w := (AMatrix[1, 0] - AMatrix[0, 1]) / S;
    Result.x := (AMatrix[0, 2] + AMatrix[2, 0]) / S;
    Result.y := (AMatrix[1, 2] + AMatrix[2, 1]) / S;
    Result.z := 0.25 * S;
  end;
end;

function QuaternionToKraftMatrix3x3(const AQuaternion: TQuaternion): TKraftMatrix3x3;
var
  x, y, z, w, xx, yy, zz, xy, xz, yz, wx, wy, wz: Single;
begin
  x := AQuaternion.x;
  y := AQuaternion.y;
  z := AQuaternion.z;
  w := AQuaternion.w;

  xx := x * x;
  yy := y * y;
  zz := z * z;
  xy := x * y;
  xz := x * z;
  yz := y * z;
  wx := w * x;
  wy := w * y;
  wz := w * z;

  Result[0, 0] := 1.0 - 2.0 * (yy + zz);
  Result[0, 1] := 2.0 * (xy - wz);
  Result[0, 2] := 2.0 * (xz + wy);

  Result[1, 0] := 2.0 * (xy + wz);
  Result[1, 1] := 1.0 - 2.0 * (xx + zz);
  Result[1, 2] := 2.0 * (yz - wx);

  Result[2, 0] := 2.0 * (xz - wy);
  Result[2, 1] := 2.0 * (yz + wx);
  Result[2, 2] := 1.0 - 2.0 * (xx + yy);
end;

function KraftMatrix4x4ToQuaternion(const AMatrix: TKraftMatrix4x4): TQuaternion;
var
  Trace, S: Single;
begin
  // Извлекаем матрицу 3x3 из матрицы 4x4 для вычисления кватерниона
  Trace := AMatrix[0, 0] + AMatrix[1, 1] + AMatrix[2, 2];

  if Trace > 0 then
  begin
    S := 0.5 / Sqrt(Trace + 1.0);
    Result.w := 0.25 / S;
    Result.x := (AMatrix[2, 1] - AMatrix[1, 2]) * S;
    Result.y := (AMatrix[0, 2] - AMatrix[2, 0]) * S;
    Result.z := (AMatrix[1, 0] - AMatrix[0, 1]) * S;
  end
  else if (AMatrix[0, 0] > AMatrix[1, 1]) and (AMatrix[0, 0] > AMatrix[2, 2]) then
  begin
    S := 2.0 * Sqrt(1.0 + AMatrix[0, 0] - AMatrix[1, 1] - AMatrix[2, 2]);
    Result.w := (AMatrix[2, 1] - AMatrix[1, 2]) / S;
    Result.x := 0.25 * S;
    Result.y := (AMatrix[0, 1] + AMatrix[1, 0]) / S;
    Result.z := (AMatrix[0, 2] + AMatrix[2, 0]) / S;
  end
  else if (AMatrix[1, 1] > AMatrix[2, 2]) then
  begin
    S := 2.0 * Sqrt(1.0 + AMatrix[1, 1] - AMatrix[0, 0] - AMatrix[2, 2]);
    Result.w := (AMatrix[0, 2] - AMatrix[2, 0]) / S;
    Result.x := (AMatrix[0, 1] + AMatrix[1, 0]) / S;
    Result.y := 0.25 * S;
    Result.z := (AMatrix[1, 2] + AMatrix[2, 1]) / S;
  end
  else
  begin
    S := 2.0 * Sqrt(1.0 + AMatrix[2, 2] - AMatrix[0, 0] - AMatrix[1, 1]);
    Result.w := (AMatrix[1, 0] - AMatrix[0, 1]) / S;
    Result.x := (AMatrix[0, 2] + AMatrix[2, 0]) / S;
    Result.y := (AMatrix[1, 2] + AMatrix[2, 1]) / S;
    Result.z := 0.25 * S;
  end;

  // Нормализуем кватернион
  Result := QuaternionNormalize(Result);
end;

end.

