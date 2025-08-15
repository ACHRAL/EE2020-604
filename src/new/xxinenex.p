/* ************************************************************************ */
/* Program:     xxinenex.p  Inventory Entitlement Model Extract             */
/* Description: Combine xxwvsarp.p Weekly VSA report and xxabcarp.p into 1  */
/*              Program generates an Excel-friendly file and a Trailer      */
/*              report page showing the run time parameters and that no     */
/*              other printed output should be expected.                    */
/*              Sam Galea says to hard code this to run for 24 weeks        */
/* Author:      Ted Hale                                                    */
/*                                                                          */
/* JIRA: EE2014-736         DATE: 08/18/16       BY: GUSTAVO MARQUEZ        */
/* ************************************************************************ */
/*  EE2014-795       !rev:1!22-Sep-2016  !Ganesh P        !1.Added the new  */
/*                   !     !             !                !output fields as */
/*                   !     !             !                !mentioned in TS  */
/*                   !     !             !                !2.Removed the few*/
/*                   !     !             !                !output fields as */
/*                   !     !             !                !mentioned in TS  */
/*                   !     !             !                !3.Replaced name  */
/*                   !     !             !                !of few fields    */
/*                   !     !             !                !with new name    */
/*                   !     !             !                !4.Added the logic*/
/*                   !     !             !                !to Extract values*/
/*                   !     !             !                !to output file   */
/****************************************************************************/
/*  07-EE2014-795    !rev:2!07-Oct-2016  !Darshi Somaiya  !1. Commented Past*/
/*                   !     !             !                !due logic added  */
/*                   !     !             !                !previously       */
/*                   !     !             !                !2. Added a new   */
/*                   !     !             !                !logic for the    */
/*                   !     !             !                !same (Past due   */
/*                   !     !             !                !field)           */
/****************************************************************************/
/*  EE2014-795-V3    !rev:3!24-Oct-2016  !Nilesh Anand    !Performance      */
/*                   !     !             !                !enhancement.     */
/****************************************************************************/
/*  EE2014-892       !rev:1!4-Nov-2016   !Vikit Shetty    !Split the time   */
/*                   !     !             !                !stamp into two   */
/*                   !     !             !                !different columns*/
/*                   !     !             !                !ie one for date  */
/*                   !     !             !                !and one for time.*/
/********************!*****!*************!****************!******************/
/* REVISION: EE2020  LAST MODIFIED:11/10/2021    BY: CSI/GG *EE2020-3*       */
/********************!*****!*************!****************!******************/
/*  EE2020-323       !rev:1!18-Aug-2023  !      TCS       !Split the time   */
/****************************************************************************/
/* REVISION: EE2020-351  LAST MODIFIED:16/10/2023    BY: TCS                */
/********************!*****!*************!****************!******************/

/* Define Variables */
DEF VAR i         AS INT NO-UNDO.
DEF VAR xSTATUS   LIKE pt_status NO-UNDO.
DEF VAR xSTATUS1  LIKE pt_status NO-UNDO.
/* TRH Removed 20111028 unneeded
DEF VAR xincludezero AS LOGICAL NO-UNDO INIT NO.  */
DEF VAR totreqs   LIKE mrp_qty  NO-UNDO INIT 0.
DEF VAR site      LIKE pt_site  NO-UNDO.
DEF VAR site1     LIKE pt_site  NO-UNDO.
DEF VAR part      LIKE pt_part  NO-UNDO.
DEF VAR part1     LIKE pt_part  NO-UNDO.
DEF VAR buyer     LIKE pt_buyer NO-UNDO.
DEF VAR buyer1    LIKE pt_buyer NO-UNDO.
DEF VAR supplier  LIKE pt_vend  NO-UNDO.
DEF VAR supplier1 LIKE pt_vend  NO-UNDO.
/* Added by TRH on 20111024 for ESMA 0602361US */
DEF VAR xftpflag  AS   LOG NO-UNDO INIT NO.
/* end TRH Added on 20111024 for ESMA 0602361US */
DEF VAR xfilename AS CHAR FORMAT "x(60)" NO-UNDO INIT "VSA_ABC_ANALYSIS.TXT".
DEF VAR mess1     AS CHAR FORMAT "x(60)" NO-UNDO.
def var l_transfer_type AS CHAR INITIAL "ascii" no-undo.
DEF VAR l_loc_dir AS CHAR INITIAL "." no-undo.
DEF var remote_addr     as char.
def var remote_user     as char.
def var remote_dir      as char.
def var remote_passwd   as char.
DEF VAR success         AS LOGICAL.
DEF VAR vcFile          as character format "x(18)" no-undo.
DEF VAR highdate        LIKE qad_wkfl.qad_datefld[1] NO-UNDO.
DEF VAR mrpsum          LIKE qad_wkfl.qad_decfld[1] NO-UNDO.
DEF VAR splitflag       AS LOG NO-UNDO INIT NO.
DEF VAR potential_po    LIKE po_nbr NO-UNDO.
DEF VAR viNbrWeeks      as integer format ">9"
                        label "Nbr of Weeks to display" NO-UNDO INIT 24.
DEF VAR vtStart         as DATE label "Start Date" no-undo.
DEF VAR vtEnd           as DATE label "End Date"  no-undo.
def var dates           AS DATE extent 24.
def var pastreqs        as   decimal format "->>>,>>>,>>9".
def var pastords        as   decimal format "->>>,>>>,>>9".
def var qtyreq          AS   decimal extent  24 format "->>>>>>,>>9".
def var qtyord          AS   decimal extent  24 format "->>>>>>,>>9".
def var avendor         like po_vend.   /* this is the vendor code calculated as xxwvsarp.p does */
DEF VAR bvendor         LIKE po_vend.   /* this is the vendor code as the xxabc report displays  */
DEF VAR a_vend          LIKE po_vend.   /*EE2020-323*/
/* def var tmpRowVal       as decimal. */
DEF VAR vendorname      LIKE ad_name NO-UNDO.
DEF VAR dlm             AS CHAR FORMAT "x(1)" INIT '|'.
DEF VAR ponbr           LIKE po_nbr NO-UNDO.
DEF VAR firm_days       LIKE pod_firm_days NO-UNDO.

/*DEF VAR davgreq         AS DECIMAL FORMAT "->>,>>>,>>9.99"
                          LABEL "Daily Average Req" NO-UNDO.        EE2014-795*/

DEF VAR ucost           LIKE sct_cst_tot LABEL "Unit Cost" NO-UNDO.
DEF VAR qoh             LIKE IN_qty_oh NO-UNDO.

/*EE2014-795-Comment-Begin
DEF VAR davgconsumption AS DECIMAL FORMAT "->>,>>>,>>9.99" LABEL "Daily Average Consuption" NO-UNDO.
DEF VAR wipqoh          LIKE IN_qty_oh NO-UNDO.
DEF VAR voh             LIKE IN_qty_oh NO-UNDO.
DEF VAR wipnonnet       AS DECIMAL FORMAT "->>,>>>,>>9.99" LABEL "WIP Non Nettable Qty" NO-UNDO.
EE2014-795-Comment-End*/

DEF VAR sfty_time       LIKE ptp_sfty_tme NO-UNDO.
DEF VAR sfty_stock      LIKE ptp_sfty_stk NO-UNDO.
DEF VAR buyplan         LIKE pt_buyer LABEL "Buyer" NO-UNDO.

DEF VAR ord_mult        LIKE pt_ord_mult NO-UNDO.
DEF VAR favoritesite    LIKE pt_site NO-UNDO.
DEF VAR sitecount       AS INT NO-UNDO INIT 0.
DEF VAR m1 AS CHAR FORMAT "x" LABEL "Your Pipe Delimited Excel-friendly text file can be found at:" NO-UNDO.
DEF VAR m2 AS CHAR FORMAT "x" LABEL "Report Output Files." NO-UNDO.
/* TRH ADDED on 20121211 for ESMA 0902774MO */
def var oldsite         LIKE ld_site no-undo.
def var oldpart         LIKE ld_part no-undo.
def var costflag as int no-undo init 0.
def var found_a_cost as log no-undo.
def var voh_cost like sct_cst_tot no-undo.
def var mrp_cost like sct_cst_tot no-undo.
def var highpercent like poad_percent no-undo.
def var podfound        as logical.
/* End TRH ADDED on 20121211 for ESMA 0902774MO */
define variable transfer_error as character no-undo. /*EE2014-736*/

/*EE2014-795-Add-Begin*/
/*define variable ld_past_due     like pod_qty_ord      no-undo. 07-EE2014-795*/
define variable l_std_pack      like pod_ord_mult      no-undo.
define variable l_po_um         like pod_um            no-undo.
define variable l_translt_days  like pod_translt_days  no-undo.
define variable l_qty_net       like in_qty_oh         no-undo.
define variable l_qty_nonet     like in_qty_oh         no-undo.
define variable l_part_type     like pt_part_type      no-undo.
define variable l_ord_min       like pt_ord_min        no-undo.
define variable l_um            like pt_um             no-undo.
define variable l_datestp as character format "x(20)"  no-undo.    /*EE2014-892*/
define variable l_timestp as character format "x(20)"  no-undo.    /*EE2014-892*/

/*EE2014-795-Add-End*/

/*07-EE2014-795 Begin Add*/
define variable fcsduedate    as date                                no-undo.
define variable req           as decimal extent 14 format "->>>>>>9" no-undo.
define variable bck           like soc_fcst_bck                      no-undo.
define variable week          as integer                             no-undo.
DEFINE VARIABLE m_due_date    like mrp_due_date                      no-undo.
define variable sdate         as date extent 8                       no-undo.
define variable start         as date                                no-undo.
define variable dwm           as character format "!(1)"             no-undo.
define variable idays         as integer   format ">>9"              no-undo.
define variable monthend      as integer                             no-undo.
define variable interval      as integer extent 8 format "->>>>>>9"  no-undo.
define variable num_intervals as integer initial 7                   no-undo.
define variable more          like mfc_logical                       no-undo.
/*07-EE2014-795 End Add*/

/*EE2020-351 Begin Add*/
DEF VAR v_exp_Dir AS CHAR  no-undo.
DEF VAR v_cft_exp_Dir AS CHAR  no-undo. 
DEF VAR v_new_locdirec AS CHAR  no-undo.
DEF VAR expflag as LOG  no-undo init false.
/*EE2020-351  End Add*/

/* for use with ftp TRH Added on 20111024 for ESMA 0602361US */
DEFINE VARIABLE a_loc_file      AS CHAR FORMAT "x(60)".

/* buffers */

DEF BUFFER qadwkfl FOR qad_wkfl.

/* Temp-Tables */

/*EE2020-3 begin*/
{us/px/pxphdef.i gpumxr}
{us/px/pxmaint.i}
{us/px/pxpgmmgr.i}
{us/px/pxphdef.i gpcmxr}
{us/px/pxphdef.i gpcalxr}
/*EE2020-3 end*/
/* Litterals */
ASSIGN mess1 = "Invalid Filename.".

/* Forms     */
FORM
    xstatus         COLON 14 LABEL "Status"
    xstatus1        COLON 40 LABEL {us/t0/t001.i}
    site            COLON 14 LABEL "Site"
    site1           COLON 40 LABEL {us/t0/t001.i}
    part            COLON 14 LABEL "Item"
    part1           COLON 40 LABEL {us/t0/t001.i}
    buyer           COLON 14 LABEL "Buyer"
    buyer1          COLON 40 LABEL {us/t0/t001.i}
    supplier        COLON 14 LABEL "Supplier"
    supplier1       COLON 40 LABEL {us/t0/t001.i}
    /* TRH Removed 20111028 Unneeded
    xincludezero    COLON 40 LABEL "Include Zero MRP Reqs?"
    SKIP(1)                          */
    /* TRH Added on 20111024 for ESMA 0602361US */
    xftpflag        COLON 40 LABEL "Send File via FTP?"
    SKIP(1)
    /* end TRH Added on 20111024 for ESMA 0602361US */
    xfilename       COLON 14 LABEL "File Name"
    SKIP(1)
with frame a width 80 side-labels.

 FORM
    m1              AT  1
    SKIP(1)
    m2              AT  1
    SKIP(1)
with frame b width 80 side-labels.

/* Streams */
DEFINE STREAM x_stream. /* for use with xxftp functions */
define stream excel.    /* Excel-Friendly Output file   */

{us/mf/mfdtitle.i "CC12"}

   FIND FIRST en_mstr WHERE en_domain = GLOBAL_domain AND en_primary = YES
   NO-LOCK NO-ERROR.
   IF NOT AVAILABLE en_mstr THEN FIND FIRST en_mstr WHERE en_domain = GLOBAL_domain
       NO-LOCK NO-ERROR.

   vcFile     =   en_entity + 'IER'
                  + substring(string(year(today),"9999"),3,2)
                  + string(month(today),"99")
                  + string(day(today),"99")
                  + ".txt".
   xfilename = vcfile.
repeat:
    /* Set up for data validation */
    IF xstatus1    = hi_char THEN xstatus1    = "".
    if site1       = hi_char then site1       = "".
    IF part1       = hi_char THEN part1       = "".
    IF buyer1      = hi_char THEN buyer1      = "".
    IF supplier1   = hi_char THEN supplier1   = "".

    update xstatus
           xstatus1
           site
           site1
           part
           part1
           buyer
           buyer1
           supplier
           supplier1
           /* TRH Removed 20111028 Unneeded
           xincludezero                    */
           xftpflag
           xfilename
    with frame a side-labels width 80.

    /* Begin Input Validation Here           */
    IF xstatus1    = ""  THEN xstatus1    = hi_char.
    if site1       = ""  then site1       = hi_char.
    if part1       = ""  then part1       = hi_char.
    if buyer1      = ""  then buyer1      = hi_char.
    if supplier1   = ""  then supplier1   = hi_char.
    IF xfilename   = "" THEN do:
         /*error message */
        {us/bbi/pxmsg.i &MSGTEXT="mess1"}
         next-prompt xfilename with frame a.
         undo,retry.
    END.


    bcdparm = "".
    {us/mf/mfquoter.i xstatus}
    {us/mf/mfquoter.i xstatus1}
    {us/mf/mfquoter.i site}
    {us/mf/mfquoter.i site1}
    {us/mf/mfquoter.i part}
    {us/mf/mfquoter.i part1}
    {us/mf/mfquoter.i buyer}
    {us/mf/mfquoter.i buyer1}
    {us/mf/mfquoter.i supplier}
    {us/mf/mfquoter.i supplier1}
    /* TRH Removed 20111028 Unneeded
    {us/mf/mfquoter.i xincludezero}        */
    {us/mf/mfquoter.i xftpflag}
    {us/mf/mfquoter.i xfilename}

    /*EE2014-795-Add-Begin*/
    Assign
       l_qty_net       = 0
       l_qty_nonet     = 0
       l_part_type     = " "
       /*ld_past_due     = 0 07-EE2014-795*/
       req             = 0 /*07-EE2014-795*/
       l_ord_min       = 0
       ord_mult        = 0
       l_um            = " "
       l_std_pack      = 0
       l_po_um         = " "
       l_translt_days  = 0.
    /*EE2014-795-Add-End*/

    if search(xfilename) <> ? then do:
       {us/bbi/pxmsg.i &MSGNUM=3122 &ERRORLEVEL=2}
    end.

    vtEnd   = hi_date.
    vtStart = TODAY.

    /* Set Start Date to most recent Monday date */
    do while not (weekday(vtStart) = 2):
       vtStart = vtStart - 1.
    end.
    dates[1] = vtStart.
    vtend = vtStart + 175.  /*Every thing before vtend is fair game */

    /* Now set 23 subsequent weekly Monday dates */
    do i = 2 to viNbrWeeks:
       dates[i] = dates[i - 1] + 7.
    end.

   {us/mf/mfselbpr.i "printer" 132}
   {us/bbi/mfphead.i}

   /* Added by TRH on 20111024 for ESMA 0602361US */
   IF xftpflag  THEN DO:
       RUN get_ftpconn (INPUT "IER",
                        OUTPUT remote_dir,
                        OUTPUT remote_addr,
                        OUTPUT remote_user,
                        OUTPUT remote_passwd,
                        OUTPUT success).
   END.
   IF xftpflag AND NOT success THEN LEAVE.
   /* end Added by TRH on 20111024 for ESMA 0602361US */

   /*l_tmstmp = string(today) + "-" + string(time,"HH:MM"). /*EE2014-795*/ */
   l_datestp = string(today).         /*EE2014-892*/
   l_timestp = string(time,"HH:MM").  /*EE2014-892*/
 /*EE2020-351 Added Begins ********/
   find first zzcft_mstr where zzcft_domain = global_domain 
                        and   zzcft_site = ""
                        and   zzcft_module = "ENTITLE"
                        no-lock no-error.
   if available zzcft_mstr then do :
   
		assign
		  expflag = true .
		  v_exp_Dir = zzcft_mstr.zzcft_exp_dir.
		  v_cft_exp_Dir = zzcft_cft_exp_dir.
		  v_new_locdirec = l_loc_dir .
	
		if r-index(v_exp_Dir,"/") < length(v_exp_Dir) then        
		  v_exp_Dir = v_exp_Dir + "/".  
		if r-index(v_cft_exp_Dir,"/") < length(v_cft_exp_Dir) then        
		  v_cft_exp_Dir = v_cft_exp_Dir + "/".  
		if r-index(v_new_locdirec,"/") < length(v_new_locdirec) then        
		  v_new_locdirec = v_new_locdirec + "/".  		  
	end. /* if available zzcft_mstr then do : */
	
	IF expflag  THEN
		output stream excel to value(v_cft_exp_Dir + "/" + xfilename).
	else 	 
		
/*EE2020-351 Added Ends ********/ 	 
	output stream excel to value(l_loc_dir + "/" + xfilename).

   put stream excel unformatted
        /*EE2014-795-Comment-Begin
         * /* Header Line 1 */
         * ""                      DLM   /* .5 */
         * ""                      DLM   /* 01 */
         * /* Removed by TRH
         * ""                      DLM   /* 02 */
         * */
         * ""                      DLM   /* 03 */
         * "Vendor"                DLM   /* 3.1 */
         * ""                      DLM   /* 3.5 */
         * ""                      DLM   /* 04 */
         * ""                      DLM   /* 05 */
         * ""                      DLM   /* 06 */
         * ""                      DLM   /* 07 */
         * ""                      DLM   /* 08 */
         * ""                      DLM   /* 09 */
         * ""                      DLM   /* 10 */
         * ""                      DLM   /* 11 */
         * ""                      DLM   /* 11.5 */
         * "Production Requirements by Week" DLM   /* 12 */
         * ""                      DLM   /* 13 */
         * ""                      DLM   /* 14 */
         * ""                      DLM   /* 15 */
         * ""                      DLM   /* 16 */
         * ""                      DLM   /* 17 */
         * ""                      DLM   /* 18 */
         * ""                      DLM   /* 19 */
         * ""                      DLM   /* 20 */
         * ""                      DLM   /* 21 */
         * ""                      DLM   /* 22 */
         * ""                      DLM   /* 23 */
         * ""                      DLM   /* 24 */
         * ""                      DLM   /* 25 */
         * ""                      DLM   /* 26 */
         * ""                      DLM   /* 27 */
         * ""                      DLM   /* 28 */
         * ""                      DLM   /* 29 */
         * ""                      DLM   /* 30 */
         * ""                      DLM   /* 31 */
         * ""                      DLM   /* 32 */
         * ""                      DLM   /* 33 */
         * ""                      DLM   /* 34 */
         * ""                      DLM   /* 35 */
         * ""                      DLM   /* 36 */
         * "Purchase Orders by Week" DLM   /* 37 */
         * ""                      DLM   /* 38 */
         * ""                      DLM   /* 39 */
         * ""                      DLM   /* 40 */
         * ""                      DLM   /* 41 */
         * ""                      DLM   /* 42 */
         * ""                      SKIP  /* 43 */
         *EE2014-795-Comment-End*/

         /* Header Line 2 */
         "Date"                  DLM /*EE2014-892*/
         "Time"                  DLM /*EE2014-892*/
         "Site"                  DLM   /* .5 */
         "Item Number"           DLM   /* 01 */
         /* removed by TRH not needed
         "WVSA Vendor"           DLM   /* 02 */
         */
         "ABC Supplier"          DLM   /* 03 */
         "Name"                  DLM   /* 3.1 */
         "PM code"               DLM   /* 3.5 */
         /*"Daily AVG Gross Req"   DLM   /* 04 */ EE2014-795*/
         "Standard Cost"         DLM   /* 05 */
         /*"Daily AVG Consumption" DLM   /* 06 */ EE2014-795*/
         "Qty On Hand"           DLM   /* 07 */

         /*EE2014-795-Add-Begin*/
         "Nettable QTY on Hand"     DLM
         "Non-Nettable QTY on Hand" DLM
         "Item Type"                DLM
         /*EE2014-795-Add-End*/

         /*EE2014-795-Comment-Begin
          *"WIP Net Qty On Hand"   DLM   /* 08 */
          *"Value On Hand"         DLM   /* 09 */
          *"WIP NoNet Qty On Hand" DLM   /* 10 */
          *EE2014-795-Comment-End*/

         "Safety Time"           DLM   /* 11 */
         "Safety Stock"          DLM   /* 11.5 */
         "Past Due"              DLM   /*EE2014-795*/
         "Week 1"                DLM   /* 12 */
         "Week 2"                DLM   /* 13 */
         "Week 3"                DLM   /* 14 */
         "Week 4"                DLM   /* 15 */
         "Week 5"                DLM   /* 16 */
         "Week 6"                DLM   /* 17 */
         "Week 7"                DLM   /* 18 */
         "Week 8"                DLM   /* 19 */
         "Week 9"                DLM   /* 20 */
         "Week 10"               DLM   /* 21 */
         "Week 11"               DLM   /* 22 */
         "Week 12"               DLM   /* 23 */
         "Week 13"               DLM   /* 24 */
         "Week 14"               DLM   /* 25 */
         "Week 15"               DLM   /* 26 */
         "Week 16"               DLM   /* 27 */
         "Week 17"               DLM   /* 28 */
         "Week 18"               DLM   /* 29 */
         "Week 19"               DLM   /* 30 */
         "Week 20"               DLM   /* 31 */
         "Week 21"               DLM   /* 32 */
         "Week 22"               DLM   /* 33 */
         "Week 23"               DLM   /* 34 */
         "Week 24"               DLM   /* 35 */
         "Part Description"      DLM   /* 36 */

         /*EE2014-795-Comment-Begin
          * "Week 1"                DLM   /* 37 */
          * "Week 2"                DLM   /* 38 */
          * "Week 3"                DLM   /* 39 */
          * "Week 4"                DLM   /* 40 */
          *EE2014-795-Comment-End*/

         /*EE2014-795-Add-Begin*/
         "OWeek 1"               DLM   /* 37 */
         "OWeek 2"               DLM   /* 38 */
         "OWeek 3"               DLM   /* 39 */
         "OWeek 4"               DLM   /* 40 */
         "OWeek 5"               DLM
         "OWeek 6"               DLM
         "OWeek 7"               DLM
         "OWeek 8"               DLM
         /*EE2014-795-Add-End*/

         "Planner"               DLM   /* 41 */
         "Prod Line"             DLM   /* 42 */
         /*"Packing Unit"        SKIP. /* 43 */ EE2014-795*/

         /*EE2014-795-Add-begin*/
         "Order Minimum"         DLM
         "Order Multiple"        DLM
         "Item Master UOM"       DLM
         "Standard Pack"         DLM
         "PO UOM"                DLM
         "Transport Days"        skip.
         /*EE2014-795-Add-End*/

         /*07-EE2014-795 Begin Add*/
         find first soc_ctrl
            where soc_domain = global_domain
            no-lock no-error.
         if available soc_ctrl then
            bck = soc_fcst_bck.

         start = TODAY.
         find first mrpc_ctrl
              where mrpc_ctrl.mrpc_domain = global_domain
              no-lock no-error.
         IF AVAILABLE mrpc_ctrl THEN
         DO:
           if (mrpc_sum_def > 0) and
              (mrpc_sum_def < 8) then
           do while not (weekday(start) = mrpc_sum_def):
                 start = start - 1.
           end. /*do while not ...*/
         END. /*IF AVAILABLE mrpc_ctrl*/
         /*07-EE2014-795 End Add*/

         define variable v_count as int .
   for each pt_mstr where pt_domain = global_domain and
            pt_part  >= part  AND pt_part   <= part1 AND /* order changed for performance */
            pt_pm_code = "p" AND
            pt_status >= xstatus AND pt_status <= xstatus1
            no-lock break by pt_part:

       /* ******************************************* */
       /* Detirmine "Favorite" Site                   */
       /* first look for a site that has requirements */
       /* if no Requirements, or multi-site then      */
       /* default to pt_site.                         */
       /* ******************************************* */
       sitecount = 0.
       favoritesite = pt_site.

       /*EE2014-795-Add-Begin*/
       l_um = pt_um.
       l_part_type = pt_part_type.
       /*EE2014-795-Add-End*/

       for each mrp_det WHERE mrp_domain = pt_domain AND
                mrp_site >= site and mrp_site <= site1 AND  /* order changed for performace */
                mrp_part = pt_part and
                mrp_due_date >= dates[1] AND
                mrp_due_date < (dates[ viNbrWeeks ] + 7)
                no-lock
                break by mrp_site:

                if first-of( mrp_site ) then do:
                    sitecount = sitecount + 1.
                end.
                if sitecount = 1 then favoritesite = mrp_site.
                else favoritesite = pt_site.
       end.

       /* end of "Detirmine" Favorite Site             */
       if favoritesite < site or favoritesite > site1 then NEXT.
       /* CALCULTE AVAILABLE STOCK and WIP QTY On Hand and WIP Qty OH Non-Nettable */
       qoh = 0.

       /*EE2014-795-Comment-Begin
        *wipqoh = 0.
        *wipnonnet = 0.
        *voh = 0.
        *EE2014-795-Comment-end*/

       /* TRH ADDED on 20121211 for ESMA 0902774MO */
       oldsite = "".
       oldpart = "".
       costflag = 0.
       l_qty_net = 0.
       l_qty_nonet = 0.
       /* END TRH ADDED on 20121211 for ESMA 0902774MO */
       for each ld_det WHERE ld_domain = pt_domain AND
                                                       ld_part = pt_part and /*EE2014-795-V3*/
                                                       ld_site >= site AND ld_site <= site1 /*AND EE2014-795-V3*/
                               /*ld_part = pt_part EE2014-795-V3*/ NO-LOCK:

           qoh = qoh + ld_qty_oh.

           /*EE2014-795-Add-Begin*/
           /*Calculate the Nettable qty on hand and Non Nettable qty on hand*/
           find first is_mstr
                where is_domain = global_domain
                  and is_status = ld_status
                no-lock no-error.
           if available is_mstr then
           do:
              if is_nettable then
                 l_qty_net = l_qty_net + ld_qty_oh.
              if not is_nettable then
                 l_qty_nonet = l_qty_nonet + ld_qty_oh.
           end.
           /*EE2014-795-Add-end*/

           /*EE2014-795-Comment-Begin
            *IF ld_loc BEGINS "WIP" AND ld_qty_oh <> 0 THEN do:
            *   wipqoh = wipqoh + ld_qty_oh.
            *   /* go get the status of the WIP Location */
            *   FIND FIRST loc_mstr WHERE loc_domain = GLOBAL_domain AND
            *                               loc_site = ld_site AND loc_loc = ld_loc NO-LOCK NO-ERROR.
            *   IF AVAILABLE loc_mstr THEN DO:
            *       FIND FIRST IS_mstr WHERE IS_domain = GLOBAL_domain AND IS_status = loc_status
            *           NO-LOCK NO-ERROR.
            *       IF AVAILABLE IS_mstr THEN
            *           IF NOT IS_nettable  THEN wipnonnet = wipnonnet + ld_qty_oh.
            *   END.
            *END.
            *EE2014-795-Comment-end*/

           /* "Standard Cost" for Inventory Valuation */
           if oldsite <> ld_site or oldpart <> ld_part then do:
               /* You need a new "ucost" */
               found_a_cost = no.
               find in_mstr where in_domain = ld_domain and
                                    in_part = ld_part and
                                    in_site = ld_site
               no-lock no-error.
               if available in_mstr then do:
                   if in_gl_cost_site <> "" and in_gl_cost_site <> ld_site then do:
                       /* you have a linked source site */
                       /* use this site for calculating inventory on hand value */
                       find sct_det where sct_domain = ld_domain and
                                          sct_sim = "Standard" and
                                          sct_part = ld_part and
                                          sct_site = in_gl_cost_site no-lock no-error.
                       if available sct_det then do:

                           voh_cost = sct_cst_tot.
                           found_a_cost = yes.
                           costflag = 1.
                       end.
                   end.
               end.

               if NOT found_a_cost then do:
                   FIND FIRST sct_det where sct_domain = pt_domain AND
                                               sct_sim = "Standard" and
                                              sct_part = ld_part and
                                              sct_site = ld_site and
                                              sct_cst_tot <> 0 no-lock no-error.

                   IF AVAILABLE sct_det THEN
                       voh_cost = sct_cst_tot.
                   ELSE DO:
                       FIND FIRST sct_det WHERE sct_domain = pt_domain AND
                                                sct_sim = "Standard" AND
                                                sct_part = ld_part and
                                                sct_cst_tot <> 0
                       NO-LOCK NO-ERROR.
                       IF AVAILABLE sct_det THEN
                           voh_cost = sct_cst_tot.
                       ELSE
                           voh_cost = pt_price.
                   END.
               end. /* end of NOT found_a_cost */
               oldsite = ld_site.
               oldpart = ld_part.
           end. /* end of if oldsite or oldpart <> ld_site or ld_part */
           /*voh = voh + (ld_qty_oh * voh_cost ). EE2014-795*/

       end. /*for each ld_det*/


       assign totreqs  = 0
              qtyreq   = 0
              qtyord   = 0
              pastreqs = 0
              pastords = 0.

       ASSIGN avendor  = "".

       for each mrp_det where mrp_domain = pt_domain
                         AND mrp_site >= site AND mrp_site <= site1 /* order changed for performance */
                         and mrp_part   = pt_part
                         AND mrp_due_date >= dates[1]
                         and mrp_due_date < ( dates[ viNbrWeeks ] + 7)
                         /* Aggregate
                         and mrp_site   = pt_site */

                         no-lock break by mrp_part
                                       by mrp_due_date:



           if mrp_due_date < dates[1] then do:
               if mrp_type = "DEMAND"  then pastreqs = pastreqs + mrp_qty.
               next.
           end. /* if mrp_due_date < dates[1] */
           //message "706 next" view-as alert-box.
           do i = 1 to ( viNbrWeeks ):

               if mrp_due_date >= dates[i] and mrp_due_date < (dates[i] + 7) then
                   if mrp_type begins "DEMAND" THEN do:
                       qtyreq[i] = qtyreq[i] + mrp_qty.
                       totreqs = totreqs + mrp_qty.
                   END.
               if mrp_due_date >= dates[i] and mrp_due_date < (dates[i] + 7) then
                   if mrp_type begins "SUPPLY" then qtyord[i] = qtyord[i] + mrp_qty.
           end. /* do i = 1 to viNbrWeeks - 1 */

       END. /* for each mrp_det where mrp_part= pt_part */
       message "717" totreqs skip qtyord[i] view-as alert-box.

       /* TRH Replaced per Meeting with Todd of PRTM and Rick Howe  */
       /* Howe: "Just put it under the FTP ESMA                     *
       IF totreqs = 0 AND xincludezero = NO THEN NEXT.              */
       /* ********************************************************* */
       IF totreqs = 0 AND qoh <= 0 THEN NEXT.
       message "727 next" view-as alert-box.
       /* Outside the MRP loop now, but still within for each pt_mstr
       FIND LAST IN_mstr USE-INDEX in_part WHERE IN_domain = GLOBAL_domain AND IN_part = pt_part AND
                               in_site >= site AND in_site <= site1 NO-LOCK NO-ERROR.
       IF AVAILABLE in_mstr THEN DO: */
           buyplan = "notfound".
           /* Figure out the Buyer and leave partloop if not in range                     */
           FIND ptp_det WHERE ptp_domain = pt_domain AND ptp_site = favoritesite AND ptp_part = pt_part
               NO-LOCK NO-ERROR.
           IF AVAILABLE ptp_det AND ptp_buyer >= buyer and ptp_buyer <= buyer1 THEN
               ASSIGN l_ord_min  = ptp_ord_min  /*EE2014-795*/
                      ord_mult   = ptp_ord_mult
                      sfty_time  = ptp_sfty_tme
                      sfty_stock = ptp_sfty_stk
                      buyplan    = ptp_buyer.
           else if not available ptp_det AND
                     pt_buyer   >= buyer and pt_buyer <= buyer1 THEN
               ASSIGN l_ord_min  = pt_ord_min /*EE2014-795*/
                      ord_mult = pt_ord_mult
                     sfty_time = pt_sfty_time
                     sfty_stock = pt_sfty_stk
                     buyplan = pt_buyer.
           IF buyplan = "notfound" THEN NEXT.
           message "750 next" view-as alert-box.
           ponbr = "".

           /* TRH REPLACED 20121212
           /* Figure out the ABC vendor for display side by side with the xxwvsarp vendor */
           FOR last qad_wkfl where qad_domain = global_domain AND qad_key1 = "poa_det" and
                  qad_key2 begins string(favoritesite,"x(8)") + string(pt_part,"x(18)") and
                  qad_decfld[1] > 0 and qad_datefld[1] <= vtstart by qad_datefld[1]:
                  assign ponbr = qad_charfld[1].
           END.

           IF ponbr > "" THEN DO:
               FIND po_mstr WHERE po_domain = pt_domain AND po_nbr = ponbr NO-LOCK NO-ERROR.
               IF AVAILABLE po_mstr THEN DO:
                   bvendor = po_vend.
                   FIND FIRST WHERE pod_domain = po_domain AND pod_nbr = po_nbr AND
                                              pod_part = pt_part NO-LOCK NO-ERROR.
                   IF AVAILABLE(pod_det) THEN firm_days = pod_firm_days.

               END.
           END.
           ELSE DO:
               FOR EACH pod_det NO-LOCK WHERE pod_domain = pt_domain AND pod_part = pt_part AND
                   pod_site = favoritesite AND NOT pod_sched AND pod_stat = "",
                   EACH po_mstr NO-LOCK WHERE po_domain = pod_domain AND po_nbr = pod_nbr
                       BY po_ord_date DESC BY po_nbr DESC:

                       ASSIGN bvendor = po_vend
                                 ponbr = po_nbr
                             firm_days = pod_firm_days.

                       LEAVE.
                   END.

           END. /* End else do: */
           */

           Bvendor = pt_vend.
           Highdate = 01/01/70.

           /*07-EE2014-795 Begin Add*/
           assign
              dwm = "w"
              req = 0.

           {us/fc/fcsdate.i today fcsduedate week site}
           fcsduedate = fcsduedate - 7 * bck.

           sdate[1] = low_date.
           {us/mf/mfcsdate.i}

           for each mrp_det no-lock
              where mrp_domain = global_domain
                and mrp_site   >= site
                and mrp_site   <= site1
                and mrp_part   = pt_part
              /*use-index mrp_site_due EE2014-795-V3*/
              :

              if mrp_dataset = "fcs_sum" then
                 next.
                 message "811 next" view-as alert-box.
              m_due_date = mrp_due_date.

              do i = num_intervals + 1 to 1 by -1:
                 if m_due_date >= sdate[i] then
                 do:
                    if mrp_type begins "demand" then
                    do:
                       if mrp_dataset = "sod_det" then
                          req[i] = req[i] + mrp_qty.
                       else
                       if mrp_dataset = "wod_det" then
                          req[i] = req[i] + mrp_qty.
                       else
                       if mrp_dataset = "wo_scrap" then
                          req[i] = req[i] + mrp_qty.
                       else
                       if mrp_dataset = "fcs_sum" then
                          req[i] = req[i] + mrp_qty.
                       else
                       if mrp_dataset = "pfc_det" then
                          req[i] = req[i] + mrp_qty.
                       else
                          req[i] = req[i] + mrp_qty.
                       if mrp_dataset = "fc_det" then
                          req[i] = req[i] - mrp_qty.
                    end. /*IF mrp_type BEGINS "demand"*/

                    if i = num_intervals + 1 then
                       more = yes.

                    leave.
                 end. /*if m_due_date >= sdate[i] ...*/
              end. /*do i = num_intervals + 1 to 1 by -1:*/
           end. /*for each mrp_det*/
           /*07-EE2014-795 End Add*/

           /* loop through poa_mstr records with effective dates only in the past/current */
           /* for this domain, site, part   */
/*ES0003201MX*/ assign podfound = false.
           For each poa_mstr where poa_domain = GLOBAL_domain and
                                     Poa_part = pt_part and  /*EE2014-795-V3*/
                                     Poa_site = favoritesite and
                                     /*Poa_part = pt_part and EE2014-795-V3*/
                                Poa_eff_date <= TODAY no-lock:
               /* only interested in progressively later dates for this domain/site/part */
               If poa_eff_date >= highdate then do:
                   /* reset highest percentage for each date */
                   Highpercent = 0.
                   /* loop through the detail records for this effective date */
                   For each poad_det where poad_domain = poa_domain and
                                 Poad_det.oid_poa_mstr = poa_mstr.oid_poa_mstr no-lock:
                       /* only interested in percentages > zero */
                       If poad_percent > 0 then do:
                           /* see if you found a new highest percentage ? this is the po supplying
                              The greatest percentage of the part for the latest known effective date */
                           If poad_percent > highpercent then do:
                               /* capture this effective date as the latest with a non-zero percentage */
                               /* making all previous effective date obsolete */
                               /* capture the po_vend                                   */
                               Find first po_mstr where po_domain = GLOBAL_domain and
                                                           Po_nbr = poad_po_nbr no-lock no-error.
                               If available po_mstr then do:
                                   assign bvendor = po_vend
/*ES0003201MX*/                           podfound = true.

                               End.
                            
                                 


                               Highdate = poa_eff_date.
                               Highpercent = poad_percent.

                               Ponbr = poad_po_nbr.

                               /* use the po_nbr and pod_line from the detail table to look up firm days */
                               Find first pod_det where pod_domain = poad_domain and
                                                        Pod_nbr = ponbr and
                                                          pod_line = poad_pod_line
                               no-lock no-error.
                               /*EE2014-795-Comment-Begin
                                *If available pod_det then
                                *   Firm_days = pod_firm_days.
                                *EE2014-795-Comment-End*/

                               /*EE2014-795-Add-Begin*/
                               if available pod_det then
                               do:
                                  assign
                                     firm_days       = pod_firm_days
                                     l_std_pack      = pod_ord_mult
                                     l_po_um         = pod_um
                                     l_translt_days  = pod_translt_days.
                                  /*if pod_status = "" and
                                   *pod_due_date <= today then
                                   *   ld_past_due = pod_qty_ord - pod_qty_rcvd.
                                   *07-EE2014-795 Delete*/
                               end.
                               /*EE2014-795-Add-End*/
                               else
                                   Firm_days = 0.
                           End.
                              /*EE2020-323-add-start-*/ 
                                if poad_percent = 100 then do:
                                    Find first po_mstr where po_domain = GLOBAL_domain and
                                                           Po_nbr = poad_po_nbr no-lock no-error.
                                     if avail po_mstr then a_vend = po_vend.  
                                end.  
                               /*EE2020-323-add-end-*/ 
                       End.
                   End.
               End.
           END.
/*ES0003201MX - start add */
           if not podfound then do:
               FOR EACH pod_det NO-LOCK where pod_domain = pt_domain AND pod_part = pt_part,
                EACH po_mstr WHERE po_domain = pod_domain and po_nbr = pod_nbr
                BREAK BY pod_start_eff[1] DESCENDING:
                    ASSIGN bvendor = po_vend
                          ponbr = po_nbr
                          firm_days = pod_firm_days
                          podfound = true
                         /*EE2014-795-Add-Begin*/
                         firm_days       = pod_firm_days
                         l_std_pack      = pod_ord_mult
                         l_po_um         = pod_um
                         l_translt_days  = pod_translt_days.
                         /*if pod_status = "" and pod_due_date <= today then
                          *   ld_past_due = pod_qty_ord - pod_qty_rcvd.
                          *07-EE2014-795 Delete*/
                         /*EE2014-795-Add-End*/
                    LEAVE.
               END.
           end. /* if not poafound */
/*ES0003201MX - end add */


           if bvendor < supplier or bvendor > supplier1 then NEXT.
           message "950 next" view-as alert-box.
         /*EE2014-795-Comment-Begin
          * /* Average Daily Requirements */
          * davgreq = 0.
          * davgconsumption = 0.
          * oldpart = "".
          * oldsite = "".
          * for each mrp_det no-lock where mrp_domain = pt_domain AND mrp_site >= site
          *       AND mrp_site <= site1
          *       and mrp_part = pt_part and
          *       (mrp_type = "demand" /* ##### TRH or can-do("cs sch_mstr,sod_det", mrp_dataset) */ ) and
          *        mrp_due_date >= vtstart and mrp_due_date < ( dates[24] + 7 ):
          *
          *        davgreq = davgreq + mrp_qty.
          *
          *        /* "Standard Cost" for Daily Average Consumption */
          *        if oldpart <> mrp_part or oldsite <> mrp_site then do:
          *            found_a_cost = no.
          *
          *            /* you need to find a new mrp_cost. */
          *            find in_mstr where in_domain = mrp_domain and
          *                               in_part = mrp_part and
          *                               in_site = mrp_site no-lock no-error.
          *            if available in_mstr then do:
          *                if in_gl_cost_site <> "" and in_gl_cost_site <> mrp_site then do:
          *
          *                    FIND sct_det where sct_domain = pt_domain AND
          *                                                sct_sim = "Standard" and
          *                                               sct_part = pt_part and
          *                                               sct_site = in_gl_cost_site
          *                    no-lock no-error.
          *                    IF AVAILABLE sct_det then do:
          *                        mrp_cost = sct_cst_tot.
          *                        found_a_cost = yes.
          *                        costflag = 2.
          *                    end.
          *                end.
          *            end.
          *
          *            if NOT found_a_cost then do:
          *                 FIND FIRST sct_det where sct_domain = pt_domain AND
          *                                             sct_sim = "Standard" and
          *                                            sct_part = mrp_part and
          *                                            sct_site = mrp_site and
          *                                            sct_cst_tot <> 0
          *                 no-lock no-error.
          *                 IF AVAILABLE sct_det THEN
          *                     mrp_cost = sct_cst_tot.
          *                 ELSE DO:
          *                     FIND FIRST sct_det where sct_domain = pt_domain AND
          *                                             sct_sim = "Standard" and
          *                                            sct_part = mrp_part and
          *                                            sct_cst_tot <> 0 no-lock no-error.
          *                     if available sct_det then
          *                         mrp_cost = sct_cst_tot.
          *                     else
          *                         mrp_cost = pt_price.
          *                 END.
          *            end. /* end of NOT found_a_cost */
          *            oldsite = mrp_site.
          *            oldpart = mrp_part.
          *        end. /* end of oldpart or oldsite <> mrp_part or mrp_site */
          *
          *        /* Daily Average Consumption  */
          *        davgconsumption = davgconsumption + (mrp_qty * mrp_cost).
          *
          * end. /*for each mrp_det*/
          * davgreq = ROUND( davgreq / ( 168 ), 2).
          *EE2014-795-Comment-End*/

           /* "Standard Cost" for display */
           If costflag = 0 then do:
                FIND sct_det where sct_domain = pt_domain AND
                                            sct_sim = "Standard" and
                                            sct_part = pt_part and
                                            sct_site = favoritesite and
                                            sct_cst_tot <> 0
                no-lock no-error.
                IF AVAILABLE sct_det THEN
                    ucost = sct_cst_tot.
                ELSE do:
                    find first sct_det where
                                             sct_domain = global_domain and  /*EE2014-795-V3*/
                                             sct_sim = "Standard" and
                                            sct_part = pt_part and
                                            sct_cst_tot <> 0 no-lock no-error.
                    if available sct_det then
                        ucost = sct_cst_tot.
                    else
                        ucost = pt_price.
                END.
           END.
           ELSE DO:
               if costflag = 1 then
                   ucost = voh_cost.
               else
                   ucost = mrp_cost.
           END.
           /* Daily Average Consumption  - Now agregated */
          /* davgconsumption = ROUND( davgconsumption / (168), 2). EE2014-795*/

   vendorname = "".
   FIND FIRST ad_mstr WHERE ad_domain = GLOBAL_domain AND ad_addr = bvendor NO-LOCK NO-ERROR.
   IF AVAILABLE ad_mstr THEN vendorname = ad_name.


   put stream excel unformatted
         /* Detail */
         l_datestp               DLM   /*EE2014-892*/
         l_timestp               DLM   /*EE2014-892*/
         favoritesite            DLM   /* .5 */
         pt_part                 DLM   /* 01 */       
         /* Removed by TRH
         avendor                 DLM   /* 02 */   */
         a_vend                  DLM                /*EE2020-323*/
     /*  bvendor                 DLM   /* 03 */  */ /*EE2020-323-comment*/  
         vendorname              DLM   /* 3.1 */
         pt_pm_code              DLM   /* 3.5 */
         /*davgreq                 DLM   /* 04 */ EE2014-795*/
         ucost                   DLM   /* 05 */
         /*davgconsumption         DLM   /* 06 */ EE2014-795*/
         qoh                     DLM   /* 07 */
         /*EE2014-795-Add-Begin*/
         l_qty_net               DLM
         l_qty_nonet             DLM
         l_part_type             DLM
         /*EE2014-795-Add-End*/

         /*EE2014-795-Comment-Begin
          *wipqoh                  DLM   /* 08 */
          *voh                     DLM   /* 09 */
          *wipnonnet               DLM   /* 10 */
          *EE2014-795-Comment-End*/

         sfty_time               DLM   /* 11 */
         sfty_stock              DLM    /* 11.5 */
         round(req[1],0)         DLM.   /*07-EE2014-795*/

   do i = 1 to (viNbrWeeks):
         put stream excel UNFORMATTED qtyreq[i] DLM.  /* 12 - 35 */
   end. /* do i = 1 to viNbrWeeks - 1 */

   PUT STREAM excel UNFORMATTED pt_desc1 DLM.

   /*EE2014-795-Comment-Begin
    *do i = 1 to 4:
    *     put stream excel UNFORMATTED qtyord[i] DLM.  /* 37 - 40 */
    *end.
    *EE2014-795-Comment-End*/

   /*EE2014-795-Add-Begin*/
   do i = 1 to 8:
      put stream excel UNFORMATTED qtyord[i] DLM.
   end.
   /*EE2014-795-Add-end*/

   PUT STREAM excel UNFORMATTED
         buyplan                 DLM   /* 41 */
         pt_prod_line            DLM   /* 42 */
         /*ord_mult               SKIP.  /* 43 */ EE2014-795*/

         /*EE2014-795-Add-begin*/
         l_ord_min               DLM
         ord_mult                DLM
         l_um                    DLM
         l_std_pack              DLM
         l_po_um                 DLM
         l_translt_days          skip.
         /*EE2014-795-Add-End*/

         v_count = v_count + 1 .
     message v_count view-as alert-box.
   END. /* End of for each pt_mstr */

/* Message to user about output  location */

FIND FIRST pgmi_mstr WHERE pgmi_exec = "xxinenex" NO-LOCK NO-ERROR.
IF AVAILABLE pgmi_mstr THEN DO:
    IF pgmi_type = "desktop" THEN DO:
        DISPLAY "Your Pipe Delimited Excel-Friendly text file can be found at: " SKIP.
        DISPLAY "Report Output Files. ".
    END.
    ELSE DO:
        DISPLAY "Your Pipe Delimited Excel-Friendly text file can be found at: " SKIP.
        DISPLAY l_loc_dir + "/" + xfilename FORMAT "X(78)".
    END.
END.



OUTPUT STREAM excel CLOSE.
/*EE2020-351 Added Begins ***************/
	IF expflag  THEN do :	       
		    unix silent value( 'mv '
                        + v_cft_exp_Dir
                        + xfilename
                        + ' '
                        + v_exp_Dir
                        + xfilename
                        ).
	end.				
	/*EE2020-351 Added end ***************/	

     /* TRH Added on 20111024 for ESMA 0602361US */
  	IF expflag = no  THEN do : /*EE2020-351*/
     IF xftpflag THEN
     RUN transfer_file(INPUT l_loc_dir,
                       INPUT xfilename,
                       INPUT remote_dir,
                       INPUT remote_addr,
                       INPUT l_transfer_type,
                       INPUT remote_user,
                       INPUT remote_passwd,
                       OUTPUT transfer_error). /*EE2014-736*/
     /* end Added by TRH on 20111024 for ESMA 0602361US */
	end. /*IF expflag = no  THEN do :*/ /*EE2020-351*/
{us/mf/mfrtrail.i}

END.  /* end of Repeat: */
{us/xx/xxftp.i}


PROCEDURE getPORDPast :
   define input  parameter irPOD  as recid no-undo.
   define output parameter odPORD as decimal no-undo.

   define buffer pod_det for pod_det.
   define buffer sch_mstr for sch_mstr.

   find first pod_det no-lock
        where recid(pod_det) = irPOD no-error.
   if avail pod_det then do:
      find first sch_mstr no-lock
           where sch_domain  = global_domain
             and sch_type    = 4
             and sch_nbr     = pod_nbr
             and sch_line    = pod_line
             and sch_rlse_id = pod_curr_rlse_id[1] no-error.
      if avail sch_mstr then
         odPORD = sch_pcr_qty - pod_cum_qty[1].
      else
         odPORD = - pod_cum_qty[1].
   end.
END PROCEDURE. /* End of getPORDPast */