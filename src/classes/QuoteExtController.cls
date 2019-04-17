/*------------------------------------------------------------
Author:         Larry DellaRocco
Company:        Salesforce.com
Description:    SBQQ__Quote__c actions
Test Class:     test_QuoteExtController

History:
<Date>          <Authors Name>      <Brief Description of Change>
07/17/2017        Kent Smith         Custom Validation Rule for Diagnostic Lab Opportunities
11/21/2017        Mani Sundaresan    Extended Bill To/Ship To site validation for BSH division (US-0003590)
06/29/2018        Ronald Mendoza     Extended Bill To/Ship to validation for Diag Perinatal, Added Validation for no quote lines
08/03/2018        Ronald Mendoza     US-0005286 - Validation for Medical Aesthetics to prevent admins from submittings quotes for approval
08/29/2018        Ronald Mendoza     US-0005303 - Validation for Auto Contract Assignment to require notes if Contract Prices have been discounted
02/05/2019		  Krishna Prasad     US-0004134 - If quote status is executed you cannot recall the quote
02/06/2019        Krishna Prasad     US-0006608 - Quote cannot be submitted for Approval since it is not a Primary Quote
------------------------------------------------------------*/


public with sharing class QuoteExtController {
    private Id quoteId;
	public SBQQ__Quote__c QuoteQuery;
    public SBAA__Approval__c[] approvals {get; set;}
    public QuoteExtController(ApexPages.StandardController stdController) {
        quoteId = stdController.getId();
		QuoteQuery = [select id,SBQQ__Status__c,ApprovalStatus__c,SBQQ__Opportunity2__r.Recordtypeid,SBQQ__Primary__c from SBQQ__Quote__c where id =:quoteId ];
    }
    
    public List<SBQQ__QuoteLine__c> lines { get; private set;}
    public Boolean haveLineErrors { get { return lines!= null && lines.size() > 0;}}
    
    private List<Schema.FieldSetMember> getQuoteLineFields() {
        return SObjectType.SBQQ__QuoteLine__c.FieldSets.Approval_Validation.getFields();
    }
    
    private List<SBQQ__QuoteLine__c> getQuoteLines() {
        String query = 'SELECT ID,';
        for(Schema.FieldSetMember f : this.getQuoteLineFields()) {
            query += f.getFieldPath() + ', ';
        }
        query += ' Quotable__c FROM SBQQ__QuoteLine__c where Quotable__c = false AND SBQQ__Quote__c = \'' + quoteID + '\'';        
        //String soql='Select ' + richTextField + ' FROM ' + objectname + ' where id=\'' + parId +'\'';
        return Database.query(query);
    } 
    
    
    /*----------------------------------------

History:
<Date>          <Authors Name>      <Brief Description of Change>
7/17/2017        Kent Smith         Updating Query with GMC_Approval_Level__c
11/21/2017       Mani Sundaresan    Extended Bill To/Ship To site validation for BSH division (US-0003590)


-----------------------------------------*/
    
    public Boolean validateQuote() {
        
        
        
        Boolean valid=true;
        Integer equipmentGroupCount = 0;
        Boolean tierNotAvailable = false;
        Boolean tierAvailable = false;
        
        /* Rich Varga Apps Associates */
        /* Add field Net Amount */
        /* HD-3492*/
        
        
        /* Rich Varga Apps Associates */
        /* added bill to fields */
        /* added ship to fields */
        /* added deliver to fields */
        /* Hd-4288 */
        
        SBQQ__Quote__c theQuote = [select FOB__c, SBQQ__PaymentTerms__c, Payment_Terms_Freight__c, Marketing_Program__c,
                                   Shipping_Method_Code__c, SBQQ__Opportunity2__r.RecordType.Name,   BillTo_Site__c, ShipTo_Site__c,
                                   Bill_To_Account__c,Ship_To_Account__c,Ship_Date__c,Requested_Date__c,SBQQ__PrimaryContact__c,Loaner_Eval_Period__c,
                                   SBQQ__Quote__c.SBQQ__NetAmount__c, 
                                   BillTo_Site__r.Active__c, BillTo_Site__r.Bill_To__c  , 
                                   Shipto_Site__r.Active__c, ShipTo_Site__r.Ship_To__c    ,
                                   Deliverto_Site__r.Active__c, DeliverTo_Site__r.Deliver_To__c, GMC_Approval_Level__c, /*add GMC_Approval_Level__c (ks)*/
                                   SBQQ__Type__c, /* Added Type to check for renewals to exclude billing and shipping validation*/
                                   /* Rich Varga Apps Associates  */
                                   /* Added Opportunity Record Type */
                                   /* US-0002853 */
                                   Opportunity_Record_Type__c, SBQQ__LineItemCount__c, SBQQ__SalesRep__r.Profile.Name, Auto_Contract_Agreed_Price_Discounted__c, SBQQ__Notes__c,SBQQ__Opportunity2__r.Recordtypeid,SBQQ__Primary__c /* RMendoza Added Line Item Count */
                                   //US-0005303 *Vinay Nallakadi* *Apps Associates* Added Contract_Auto_Assigned__c field to query *Validation to prevent submitting approvals for Quotes that have Contract Auto Assigned=false
                                   ,Contract_Auto_Assigned__c
                                   from SBQQ__Quote__c where id=:quoteId];
        
        List<SBQQ__QuoteLine__c> quoteLineList = [SELECT Id, Tier__c, SBQQ__Group__c, SBQQ__Group__r.Name from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteId];
        
        for(SBQQ__QuoteLine__c ql : quoteLineList){
            if(ql.SBQQ__Group__r.Name == 'Equipment' || ql.SBQQ__Group__c == NULL)
                equipmentGroupCount++;
            if(ql.Tier__c != null && ql.Tier__c > 0)
                tierAvailable = true;
            if(ql.Tier__c == NULL || ql.Tier__c == 0)  
                tierNotAvailable = true;  
        }
        
        
        //Integer equipmentGroupCount = [SELECT Count() from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quoteId AND (SBQQ__Group__r.Name = 'Equipment' OR SBQQ__Group__c = null)];
        
        
        /* added Rich Varga Apps Associates */
        /* Sum payment amount from payment schedule for validation */
        /* HD-3264  */
        
        
        AggregateResult[] groupedResults = [SELECT SUM(Payment_Total__c) FROM Payment_Schedule__c where Quote__c = :quoteId]; 
        
        
        
        System.debug('Count:'+equipmentGroupCount);
        system.debug('Amt  :'+(groupedResults[0].get('expr0')));
        
        try {
            if(theQuote.SBQQ__Opportunity2__r.RecordType.Name == 'B&SH Service Contract Opportunity') {
                /*
* bill to site and shipt to site removed as required fields for service conracts
*
if(theQuote.BillTo_Site__c == null) {
ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Bill To Site Required prior to Approval'));
valid=false;
}*/
                if(theQuote.ShipTo_Site__c == null) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Ship To Site Required prior to Approval'));
                    valid=false;
                }
                if(theQuote.Ship_To_Account__c == null) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Ship To Account Required prior to Approval'));
                    valid=false;
                }
                
                /* added Rich Varga Apps Associates */
                /*  Compare total amount from payment schedule to quote total */
                /* HD-3264  */      
                
                if(groupedResults[0].get('expr0') != theQuote.SBQQ__NetAmount__c)
                {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'The total payments does not match the quote total. Please review the payments before submitting this quote..'));
                    valid=false;    
                }
                
            } else
                /* Rich Varga Apps Associates */
                /* Added the  Bill to site and ship site check for Surgical */
                
            { //Added condition to run validation for diagnostic lab record types - RMendoza, Added condition to exclude validation for renewals
                //Added condition to run validation for BSH record type(US-0003590)
                if(theQuote.BillTo_Site__c == null && (theQuote.Opportunity_Record_Type__c == 'Surgical Open Opportunity' || theQuote.Opportunity_Record_Type__c == 'B&SH Professional Services' || ((theQuote.Opportunity_Record_Type__c == 'Diagnostic Lab Open Opportunity' || theQuote.Opportunity_Record_Type__c == 'Diagnostic Perinatal Open Opportunity') && theQuote.SBQQ__Type__c != 'Renewal'))) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Bill To Site Required prior to Approval'));
                    valid=false;
                }  //Added condition to run validation for diagnostic lab record types - RMendoza, Added condition to exclude validation for renewals
                if(theQuote.ShipTo_Site__c == null && (theQuote.Opportunity_Record_Type__c == 'Surgical Open Opportunity' || theQuote.Opportunity_Record_Type__c == 'B&SH Professional Services' || ((theQuote.Opportunity_Record_Type__c == 'Diagnostic Lab Open Opportunity' || theQuote.Opportunity_Record_Type__c == 'Diagnostic Perinatal Open Opportunity') && theQuote.SBQQ__Type__c != 'Renewal'))) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Ship To Site Required prior to Approval'));
                    valid=false;
                }
                if(String.isBlank(theQuote.FOB__c)) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'FOB Required prior to Approval'));
                    valid=false;
                }
                if(String.isBlank(theQuote.SBQQ__PaymentTerms__c)) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Payment Term (AR) Required prior to Approval'));
                    valid=false;
                }
                if(String.isBlank(theQuote.Payment_Terms_Freight__c)) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Payment Term (Freight) Required prior to Approval'));
                    valid=false;
                }
                /* Rich Varga Apps Associates */
                /* Added Opp Record type as added condition */
                /* For ship date and request date */
                /*  US-0002853 */
                /*  Rich Varga Apps Associates */ 
                /* Removed ship date */
                /*  HD-3360 */
                /*
if(theQuote.Ship_Date__c == null && equipmentGroupCount > 0 && theQuote.Opportunity_Record_Type__c != 'Surgical Open Opportunity') {
ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Ship Date Required prior to Approval'));
valid=false;
}
*/
                //if(theQuote.Requested_Date__c == null && equipmentGroupCount > 0  && theQuote.Opportunity_Record_Type__c != 'Surgical Open Opportunity') {
                /* Only check request date for B&SH Open Opportunity */
                /* Rich Varga 7-11-17 */
                if(theQuote.Requested_Date__c == null && equipmentGroupCount > 0  && (theQuote.Opportunity_Record_Type__c== 'B&SH Sales Open Opportunity' ||
                                                                                      theQuote.Opportunity_Record_Type__c== 'B&SH Mammopad Opportunity')){
                                                                                          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Requested Date Required prior to Approval'));
                                                                                          valid=false;
                                                                                      }
                /* Rich Varga Apps Associates */
                /* Added the  Bill to site and ship site check for Surgical */
                /* Remove the original code check for equipment group count as well */
                //US-0004906 - Add Logic to require bill to and ship to for Perinatal Quotes - Ronald Mendoza
                if(theQuote.Bill_To_Account__c == null && theQuote.Opportunity_Record_Type__c == 'Surgical Open Opportunity' ) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Bill To Account Required prior to Approval'));
                    valid=false;
                }
                if(theQuote.Ship_To_Account__c == null && theQuote.Opportunity_Record_Type__c == 'Surgical Open Opportunity'  ) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Ship To Account Required prior to Approval'));
                    valid=false;
                }
                if(theQuote.SBQQ__PrimaryContact__c == null && equipmentGroupCount > 0) {
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Primary Contact Required prior to Approval'));
                    valid=false;
                }
                if(tierAvailable && tierNotAvailable){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Kindly ensure if Tier is populated on all Quote Lines prior to Approval'));
                    valid=false;
                }
                
                if(String.isBlank(theQuote.Shipping_Method_Code__c) && 
                   (theQuote.Marketing_Program__c=='Trade-in, Trade-up' || theQuote.Marketing_Program__c=='Equipment Purchase' || 
                    theQuote.Marketing_Program__c=='Loaner/Evaluation Agreement' || theQuote.Marketing_Program__c=='Rental Agreement')) {
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Shipping Method Code Required prior to Approval'));
                        valid=false;
                    }
                if(String.isBlank(theQuote.Loaner_Eval_Period__c) && theQuote.Marketing_Program__c == 'Loaner/Evaluation Agreement'){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Loaner Eval Period Required prior to Approval'));
                    valid=false;
                }
                
                
                /* Rich Varga Apps Associates */
                /* HD-4288 */ 
                
                if ((!thequote.BillTo_Site__r.Active__c) &&  (thequote.BillTo_Site__c !=null)){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Bill to Site is not Active'));
                    valid=false;
                }
                if ((!thequote.BillTo_Site__r.Bill_To__c) && (thequote.BillTo_Site__c !=null)){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Bill to Site does not have Active Bill to Usage'));
                    valid=false;
                }
                if ((!thequote.ShipTo_Site__r.Active__c) &&  (thequote.Shipto_Site__c !=null)){ 
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Ship to Site is not Active'));
                    valid=false;
                }
                if ((!thequote.ShipTo_Site__r.Ship_To__c) &&  (thequote.Shipto_Site__c !=null)){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Ship to Site does not have Active Ship to Usage'));
                    valid=false;
                }
                if ((!thequote.DeliverTo_Site__r.Active__c)  &&  (thequote.Deliverto_Site__c !=null)){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Deliver to Site is not Active'));
                    valid=false;
                }
                if((!thequote.DeliverTo_Site__r.Deliver_To__c)  &&  (thequote.Deliverto_Site__c !=null)){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Deliver to Site does not have Active Deliver to Usage'));
                    valid=false;
                }
                /*-----------------(ks) Added validation requiring a value for GMC Approval if the Opportunity is for Diagnostic Lab---------------------*/     
                if(thequote.GMC_Approval_Level__c == null && thequote.Opportunity_Record_Type__c == 'Diagnostic Lab Open Opportunity'){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please add a GMC Approval level before submitting for Approval'));
                    valid=false;
                }
                //US-0005303 - Validation for Auto Contract Assignment to require notes if Contract Prices have been discounted
                if(thequote.Auto_Contract_Agreed_Price_Discounted__c == true && thequote.SBQQ__Notes__c  == null){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please input internal notes to specify reasoning for discounting contracted prices'));
                    valid=false;
                }
              
                
                //US-0005286 - Validation to prevent non sales reps to be entered in as sales reps
                //List<Profile> PROFILE = [SELECT Id, Name FROM Profile WHERE Id=:theQuote.SBQQ__SalesRep__c.getProfileId() LIMIT 1];
                //String userProfileName = PROFILE[0].Name;
                if(thequote.SBQQ__SalesRep__r.Profile.Name != null && thequote.SBQQ__SalesRep__r.Profile.Name != ''){
                    String userProfileName = thequote.SBQQ__SalesRep__r.Profile.Name;
                    if(userProfileName == 'Medical Aesthetics Enablement Admin' || userProfileName == 'Medical Aesthetics Sales Admin' 
                       || userProfileName == 'Corporate Sales Admin' || userProfileName == 'Corporate System Administrator' ||
                       userProfileName == 'System Administrator' || userProfileName == 'B&SH Enablement Admin' || userProfileName == 'Surgical Enablement Admin'
                       || userProfileName == 'Diagnostics Enablement Admin'){
                           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please Populate Sales Rep field with a valid Sales Rep User'));
                           valid=false;
                       }
                }
                   //US-0005303 Validation to prevent Quote from submitting for approval if are Contract Auto Assigned is false
         if(thequote.Opportunity_Record_Type__c.contains('B&SH') &&thequote.Marketing_Program__c=='Equipment Purchase'  && thequote.Contract_Auto_Assigned__c==false){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'This Quote must use Auto Contract Assignment Functionality'));
             valid=false;
         }
               
            }
        } catch(Exception e) {
            
        }
        
        lines = getQuoteLines();
        if(lines.size()>0) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Quote contains non-Quotable products. Please remove or replace any non-Quotable products.'));
            valid=false;
        } //US-0004906 - Added validation to require quote lines before submitting for approval - RMendoza
        else if (theQuote.SBQQ__LineItemCount__c < 1){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Quote has no quote lines.  Please add products before submitting for approval'));
            valid=false;
        }
        return valid;
    }
    
    public PageReference backToQuote() {
        return new PageReference('/' + quoteId);
    }
    //02/06/2019        Krishna Prasad     US-0006608 - Quote cannot be submitted for Approval since it is not a Primary Quote
    public PageReference onSubmit() {
	/*if (quoteId != null) {
		if(validateQuote()) {
		SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
		return new PageReference('/' + quoteId);
		}
	}
	return null;*/
	
	Record_Type_IDs__c MesRecordTypes = Record_Type_IDs__c.getOrgDefaults();

	if (quoteId != null) {
        system.debug('outside if');
		if(validateQuote()) {
            system.debug('inside if');
            if(QuoteQuery.SBQQ__Opportunity2__r.Recordtypeid == MesRecordTypes.Opportunity_Medical_Aesthetics_Svc_Contr__c && QuoteQuery.SBQQ__Primary__c != true){
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Quote cannot be submitted for Approval since it is not a Primary Quote'));
				return null;
            }else{
                SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
			    return new PageReference('/' + quoteId);
            }
			return null;
		}
		return null;
	}
    return null;    
}	
    //02/05/2019		  Krishna Prasad     US-0004134 - If quote status is executed you cannot recall the quote	
    public PageReference onRecall() {
        
		if(QuoteQuery.ApprovalStatus__c != 'Executed'){
			if (quoteId != null) {
				SBAA.ApprovalAPI.recall(quoteId, SBAA__Approval__c.Quote__c);
			}
			return new PageReference('/' + quoteId);
		}else{
			 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Quote is in Executed status and cannot be recalled'));
			return null;
		}
    }
    public PageReference onPreview() {
        if (quoteId != null) {
            approvals = SBAA.ApprovalAPI.preview(quoteId, SBAA__Approval__c.Quote__c);
        }
        return null;
    }
}