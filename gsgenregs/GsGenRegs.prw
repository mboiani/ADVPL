#include 'protheus.ch'

class GsGenRegs 
	
	data oHash AS OBJECT
	data cAutoKey AS CHARACTER
	data aOrcs AS ARRAY
	
	method new() constructor 
	method insert()
	method addAtendente()
	method addOrcamento()
	method addLocal()
	method addRH()
	method addMI()
	method addMC()
	method gerarContrt()
	method getRec()
endclass

method new() class GsGenRegs
	::oHash := FwHashMap():New()
	::cAutoKey := REPLICATE("0",6)
	::aOrcs := {}
return

method getRec(cKey) class GsGenRegs

Return ::oHash:Get(cKey)

method insert(cTable, aData) class GsGenRegs
Local cPosRet := ""
Local cColName := IIF(LEFT(cTable,1) == 'S', RIGHT(cTable,2), cTable)
Local nX
Local cCommand
Local nRecno := 0
Default aData := {}
If ASCAN(aData, {|s| UPPER(s[1]) == cColName + "_FILIAL"}) == 0
	AADD(aData, {cColName + "_FILIAL", xFilial(cTable)})
EndIf
Begin Transaction
Reclock(cTable, .T.)
	For nX := 1 TO LEN(aData)
		cCommand := cTable+"->"+aData[nX][1] + " := "
		Conout("saving " + aData[nX][1])
		If VALTYPE(aData[nX][2]) == 'C'
			cCommand += "'"+aData[nX][2]+"'"
		ElseIf VALTYPE(aData[nX][2]) == 'N'
			cCommand += cValToChar(aData[nX][2])
		ElseIf VALTYPE(aData[nX][2]) == 'D'
			cCommand += "cToD('" + DtoC(aData[nX][2]) + "')"
		ElseIf VALTYPE(aData[nX][2]) == 'L'
			If aData[nX][2]
				cCommand += ".T."
			Else
				cCommand += ".F."
			EndIf
		EndIf
		(&(cCommand))
	Next nX
MsUnLock()
End Transaction
::cAutoKey := cTable + Soma1(RIGHT(::cAutoKey, 6))
nRecno := (&(cTable+"->(Recno())"))
::oHash:Put(::cAutoKey,nRecno)

Return ::cAutoKey

method addAtendente(nQtd,lSRA,aFields) class GsGenRegs
Local aKeys 	:= {}
Local nX
Local nY
Local aInsert 	:= {}
Local cCDFUNC 	:= ""
Local cCodFunc 	:= ""
Local cCodCC 	:= ""
Local lSeek		:= .T.
Local cAa1Num	:= ""
Default nQtd 	:= 1
Default lSRA 	:= .T.
Default aFields := {}


For nX := 1 To nQtd
	aInsert := {}
	cCDFUNC := ""
	cCodFunc := ""
	cCodCC := ""
	lSeek := .T.
	If lSRA
		AADD(aInsert, {"RA_FILIAL", xFilial("SRA")})
		AADD(aInsert, {"RA_MAT", Soma1(GetMax("RA_MAT","SRA"))})
		AADD(aInsert, {"RA_NOME", "MINION " + cValToChar(nX)})
		AADD(aInsert, {"RA_NATURAL", "AC"})
		AADD(aInsert, {"RA_NACIONA", "10"})
		AADD(aInsert, {"RA_ESTCIVI", "C"})
		AADD(aInsert, {"RA_SEXO", "M"})
		AADD(aInsert, {"RA_NASC", cToD("04/01/1994")})
		AADD(aInsert, {"RA_GRINRAI", "10"})
		AADD(aInsert, {"RA_CC", GetCC()})
		AADD(aInsert, {"RA_ADMISSA", cToD("04/01/2019")})
		AADD(aInsert, {"RA_OPCAO", cToD("04/01/2019")})
		AADD(aInsert, {"RA_HRSMES", 200})
		AADD(aInsert, {"RA_HRSEMAN", 40})
		AADD(aInsert, {"RA_CODFUNC", GetVldReg('RJ_FUNCAO','SRJ')})
		AADD(aInsert, {"RA_PROCES", GetVldReg('RCJ_CODIGO','RCJ')})
		AADD(aInsert, {"RA_CATFUNC", 'A'})
		AADD(aInsert, {"RA_TIPOPGT", 'M'})
		AADD(aInsert, {"RA_TIPOADM", '1A'})
		AADD(aInsert, {"RA_VIEMRAI", '10'})
		AADD(aInsert, {"RA_NUMCP", '323319 '})
		AADD(aInsert, {"RA_SERCP", '00000'})
		AADD(aInsert, {"RA_TNOTRAB", GetVldReg('R6_TURNO','SR6')})
		For nY := 1 TO LEN(aFields)
			If "RA_" $ aFields[nY][1]
				If ASCAN(aInsert, {|a| a[1] == aFields[nY][1]}) > 0
					aInsert[ASCAN(aInsert, {|a| a[1] == aFields[nY][1]})][2] := aFields[nY][2] 
				Else
					AADD(aInsert, aFields[nY])
				EndIf
			EndIf
		Next nY
		cCodFunc := aInsert[ASCAN(aInsert, {|z| z[1] == "RA_CODFUNC"})][2]
		cCodCC := aInsert[ASCAN(aInsert, {|z| z[1] == "RA_CC"})][2]
		cCDFUNC := aInsert[ASCAN(aInsert, {|z| z[1] == "RA_MAT"})][2]
		AADD(aKeys, {"SRA",::insert("SRA", aInsert)})
		aInsert := {}
	EndIf
	AADD(aInsert, {"AA1_FILIAL", xFilial("AA1")})
	
	DbSelectArea("AA1")
	DbSetOrder(1)
	While lSeek
		cAa1Num	:= GetSx8Num("AA1","AA1_CODTEC")
		lSeek := DbSeek( xFilial('AA1')+ cAa1Num ) 
	EndDo
	
	AADD(aInsert, {"AA1_CODTEC", cAa1Num})
	AADD(aInsert, {"AA1_NOMTEC", "MINION " + cValToChar(nX)})
	AADD(aInsert, {"AA1_FUNCAO", IIF(!EMPTY(cCodFunc), cCodFunc, GetVldReg('RJ_FUNCAO','SRJ'))})
	AADD(aInsert, {"AA1_CC", IIF(!EMPTY(cCodCC), cCodCC,GetCC())})
	If !EMPTY(cCDFUNC)
		AADD(aInsert, {"AA1_CDFUNC", cCDFUNC})
	EndIf
	AADD(aInsert, {"AA1_VALOR",0})
	AADD(aInsert, {"AA1_CUSTO",0})
	AADD(aInsert, {"AA1_RATE", 0})
	AADD(aInsert, {"AA1_TIPO", '1'})
	AADD(aInsert, {"AA1_CONTRB", '0'})
	AADD(aInsert, {"AA1_ALOCA", '1'})
	AADD(aInsert, {"AA1_TIPMAR", '1'})
	AADD(aInsert, {"AA1_VISTOR", "2"})
	AADD(aInsert, {"AA1_VISVLR", "2"})
	AADD(aInsert, {"AA1_VISPRO", "2"})
	AADD(aInsert, {"AA1_IMPPRO", "2"})
	AADD(aInsert, {"AA1_CATEGO", "2"})
	AADD(aInsert, {"AA1_ALTVIS", "2"})
	AADD(aInsert, {"AA1_FTVIST", "2"})
	AADD(aInsert, {"AA1_CRMSIM", "2"})
	AADD(aInsert, {"AA1_MPONTO", "2"})
	AADD(aInsert, {"AA1_RSPMNT", "2"})
	AADD(aInsert, {"AA1_RSPTRA", "2"})
	If lSRA
		AADD(aInsert, {"AA1_FUNFIL", xFilial("SRA")})
	EndIf
	For nY := 1 TO LEN(aFields)
		If "AA1_" $ aFields[nY][1]
			If ASCAN(aInsert, {|a| a[1] == aFields[nY][1]}) > 0
				aInsert[ASCAN(aInsert, {|a| a[1] == aFields[nY][1]})][2] := aFields[nY][2] 
			Else
				AADD(aInsert, aFields[nY])
			EndIf
		EndIf
	Next nY
	AADD(aKeys, {"AA1",::insert("AA1", aInsert)})
	aInsert := {}
Next nX

Return aKeys

Static Function GetMax(cColumn, cTable, cCondition)
Local xRet
Local aArea := GetArea()
Local cColName := IIF(LEFT(cTable,1) == 'S', RIGHT(cTable,2), cTable)
Local cSql := " SELECT MAX(" + cColumn + ") C FROM " + RetSqlName( cTable ) + " WHERE D_E_L_E_T_ = ' ' AND " + cColName + "_FILIAL = '" + xFilial(cTable) + "' "
Local cAliasQry := GetNextAlias()
Default cCondition := ""
cSql += cCondition
cSql := ChangeQuery(cSql)
dbUseArea( .T., "TOPCONN", TCGENQRY(,,cSql),cAliasQry, .F., .T.)

xRet := (&("(cAliasQry)->(C)"))
(cAliasQry)->(dbCloseArea())
RestArea(aArea)
Return xRet

Static Function GetVldReg(cColumn, cTable, cCondition)
Local xRet
Local aArea := GetArea()
Local cColName := IIF(LEFT(cTable,1) == 'S', RIGHT(cTable,2), cTable)
Local cSql := " SELECT " + cColumn + " C FROM " + RetSqlName( cTable ) + " WHERE D_E_L_E_T_ = ' ' AND " + cColName + "_FILIAL = '" + xFilial(cTable) + "' "
Local cAliasQry := GetNextAlias()

Default cCondition := ""
cSql += cCondition
cSql := ChangeQuery(cSql)
dbUseArea( .T., "TOPCONN", TCGENQRY(,,cSql),cAliasQry, .F., .T.)

xRet := (&("(cAliasQry)->(C)"))
(cAliasQry)->(dbCloseArea())
RestArea(aArea)

Return xRet


Static Function GetCC()
Local cQry := GetNextAlias()
Local aArea := GetArea()

BeginSQL Alias cQry
	SELECT CTT.CTT_CUSTO
	  FROM %Table:CTT% CTT
	 WHERE CTT.CTT_FILIAL = %xFilial:CTT%
	   AND CTT.%NotDel%
	   AND CTT.CTT_CLASSE = '2'
	   AND CTT.CTT_BLOQ = '2'
EndSQL
cRet := (cQry)->(CTT_CUSTO)
(cQry)->(dbCloseArea())
RestArea(aArea)
Return cRet

method addOrcamento(cID, lAgrupado, aFields) class GsGenRegs
Local aInsert := {}
Local cCodProd := ""
Local cTes := ""
Local nY
Local cTfjNum	:= ""
Local lSeek		:= .T.

Default aFields := {}
Default lAgrupado := .T.
Begin Transaction
AADD(aInsert, {"TFJ_FILIAL",xFilial('TFJ')})

DbSelectArea("TFJ")
DbSetOrder(1)
While lSeek
	cTfjNum := GetSxeNum("TFJ","TFJ_CODIGO")
	lSeek 	:= DbSeek( xFilial('TFJ')+cTfjNum)
EndDo

AADD(aInsert, {"TFJ_CODIGO", cTfjNum})
AADD(aInsert, {"TFJ_ORCSIM",'1'})
AADD(aInsert, {"TFJ_ENTIDA",'1'})
AADD(aInsert, {"TFJ_CODENT", GetVldReg('A1_COD','SA1')})
AADD(aInsert, {"TFJ_LOJA", GetVldReg('A1_LOJA','SA1')})
AADD(aInsert, {"TFJ_CONDPG", GetVldReg('E4_CODIGO','SE4')})
AADD(aInsert, {"TFJ_AGRUP", '1'})
If lAgrupado
	AADD(aInsert, {"TFJ_GRPRH", (cCodProd := GetVldReg('B1_COD','SB1'))})
	AADD(aInsert, {"TFJ_GRPMI", cCodProd})
	AADD(aInsert, {"TFJ_GRPMC", cCodProd})
	AADD(aInsert, {"TFJ_GRPLE", cCodProd})
	AADD(aInsert, {"TFJ_ITEMRH", '01'})
	AADD(aInsert, {"TFJ_ITEMMI", '01'})
	AADD(aInsert, {"TFJ_ITEMMC", '01'})
	AADD(aInsert, {"TFJ_ITEMLE", '01'})
	AADD(aInsert, {"TFJ_TES", (cTes := GetVldReg('F4_CODIGO','SF4', " AND F4_CODIGO > '500' "))})
	AADD(aInsert, {"TFJ_TESMI", cTes})
	AADD(aInsert, {"TFJ_TESMC", cTes})
	AADD(aInsert, {"TFJ_TESLE", cTes})
EndIf
AADD(aInsert, {"TFJ_STATUS", '1'})
AADD(aInsert, {"TFJ_GESMAT", '1'})
AADD(aInsert, {"TFJ_CLIPED", '1'})
AADD(aInsert, {"TFJ_DSGCN", '2'})
AADD(aInsert, {"TFJ_ANTECI", '2'})
AADD(aInsert, {"TFJ_CNTREC", '2'})
AADD(aInsert, {"TFJ_RGMCX", '2'})

For nY := 1 TO LEN(aFields)
	If "TFJ_" $ aFields[nY][1]
		If ASCAN(aInsert, {|a| a[1] == aFields[nY][1]}) > 0
			aInsert[ASCAN(aInsert, {|a| a[1] == aFields[nY][1]})][2] := aFields[nY][2] 
		Else
			AADD(aInsert, aFields[nY])
		EndIf
	EndIf
Next nY
AADD(::aOrcs, {cID, ::insert("TFJ", aInsert) ,lAgrupado, {}})
End Transaction
return

method addLocal(cIdOrc, cIdLocal, aFields) class GsGenRegs
Local aInsert := {}
Local nPosTFJ := ASCAN(::aOrcs, {|a| a[1] == cIdOrc})
Local nRECTFJ := ::getRec(::aOrcs[nPosTFJ][2])
Local nY
Local lSeek		:= .T.
Local cTflNum	:= ""
Default aFields := {}

Begin Transaction
AADD(aInsert, {"TFL_FILIAL",xFilial('TFL')})

DbSelectArea("TFL")
DbSetOrder(1)
While lSeek
	cTflNum := GetSxeNum('TFL','TFL_CODIGO')
	lSeek	:= DbSeek(xFilial('TFL')+cTflNum)
EndDo

AADD(aInsert, {"TFL_CODIGO",cTflNum})
AADD(aInsert, {"TFL_LOCAL",GetVldReg('ABS_LOCAL','ABS')})
AADD(aInsert, {"TFL_DTINI",DATE()})
AADD(aInsert, {"TFL_DTFIM",DATE() + 365})
AADD(aInsert, {"TFL_PEDTIT",'1'})

TFJ->(DBgoTO(nRECTFJ))
AADD(aInsert, {"TFL_CODPAI",TFJ->TFJ_CODIGO})

For nY := 1 TO LEN(aFields)
	If "TFL_" $ aFields[nY][1]
		If ASCAN(aInsert, {|a| a[1] == aFields[nY][1]}) > 0
			aInsert[ASCAN(aInsert, {|a| a[1] == aFields[nY][1]})][2] := aFields[nY][2] 
		Else
			AADD(aInsert, aFields[nY])
		EndIf
	EndIf
Next nY

AADD(::aOrcs[nPosTFJ][4], {cIdLocal, ::insert("TFL", aInsert), {}})
End Transaction
return cTflNum

method addRH(cIdOrc, cIdLocal, cIdRH, aFields) class GsGenRegs
Local aInsert := {}
Local nPosTFJ := ASCAN(::aOrcs, {|a| a[1] == cIdOrc})
Local nPosTFL := ASCAN(::aOrcs[nPosTFJ][4], {|a| a[1] == cIdLocal})
Local nRECTFJ := ::getRec(::aOrcs[nPosTFJ][2])
Local nRECTFL := ::getRec(::aOrcs[nPosTFJ][4][nPosTFL][2])
Local nY
Local cCodPai
Local cCodProd
Local nTotal
Local lSeek		:= .T.
Local cTffNum	:= ""
Default aFields := {}
Begin Transaction
TFL->(DbGoTo(nRECTFL))
cCodPai := TFL->TFL_CODIGO

AADD(aInsert, {"TFF_FILIAL",xFilial('TFF')})

DbSelectArea("TFF")
DbSetOrder(1)
While lSeek
	cTffNum	:= GetSxeNum('TFF',"TFF_COD")
	lSeek	:= DbSeek( xFilial('TFF')+cTffNum)
EndDo

AADD(aInsert, {"TFF_COD",cTffNum})
AADD(aInsert, {"TFF_ITEM",Soma1(GetMax("TFF_ITEM","TFF"," AND TFF_CODPAI  = '" + cCodPai + "'"))})
AADD(aInsert, {"TFF_PRODUT",(cCodProd := GetVldReg("B5_COD","SB5", " AND B5_TPISERV = '4' "))})
AADD(aInsert, {"TFF_UM", POSICIONE("SB1",1,xFilial("SB1") + cCodProd, "B1_UM")})
AADD(aInsert, {"TFF_QTDVEN",10})
AADD(aInsert, {"TFF_PRCVEN",100})

TFL->(DbGoTo(nRECTFL))

AADD(aInsert, {"TFF_LOCAL",TFL->TFL_LOCAL})
AADD(aInsert, {"TFF_PERINI",TFL->TFL_DTINI})
AADD(aInsert, {"TFF_PERFIM",TFL->TFL_DTFIM})
AADD(aInsert, {"TFF_CODPAI",TFL->TFL_CODIGO})
AADD(aInsert, {"TFF_FUNCAO", GetVldReg('RJ_FUNCAO','SRJ')})
AADD(aInsert, {"TFF_TURNO",  GetVldReg('R6_TURNO','SR6')})
AADD(aInsert, {"TFF_COBCTR",'1'})
AADD(aInsert, {"TFF_INSALU",'1'})
AADD(aInsert, {"TFF_GRAUIN",'1'})
AADD(aInsert, {"TFF_PERICU",'1'})

For nY := 1 TO LEN(aFields)
	If "TFF_" $ aFields[nY][1]
		If ASCAN(aInsert, {|a| a[1] == aFields[nY][1]}) > 0
			aInsert[ASCAN(aInsert, {|a| a[1] == aFields[nY][1]})][2] := aFields[nY][2] 
		Else
			AADD(aInsert, aFields[nY])
		EndIf
	EndIf
Next nY

nTotal := aInsert[ASCAN(aInsert, {|a| a[1] == "TFF_QTDVEN"})][2] * aInsert[ASCAN(aInsert, {|a| a[1] == "TFF_PRCVEN"})][2]

TFL->(DbGoTo(nRECTFL))
RecLock("TFL", .F.)	
	TFL->TFL_TOTRH += nTotal
TFL->(MsUnLock())

AADD(::aOrcs[nPosTFJ][4][nPosTFL][3], {cIdRH, ::insert("TFF", aInsert), {}, 'RH'})
End Transaction
return cTffNum
 
method addMI(cIdOrc, cIdLocal, cIdRH, aFields) class GsGenRegs

return

method addMC(cIdOrc, cIdLocal, cIdRH, aFields) class GsGenRegs

return

method gerarContrt(cIdOrc, aFields) class GsGenRegs
Local aInsert := {}
Local aInsCNB := {}
Local aTmpCNC := {}
Local aTmpCNA := {}
Local aTmpCNF := {}
Local aTmpSE1 := {}
Local aTmpCPD := {}
Local aTmpCNB := {}
Local nPosTFJ := ASCAN(::aOrcs, {|a| a[1] == cIdOrc})
Local nRECTFL := ::getRec(::aOrcs[nPosTFJ][4][1][2]) //primeira TFL do orçamento
Local nRECTFJ := ::getRec(::aOrcs[nPosTFJ][2])
Local nRECTFF
Local dDataMin
Local dDataMax
Local nPosINI
Local nPosFIM
Local cCondPG
Local nValTotal := 0
Local cContrato := CN300Num()
Local aKeys := {}
Local cCodCli
Local cLoja
Local cNumSer
Local cCodProd
Local nY
Local nX
Local nZ
Local cCNANum
Local cCronog

Default aFields := {}
Begin Transaction
TFJ->(DbGoTo(nRECTFJ))
cCondPG := TFJ->TFJ_CONDPG

AADD(aInsert, {"AA3_FILIAL",xFilial('AA3')})
AADD(aInsert, {"AA3_CODCLI",(cCodCli := TFJ->TFJ_CODENT)})
AADD(aInsert, {"AA3_LOJA",(cLoja := TFJ->TFJ_LOJA)})
AADD(aInsert, {"AA3_CODPRO",(cCodProd := TFJ->TFJ_GRPRH)})
AADD(aInsert, {"AA3_NUMSER", (cNumSer := Soma1(GetMax("AA3_NUMSER","AA3")))})
AADD(aInsert, {"AA3_DTVEND", DATE()})
AADD(aInsert, {"AA3_DTGAR",DATE() + 120})
AADD(aInsert, {"AA3_CONTRT", cContrato})
AADD(aInsert, {"AA3_STATUS", '01'})
AADD(aInsert, {"AA3_HORDIA", 8})

TFL->(DbGoTo(nRECTFL))
AADD(aInsert, {"AA3_CODLOC", TFL->TFL_LOCAL})
AADD(aInsert, {"AA3_EQALOC", '2'})
AADD(aInsert, {"AA3_MANPRE", '2'})
AADD(aInsert, {"AA3_ORIGEM", "CN9"})
AADD(aInsert, {"AA3_EXIGNF", "1"})
AADD(aInsert, {"AA3_EQ3", "2"})
AADD(aInsert, {"AA3_FILORI", cFilant})
AADD(aInsert, {"AA3_MSBLQL", "2"})
AADD(aInsert, {"AA3_OSMONT", "2"})
AADD(aInsert, {"AA3_HMEATV", "2"})
AADD(aInsert, {"AA3_CONSEP", .F.})
AADD(aInsert, {"AA3_CONRET", .F.})
For nY := 1 TO LEN(aFields)
	If "AA3_" $ aFields[nY][1]
		If ASCAN(aInsert, {|a| a[1] == aFields[nY][1]}) > 0
			aInsert[ASCAN(aInsert, {|a| a[1] == aFields[nY][1]})][2] := aFields[nY][2] 
		Else
			AADD(aInsert, aFields[nY])
		EndIf
	EndIf
Next nY
AADD(aKeys, {"AA3",::insert("AA3", aInsert)})
aInsert := {}

AADD(aInsert, {"AAF_FILIAL",xFilial('AAF')})
AADD(aInsert, {"AAF_CODCLI",cCodCli })
AADD(aInsert, {"AAF_LOJA",cLoja })
AADD(aInsert, {"AAF_CODPRO", cCodProd})
AADD(aInsert, {"AAF_NUMSER", cNumSer})
AADD(aInsert, {"AAF_NSERAC", cNumSer})
AADD(aInsert, {"AAF_DTINI", DATE()})
AADD(aInsert, {"AAF_PRODAC", cCodProd})
AADD(aInsert, {"AAF_LOGINI", 'CADASTRO AMARRACAO CLIENTE X EQPTO'}) 
For nY := 1 TO LEN(aFields)
	If "AAF_" $ aFields[nY][1]
		If ASCAN(aInsert, {|a| a[1] == aFields[nY][1]}) > 0
			aInsert[ASCAN(aInsert, {|a| a[1] == aFields[nY][1]})][2] := aFields[nY][2] 
		Else
			AADD(aInsert, aFields[nY])
		EndIf
	EndIf
Next nY
AADD(aKeys, {"AAF",::insert("AAF", aInsert)})
aInsert := {}

AADD(aInsert, {"CN9_FILIAL",xFilial('CN9')}) 
AADD(aInsert, {"CN9_NUMERO", cContrato})
For nY := 1 TO LEN(::aOrcs[nPosTFJ][4])
	
	nRECTFL := ::getRec(::aOrcs[nPosTFJ][4][nY][2])
	TFL->(DbGoTo(nRECTFL))
	
	nValTotal += TFL->TFL_TOTRH
	nValTotal += TFL->TFL_TOTMI
	nValTotal += TFL->TFL_TOTMC
	nValTotal += TFL->TFL_TOTLE
	
	If EMPTY(dDataMin)
		dDataMin := TFL->TFL_DTINI
	EndIf
	
	If EMPTY(dDataMax)
		dDataMax := TFL->TFL_DTFIM
	EndIf
	
	If dDataMin > TFL->TFL_DTINI
		dDataMin := TFL->TFL_DTINI
	EndIf
	
	If dDataMax < TFL->TFL_DTFIM
		dDataMax := TFL->TFL_DTFIM
	EndIf
Next nY

AADD(aInsert, {"CN9_DTINIC", dDataMin})
AADD(aInsert, {"CN9_DTASSI", dDataMin})
AADD(aInsert, {"CN9_UNVIGE", '1'})
AADD(aInsert, {"CN9_VIGE", dDataMax - dDataMin + 1}) 
AADD(aInsert, {"CN9_DTFIM", dDataMax + 1})
AADD(aInsert, {"CN9_MOEDA", 1})
AADD(aInsert, {"CN9_CONDPG", cCondPG})
AADD(aInsert, {"CN9_TPCTO", GetVldReg('CN1_CODIGO','CN1', " AND CN1_ESPCTR = '2' AND CN1_MEDEVE = '2' AND CN1_CTRFIX = '1' AND CN1_VLRPRV = '1' ")})
AADD(aInsert, {"CN9_VLINI", nValTotal})
AADD(aInsert, {"CN9_VLATU", nValTotal})
AADD(aInsert, {"CN9_FLGREJ", '2'})
AADD(aInsert, {"CN9_FLGCAU", '2'})
AADD(aInsert, {"CN9_TPCAUC", '1'})
AADD(aInsert, {"CN9_SALDO", nValTotal})
AADD(aInsert, {"CN9_DTPROP", dDataMin})
AADD(aInsert, {"CN9_SITUAC", '05'})
AADD(aInsert, {"CN9_VLDCTR", '1'})
AADD(aInsert, {"CN9_FILORI", cFilAnt})
AADD(aInsert, {"CN9_ASSINA", dDataMin})
AADD(aInsert, {"CN9_ESPCTR", '2'})
AADD(aInsert, {"CN9_FILCTR", xFilial('CN9')})
For nY := 1 TO LEN(aFields)
	If "CN9_" $ aFields[nY][1]
		If ASCAN(aInsert, {|a| a[1] == aFields[nY][1]}) > 0
			aInsert[ASCAN(aInsert, {|a| a[1] == aFields[nY][1]})][2] := aFields[nY][2] 
		Else
			AADD(aInsert, aFields[nY])
		EndIf
	EndIf
Next nY
AADD(aKeys, {"CN9",::insert("CN9", aInsert)})
aInsert := {}

TFJ->(DbGoTo(nRECTFJ))
RecLock("TFJ", .F.)
	TFJ->TFJ_CONTRT := cContrato
TFJ->(MsUnlock())

AADD(aInsert, {"CNN_FILIAL",xFilial('CNN')}) 
AADD(aInsert, {"CNN_CONTRA", cContrato})
AADD(aInsert, {"CNN_USRCOD", RetCodUsr()})
AADD(aInsert, {"CNN_TRACOD", '001'})
For nY := 1 TO LEN(aFields)
	If "CNN_" $ aFields[nY][1]
		If ASCAN(aInsert, {|a| a[1] == aFields[nY][1]}) > 0
			aInsert[ASCAN(aInsert, {|a| a[1] == aFields[nY][1]})][2] := aFields[nY][2] 
		Else
			AADD(aInsert, aFields[nY])
		EndIf
	EndIf
Next nY
AADD(aKeys, {"CNN",::insert("CNN", aInsert)})
aInsert := {}

AADD(aTmpCNC, {"CNC_FILIAL",xFilial('CNC')})
AADD(aTmpCNC, {"CNC_NUMERO", cContrato})
AADD(aTmpCNC, {"CNC_CLIENT", cCodCli})
AADD(aTmpCNC, {"CNC_LOJACL", cLoja})

For nY := 1 TO LEN(aFields)
	If "CNC_" $ aFields[nY][1]
		If ASCAN(aTmpCNC, {|a| a[1] == aFields[nY][1]}) > 0
			aTmpCNC[ASCAN(aTmpCNC, {|a| a[1] == aFields[nY][1]})][2] := aFields[nY][2] 
		Else
			AADD(aTmpCNC, aFields[nY])
		EndIf
	EndIf
Next nY

AADD(aInsert, ACLONE(aTmpCNC))
aTmpCNC := {}

For nY := 1 TO LEN(::aOrcs[nPosTFJ][4])
	nRECTFL := ::getRec(::aOrcs[nPosTFJ][4][nY][2])
	TFL->(dbGoTO(nRECTFL))
	
	For nX := 1 TO LEN(aInsert)
		If ASCAN(aInsert,{|a| a[3][2] + a[4][2] == POSICIONE("ABS",1,xFilial("ABS") + TFL->TFL_LOCAL, "ABS_CODIGO") +;
		 		POSICIONE("ABS",1,xFilial("ABS") +	TFL->TFL_LOCAL, "ABS_LOJA")}) == 0 
			aTmpCNC := {}
			AADD(aTmpCNC, {"CNC_FILIAL",xFilial('CNC')})
			AADD(aTmpCNC, {"CNC_NUMERO", cContrato})
			AADD(aTmpCNC, {"CNC_CLIENT", POSICIONE("ABS",1,xFilial("ABS") + TFL->TFL_LOCAL, "ABS_CODIGO")})
			AADD(aTmpCNC, {"CNC_LOJACL", POSICIONE("ABS",1,xFilial("ABS") + TFL->TFL_LOCAL, "ABS_LOJA")})
			For nZ := 1 TO LEN(aFields)
				If "CNC_" $ aFields[nZ][1]
					If ASCAN(aTmpCNC, {|a| a[1] == aFields[nZ][1]}) > 0
						aTmpCNC[ASCAN(aTmpCNC, {|a| a[1] == aFields[nZ][1]})][2] := aFields[nZ][2] 
					Else
						AADD(aTmpCNC, aFields[nZ])
					EndIf
				EndIf
			Next nZ
			AADD(aInsert, ACLONE(aTmpCNC))
		EndIf
	Next nX
Next nY

For nX := 1 To LEN(aInsert)
	AADD(aKeys, {"CNC",::insert("CNC", aInsert[nX])})
Next nX

aInsert := {}
cCNANum := ""
cCronog := ""
cSE1Num := ""
cCNB_ITEM := ""

For nY := 1 TO LEN(::aOrcs[nPosTFJ][4])
	nRECTFL := ::getRec(::aOrcs[nPosTFJ][4][nY][2])
	TFJ->(DbGoTo(nRECTFJ))
	TFL->(dbGoTO(nRECTFL))
	aTmpCNA := {}
	aTmpCNF := {}
	aTmpSE1 := {}
	aInsCNB := {}
	aTmpCPD := {}
	
	AADD(aTmpCNA, {"CNA_FILIAL",xFilial('CNA')})
	AADD(aTmpCNA, {"CNA_CONTRA",cContrato})
	If EMPTY(cCNANum)
		AADD(aTmpCNA, {"CNA_NUMERO", (cCNANum := Soma1(GetMax("CNA_NUMERO","CNA"," AND CNA_NUMERO = '" + cContrato + "'"))) })
	Else
		AADD(aTmpCNA, {"CNA_NUMERO", (cCNANum := Soma1(cCNANum)) })
	EndIf
	AADD(aTmpCNA, {"CNA_CLIENT", POSICIONE("ABS",1,xFilial("ABS") + TFL->TFL_LOCAL, "ABS_CODIGO")}) 
	AADD(aTmpCNA, {"CNA_LOJACL", POSICIONE("ABS",1,xFilial("ABS") + TFL->TFL_LOCAL, "ABS_LOJA") })
	AADD(aTmpCNA, {"CNA_DTINI", TFL->TFL_DTINI})
	AADD(aTmpCNA, {"CNA_VLTOT", TFL->TFL_TOTRH + TFL->TFL_TOTMI + TFL->TFL_TOTMC + TFL->TFL_TOTLE })
	AADD(aTmpCNA, {"CNA_SALDO", TFL->TFL_TOTRH + TFL->TFL_TOTMI + TFL->TFL_TOTMC + TFL->TFL_TOTLE })
	AADD(aTmpCNA, {"CNA_TIPPLA", GetVldReg('CNL_CODIGO','CNL', " AND CNL_LMTAVS = '0' AND CNL_MEDEVE = '0' AND CNL_MEDAUT = '0' AND CNL_CTRFIX = '0' AND CNL_VLRPRV = '0' AND CNL_CROCTB = '0' AND CNL_CROFIS = '0' ")})
	AADD(aTmpCNA, {"CNA_DTFIM", TFL->TFL_DTFIM})
	If EMPTY(cCronog)
		AADD(aTmpCNA, {"CNA_CRONOG", (cCronog := Soma1(GetMax("CNA_CRONOG","CNA"))) })
	Else
		AADD(aTmpCNA, {"CNA_CRONOG", (cCronog := Soma1(cCronog) )})
	EndIf
	AADD(aTmpCNA, {"CNA_FLREAJ", '2'})
	AADD(aTmpCNA, {"CNA_PRORAT", '2'})
	AADD(aTmpCNA, {"CNA_RPGANT", '2'})
	
	For nZ := 1 TO LEN(aFields)
		If "CNA_" $ aFields[nZ][1]
			If ASCAN(aTmpCNA, {|a| a[1] == aFields[nZ][1]}) > 0
				aTmpCNA[ASCAN(aTmpCNA, {|a| a[1] == aFields[nZ][1]})][2] := aFields[nZ][2] 
			Else
				AADD(aTmpCNA, aFields[nZ])
			EndIf
		EndIf
	Next nZ
	
	TFL->(dbGoTO(nRECTFL))
	RecLock("TFL",.F.)
		TFL->TFL_PLAN := cCNANum
		TFL->TFL_CONTRT := cContrato
		TFL->TFL_ITPLRH := Soma1(REPLICATE("0", TamSX3("TFL_ITPLRH")[1]))
		TFL->TFL_ITPLMI := Soma1(REPLICATE("0", TamSX3("TFL_ITPLMI")[1]))
		TFL->TFL_ITPLMC := Soma1(REPLICATE("0", TamSX3("TFL_ITPLMC")[1]))
		TFL->TFL_ITPLLE := Soma1(REPLICATE("0", TamSX3("TFL_ITPLLE")[1]))
	TFL->(MsUnlock())
	
	AADD(aTmpCNF, {"CNF_FILIAL",xFilial('CNF')})
	AADD(aTmpCNF, {"CNF_NUMERO",cCronog})
	AADD(aTmpCNF, {"CNF_CONTRA",cContrato})
	AADD(aTmpCNF, {"CNF_PARCEL",'1'})
	AADD(aTmpCNF, {"CNF_COMPET", STRZERO(MONTH(TFL->TFL_DTINI),2) + '/' + cValToChar(YEAR(TFL->TFL_DTINI))})
	AADD(aTmpCNF, {"CNF_VLPREV", TFL->TFL_TOTRH + TFL->TFL_TOTMI + TFL->TFL_TOTMC + TFL->TFL_TOTLE })
	AADD(aTmpCNF, {"CNF_SALDO", TFL->TFL_TOTRH + TFL->TFL_TOTMI + TFL->TFL_TOTMC + TFL->TFL_TOTLE })
	AADD(aTmpCNF, {"CNF_PRUMED", TFL->TFL_DTINI})
	AADD(aTmpCNF, {"CNF_DTVENC", TFL->TFL_DTINI})
	AADD(aTmpCNF, {"CNF_MAXPAR", 1})
	AADD(aTmpCNF, {"CNF_TXMOED", 1})
	AADD(aTmpCNF, {"CNF_PERIOD",'1'})
	AADD(aTmpCNF, {"CNF_DIAPAR", 30})
	AADD(aTmpCNF, {"CNF_NUMPLA", cCNANum})
	
	For nZ := 1 TO LEN(aFields)
		If "CNF_" $ aFields[nZ][1]
			If ASCAN(aTmpCNF, {|a| a[1] == aFields[nZ][1]}) > 0
				aTmpCNF[ASCAN(aTmpCNF, {|a| a[1] == aFields[nZ][1]})][2] := aFields[nZ][2] 
			Else
				AADD(aTmpCNF, aFields[nZ])
			EndIf
		EndIf
	Next nZ
	
	AADD(aTmpSE1, {"E1_FILIAL",xFilial('SE1')})
	AADD(aTmpSE1, {"E1_PREFIXO",'CTR'})
	If EMPTY(cSE1Num)
		AADD(aTmpSE1, {"E1_NUM", (cSE1Num := Soma1(GetMax("E1_NUM","SE1")))})
	Else
		AADD(aTmpSE1, {"E1_NUM", (cSE1Num := Soma1(cSE1Num))})
	EndIf
	AADD(aTmpSE1, {"E1_PARCELA", '1'})
	AADD(aTmpSE1, {"E1_TIPO", 'PR' })
	AADD(aTmpSE1, {"E1_CLIENTE", POSICIONE("ABS",1,xFilial("ABS") + TFL->TFL_LOCAL, "ABS_CODIGO") })
	AADD(aTmpSE1, {"E1_LOJA", POSICIONE("ABS",1,xFilial("ABS") + TFL->TFL_LOCAL, "ABS_LOJA") })
	AADD(aTmpSE1, {"E1_NOMCLI", LEFT(POSICIONE("SA1",1,xFilial("SA1") +;
	 							POSICIONE("ABS",1,xFilial("ABS") +;
	 							TFL->TFL_LOCAL, "ABS_CODIGO") +;
	 							POSICIONE("ABS",1,xFilial("ABS") +;
	 							TFL->TFL_LOCAL, "ABS_LOJA"), "A1_NOME"),20) })
	AADD(aTmpSE1, {"E1_EMISSAO", TFL->TFL_DTINI}) 
	AADD(aTmpSE1, {"E1_VENCTO", TFL->TFL_DTINI})
	AADD(aTmpSE1, {"E1_VENCREA", TFL->TFL_DTINI})
	AADD(aTmpSE1, {"E1_VENCORI", TFL->TFL_DTINI})
	AADD(aTmpSE1, {"E1_VALOR",TFL->TFL_TOTRH + TFL->TFL_TOTMI + TFL->TFL_TOTMC + TFL->TFL_TOTLE})
	AADD(aTmpSE1, {"E1_SALDO",TFL->TFL_TOTRH + TFL->TFL_TOTMI + TFL->TFL_TOTMC + TFL->TFL_TOTLE})
	AADD(aTmpSE1, {"E1_VLCRUZ",TFL->TFL_TOTRH + TFL->TFL_TOTMI + TFL->TFL_TOTMC + TFL->TFL_TOTLE})
	AADD(aTmpSE1, {"E1_EMIS1", TFL->TFL_DTINI})
	AADD(aTmpSE1, {"E1_MOEDA", 1})
	AADD(aTmpSE1, {"E1_STATUS", 'A'})
	AADD(aTmpSE1, {"E1_ORIGEM", 'CNTA100'})
	AADD(aTmpSE1, {"E1_FLUXO", 'S' })
	AADD(aTmpSE1, {"E1_FILORIG",cFilAnt})
	AADD(aTmpSE1, {"E1_MSFIL",cFilAnt})
	AADD(aTmpSE1, {"E1_MSEMP",cEmpAnt})
	AADD(aTmpSE1, {"E1_MDPLANI", cCNANum})
	AADD(aTmpSE1, {"E1_MDCRON", cCronog})
	AADD(aTmpSE1, {"E1_MDCONTR",cContrato})
	AADD(aTmpSE1, {"E1_MDPARCE",'1'})
	AADD(aTmpSE1, {"E1_RELATO",'2'})
	AADD(aTmpSE1, {"E1_TPDESC",'C'})
	
	For nZ := 1 TO LEN(aFields)
		If "E1_" $ aFields[nZ][1]
			If ASCAN(aTmpSE1, {|a| a[1] == aFields[nZ][1]}) > 0
				aTmpSE1[ASCAN(aTmpSE1, {|a| a[1] == aFields[nZ][1]})][2] := aFields[nZ][2] 
			Else
				AADD(aTmpSE1, aFields[nZ])
			EndIf
		EndIf
	Next nZ
	
	AADD(aTmpCPD, {"CPD_FILIAL",xFilial('CPD')})
	AADD(aTmpCPD, {"CPD_CONTRA",cContrato})
	AADD(aTmpCPD, {"CPD_NUMPLA",cCNANum})
	AADD(aTmpCPD, {"CPD_FILAUT",cFilAnt})
	
	For nZ := 1 TO LEN(aFields)
		If "CPD_" $ aFields[nZ][1]
			If ASCAN(aTmpCPD, {|a| a[1] == aFields[nZ][1]}) > 0
				aTmpCPD[ASCAN(aTmpCPD, {|a| a[1] == aFields[nZ][1]})][2] := aFields[nZ][2] 
			Else
				AADD(aTmpCPD, aFields[nZ])
			EndIf
		EndIf
	Next nZ
	
	AADD(aTmpCNB, {"CNB_FILIAL",xFilial('CNB')})
	AADD(aTmpCNB, {"CNB_NUMERO",cCNANum})
	AADD(aTmpCNB, {"CNB_ITEM", (cCNB_ITEM := Soma1(GetMax("CNB_ITEM","CNB"," AND CNB_NUMERO = '" + cCNANum + "' AND CNB_CONTRA = '" + cContrato + "' ")))})
	AADD(aTmpCNB, {"CNB_CONTRA",cContrato})
	AADD(aTmpCNB, {"CNB_PRODUT",TFJ->TFJ_GRPRH})
	AADD(aTmpCNB, {"CNB_DESCRI",POSICIONE("SB1",1,xFilial("SB1") + TFJ->TFJ_GRPRH,"B1_DESC")})
	AADD(aTmpCNB, {"CNB_UM",POSICIONE("SB1",1,xFilial("SB1") + TFJ->TFJ_GRPRH,"B1_UM")})
	AADD(aTmpCNB, {"CNB_QUANT",1})
	AADD(aTmpCNB, {"CNB_VLUNIT",TFL->TFL_TOTRH})
	AADD(aTmpCNB, {"CNB_VLTOT",TFL->TFL_TOTRH})
	AADD(aTmpCNB, {"CNB_DTCAD",TFL->TFL_DTINI})
	AADD(aTmpCNB, {"CNB_RATEIO",'2'})
	AADD(aTmpCNB, {"CNB_PRCORI",TFL->TFL_TOTRH})
	AADD(aTmpCNB, {"CNB_QTDORI",1})
	AADD(aTmpCNB, {"CNB_SLDMED",1})
	AADD(aTmpCNB, {"CNB_SLDREC",1})
	AADD(aTmpCNB, {"CNB_FLGCMS",'1'})
	AADD(aTmpCNB, {"CNB_TS",TFJ->TFJ_TES})
	AADD(aTmpCNB, {"CNB_GERBIN",'2'})
	AADD(aTmpCNB, {"CNB_BASINS",'2'})
	AADD(aTmpCNB, {"CNB_FILORI",cFilAnt})
	AADD(aTmpCNB, {"CNB_PEDTIT",'1'})
	AADD(aTmpCNB, {"CNB_CC",POSICIONE("ABS",1,xFilial("ABS") + TFL->TFL_LOCAL,"ABS_CCUSTO")})
	AADD(aTmpCNB, {"CNB_RJRTO",.F.})
	AADD(aTmpCNB, {"CNB_ATIVO",'1'})
	AADD(aTmpCNB, {"CNB_FLREAJ",'2'})
	
	For nZ := 1 TO LEN(aFields)
		If "CNB_" $ aFields[nZ][1]
			If ASCAN(aTmpCNB, {|a| a[1] == aFields[nZ][1]}) > 0
				aTmpCNB[ASCAN(aTmpCNB, {|a| a[1] == aFields[nZ][1]})][2] := aFields[nZ][2] 
			Else
				AADD(aTmpCNB, aFields[nZ])
			EndIf
		EndIf
	Next nZ
	
	AADD(aInsCNB, ACLONE(aTmpCNB))
	aTmpCNB := {}
	If TFJ->TFJ_GRPMI == aInsCNB[1][5][2]
		aInsCNB[1][9][2] += TFL->TFL_TOTMI
		aInsCNB[1][10][2] += TFL->TFL_TOTMI
		aInsCNB[1][13][2] += TFL->TFL_TOTMI
	Else
		AADD(aTmpCNB, {"CNB_FILIAL",xFilial('CNB')})
		AADD(aTmpCNB, {"CNB_NUMERO",cCNANum})
		AADD(aTmpCNB, {"CNB_ITEM",(cCNB_ITEM := Soma1(cCNB_ITEM))})
		AADD(aTmpCNB, {"CNB_CONTRA",cContrato})
		AADD(aTmpCNB, {"CNB_PRODUT",TFJ->TFJ_GRPMI})
		AADD(aTmpCNB, {"CNB_DESCRI",POSICIONE("SB1",1,xFilial("SB1") + TFJ->TFJ_GRPMI,"B1_DESC")})
		AADD(aTmpCNB, {"CNB_UM",POSICIONE("SB1",1,xFilial("SB1") + TFJ->TFJ_GRPMI,"B1_UM")})
		AADD(aTmpCNB, {"CNB_QUANT",1})
		AADD(aTmpCNB, {"CNB_VLUNIT",TFL->TFL_TOTMI})
		AADD(aTmpCNB, {"CNB_VLTOT",TFL->TFL_TOTMI})
		AADD(aTmpCNB, {"CNB_DTCAD",TFL->TFL_DTINI})
		AADD(aTmpCNB, {"CNB_RATEIO",'2'})
		AADD(aTmpCNB, {"CNB_PRCORI",TFL->TFL_TOTMI})
		AADD(aTmpCNB, {"CNB_QTDORI",1})
		AADD(aTmpCNB, {"CNB_SLDMED",1})
		AADD(aTmpCNB, {"CNB_SLDREC",1})
		AADD(aTmpCNB, {"CNB_FLGCMS",'1'})
		AADD(aTmpCNB, {"CNB_TS",TFJ->TFJ_TESMI})
		AADD(aTmpCNB, {"CNB_GERBIN",'2'})
		AADD(aTmpCNB, {"CNB_BASINS",'2'})
		AADD(aTmpCNB, {"CNB_FILORI",cFilAnt})
		AADD(aTmpCNB, {"CNB_PEDTIT",'1'})
		AADD(aTmpCNB, {"CNB_CC",POSICIONE("ABS",1,xFilial("ABS") + TFL->TFL_LOCAL,"ABS_CCUSTO")})
		AADD(aTmpCNB, {"CNB_RJRTO",'F'})
		AADD(aTmpCNB, {"CNB_ATIVO",'1'})
		AADD(aTmpCNB, {"CNB_FLREAJ",'2'})
		
		For nZ := 1 TO LEN(aFields)
			If "CNB_" $ aFields[nZ][1]
				If ASCAN(aTmpCNB, {|a| a[1] == aFields[nZ][1]}) > 0
					aTmpCNB[ASCAN(aTmpCNB, {|a| a[1] == aFields[nZ][1]})][2] := aFields[nZ][2] 
				Else
					AADD(aTmpCNB, aFields[nZ])
				EndIf
			EndIf
		Next nZ
		
		AADD(aInsCNB, ACLONE(aTmpCNB))
		aTmpCNB := {}
	EndIf
	For nX := 1 TO LEN(aInsCNB)
		If TFJ->TFJ_GRPMC == aInsCNB[nX][5][2]
			aInsCNB[nX][9][2] += TFL->TFL_TOTMC
			aInsCNB[nX][10][2] += TFL->TFL_TOTMC
			aInsCNB[nX][13][2] += TFL->TFL_TOTMC
		Else
			AADD(aTmpCNB, {"CNB_FILIAL",xFilial('CNB')})
			AADD(aTmpCNB, {"CNB_NUMERO",cCNANum})
			AADD(aTmpCNB, {"CNB_ITEM",(cCNB_ITEM := Soma1(cCNB_ITEM))})
			AADD(aTmpCNB, {"CNB_CONTRA",cContrato})
			AADD(aTmpCNB, {"CNB_PRODUT",TFJ->TFJ_GRPMC})
			AADD(aTmpCNB, {"CNB_DESCRI",POSICIONE("SB1",1,xFilial("SB1") + TFJ->TFJ_GRPMC,"B1_DESC")})
			AADD(aTmpCNB, {"CNB_UM",POSICIONE("SB1",1,xFilial("SB1") + TFJ->TFJ_GRPMC,"B1_UM")})
			AADD(aTmpCNB, {"CNB_QUANT",1})
			AADD(aTmpCNB, {"CNB_VLUNIT",TFL->TFL_TOTMC})
			AADD(aTmpCNB, {"CNB_VLTOT",TFL->TFL_TOTMC})
			AADD(aTmpCNB, {"CNB_DTCAD",TFL->TFL_DTINC})
			AADD(aTmpCNB, {"CNB_RATEIO",'2'})
			AADD(aTmpCNB, {"CNB_PRCORI",TFL->TFL_TOTMC})
			AADD(aTmpCNB, {"CNB_QTDORI",1})
			AADD(aTmpCNB, {"CNB_SLDMED",1})
			AADD(aTmpCNB, {"CNB_SLDREC",1})
			AADD(aTmpCNB, {"CNB_FLGCMS",'1'})
			AADD(aTmpCNB, {"CNB_TS",TFJ->TFJ_TESMC})
			AADD(aTmpCNB, {"CNB_GERBIN",'2'})
			AADD(aTmpCNB, {"CNB_BASINS",'2'})
			AADD(aTmpCNB, {"CNB_FILORI",cFilAnt})
			AADD(aTmpCNB, {"CNB_PEDTIT",'1'})
			AADD(aTmpCNB, {"CNB_CC",POSICIONE("ABS",1,xFilial("ABS") + TFL->TFL_LOCAL,"ABS_CCUSTO")})
			AADD(aTmpCNB, {"CNB_RJRTO",'F'})
			AADD(aTmpCNB, {"CNB_ATIVO",'1'})
			AADD(aTmpCNB, {"CNB_FLREAJ",'2'})
			
			For nZ := 1 TO LEN(aFields)
				If "CNB_" $ aFields[nZ][1]
					If ASCAN(aTmpCNB, {|a| a[1] == aFields[nZ][1]}) > 0
						aTmpCNB[ASCAN(aTmpCNB, {|a| a[1] == aFields[nZ][1]})][2] := aFields[nZ][2] 
					Else
						AADD(aTmpCNB, aFields[nZ])
					EndIf
				EndIf
			Next nZ
			
			AADD(aInsCNB, ACLONE(aTmpCNB))
			aTmpCNB := {}
		EndIf
	Next nX
	
	AADD(aKeys, {"CNA",::insert("CNA", aTmpCNA)})
	aTmpCNA := {}

	AADD(aKeys, {"CNF",::insert("CNF", aTmpCNF)})
	aTmpCNF := {}
	
	AADD(aKeys, {"SE1",::insert("SE1", aTmpSE1)})
	aTmpSE1 := {}
	
	AADD(aKeys, {"CPD",::insert("CPD", aTmpCPD)})
	aTmpCPD := {}
	
	For nZ := 1 TO LEN(aInsCNB)
		AADD(aKeys, {"CNB",::insert("CNB", aInsCNB[nZ])})
	Next nZ
	aInsCNB := {}
	
	For nX := 1 TO LEN(::aOrcs[nPosTFJ][4][nY][3])
		cABQ_ITEM := ""
		If ::aOrcs[nPosTFJ][4][nY][3][nX][4] == 'RH'
			aInsert := {}
			nRECTFF := ::getRec(::aOrcs[nPosTFJ][4][nY][3][nX][2])
			TFF->(DbGoTo(nRECTFF))
			RecLock("TFF", .F.)
				TFF->TFF_CONTRT := cContrato
			TFF->(MsUnlock())
			AADD(aInsert, {"ABQ_FILIAL",xFilial('ABQ')}) 
			AADD(aInsert, {"ABQ_CONTRT", cContrato})
			If EMPTY(cABQ_ITEM)
				AADD(aInsert, {"ABQ_ITEM", (cABQ_ITEM := Soma1(GetMax("ABQ_ITEM","ABQ"," AND ABQ_CONTRT  = '" + cContrato + "'")))})
			Else
				AADD(aInsert, {"ABQ_ITEM", (cABQ_ITEM := Soma1(cABQ_ITEM))})
			Endif
			AADD(aInsert, {"ABQ_PRODUT", TFF->TFF_PRODUT})
			AADD(aInsert, {"ABQ_TPPROD",'2'})
			AADD(aInsert, {"ABQ_TPREC",'1'})
			AADD(aInsert, {"ABQ_FUNCAO", TFF->TFF_FUNCAO})
			AADD(aInsert, {"ABQ_PERINI", TFF->TFF_PERINI})
			AADD(aInsert, {"ABQ_PERFIM", TFF->TFF_PERFIM})
			AADD(aInsert, {"ABQ_TURNO", TFF->TFF_TURNO})
			AADD(aInsert, {"ABQ_HRSEST",10000}) //no produto ele chama a CriaCalend pra calcular isso
			AADD(aInsert, {"ABQ_FATOR", 10})
			AADD(aInsert, {"ABQ_TOTAL", 100000})
			AADD(aInsert, {"ABQ_SALDO", 100000})
			AADD(aInsert, {"ABQ_ORIGEM", 'CN9'})
			AADD(aInsert, {"ABQ_CODTFF", TFF->TFF_COD})
			AADD(aInsert, {"ABQ_LOCAL", TFF->TFF_LOCAL})
			AADD(aInsert, {"ABQ_FILTFF", TFF->TFF_FILIAL})
			
			For nZ := 1 TO LEN(aFields)
				If "ABQ_" $ aFields[nZ][1]
					If ASCAN(aInsert, {|a| a[1] == aFields[nZ][1]}) > 0
						aInsert[ASCAN(aInsert, {|a| a[1] == aFields[nZ][1]})][2] := aFields[nZ][2] 
					Else
						AADD(aInsert, aFields[nZ])
					EndIf
				EndIf
			Next nZ
			AADD(aKeys, {"ABQ",::insert("ABQ", aInsert)})
			aInsert := {}
		EndIf
	Next nX
	
Next nY

conout("Done !")

End Transaction
return cContrato