program TestApp;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  SysUtils,
  Classes,
  SyncObjs,
  Windows;

const 
  ResultFileName = 'Result.txt';
  N = 1000000;
  ThreadsAmount = 2;

var 
  ResultCriticalSection: TCriticalSection; 
  ResultFileStream: TFileStream;
  LastAppended: integer;
  ResultCount: integer;

type
  TPrimesWriter = class(TThread)
  private
    fFileName: string;
    ThreadFileStream: TFileStream;
    //
    PrimesList: array of integer;
    fAppendedCount: integer;
    //
    procedure SearchForPrimes();
    procedure AppendPrime(aValue: integer);
  protected
    procedure Execute; override;
  public
    property FileName: string read fFileName;
    property AppendedCount: integer read fAppendedCount;
    //
    constructor Create(aThreadNo: byte);
    destructor Destroy(); override;
  end;

constructor TPrimesWriter.Create(aThreadNo: byte);
begin
  inherited Create(true);
  //  
  fFileName := Format('Thread%d.txt', [aThreadNo]);
  if FileExists(fFileName) then
    DeleteFile(PWideChar(FileName));
  ThreadFileStream := TFileStream.Create(fFileName, fmCreate + fmOpenWrite);
  //
  SetLength(PrimesList, 0);  
  fAppendedCount := 0;
end;

destructor TPrimesWriter.Destroy();
begin
  if Assigned(ThreadFileStream) then  
    ThreadFileStream.Free;
  //
  SetLength(PrimesList, 0);  
  //
  inherited;
end;

procedure TPrimesWriter.AppendPrime(aValue: integer);
var 
  i: integer;
  value_str: string;
  value_len: integer; 
begin
  i := length(PrimesList);
  SetLength(PrimesList, i + 1);
  PrimesList[i] := aValue;
  //
  value_str := inttostr(aValue) + ' ';
  value_len := length(value_str) * sizeof(char);
  //
  try
    ResultCriticalSection.Enter;    
    //
    if (aValue > LastAppended) then
    begin
      ResultFileStream.Write(value_str[1], value_len); 
      LastAppended := aValue;
      inc(ResultCount);
      //
      ThreadFileStream.Write(value_str[1], value_len);      
      inc(fAppendedCount);
    end;
  finally
    ResultCriticalSection.Leave;
  end;    
end;

procedure TPrimesWriter.SearchForPrimes();
var
  i, j, k: integer;  
  fl: boolean;
begin          
  i := 1;
  AppendPrime(2);
  while (i < N) and (not Terminated) do
  begin
    i := i + 2;
    //
    if (i > 10) and (i mod 10 = 5) then
      continue;
    fl := true;
    for k := 0 to length(PrimesList) - 1 do
    begin
      if Terminated then exit;
      //
      j := PrimesList[k];
      if (j * j - 1 > i) then break;
      if (i mod j = 0) then
      begin
        fl := false;
        break;
      end;
    end;
    if fl then AppendPrime(i);
  end;
end;

procedure TPrimesWriter.Execute;
begin
  inherited;
  //
  SearchForPrimes();
end;

var 
  PrimesThreads: array [0 .. ThreadsAmount - 1] of TPrimesWriter;
  fl: boolean;
  i: integer;   
  TC: Cardinal;

begin  
  TC := GetTickCount();
  ResultCount := 0;
  try
    try
      if FileExists(ResultFileName) then
        DeleteFile(ResultFileName);
      ResultFileStream := TFileStream.Create(ResultFileName, fmCreate + fmOpenReadWrite);
      //
      ResultCriticalSection := TCriticalSection.Create();        
      LastAppended := 0;  
      //
      for i := 0 to ThreadsAmount - 1 do
      begin
        PrimesThreads[i] := TPrimesWriter.Create(i + 1);      
        PrimesThreads[i].FreeOnTerminate := false;
        PrimesThreads[i].Priority := tpNormal;        
      end;     
      //
      for i := 0 to ThreadsAmount - 1 do      
        PrimesThreads[i].Start;      
      //                  
      while true do
      begin
        fl := true;    
        for i := 0 to ThreadsAmount - 1 do
          fl := fl and PrimesThreads[i].Finished;                    
        if fl then break;
        //
        Sleep(100);
      end;     
    except
      on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
    end;
  finally
    if Assigned(ResultCriticalSection) then
      ResultCriticalSection.Free;
    //
    if Assigned(ResultFileStream) then ResultFileStream.Free;      
    //
    for i := 0 to ThreadsAmount - 1 do
      if Assigned(PrimesThreads[i]) then
      begin
        Writeln(Format('%d primes in %s',
          [PrimesThreads[i].AppendedCount, PrimesThreads[i].FileName]));        
        PrimesThreads[i].Free;
      end;
  end;
  //
  Writeln(Format('Total primes %d', [ResultCount]));
  Writeln(Format('Execution time %d ms', [GetTickCount() - TC]));
  //
  ReadLn;
end.
