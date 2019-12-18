#include 'totvs.ch'
#include "fileio.ch"

Static cForPos
Static nObjLvl := 0
Static nTotalLoop := 0
//------------------------------------------------------------------------------
/*/{Protheus.doc} TECPrtObj
Imprime todas as propriedades de um objeto em um TXT

@param		o, obj, objeto que será pesquisado
@param		cpatch, string, caminho + nome do arquivo (c:\temp\print.txt) onde o obj deve ser impresso
@param		ret, string, utilizado na recursividade. Não informar nada
@param		lFirstExec, bool, utilizado na recursividade. Não informar nada

@author	Mateus Boiani
@since		05/03/2018
/*/
//------------------------------------------------------------------------------
Function TECPrtObj(o, cpath, ret, lFirstExec)
local x
Local cpretext := ""
local a := IIF(VALTYPE(o) == 'A', o, ClassDataArr(o))
Local nHandle
Local cObjLvl := "[Level: {" + cValToChar(nObjLvl) + "}] "
default lFirstExec := .T.
default ret := ""

If lFirstExec
	nHandle :=  FCREATE(cpath, FC_NORMAL)
EndIf

for x := 1 to len(a)
	nTotalLoop++
	conout(cValToChar(nTotalLoop))
	If lFirstExec
		cForPos := "( " + cValToChar(x) + " )"
	EndIf
	ret += cForPos + cpretext + "Nome da Propriedade: " + a[x][1] + CHR(10)
	ret += cForPos + cpretext + "Tipo do Valor: " + VALTYPE(a[x][2]) + CHR(10)
	If VALTYPE(a[x][2]) == 'C'
		ret += cObjLvl + cForPos + cpretext + "Valor: " + a[x][2] + CHR(10)
	Elseif VALTYPE(a[x][2]) == 'L' .OR. VALTYPE(a[x][2]) == 'N'
		ret += cObjLvl + cForPos + cpretext + "Valor: " + cValToChar(a[x][2]) + CHR(10)
	Elseif VALTYPE(a[x][2]) == 'U'
		ret += cObjLvl + cForPos + cpretext + "Valor: " + "nil" + CHR(10)
	ElseIf VALTYPE(a[x][2]) == 'A'
		If EMPTY(a[x][2])
			ret += cForPos + cpretext + "Valor: " + "{}" + CHR(10)
		Else 
			TECPrtArr(a[x][2], @ret)
		EndIf
	ElseIf VALTYPE(a[x][2]) == 'O' .AND. nObjLvl <= 5
		nObjLvl++
		TECPrtObj(a[x][2],/*Path*/,@ret,.F.)
		nObjLvl--
	ElseIf VALTYPE(a[x][2]) == 'B'
		ret += cObjLvl + cForPos + cpretext + "Valor: " + GetCBSource(a[x][2]) + CHR(10)
	EndIf
	If lFirstExec
		ret += REPLICATE("-",56) + CHR(10)
		FSeek(nHandle, 0, FS_END)
		FWrite(nHandle, ret)
		ret := ""
	EndIf
next

If lFirstExec
	fclose(nHandle)
	nTotalLoop := 0
EndIf

Return ret

Static Function TECPrtArr(arr, ret, cpretext)
local x
Local cSave
Local cObjLvl := "[Level: {" + cValToChar(nObjLvl) + "}] "
default cpretext := ""

for x := 1 to Len(arr)

	If x == 1
		ret += cpretext + "{" + CHR(10)
		cSave := cpretext
		cpretext := "	" + cpretext
	EndIf
	nTotalLoop++
	conout(cValToChar(nTotalLoop))
	If VALTYPE(arr[x]) == 'C'
		ret += cObjLvl + cpretext + cForPos + "Prop"+ cValToChar(x) + ": " + arr[x] + CHR(10)
	Elseif VALTYPE(arr[x]) == 'L' .OR. VALTYPE(arr[x]) == 'N'
		ret += cObjLvl + cpretext + cForPos + "Prop"+ cValToChar(x) + ": " + cValToChar(arr[x]) + CHR(10)
	Elseif VALTYPE(arr[x]) == 'U'
		ret += cObjLvl + cpretext + cForPos + "Prop"+ cValToChar(x) + ": " + "nil" + CHR(10)
	Elseif VALTYPE(arr[x]) == 'B'
		ret += cObjLvl + cpretext + cForPos + "Prop"+ cValToChar(x) + ": " + GetCBSource(arr[x]) + CHR(10)
	ElseIf VALTYPE(arr[x]) == 'A'
		TECPrtArr(arr[x], @ret, @cpretext)
	ElseIf VALTYPE(arr[x]) == 'O' .AND. nObjLvl <= 5
		nObjLvl++
		TECPrtObj(arr[x],/*Path*/,@ret,.F.)
		nObjLvl--
	EndIf
	
	If x == Len(arr)
		ret += cSave + "}" + CHR(10)
		cpretext := cSave
	EndIf
	
next

return