program Test;

{$APPTYPE CONSOLE}

uses
  SysUtils, SyncObjs, Classes, Windows;

type
  TToWrite = record
    order: Integer;
    prime: Integer;
  end;

type
  TPrimeWriter = class(TThread)
  private
    FOwnFile: TextFile;
  protected
    procedure Execute; override;
  public
    FOwnPrimeCount: Integer;
    FOwnTime: double;
    FFileName: string;
  end;



var
n: Integer;
CSGlobeI: TCriticalSection;
CSWrite: TCriticalSection;
CommonFile: TextFile;
WriteThreads: array of TPrimeWriter;
ThreadsCount: Integer;
ii: Integer;
a: array of integer;
globI: Integer;
LastWrote: Integer;
foundCount: Integer;
Quit: Boolean;
S: string;


procedure TPrimeWriter.Execute;
var
  i, j, k: integer;
  toWrite: Integer;
  toWrites: array of TToWrite;
  LFC: Integer;
  Fr,Sta,Sto: int64;
begin
  AssignFile(FOwnFile, FFileName);
  ReWrite(FOwnFile);
  Closefile(FOwnFile);
  FOwnPrimeCount := 0;
  QueryPerformanceFrequency(Fr);
  QueryPerformanceCounter(Sta);
  while (globI < n  + 1) or (Length(toWrites) > 0) do
    begin

      if globI < n  + 1 then
        begin
          CSGlobeI.Enter;
          i:= globI;
          globI:= globI + 1;

          if a[i] <> 0 then
            begin
              FOwnPrimeCount := FOwnPrimeCount + 1;
              foundCount := foundCount + 1;
              LFC := foundCount;
              toWrite := a[i];
              j := i;
              while j < n + 1 do
                begin
                  a[j] := 0;
                  j := j + i;
                end;
              CSGlobeI.Leave;

              Append(FOwnFile);
              Write(FOwnFile, inttostr(toWrite) + ' ');
              Closefile(FOwnFile);

              SetLength(toWrites, Length(toWrites) + 1);
              toWrites[Length(toWrites) - 1].order := LFC;
              toWrites[Length(toWrites) - 1].prime := toWrite;
            end
          else CSGlobeI.Leave;
        end;

      for j:=0 to Length(toWrites) - 1 do
        begin
          if toWrites[j].order = LastWrote then
            begin

              CSWrite.Enter;
              Append(CommonFile);
              Write(CommonFile, inttostr(toWrites[j].prime) + ' ');
              Closefile(CommonFile);
              LastWrote := toWrites[j].order + 1;
              CSWrite.Leave;

              if Length(toWrites) > 1 then
                begin
                  for k := 1 to Length(toWrites) - 1 do
                    begin
                      toWrites[k - 1] := toWrites[k]
                    end;
                end;
              SetLength(toWrites, Length(toWrites) - 1);
            end
          else break;
        end;
    end;
  QueryPerformanceCounter(Sto);
  FOwnTime:=(Sto-Sta)/Fr;
end;

begin
  Writeln('Please enter bound of prime numbers search as an unsigned integer:');
  while True do
    begin
      try
        ReadLn(n);
        Break;
      except
        Writeln('It is not an unsigned integer. Try again.');
      end;
    end;


  Writeln('begin culculating');
  SetLength(a, n + 1);

  a[0] := 0;
  a[1] := 0;
  for ii := 2 to n do
    begin
      a[ii] := ii;
    end;

  AssignFile(CommonFile, 'Result.txt');
  ReWrite(CommonFile);
  CSGlobeI := TCriticalSection.Create();
  CSWrite := TCriticalSection.Create();
  ThreadsCount := 3;
  SetLength(WriteThreads, ThreadsCount);
  globI := 2;
  LastWrote := 1;
  foundCount := 0;
  for ii:=0 to ThreadsCount - 1 do
    begin
      WriteThreads[ii] := TPrimeWriter.Create(true);
      WriteThreads[ii].FFileName := Format('Thread%d.txt', [ii + 1]);
      WriteThreads[ii].Resume;
    end;

  for ii:=0 to ThreadsCount - 1 do
    begin
      WriteThreads[ii].WaitFor;
      Writeln(Format('Thread%d time is %f', [ii + 1, WriteThreads[ii].FOwnTime]));
      Writeln(Format('Thread%d number of written primes is %d', [ii + 1, WriteThreads[ii].FOwnPrimeCount]));
      WriteThreads[ii].DoTerminate;
      Writeln(Format('Thread%d finished', [ii + 1]));
    end;

  try
    WriteLn('To quit enter anything');
    Quit := False;
    while not Quit do
      begin
        ReadLn(S);
        Quit := True;
      end;
  except
  end;
end.
