#include 'protheus.ch'

//	@author Mateus Boiani
//	@since 31/12/2018

/*
Exemplo de utilização:

//--------------------------------------------
METHOD TEC870_076() CLASS TECA870TestCase
	Local oHelper	:=	FWTestHelper():New()
	Local cQuery
	Local oMdlRev
	// [1] Instancio a ferramenta
	Local oAuto := AutoCheck():New()
	
	// [2] Indico quando deve começar a verificar as alterações
	oAuto:StartLogging()
	
	oHelper:ChangeFil("D MG 01")
	oHelper:Activate()
	
	At870ExcR("4","00000000539","TECOP12000016IM","001")
	
	oHelper:UTFindReg( "TFJ", 1, '00000000537')
	
	oMdlRev := FwLoadModel('TECA740')
	oMdlRev:SetOperation( MODEL_OPERATION_UPDATE)
	oMdlRev:Activate()
	
	At870RAuto(oMdlRev,oMdlRev,10,10)
	
	oMdlRev:DeActivate()
	oMdlRev := nil
	
	// [3] Indico quando deve terminar a verificação das alterações
	oAuto:EndLogging()
	
	// [4] Gero o código de verificação das alterações
	oAuto:Generate(lShowLog <- o Default é .T. ; Alterar para .F. em caso de mensagem "não suporta componentes visuais")

	oAuto:cLogInsert //ver essa var no commands
	oAuto:cLogUpdate //ver essa var no commands
	oAuto:cLogDelete //ver essa var no commands


Return oHelper
//--------------------------------------------
*/

class AutoCheck 

	data nPosIni as Numeric
	data nPosFim as Numeric
	data cLogInsert AS CHARACTER
	data cLogUpdate AS CHARACTER
	data cLogDelete AS CHARACTER
	data aIndex AS ARRAY
	data aNoValid AS ARRAY
	data aNoModule AS ARRAY
	data aSniffModule AS ARRAY
	
	method New()
	method StartLogging()
	method EndLogging()
	method Generate()
	method Destroy()
	method SetIndex()
	method RemoveCheck()
	method RemoveModule()
	method SniffModule()
	
endclass

method RemoveModule(aModules) class AutoCheck
	Local nX
	For nX := 1 to LEN(aModules)
		AADD(Self:aNoModule, aModules[nX])
	Next
return Self:aNoModule

method SniffModule(aModules) class AutoCheck
	Local nX
	For nX := 1 to LEN(aModules)
		AADD(Self:aSniffModule, aModules[nX])
	Next
return Self:aSniffModule

method SetIndex(aTableIndex) class AutoCheck
	Local nX
	For nX := 1 TO LEN(aTableIndex)
		AADD(Self:aIndex, aTableIndex[nX])
	Next
return Self:aIndex

method Destroy() class AutoCheck
	Self:nPosIni := 0
	Self:nPosFim := 0
	Self:cLogInsert :=	""
	Self:cLogUpdate :=	""
	Self:cLogDelete :=	""
	Self:aIndex := {}
	Self:aNoValid := {}
return

method RemoveCheck(aCpos) class AutoCheck
	Local nX
	For nX := 1 To LEN(aCpos)
		AADD(Self:aNoValid, aCpos[nX])
	Next
return Self:aNoValid

method New() class AutoCheck
	Self:nPosIni := 0
	Self:nPosFim := 0
	Self:cLogInsert :=	""
	Self:cLogUpdate :=	""
	Self:cLogDelete :=	""
	Self:aIndex := {}
	Self:aNoValid := {}
return

method StartLogging() class AutoCheck
	Self:nPosIni := ExecSelect()
Return

method EndLogging() class AutoCheck
	Self:nPosFim := ExecSelect()
Return

Static Function ExecSelect()
Local nRet := 0
Local aArea := GetArea()
Local cSQL := "SELECT TOP 1 LOG_ID from LOGZERA ORDER BY LOG_ID DESC"
Local cAliasLOG := GetNextAlias()

cSql := ChangeQuery(cSql)
dbUseArea( .T., "TOPCONN", TCGENQRY(,,cSql),cAliasLOG, .F., .T.)
If (cAliasLOG)->(EOF())
	nRet := 0
Else
	nRet := (cAliasLOG)->(LOG_ID)
EndIf
(cAliasLOG)->(dbCloseArea())
RestArea(aArea)

Return nRet

method Generate(lShowLog) class AutoCheck
Local oFont	:= TFont():New("Courier New",07,15)
Local oMemo
Local oDlgEsc
Local aInsert := {}
Local aUpdate := {}
Local aDelet := {}
Local aArea := GetArea()
Local cAliasLOG := GetNextAlias()
Local cSQL := " SELECT COLUNAS , LOG_ID , COMANDO , NOME_DA_TABELA , R_E_C_N_O_ from LOGZERA WHERE LOG_ID > "
Local nX
Local nY
Local nAux := 0
local nAux2 := 0
Local aAux := {}
Local oTop
Local aIndex := {}
Local xAux
Local lAux := .F.

Default lShowLog := .T.

cSQL += cValToChar(Self:nPosIni) + " AND LOG_ID <= " + cValToChar(Self:nPosFim) + " "
cSQL += " ORDER BY HORA ASC"
cSQL := ChangeQuery(cSQL)
dbUseArea( .T., "TOPCONN", TCGENQRY(,,cSql),cAliasLOG, .F., .T.)

While !((cAliasLOG)->(EOF()))
	If (nAux := ASCAN(aUpdate, {|m| m[1] == LEFT((cAliasLOG)->(NOME_DA_TABELA),3) .AND. m[2] == (cAliasLOG)->(R_E_C_N_O_)})) > 0 .AND.;
			ASCAN(aInsert, {|m| m[1] == LEFT((cAliasLOG)->(NOME_DA_TABELA),3) .AND. m[2] == (cAliasLOG)->(R_E_C_N_O_)}) == 0 .AND.;
				ASCAN(aDelet, {|m| m[1] == LEFT((cAliasLOG)->(NOME_DA_TABELA),3) .AND. m[2] == (cAliasLOG)->(R_E_C_N_O_)}) == 0 .AND.;
					!((Alltrim(UPPER((cAliasLOG)->(COMANDO))) == 'DELETE'))
		//Caso um dado seja atualizado mais de uma vez, verificar todas as colunas que foram modificadas em todas as alterações
		aAux := StrTokArr(Alltrim((cAliasLOG)->(COLUNAS)),";")
		For nX := 1 To LEN(aAux)
			If VALTYPE(aAux[nX]) == 'C' .AND. !(aAux[nX] $ aUpdate[nAux][3])
				aUpdate[nAux][3] += ";"+aAux[nX]
			EndIf
		Next
	ElseIf (Alltrim(UPPER((cAliasLOG)->(COMANDO))) == 'DELETE' .OR.;
	 			ASCAN(aDelet, {|m| m[1] == LEFT((cAliasLOG)->(NOME_DA_TABELA),3) .AND. m[2] == (cAliasLOG)->(R_E_C_N_O_)}) > 0) .AND. (;
	 				(nAux := ASCAN(aUpdate, {|m| m[1] == LEFT((cAliasLOG)->(NOME_DA_TABELA),3) .AND. m[2] == (cAliasLOG)->(R_E_C_N_O_)})) > 0 .OR.;
	 					(nAux2 := ASCAN(aInsert, {|m| m[1] == LEFT((cAliasLOG)->(NOME_DA_TABELA),3) .AND. m[2] == (cAliasLOG)->(R_E_C_N_O_)})) > 0)
	 	//Dado incluido/alterado e depois apagado
		If nAux > 0
			aUpdate[nAux][1] := ""
			aUpdate[nAux][2] := 0
			aUpdate[nAux][3] := ""
		EndIf
		
		If nAux2 == 0
			nAux2 := ASCAN(aInsert, {|m| m[1] == LEFT((cAliasLOG)->(NOME_DA_TABELA),3) .AND. m[2] == (cAliasLOG)->(R_E_C_N_O_)})
		EndIf
		
		If nAux2 > 0
			aInsert[nAux2][1] := ""
			aInsert[nAux2][2] := 0
		EndIf
		
		AADD(aDelet, {LEFT((cAliasLOG)->(NOME_DA_TABELA),3),(cAliasLOG)->(R_E_C_N_O_)})
		
	Else
		If Alltrim(UPPER((cAliasLOG)->(COMANDO))) == 'INSERT'
			AADD(aInsert, {LEFT((cAliasLOG)->(NOME_DA_TABELA),3),(cAliasLOG)->(R_E_C_N_O_),Alltrim((cAliasLOG)->(COLUNAS))})
		ElseIf Alltrim(UPPER((cAliasLOG)->(COMANDO))) == 'UPDATE' .AND.;
		 			ASCAN(aInsert, {|m| m[1] == (cAliasLOG)->(NOME_DA_TABELA) .AND. m[2] == (cAliasLOG)->(R_E_C_N_O_)}) == 0
			AADD(aUpdate, {LEFT((cAliasLOG)->(NOME_DA_TABELA),3),(cAliasLOG)->(R_E_C_N_O_),Alltrim((cAliasLOG)->(COLUNAS))})
		ElseIf Alltrim(UPPER((cAliasLOG)->(COMANDO))) == 'DELETE'
			AADD(aDelet, {LEFT((cAliasLOG)->(NOME_DA_TABELA),3),(cAliasLOG)->(R_E_C_N_O_)})
		EndIf
	EndIf
	(cAliasLOG)->(DbSkip())
End 

(cAliasLOG)->(DbCloseArea())

ASORT(aInsert,,,{|x,y| x[1] > y[1]})
ASORT(aUpdate,,,{|x,y| x[1] > y[1]})
ASORT(aDelet,,,{|x,y| x[1] > y[1]})

For nX := 1 to LEN(aInsert)
	If !EMPTY(aInsert[nX][1]) .AND. !EMPTY(aInsert[nX][2])
		If ASCAN(aIndex, {|w| w[1] == aInsert[nX][1]}) == 0
			AADD(aIndex, {aInsert[nX][1], (GetIndex(aInsert[nX][1],Self:aIndex))})
		EndIf
		If EMPTY(Self:cLogInsert)
			Self:cLogInsert += CRLF
			Self:cLogInsert += "// ---------------------------------------------------------------" + CRLF
			Self:cLogInsert += "// Inicio dos scripts para verificação dos dados inseridos (INSERT)" + CRLF
			Self:cLogInsert += "// ---------------------------------------------------------------" + CRLF
		EndIf
		Self:cLogInsert += CRLF
		Self:cLogInsert += "cTable	:= '" + aInsert[nX][1] + "'"
		Self:cLogInsert += CRLF
		Self:cLogInsert += 'cQuery	:= "' + StrSearchPK((aIndex[ASCAN(aIndex, {|w| w[1] == aInsert[nX][1]})][2]),aInsert[nX][1],aInsert[nX][2]) + '"'
		Self:cLogInsert += CRLF
		Self:cLogInsert += CRLF
		aAux := StrTokArr(Alltrim(aInsert[nX][3]),";")
		For nY := 1 TO LEN(aAux)
			If VALTYPE(aAux[nY]) == 'C' .AND. aAux[nY] <> "D_E_L_E_T_" .AND. ASCAN(Self:aNoValid, aAux[nY]) == 0
				xAux := GetVal(aAux[nY],aInsert[nX][1],aInsert[nX][2])
				If VALTYPE(xAux) == 'C'
					Self:cLogInsert += "oHelper:UTQueryDB(cTable,'" + aAux[nY] + "',cQuery, '" + xAux + "')" + CRLF
					lAux := .T.
				ElseIf VALTYPE(xAux) == 'N'
					Self:cLogInsert += "oHelper:UTQueryDB(cTable,'" + aAux[nY] + "',cQuery, " + cValToChar(xAux) + ")" + CRLF
					lAux := .T.
				ElseIf VALTYPE(xAux) == 'D'
					Self:cLogInsert += "oHelper:UTQueryDB(cTable,'" + aAux[nY] + "',cQuery, CTOD('" + DToC(xAux) + "'))" + CRLF
					lAux := .T.
				EndIf
			EndIf
		Next
		If lAux
			Self:cLogInsert += "oHelper:AssertTrue(oHelper:lOk,'')" + CRLF
		EndIf
		lAux := .F.
	EndIf
Next

For nX := 1 to LEN(aUpdate)
	If !EMPTY(aUpdate[nX][1]) .AND. !EMPTY(aUpdate[nX][2])
		If ASCAN(aIndex, {|w| w[1] == aUpdate[nX][1]}) == 0
			AADD(aIndex, {aUpdate[nX][1], (GetIndex(aUpdate[nX][1],Self:aIndex))})
		EndIf
		If EMPTY(Self:cLogUpdate)
			Self:cLogUpdate += CRLF
			Self:cLogUpdate += "// ---------------------------------------------------------------" + CRLF
			Self:cLogUpdate += "// Inicio dos scripts para verificação dos dados atualizados (UPDATE)" + CRLF
			Self:cLogUpdate += "// ---------------------------------------------------------------" + CRLF
		EndIf
		Self:cLogUpdate += CRLF
		Self:cLogUpdate += "cTable	:= '" + aUpdate[nX][1] + "'"
		Self:cLogUpdate += CRLF
		Self:cLogUpdate += 'cQuery	:= "' + StrSearchPK((aIndex[ASCAN(aIndex, {|w| w[1] == aUpdate[nX][1]})][2]),aUpdate[nX][1],aUpdate[nX][2]) + '"'
		Self:cLogUpdate += CRLF
		Self:cLogUpdate += CRLF
		aAux := StrTokArr(Alltrim(aUpdate[nX][3]),";")
		For nY := 1 TO LEN(aAux)
			If VALTYPE(aAux[nY]) == 'C' .AND. aAux[nY] <> "D_E_L_E_T_" .AND. ASCAN(Self:aNoValid, aAux[nY]) == 0
				xAux := GetVal(aAux[nY],aUpdate[nX][1],aUpdate[nX][2])
				If VALTYPE(xAux) == 'C'
					Self:cLogUpdate += "oHelper:UTQueryDB(cTable,'" + aAux[nY] + "',cQuery, '" + xAux + "')" + CRLF
					lAux := .T.
				ElseIf VALTYPE(xAux) == 'N'
					Self:cLogUpdate += "oHelper:UTQueryDB(cTable,'" + aAux[nY] + "',cQuery, " + cValToChar(xAux) + ")" + CRLF
					lAux := .T.
				ElseIf VALTYPE(xAux) == 'D'
					Self:cLogUpdate += "oHelper:UTQueryDB(cTable,'" + aAux[nY] + "',cQuery, CTOD('" + DToC(xAux) + "'))" + CRLF
					lAux := .T.
				EndIf
			EndIf
		Next
		If lAux
			Self:cLogUpdate += "oHelper:AssertTrue(oHelper:lOk,'')" + CRLF
		EndIf
		lAux := .F.
	EndIf
Next

For nX := 1 to LEN(aDelet)
	If !EMPTY(aDelet[nX][1]) .AND. !EMPTY(aDelet[nX][2])
		If ASCAN(aIndex, {|w| w[1] == aDelet[nX][1]}) == 0
			AADD(aIndex, {aDelet[nX][1], (GetIndex(aDelet[nX][1],Self:aIndex))})
		EndIf
		If EMPTY(Self:cLogDelete)
			Self:cLogDelete += CRLF
			Self:cLogDelete += "// ---------------------------------------------------------------" + CRLF
			Self:cLogDelete += "// Inicio dos scripts para verificação dos dados apagados (DELETE)" + CRLF
			Self:cLogDelete += "// ---------------------------------------------------------------" + CRLF
		EndIf
		Self:cLogDelete += CRLF
		Self:cLogDelete += "cTable	:= '" + aDelet[nX][1] + "'"
		Self:cLogDelete += CRLF
		Self:cLogDelete += 'cQuery	:= "' + StrSearchPK((aIndex[ASCAN(aIndex, {|w| w[1] == aDelet[nX][1]})][2]),aDelet[nX][1],aDelet[nX][2]) + '"'
		Self:cLogDelete += CRLF
		Self:cLogDelete += CRLF
		aAux := { IIF(LEFT(aDelet[nX][1],1) == 'S',RIGHT(aDelet[nX][1],2),aDelet[nX][1]) + "_FILIAL" }
		For nY := 1 TO LEN(aAux)
			xAux := GetVal(aAux[nY],aDelet[nX][1],aDelet[nX][2])
			Self:cLogDelete += "oHelper:UTQueryDB(cTable,'" + aAux[nY] + "',cQuery, '" + xAux + "')" + CRLF
			lAux := .T.
		Next
		If lAux
			Self:cLogDelete += "oHelper:AssertFalse(oHelper:lOk,'')" + CRLF
		EndIf
		lAux := .F.
	EndIf
Next

If lShowLog
	Define Dialog oDlgEsc Title "Auto Generated CheckDb" From 0,0 to 425, 600 Pixel
	@ 000, 000 MsPanel oTop Of oDlgEsc Size 000,250
	oTop:Align := CONTROL_ALIGN_TOP
	@ 005,005 Get oMemo Var (Self:cLogInsert + Self:cLogUpdate + Self:cLogDelete) Memo FONT oFont Size 292,186 READONLY Of oTop Pixel
	oMemo:EnableVScroll(.T.)
	oMemo:EnableHScroll(.T.)
	oMemo:lWordWrap := .T.
	oMemo:bRClicked := {|| AllwaysTrue()}
	Define SButton From 196, 270 Type 1 Action (oDlgEsc:End()) Enable Of oTop Pixel
	Activate Dialog oDlgEsc Centered
EndIf

RestArea(aArea)
Return


Static Function GetIndex(cTable, aIndex)
Local cRet := ""
Local aArea := GetArea()
Local cOrdem := "1"
Local nAux := 0

DbSelectArea("SIX")
DbSetOrder(1)
DbGoTop()

If (nAux := ASCAN(aIndex, {|m| UPPER(LEFT(Alltrim(m[1]),3)) == UPPER(LEFT(Alltrim(cTable),3))})) > 0
	If VALTYPE(aIndex[nAux][2]) == 'N'
		cOrdem := cValToChar(aIndex[nAux][2])
	ElseIf VALTYPE(aIndex[nAux][2]) == 'C'
		cOrdem := aIndex[nAux][2]
	EndIf
EndIf

If nAux > 0 .AND. LEN(aIndex[nAux]) >= 3 .AND. !EMPTY(aIndex[nAux][3])
	cRet := Alltrim(aIndex[nAux][3])
ElseIf DbSeek(cTable + cOrdem)
	cRet := Alltrim(SIX->CHAVE)
EndIf

RestArea(aArea)
Return cRet


Static Function StrSearchPK(cChave,cTable,nRECNO)
Local cRet := ""
Local nX
Local aAux
Local xAux
Local aArea := GetArea()

cChave := UPPER(cChave)

cChave := STRTRAN(cChave, "DTOS(")
cChave := STRTRAN(cChave, "DTOC(")
cChave := STRTRAN(cChave, "STR(")
cChave := STRTRAN(cChave, ")")

aAux := StrTokArr(cChave,"+")

For nX := 1 To LEN(aAux)
	If VALTYPE(aAux[nX]) == 'C'

		xAux := GetVal(aAux[nX], cTable, nRECNO)
		
		If VALTYPE(xAux) == 'C'
			cRet +=  aAux[nX] + " = '" + xAux + "' AND "
		ElseIf VALTYPE(xAux) == 'D'
			cRet +=  aAux[nX] + " = '" + DTOS(xAux) + "' AND "
		ElseIf VALTYPE(xAux) == 'N'
			cRet +=  aAux[nX] + " = " + cValToChar(xAux) + " AND "
		EndIf
	EndIf
Next

RestArea(aArea)
Return (LEFT(cRet, LEN(cRet)-5))

Static Function GetVal(cColuna, cTabela, nRec)
Local xVal
Local aArea := GetArea()

DbSelectArea(cTabela)
DbSetOrder(1)
DbGoTo(nRec)

xVal := cTabela + "->" + cColuna
xVal := (&(xVal))

RestArea(aArea)
Return xVal