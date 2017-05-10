library DuplexSupport;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  SysUtils,
  Classes,
  ADODB;

{$R *.res}

//根据条码获取病人联机标识列表 
function GetEquipIdList(const Aadoconnstr,ABarCode,AEquipChar:pchar):PChar;stdcall;
var
  adoconn:Tadoconnection;
  adotemp22:Tadoquery;
  sResult:string;
begin
  result:=nil;
  
  adoconn:=Tadoconnection.Create(nil);
  adoconn.ConnectionString:=strpas(Aadoconnstr);
  adoconn.LoginPrompt:=false;

  adotemp22:=Tadoquery.Create(nil);
  adotemp22.Connection:=adoconn;
  adotemp22.Close;
  adotemp22.SQL.Clear;
  adotemp22.SQL.Text:='select distinct CASE WHEN ISNULL(CCI.defaultvalue,'''')='''' THEN cci.dlttype ELSE CCI.defaultvalue END AS dlttype from chk_valu_his cvh '+
                      'inner join combinitem cbi on cbi.id=cvh.pkcombin_id '+
                      'inner join CombSChkItem cbci on cbci.combunid=cbi.unid '+
                      'inner join clinicchkitem cci on cci.unid=cbci.itemunid '+
                      'where cvh.pkunid in '+
                      '( '+
                      'select cch.unid from chk_con_his cch where dbo.uf_GetExtBarcode(cch.unid) like ''%,'+strpas(ABarCode)+',%'' '+
                      ') '+
                      'and cci.commword='''+strpas(AEquipChar)+''' ';
  Try
    adotemp22.Open;
  except
    on E:Exception do
    begin
      adotemp22.Free;
      adoconn.Free;
      exit;
    end;
  end;

  while not adotemp22.Eof do
  begin
    if trim(adotemp22.fieldbyname('dlttype').AsString)='' then begin adotemp22.Next;continue; end;
    
    //这就要求联机标识本身不能有#2
    sResult:=sResult+adotemp22.fieldbyname('dlttype').AsString+#2;

    adotemp22.Next;
  end;
  adotemp22.Free;
  adoconn.Free;

  //=======将string转换为pchar
  try
    GetMem(result,length(sResult)+1) ;
  except
    result := nil ;
    exit;
  end ;
  if assigned(result) then
  begin
    StrPLCopy(result,sResult,length(sResult)) ;
    result[length(sResult)] := #0;
  end;
  //==============================}
end;

exports
  GetEquipIdList;


begin
end.
