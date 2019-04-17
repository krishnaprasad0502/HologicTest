/*------------------------------------------------------------
Author:     Kasmoor Reddy     
Company:    Apps Associates   
Description:Display QuoteLines of the Quote   
Inputs:     Pass Quote id from button
Returns:    Return list of Quote Lines related to the passed Quote Id from the button

History:
<Date>      <Authors Name>    <Brief Description of Change>
11/22/2018   Kasmoor Reddy     Initial Creation (US-0005626)
------------------------------------------------------------*/
public class QuoteLinesSpecificToQuoteClass {
    //Variable declarations
    @TestVisible private integer totalRecs = 0;
    @TestVisible private integer OffsetSize = 0;
    @TestVisible private integer LimitSize= 20;
    public List<SBQQ__QuoteLine__c> QuoteLineList{get;set;}
    public SBQQ__Quote__c quote { get; set; }
    
    
    //public String Integrationmessage {get;set;}
    public QuoteLinesSpecificToQuoteClass(ApexPages.StandardController controller)
    {
        this.quote = (SBQQ__Quote__c) controller.getRecord();
        
        totalRecs=[select count() from SBQQ__QuoteLine__c where SBQQ__Quote__c=:quote.id and Include_In_Order__c = True];
        //Add list of Quote Lines of the Quote Id Passed
        QuoteLineList=new List<SBQQ__QuoteLine__c>([select Name,Agreed_Price_Line__c ,Include_In_Order__c,Integration_Message__c,BillTo_Site__r.Account__r.Parent_Account_Number__c,ShipTo_Site__r.Account__r.Parent_Account_Number__c,BillTo_Site__r.Oracle_Party_Site_Number__c,ShipTo_Site__r.Oracle_Party_Site_Number__c,Received_By_Integration__c,Integration_Status__c,SBQQ__Product__c,Bill_To_Account__c,BillTo_Site__c,Ship_To_Account__c,ShipTo_Site__c,SBQQ__Quote__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=: quote.id and Include_In_Order__c = True LIMIT :LimitSize OFFSET :OffsetSize]);
        //Integrationmessage = QuoteLineList[0].
    }
    public PageReference Search()
    {
        
        QuoteLineList=new List<SBQQ__QuoteLine__c>([select Name,Agreed_Price_Line__c ,BillTo_Site__r.Account__r.Parent_Account_Number__c,ShipTo_Site__r.Account__r.Parent_Account_Number__c,BillTo_Site__r.Oracle_Party_Site_Number__c,ShipTo_Site__r.Oracle_Party_Site_Number__c,Include_In_Order__c,Integration_Message__c,Received_By_Integration__c,Integration_Status__c,SBQQ__Product__c,Bill_To_Account__c,BillTo_Site__c,Ship_To_Account__c,ShipTo_Site__c,SBQQ__Quote__c from SBQQ__QuoteLine__c where SBQQ__Quote__c=: quote.id and Include_In_Order__c = True LIMIT :LimitSize OFFSET :OffsetSize]);       
        return null;
    }
    //pagination
    public void previous()
    {
        OffsetSize = OffsetSize-LimitSize;
        
        Search();
        
    }
    public void next()
    {
        OffsetSize = OffsetSize + LimitSize;
        
        Search();
        
    }
    public boolean getprev()
    {
        if(OffsetSize == 0)
            return true;
        else
            return false;
    }
    public boolean getnxt()
    {
        if((OffsetSize + LimitSize) > totalRecs)
            return true;
        else
            return false;
    }
    public PageReference ReturnToQuote()
    {
        //Id QuoteId=ApexPages.currentPage().getParameters().get('id');
        PageReference pageRef=new ApexPages.StandardController(quote).view();
        //new PageReference('/'+quote.id);
        return pageRef;
        
    }
    public PageReference SaveQuoteLines()
    {
        update QuoteLineList;
        return null;
    }
   
}