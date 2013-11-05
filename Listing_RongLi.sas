/*====================================================================
PROJECT       : BANCOVA2013
PROGRAM       : L_01_DemogTable_RoseLi.SAS
PROGRAMMER(S) : Rose Li
PURPOSE       : Produce a data listing			
AUTHOR        : Rose Li
DATE          : 11/04/2013
QC PROGRAMMER : John Zhang
QC Date       : 
DATA          :  
OUTPUT DIR    :
OUTPUT FILES  : 
---------------------------------------------------------------------
REVISION HISTORY
                         
---------------------------------------------------------------------
IDEAS:

---------------------------------------------------------------------
NOTES:

     
=====================================================================*/


*======================================================
Parameters:
	options
	macro variables

*======================================================;


dm 'clear output';
dm 'clear log'; 

OPTION nodate nocenter LS=80 ps=1000;


**************************************************************************************
*                      Create a listing for demog data                               *
**************************************************************************************;


%let root=C:\Users\Peng\Desktop\Bancova;
%let outputs=&root.\Week3\HW3\outputs;
%let infile = derived.demog_data;  
%let exfile = &root.\Week3 - Demographic\HW3\outputs\L_01_Demog_RoseLi.rtf;

libname raw "&root.\Week3 - Demographic\HW3\raw";
libname derived "&root.\Week3 - Demographic\HW3\derived";

proc format;
   value trt
         1 = "TREATMENT"
	     2 = "PLACEBO";
run;

ods escapechar "^";
options  nonumber nodate center  missing=" ";

ods rtf file="&exfile" style=minimal;
proc report data=&infile(where=(itt=1)) nowindows headline headskip missing split='|'
	style(report)=[frame=above rules=groups cellpadding=1.5pt] 
	style(header)=[just=center background=white]
	style(column)=[just=center cellwidth=1.2in font_face=Courier font_size=8pt];
	column subjid age treat gender race height weight BMI;
	define subjid / 'Subject|ID' order style=[cellwidth=0.6in] ;
	define treat / 'Treatment|Group' style=[cellwidth=1in] format=trt.;
	define age / 'Age' style=[cellwidth=0.5in];
	define gender / 'Gender' style=[cellwidth=0.6in];
	define race / 'Race' style=[cellwidth=0.8in];
	define height / 'Height|(cm)' style=[cellwidth=0.6in];
	define weight / 'Weight|(kg)' style=[cellwidth=0.6in];
	define BMI / 'BMI|(kg/m^{super 2})'format=4.1 style=[cellwidth=0.7in];

	compute after / style=[just=left];
		line @1 '_________________________________________________________________________________';
		line ' ';
        line @1 '* Intent to treat population includes all randomized patients who take at least one dose of study drug, 
and have baseline and at least one post-baseline efficacy measurement.';
	endcomp;

title1 font=Arial height=10pt "LISTING 1";
title2 font=Arial height=10pt "DEMOGRAPHICS AND BASELINE CHARACTERISTICS";   
title3 font=Arial height=10pt "(ITT POPULATION)^{super *}";

run;
ods rtf close;
