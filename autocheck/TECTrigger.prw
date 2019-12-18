#include 'protheus.ch'

/*
//-----------
Como criar Triggers e utilizar a tabela de LOG:

-> Por enquanto, esta implementado apenas em SqlServer. Compile o fonte
"TECTrigger.prw" no seu RPO e adicione uma chamada da função TECTrigger
em um MenuDef qualquer. Execute a rotina com a opção de "Criar Trigger"

-> O checkbox "Executar DbSelectArea()" força um dbSelectArea em todas as tabelas
da SX2. Isso garante que todas as tabelas do dicionário sejam criadas fisicamente
no seu banco. Isso também faz com que a criação das triggers fique BEM mais lenta

-> Todos os comandos de criação de trigger são feitos diretamente no BD, via TCSqlExec

-> Se você restaurar/mudar de banco de dados etc... , tudo o que foi feito no
TECTrigger é perdido. Se você fizer o backup de um BD que já passou pelo TecTrigger,
a tabela LOGZERA e os triggers também vão para o backup

-> A opção "Apaga Triggers" apaga todas as triggers criadas pelo TecTrigger e também
a tabela LOGZERA

-> Você pode usar a tabela LOGZERA no seu dia-a-dia, pois ela registra todas as operações
de INSERT/UPDATE/DELETE que ocorrem no banco na tabela LOGZERA. Isso significa que você
pode fazer algum processo no ERP e depois ver na tabela LOGZERA o que aconteceu

//-----------
*/

//-------------------------------------------------------------------
/*/{Protheus.doc} TECTrigger
** Funciona apenas em SQLServer **
** Homologado apenas na versão 2014 **

-> Cria duas triggers em cada tabela do banco de dados
-> A opção "Executa DbSelectArea()" força a criação de todas as tabelas na SX2

@author Mateus Boiani
@since 31/12/2018
@version 1.0 
/*/
//-------------------------------------------------------------------
Function TECTrigger()
Local oDlgSelect
Local oCheckBox
Local oCreate
Local oDrop
Local oExit
Local lCheck := .F.

DEFINE MSDIALOG oDlgSelect FROM 0,0 TO 150,155 PIXEL TITLE "TECTrigger"

	oCreate := TButton():New( 5, 17, "Criar Triggers",oDlgSelect,{|| TecExecTrg(1,lCheck) , oDlgSelect:End()}, 45,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oDrop := TButton():New( 20, 17, "Apagar Triggers",oDlgSelect,{|| TecExecTrg(2,lCheck) , oDlgSelect:End()}, 45,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	
	oCheck1 := TCheckBox():New(48,03,'Executa DbSelectArea() ?',,oDlgSelect,100,210,,,,,,,,.T.,,,)
	oCheck1:bSetGet 	:= {|| lCheck := !lCheck }
	
	oExit := TButton():New( 60, 40, "Sair",oDlgSelect,{|| oDlgSelect:End() }, 30,10,,,.F.,.T.,.F.,,.F.,,,.F. ) 

ACTIVATE MSDIALOG oDlgSelect CENTER

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} TecExecTrg
Função utilizada apenas para colocar tudo dentro de um FwMsgRun

@author Mateus Boiani
@since 31/12/2018
@version 1.0 
/*/
//-------------------------------------------------------------------
Function TecExecTrg(nOpc,lCheck)
Default lCheck := .F.
If nOpc == 1
	FwMsgRun(Nil,{|| CreateTrigg(lCheck)}, Nil, "Aguarde, criando gatilhos...")
ElseIf nOpc == 2
	FwMsgRun(Nil,{|| DropTrigg(lCheck)}, Nil, "Aguarde, apagando gatilhos...")
Endif

MsgInfo("Operação finalizada.")

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} CreateTrigg
-> Cria a tabela LOGZERA no banco
** Obs: Acho que por alguma limitação do DbAccess o campo COLUNAS não pode
ser criado como VARCHAR(max)... o valor 2200 suporta até 200 colunas,
isso significa que uma operação que modifique mais de 200 colunas de uma vez não será
100% "logged"
-> Cria a função getCols() no banco
-> Cria os gatilhos de UPDATE e INSERT

@author Mateus Boiani
@since 31/12/2018
@version 1.0 
/*/
//-------------------------------------------------------------------
Static Function CreateTrigg(lDbSelect)
Local cSQL
Local aTables := GetTables(lDbSelect)
Local nX

TCSqlExec( (GetSqlFunc()) )
TCSqlExec("create table LOGZERA (LOG_ID int identity primary key, COMANDO varchar(30), NOME_DA_TABELA varchar(10), HORA datetime, R_E_C_N_O_ int, COLUNAS varchar(2200) DEFAULT '')")

For nX := 1 to LEN(aTables)
	cSQL := GetSQLTrUP(aTables[nX])
	TCSqlExec( cSQL )
	
	cSQL := GetSqlTrIn(aTables[nX])
	TCSqlExec( cSQL )
	
	conout(aTables[nX] + " - " + cValTochar(nX) + " de " + cValTochar(LEN(aTables)))
Next

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} GetSqlTrIn
-> Retorna o comando SQL para a criação da trigger de INSERT

@author Mateus Boiani
@since 31/12/2018
@version 1.0 
/*/
//-------------------------------------------------------------------
Static Function GetSqlTrIn(cTable)
Local cSql := CRLF

cSql += "CREATE TRIGGER trigg_INSERT##TABLE_NAME## ON ##TABLE_NAME## AFTER INSERT AS" + CRLF
cSql += "INSERT INTO LOGZERA (COMANDO,NOME_DA_TABELA,HORA,R_E_C_N_O_, COLUNAS) select" + CRLF
cSql += "'insert',##TABLE_NAME_WITH_QUOTES##, SYSDATETIME() ,R_E_C_N_O_, dbo.getCols(##TABLE_NAME_WITH_QUOTES##) FROM inserted" + CRLF

cSql := StrTran(cSql, "##TABLE_NAME##",cTable)
cSql := StrTran(cSql, "##TABLE_NAME_WITH_QUOTES##",("'" + cTable + "'"))

Return cSql

//-------------------------------------------------------------------
/*/{Protheus.doc} GetSqlFunc
-> Retorna o comando SQL para a criação da FUNCTION getCols()
** Essa função retorna todos as colunas varchar e float de uma tabela
em uma linha só, separadas por ponto-e-virgula.

@author Mateus Boiani
@since 31/12/2018
@version 1.0 
/*/
//-------------------------------------------------------------------
Static Function GetSqlFunc()
Local cSql := CRLF

cSql += "CREATE FUNCTION getCols (@table_name VARCHAR(20))" + CRLF
cSql += "RETURNS VARCHAR(max)" + CRLF
cSql += "AS" + CRLF
cSql += "BEGIN" + CRLF
cSql += "	Declare @aux AS VARCHAR(MAX)" + CRLF 
cSql += "	SELECT  @aux = COALESCE(@aux + ';', '') + COLUMN_NAME" + CRLF
cSql += "	FROM   INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME IS NOT NULL" + CRLF
cSql += "	AND TABLE_NAME = @table_name" + CRLF
cSql += "	and DATA_TYPE in ('varchar','float')" + CRLF
cSql += "	set @aux = @aux + ';'" + CRLF
cSql += "	RETURN(@aux)" + CRLF
cSql += "END" + CRLF

Return cSql
//-------------------------------------------------------------------
/*/{Protheus.doc} GetSQLTrUP
-> Retorna o comando SQL para a criação da Trigger de UPDATE
** Precisei criar tabelas temporárias pq o sp_executesql não consegue processar
comando na INSERTED nem na DELETED 
@author Mateus Boiani
@since 31/12/2018
@version 1.0 
/*/
//-------------------------------------------------------------------
Static Function GetSQLTrUP(cTable)
Local cSql := CRLF
cSql += "create trigger trigg_UPDATE##TABLE_NAME## ON ##TABLE_NAME## AFTER UPDATE AS" + CRLF
cSql += "begin" + CRLF
cSql += "	declare @colunas as VARCHAR(max)" + CRLF
cSql += "	declare @nome_coluna as VARCHAR(50)" + CRLF
cSql += "	declare @colunas_alteradas as VARCHAR(max) = ''" + CRLF
cSql += "	declare @com1 as nvarchar(100)" + CRLF
cSql += "	declare @com2 as nvarchar(100)" + CRLF
cSql += "	declare @res1 as varchar(max)" + CRLF
cSql += "	declare @res2 as varchar(max)" + CRLF
cSql += "	declare @ParmDefinition1 nvarchar(500) = N'@res1 as varchar(max) output';" + CRLF
cSql += "	declare @ParmDefinition2 nvarchar(500) = N'@res2 as varchar(max) output';" + CRLF
cSql += "" + CRLF
cSql += "	set @colunas = dbo.getCols(##TABLE_NAME_WITH_QUOTES##)" + CRLF
cSql += "" + CRLF
cSql += "	select * into #del from deleted" + CRLF
cSql += "	select * into #ins from inserted" + CRLF
cSql += "" + CRLF
cSql += "	while ( select COUNT(R_E_C_N_O_) from #ins ) > 0" + CRLF
cSql += "	Begin" + CRLF
cSql += "		while CHARINDEX(';', @colunas) > 0" + CRLF  
cSql += "		begin" + CRLF
cSql += "			set @nome_coluna = LEFT(@colunas,CHARINDEX(';', @colunas)-1)" + CRLF
cSql += "			set @colunas =  SUBSTRING(@colunas,CHARINDEX(';', @colunas) + 1,9999999)" + CRLF
cSql += "" + CRLF
cSql += "			set @com1 = 'select TOP 1 @res1 = CAST(d.' + @nome_coluna + ' AS VARCHAR(max)) from #del d order by d.R_E_C_N_O_ asc'" + CRLF
cSql += "			set @com2 = 'select TOP 1 @res2 = CAST(i.' + @nome_coluna + ' AS VARCHAR(max)) from #ins i order by i.R_E_C_N_O_ asc'" + CRLF
cSql += "" + CRLF
cSql += "			EXEC sp_executesql @com1 , @ParmDefinition1, @res1 out" + CRLF
cSql += "			EXEC sp_executesql @com2 , @ParmDefinition2, @res2 out" + CRLF
cSql += "" + CRLF
cSql += "			IF @res1 != @res2" + CRLF
cSql += "			begin" + CRLF
cSql += "				set @colunas_alteradas = @colunas_alteradas  + ';' + @nome_coluna" + CRLF
cSql += "			end" + CRLF
cSql += "		end" + CRLF
cSql += "		If @colunas_alteradas <> ''" + CRLF
cSql += "			Begin" + CRLF
cSql += "				If CHARINDEX('D_E_L_E_T_',@colunas_alteradas) = 0" + CRLF
cSql += "					Begin" + CRLF
cSql += "						INSERT INTO LOGZERA (COMANDO, NOME_DA_TABELA, HORA, R_E_C_N_O_, COLUNAS)" + CRLF
cSql += "						values ('update', ##TABLE_NAME_WITH_QUOTES##, SYSDATETIME(),(select TOP 1 R_E_C_N_O_ from #ins i order by i.R_E_C_N_O_ asc), @colunas_alteradas)" + CRLF
cSql += "					End" + CRLF
cSql += "				Else" + CRLF
cSql += "					Begin" + CRLF
cSql += "						INSERT INTO LOGZERA (COMANDO, NOME_DA_TABELA, HORA, R_E_C_N_O_, COLUNAS)" + CRLF
cSql += "						values ('delete', ##TABLE_NAME_WITH_QUOTES##, SYSDATETIME(),(select TOP 1 R_E_C_N_O_ from #ins i order by i.R_E_C_N_O_ asc), @colunas_alteradas)" + CRLF
cSql += "					End" + CRLF
cSql += "			End" + CRLF
cSql += "		set @colunas_alteradas = ''" + CRLF
cSql += "		delete #del where R_E_C_N_O_ = (select TOP 1 R_E_C_N_O_ from #del d order by d.R_E_C_N_O_ asc)" + CRLF
cSql += "		delete #ins where R_E_C_N_O_ = (select TOP 1 R_E_C_N_O_ from #ins i order by i.R_E_C_N_O_ asc)" + CRLF
cSql += "		set @colunas = dbo.getCols(##TABLE_NAME_WITH_QUOTES##)" + CRLF
cSql += "	end" + CRLF
cSql += "	drop table #del" + CRLF
cSql += "	drop table #ins" + CRLF
cSql += "end" + CRLF

cSql := StrTran(cSql, "##TABLE_NAME##",cTable)
cSql := StrTran(cSql, "##TABLE_NAME_WITH_QUOTES##",("'" + cTable + "'"))

Return cSql

//-------------------------------------------------------------------
/*/{Protheus.doc} GetTables
-> Percorre a SX2 e adciona as tabelas encontradas no array aRet.
** Algumas tabelas são ignoradas pq não estavam sendo criadas no meu ambiente.... (ocorria errorlog)
@author Mateus Boiani
@since 31/12/2018
@version 1.0 
/*/
//-------------------------------------------------------------------
Static Function GetTables(lDbSelect)
Local aRet := {}
Local cSkip := "DFC|DHD|DYQ|EYW|GA0|SEK|D36" //verificar

DbSelectArea("SX2")
DBGoTop()

While !SX2->(EOF())
	If !(SX2->X2_CHAVE $ cSkip)
		AADD(aRet, ALLTRIM(SX2->X2_ARQUIVO))
		If lDbSelect
			DbSelectArea((SX2->X2_CHAVE))
			DbCloseArea((SX2->X2_CHAVE))
		EndIf
		conout((SX2->X2_CHAVE))
	EndIf
	SX2->(DbSkip())
End

Return aRet

//-------------------------------------------------------------------
/*/{Protheus.doc} DropTrigg
->Dropa todas as triggers criadas por esse script

@author Mateus Boiani
@since 31/12/2018
@version 1.0 
/*/
//-------------------------------------------------------------------
Static Function DropTrigg(lDbSelect)

Local cSQL
Local aTables := GetTables(lDbSelect)
Local nX

TCSqlExec( "Drop function getCols" )

For nX := 1 TO LEN(aTables)
	cSQL := DropInsert(aTables[nX])
	TCSqlExec( cSQL )
	
	cSQL := DropUpdate(aTables[nX])
	TCSqlExec( cSQL )
	
	conout(aTables[nX] + " - " + cValTochar(nX) + " de " + cValTochar(LEN(aTables)))
Next

TCSqlExec( "Drop table LOGZERA" )

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} DropInsert
-> Dropa a trigger de insert

@author Mateus Boiani
@since 31/12/2018
@version 1.0 
/*/
//-------------------------------------------------------------------
Static Function DropInsert(cTable)
Local cSql := CRLF

cSql +=	"DROP TRIGGER trigg_INSERT##TABLE_NAME##" + CRLF
cSql := StrTran(cSql, "##TABLE_NAME##",cTable)

Return cSql

//-------------------------------------------------------------------
/*/{Protheus.doc} DropUpdate
-> Dropa a trigger de update

@author Mateus Boiani
@since 31/12/2018
@version 1.0 
/*/
//-------------------------------------------------------------------
Static Function DropUpdate(cTable)
Local cSql := CRLF

cSql +=	"DROP TRIGGER trigg_UPDATE##TABLE_NAME##" + CRLF
cSql := StrTran(cSql, "##TABLE_NAME##",cTable)

Return cSql