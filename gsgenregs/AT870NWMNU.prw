#include 'protheus.ch'

User Function AT870NWMNU()
Local nC
Local aRetMenu := {}

If ValType(PARAMIXB) == "A" 
	nTam := Len(PARAMIXB)
	For nC := 1 to nTam
		aAdd(aRetMenu, aClone(PARAMIXB[nC]))
	Next nC
EndIf

aAdd( aRetMenu, {"Gerar Registros", { || u_GERREG()} , 2} )

Return aRetMenu

User Function GERREG()
Local oDlgEscTela := Nil
Local oExit
Local oOk
Local oGet1
Local oGet2
Local oCheck1
Local cVal := "000000"
Local cVal2 := "000000"
Local lCheck := .T.

If Aviso("GsGenRegs","Escolha que tipo de registro deseja gerar automáticamente:",{"Atendentes","Orçamento"},2) == 1
	DEFINE MSDIALOG oDlgEscTela TITLE "Gerar Atendentes" FROM 0,0 TO 120,320 PIXEL
		@ 5, 9 SAY "Quantidade: " SIZE 50, 19 PIXEL
	oExit := TButton():New( 35, 54, "Sair",oDlgEscTela,{|| oDlgEscTela:End() }, 35,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oOk := TButton():New( 35, 9, "Gerar",oDlgEscTela,{|| AddAtendente(cVal,lCheck), oDlgEscTela:End() }, 35,10,,,.F.,.T.,.F.,,.F.,,,.F. )
	oGet1:= TGet():New( 15, 9, { | u | If( PCount() == 0, cVal, cVal := u ) },oDlgEscTela, ;
    				 50, 010, "@E 999999",, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cVal",,,,.T.  )
    				 
    oCheck1 := TCheckBox():New(15,60,'Gera Funcionário? (SRA)',{|u|if( pcount()==0,lCheck,lCheck := u)},oDlgEscTela,100,210,,,,,,,,.T.,,,)
	ACTIVATE MSDIALOG oDlgEscTela CENTERED
Else
	DEFINE MSDIALOG oDlgEscTela TITLE "Gerar Orçamento" FROM 0,0 TO 190,320 PIXEL
		@ 5, 9 SAY "Quantidade de LOCAIS (TFL): " SIZE 75, 29 PIXEL
		@ 37, 9 SAY "Quantidade de RH por Local (TFF): " SIZE 85, 29 PIXEL
		oCheck1 := TCheckBox():New(15,100,'Gerar o contrato?',{|u|if( pcount()==0,lCheck,lCheck := u)},oDlgEscTela,100,210,,,,,,,,.T.,,,)
		
		oGet1:= TGet():New( 15, 9, { | u | If( PCount() == 0, cVal, cVal := u ) },oDlgEscTela, ;
	    				 50, 010, "@E 999999",, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cVal",,,,.T.  )
			
		oGet2:= TGet():New( 50, 9, { | u | If( PCount() == 0, cVal2, cVal2 := u ) },oDlgEscTela, ;
	    				 50, 010, "@E 999999",, 0, 16777215,,.F.,,.T.,,.F.,,.F.,.F.,,.F.,.F. ,,"cVal2",,,,.T.  )
			
		oOk := TButton():New( 50, 110, "Gerar",oDlgEscTela,{|| AddORC(cVal,cVal2,lCheck), oDlgEscTela:End() }, 35,10,,,.F.,.T.,.F.,,.F.,,,.F. )
		oExit := TButton():New( 70, 110, "Sair",oDlgEscTela,{|| oDlgEscTela:End() }, 35,10,,,.F.,.T.,.F.,,.F.,,,.F. )
		
	ACTIVATE MSDIALOG oDlgEscTela CENTERED
EndIf

Return .T.

Static Function AddAtendente(nQtd,lSRA)
Local oGsGenRegs := GsGenRegs():New()
nQtd := VAL(Alltrim(nQtd))
IF nQtd > 0
	oGsGenRegs:addAtendente(nQtd,lSRA)
	If lSRA
		MsgAlert(cValToChar(nQtd) + " atendentes (AA1) e funcionários (SRA) inseridos !")
	Else
		MsgAlert(cValToChar(nQtd) + " atendentes inseridos !")
	EndIf
Else
	MsgAlert("Nenhum atendente inserido")
EndIf
Return

Static Function AddORC(nTFL,nTFF,lGeraGCT)
Local oGsGenRegs := GsGenRegs():New()
Local nX
Local nY
nTFL := VAL(Alltrim(nTFL))
nTFF := VAL(Alltrim(nTFF))

If nTFL > 0 .AND. nTFF > 0
	oGsGenRegs:addOrcamento("ORC1")
	For nX := 1 TO nTFL
		oGsGenRegs:addLocal("ORC1", "LOC" + cValToChar(nX))
		For nY := 1 TO nTFF
			oGsGenRegs:addRH("ORC1", "LOC" + cValToChar(nX), "RH" + cValToChar(nY))
		Next nY
	Next nX
	If lGeraGCT
		oGsGenRegs:gerarContrt("ORC1")
	EndIf
	TFJ->(DbGoTo(oGsGenRegs:getRec( oGsGenRegs:aORCS[1][2])))
	MsgAlert("Processamento concluído! Orçamento: " + TFJ->TFJ_CODIGO + IIF(lGeraGCT,". Contrato: " + TFJ->TFJ_CONTRT,""))
Else
	MsgAlert("Nenhum orçamento inserido")
EndIf

Return