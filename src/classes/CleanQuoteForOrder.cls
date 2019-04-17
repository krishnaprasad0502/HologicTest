/*------------------------------------------------------------
Author:         Marc Goldstein
Company:        Salesforce.com
Description:    Method to clean Quote For Order, sets Quote Line Item attributes from quote for Integration
Test Class:     Test_CleanQuoteForOrder

History:
<Date>          <Authors Name>      <Brief Description of Change>
06/11/2016      Marc Goldstein      Initial Creation
------------------------------------------------------------*/
public class CleanQuoteForOrder {

    public static void CreateOrder(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap) {
        
        List<Id> defaultQuoteIds = new List<Id>();
        Set<Id> incompleteSystemSet = new Set<Id>();
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();

        for (SBQQ__Quote__c qte : newList) {
            //if create order checked and previously not checked
            if (qte.Create_Order__c==true && oldMap.get(qte.Id).Create_Order__c == false) {            
                defaultQuoteIds.add(qte.Id);
            }
        }

        quoteLines=getQuoteLines(defaultQuoteIds);

        //Validate that all components in a system are fully selected
        incompleteSystemSet = validateAllComponensSelected(quoteLines);

        for (SBQQ__Quote__c qte : newList) {
            if (incompleteSystemSet.contains(qte.Id))
               qte.addError('You must select all components of a system prior to creating an order');   
        }
        updateItemsFromQuote(quoteLines); 
    }

    private static List<SBQQ__QuoteLine__c> getQuoteLines(List<Id> quoteId){
       List<SBQQ__QuoteLine__c> quoteLines = [select 
            ShipTo_Site__c,SBQQ__Quote__r.ShipTo_Site__c
            ,DeliverTo_Site__c,SBQQ__Quote__r.DeliverTo_Site__c 
            ,BillTo_Site__c,SBQQ__Quote__r.BillTo_Site__c
            ,Ship_To_Account__c,SBQQ__Quote__r.Ship_To_Account__c
            ,Deliver_To_Account__c,SBQQ__Quote__r.Deliver_To_Account__c
            ,Bill_To_Account__c,SBQQ__Quote__r.Bill_To_Account__c
            ,FOB__c,SBQQ__Quote__r.FOB__c
            ,Ship_Date__c,SBQQ__Quote__r.Ship_Date__c
            ,Requested_Date__c,SBQQ__Quote__r.Requested_Date__c
            ,Shipping_Method_Code__c, SBQQ__Quote__r.Shipping_Method_Code__c
            ,Sales_Rep__c, SBQQ__Quote__r.SBQQ__SalesRep__c
            ,Payment_Terms__c,SBQQ__Quote__r.SBQQ__PaymentTerms__c
            ,Ready_For_Integration__c
            ,SBQQ__Quote__c,SBQQ__RequiredBy__c,Include_In_Order__c
            from SBQQ__QuoteLine__c 
            where SBQQ__Quote__c in :quoteId
            order by SBQQ__Quote__c,SBQQ__RequiredBy__c nulls last,Include_In_Order__c desc
            ]; 
            
        return quoteLines;
    }
        
 

    //Returns quotes that have unselected component
    private static Set<Id> validateAllComponensSelected(List<SBQQ__QuoteLine__c> quoteLines){
        Set<Id> incompleteSystemSet = new Set<Id>();
        Id prevReqBy;
        Boolean prevIncludeOrder=false;

//Not handling parent
        for (SBQQ__QuoteLine__c ql : quoteLines){
//            system.debug('QID:'+ql.Id);
//            system.debug('RB:'+ql.SBQQ__RequiredBy__c);
//            system.debug('Include in Order:'+ql.Include_In_Order__c);
            
            if(ql.SBQQ__RequiredBy__c!=null && ql.SBQQ__RequiredBy__c==prevReqBy && ql.Include_In_Order__c==false && ql.Include_In_Order__c!=prevIncludeOrder){
                if(!incompleteSystemSet.contains(ql.SBQQ__Quote__c)){
                    incompleteSystemSet.add(ql.SBQQ__Quote__c);
//                   system.debug('Incomplete Set:'+ql.Id);
                }
            }
            prevReqBy=ql.SBQQ__RequiredBy__c;
            prevIncludeOrder=ql.Include_In_Order__c;
        }
        return incompleteSystemSet;
        
    }

    //Defaults are line items that ready for integration to header value
    public static void updateItemsFromQuote(List<SBQQ__QuoteLine__c> quoteLines){
        for (SBQQ__QuoteLine__c ql : quoteLines){
            if (ql.Ready_For_Integration__c){
                if (ql.ShipTo_Site__c==null)
                    ql.ShipTo_Site__c = ql.SBQQ__Quote__r.ShipTo_Site__c;
                if (ql.DeliverTo_Site__c==null)
                    ql.DeliverTo_Site__c = ql.SBQQ__Quote__r.DeliverTo_Site__c;
                if (ql.BillTo_Site__c==null)
                    ql.BillTo_Site__c = ql.SBQQ__Quote__r.BillTo_Site__c;             
                if (ql.Ship_To_Account__c==null)
                    ql.Ship_To_Account__c = ql.SBQQ__Quote__r.Ship_To_Account__c;
                if (ql.Deliver_To_Account__c==null)
                    ql.Deliver_To_Account__c = ql.SBQQ__Quote__r.Deliver_To_Account__c;
                if (ql.Bill_To_Account__c==null)
                    ql.Bill_To_Account__c = ql.SBQQ__Quote__r.Bill_To_Account__c;
                if (String.isBlank(ql.FOB__c))
                    ql.FOB__c = ql.SBQQ__Quote__r.FOB__c;
                if (ql.Ship_Date__c==null)
                    ql.Ship_Date__c = ql.SBQQ__Quote__r.Ship_Date__c;
                if (ql.Requested_Date__c==null)
                    ql.Requested_Date__c = ql.SBQQ__Quote__r.Requested_Date__c;
                //if (String.isBlank(ql.Payment_Terms_Freight__c))
                    //ql.Payment_Terms_Freight__c = ql.SBQQ__Quote__r.Payment_Terms_Freight__c;
                if(String.isBlank(ql.Payment_Terms__c))
                    ql.Payment_Terms__c = ql.SBQQ__Quote__r.SBQQ__PaymentTerms__c;
                if (String.isBlank(ql.Shipping_Method_Code__c))
                    ql.Shipping_Method_Code__c = ql.SBQQ__Quote__r.Shipping_Method_Code__c;
                if(ql.Sales_Rep__c==null)
                    ql.Sales_Rep__c=ql.SBQQ__Quote__r.SBQQ__SalesRep__c;
            }
        }
        update quoteLines;
    }

    public static void SetOperatingUnit(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap){
      
      List<Id> spID = new List<Id>();
      for (SBQQ__Quote__c qte : newList) {
        spID.add(qte.sbqq__salesrep__c);
      }

      
      Map<Id, User> mapSPOperatingUnit = new Map<Id, User>(); 
      for(User us : [select operating_unit__c from User where Id in :spID])
        mapSPOperatingUnit.put(us.Id, us);


      for (SBQQ__Quote__c qte : newList) {
        
          if (mapSPOperatingUnit.containskey(qte.sbqq__salesrep__c)) {            
            
              //Insert Trigger or value has not been set
              //if (oldMap == null || oldMap.get(qte.Id).operating_unit__c == null) {  
              if(qte.operating_unit__c == null || (oldMap != null &&oldMap.get(qte.Id).SBQQ__SalesRep__c != qte.SBQQ__SalesRep__c)) {
                qte.Operating_Unit__c = mapSPOperatingUnit.get(qte.SBQQ__SalesRep__c).Operating_Unit__c;
                qte.Order_Type__c = '';
              }
          }
      }  

      
  }
  
}