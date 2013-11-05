/*====================================================================
PROJECT       : BANCOVA2013
PROGRAM       : T_01_DemogTable_RongLi.SAS
PROGRAMMER(S) : Rong Li
PURPOSE       : Create a demographic table			
AUTHOR        : Rong Li
DATE          : 10/17/2013
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

Program for creating a demographic table for clinical data
---Uses Wilcoxon Tests for Continuous Variables
---Uses Chi-square or Fisher's Exact Test for Categorical Variables
     
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
*              Create macro variables and prepare the data for reports               *
**************************************************************************************;


%let root=C:\Users\Peng\Desktop\Bancova;
%let outputs=&root.\Week3\HW3\outputs;
%let infile = derived.demog_data;  
%let exfile = &root.\Week3 - Demographic\HW3\outputs\T_01_DemogTable_RongLi_Download_Open_in_Word.rtf;
%let treatment = treat;
%let itt = itt;	
%let id = subjid;

libname raw "&root.\Week3 - Demographic\HW3\raw";
libname derived "&root.\Week3 - Demographic\HW3\derived";

* Check duplicates;
proc sort data=&infile out=test dupout=dup;
    by &id;
run;

* Add treat=3 to calculate the total number;
data datafile;
    set &infile (where=(&itt=1));
	output;
	&itt = 3;
	output;
run;
	
* Initialize results dataset which will be added to by the macro;
data results;
    set _null_;
run;


**************************************************************************************
*                                   Define the macro                                 *
*                                 Macro calls are below                              *
**************************************************************************************;


%macro table (vartype,varname,labname);

%if &vartype=NUM %then %do;

  proc univariate noprint data = datafile;
      class &treatment;
      var &varname;
      output out=stats1 n=_n mean=_mean median=_median std=_std min=_min max=_max ;
  run;

  data stats2;
      set stats1;
      format n mean median std min max $14.;
      n = put(_n, 3.);
      mean = put (_mean,7.1);
      median = put(_median,7.1);
      std = put(_std,8.2);
      min = put(_min,7.1);
      max = put(_max, 7.1);
      drop _n _mean _median _std _min _max;
  run;

  proc transpose data=stats2 out=stats3 prefix=col;
	  var n mean median std min max;
	  id treat;
  run;

  proc npar1way noprint data = datafile;
      class &treatment;
      var &varname;
	  output out=stats4; 
	  where &treatment in (1,2);
  run;

  data stats5 (keep = label pvalue);
      length label $ 30;
      set stats4 ;
      label = "&labname";
      pvalue = put(p2_wil, 8.4);
  run;

  data combo;     
      length label $ 30 col1 col2 col3 $ 25;
      set stats5 stats3;
      keep label col1 col2 col3 pvalue subgroup;
      subgroup = 0;
       if _n_ >1 then do;
		subgroup = 1;
         select;
            when(_name_ = 'n')    label = "    N";
            when(_name_ = 'mean') label = "    Mean";
            when(_name_ = 'median') label = "    Median";
            when(_name_ = 'std') label = "    Std.Dev";
            when(_name_ = 'min') label = "    Min";
            when(_name_ = 'max') label = "    Max";
		 otherwise;
	    end;
	   end;
  run;

  data results;
      set results combo;
  run;

%end;

%if &vartype=CHAR %then %do;

  proc freq noprint data=datafile;
      tables &varname*&treatment / out=freqs1 outpct;
	  where &treatment ne .;
  run;

  data freqs2;
	  set freqs1;
	  where not missing(&varname);
	  length value $25;
	  value = put(count, 4.) || ' (' || put(pct_col, 4.1) || '%)';
  run;
 
  proc sort data=freqs2;
	  by &varname;
  run;

  proc transpose data=freqs2 out=freqs3(drop=_name_) prefix=col;
	  by &varname;
	  var value;
	  id &treatment;
  run;

  proc sql noprint;
      select min(count) into :mincol
       from freqs1;
  quit;

  %if %EVAL(&mincol < 5) = 1 %then %do;
    proc freq noprint data=datafile;
        tables &varname*&treatment / exact;
        output out=stats1 exact ;
	    where &treatment in (1,2);
    run;

    data stats2 (keep=label pvalue);
        length label $30;
	    set stats1;
	    label = "&labname";
	    pvalue = put(xp2_fish, 8.4);
    run;

  %end;

  %else %do;
    proc freq noprint data=datafile;
        tables &varname*&treatment / chisq;
        output out=stats1 chisq ;
	    where &treatment in (1,2);
    run;

    data stats2 (keep = label pvalue);
       length label $30;
	   set stats1;
	   label = "&labname";
	   pvalue = put(p_pchi, 8.4);
    run;

  %end;

  data combo;
      length label $ 70 col1 col2 col3 $25;
	  set stats2 freqs3;
	  keep label col1 col2 col3 pvalue subgroup;
      subgroup = 0;
       if _n_ > 1 then do; 
        label = "    "||propcase(&varname);
        subgroup = 1;
       end;
  run;

  data results;
      set results combo;
  run;

%end;

%mend;
%table (CHAR,Gender,Gender N(%));
%table (CHAR,Race,Race N(%));
%table (NUM,Age,Age (yrs));
%table (NUM,Height,Height (cm));
%table (NUM,Weight,Weight (kg));
%table (NUM,BMI,BMI (kg/m^{super 2}));


**************************************************************************************
*               Create Groups and calculate total number in each group               *
*                             Preprare data for PROC REPORT                          *
**************************************************************************************;

data final;
  set results;
   retain groups;
   if _n_ = 1 then groups = 0;
   if subgroup = 0 then groups = groups + 1;  
run;

data _null_;
   set datafile end = eof;
   if treat='1' then n0 + 1;
   else if treat='2' then n1 + 1;
   n + 1;
   if eof then
      do;
         call symput("n0",compress('(N='||put(n0,4.) || ')'));
         call symput("n1",compress('(N='||put(n1,4.) || ')'));
         call symput("n",compress('(N='||put(n,4.) || ')'));
      end;
run;


**************************************************************************************
*                                  Create Report                                     *
**************************************************************************************;


title;
footnote;
ods escapechar='^';
options  nonumber nodate center  missing=" ";

ods rtf file="&exfile" style=minimal;

proc report data = final nowindows spacing=0 headskip missing split = "|"
    style(report)=[frame=above rules=groups cellspacing=3 cellpadding=0 ]
	style(header)=[just=center background=white]
	style(column)=[just=left cellwidth=1.2in font_face=Courier font_size=8pt];
    columns groups subgroup label col1 col2 col3 pvalue;
    define groups   / order order=internal noprint;
    define subgroup /order order = internal noprint; 
    define label    / display   "Variables" style=[cellwidth=1.4in]  ;
    define col1     / display style=[just=right] "Treatment|&n0";
    define col2     / display style=[just=right]  "Placebo|&n1";
    define col3     / display style=[just=right] "Total|&n";
    define pvalue   / display style=[just=center]" |P-value^{super **}"; 

    compute before groups;
      line "  ";
    endcomp;

    compute label;
      if (subgroup ^= 0) then
      call define('label', 'style', "style=[pretext='\ql\li180 ' protectspecialchars=off]");
    endcomp;  

    compute after / style=[just=left font_face=Courier font_size=8pt];
      line @1 '______________________________________________________________________________________________';
      line ' ';
      line @1 '* Intent to treat population includes all randomized patients who take at least one dose of study drug, 
and have baseline and at least one post-baseline efficacy measurement.';
      line ' ';
      line @1 "** P-values are obtained from the following methods: Age, Height, Weight, BMI = Wilcoxon rank-sum test; Gender, Race = Fisher's exact test.";
    endcomp;

    title1 font=Arial height=11pt "TABLE 1";
    title2 font=Arial height=11pt "DEMOGRAPHICS AND BASELINE CHARACTERISTICS";   
    title3 font=Arial height=11pt "(ITT POPULATION)^{super *}";

run;

ods rtf close;


