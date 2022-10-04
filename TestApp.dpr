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
  N = 100;
  ThreadsAmount = 2;

var res_cnt: integer;    

type
  PCriticalSection = ^TCriticalSection;
  PTextFile = ^TextFile;

  TPrimeWriter = class(TThread)
  private
    ResultCS: TCriticalSection;
    FileName: string;
    ResultFileStream: TFileStream;
    ThreadFile: TextFile;
    ThreadFileStream: TFileStream;
    //
    PrimesList: array of integer;
    PrevPos: Int64;
    //
    procedure SearchForPrimes();
    procedure AppendPrime(aValue: integer);
  protected
    procedure Execute; override;
  public
    constructor Create(aResultFile: TFileStream; aResultCS: TCriticalSection; aThreadNo: byte);
    destructor Destroy(); override;
  end;

constructor TPrimeWriter.Create(aResultFile: TFileStream; aResultCS: TCriticalSection; aThreadNo: byte);
begin
  inherited Create(true);
  //
  ResultCS := aResultCS;
  ResultFileStream := aResultFile;
  //
  FileName := Format('Thread%d.txt', [aThreadNo]);
  if FileExists(FileName) then
    DeleteFile(PWideChar(FileName));
  ThreadFileStream := TFileStream.Create(FileName, fmCreate + fmOpenWrite);
  //
  SetLength(PrimesList, 0);  
end;

destructor TPrimeWriter.Destroy();
begin
  if Assigned(ThreadFileStream) then  
    ThreadFileStream.Free;
  //
  SetLength(PrimesList, 0);  
  //
  inherited;
end;

procedure TPrimeWriter.AppendPrime(aValue: integer);
var 
  i, sz: integer;
  file_str, value_str: string;
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
    ResultCS.Enter;
    //
    ResultFileStream.Position := PrevPos;    
    sz := ResultFileStream.Size - PrevPos; 
    PrevPos := sz + PrevPos; 
    if sz < 0 then 
      sz := 0;    
    SetLength(file_str, sz);    
    if (sz > 0) then  
      ResultFileStream.Read(file_str[1], sz);          
    //
    if pos(value_str, file_str) = 0 then
    begin
      inc(res_cnt);
      ResultFileStream.Seek(0, soFromEnd);  
      ResultFileStream.Write(value_str[1], value_len); 
      PrevPos := PrevPos + value_len;             
      //
      ThreadFileStream.Write(value_str[1], value_len);      
    end;      
  finally
    ResultCS.Leave;
  end;    
  //       
  //res := res + value_str;
end;

procedure TPrimeWriter.SearchForPrimes();
var
  i, j, k, c: integer;  
  fl: boolean;
  //res: string;
begin          
  //res := '';
  PrevPos := 0;
  i := 1;
  AppendPrime(2);
  while i < N do
  begin        
    i := i + 2;
    //
    if (i > 10) and (i mod 10 = 5) then
      continue;
    fl := true;  
    for k := 0 to length(PrimesList) - 1 do
    begin
      j := PrimesList[k];
      if (j * j - 1 > i) then
      begin
        AppendPrime(i);
        fl := false;
        break;
      end;          
      if (i mod j = 0) then
      begin
        fl := false;
        break;      
      end;
    end;
    if fl then           
      AppendPrime(i);
  end;
  //  
  //WriteLn(res);
  Write(FileName + ': ');
  WriteLn(length(PrimesList)); 
end;

procedure TPrimeWriter.Execute;
begin
  inherited;
  //
  SearchForPrimes();
end;

var 
  ResultFile: TFileStream;
  ResultCS: TCriticalSection;  
  PrimeThreads: array [0 .. ThreadsAmount - 1] of TPrimeWriter;
  fl: boolean;
  i: integer;   
  TC: Cardinal;

begin  
  TC := GetTickCount();
  try
    try
      if FileExists(ResultFileName) then
        DeleteFile(ResultFileName);
      ResultFile := TFileStream.Create(ResultFileName, fmCreate + fmOpenReadWrite + fmShareDenyNone);
      //
      ResultCS := TCriticalSection.Create();      
      //
      for i := 0 to ThreadsAmount - 1 do
      begin
        PrimeThreads[i] := TPrimeWriter.Create(ResultFile, ResultCS, i + 1);      
        PrimeThreads[i].FreeOnTerminate := false;
        PrimeThreads[i].Priority := tpNormal;        
      end;     
      //
      for i := 0 to ThreadsAmount - 1 do      
        PrimeThreads[i].Resume;      
      //                  
      while true do
      begin
        fl := true;    
        for i := 0 to ThreadsAmount - 1 do
          fl := fl and PrimeThreads[i].Finished;                    
        if fl then break;
        //
        Sleep(100);
      end;     
    except
      on E: Exception do
        Writeln(E.ClassName, ': ', E.Message);
    end;
  finally
    if Assigned(ResultCS) then
      ResultCS.Free;
    //
    if Assigned(ResultFile) then ResultFile.Free;      
    //
    for i := 0 to ThreadsAmount - 1 do
      if Assigned(PrimeThreads[i]) then
        PrimeThreads[i].Free;
  end;
  //
  Writeln('Finished!');
  Writeln(res_cnt);
  Writeln(GetTickCount() - TC);
  ReadLn;
end.
