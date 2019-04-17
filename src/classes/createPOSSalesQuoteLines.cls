/*--------------------------------------------------------------------------------------------------------------
Author:         Mani Sundaresan
Description:    this class is used to create the POSSales quote lines related relavant quote.

History:
<Date>          <Authors Name>      <Brief Description of Change>
06/07/2018      Mani Sundaresan       Initial Creation (US-0004421)
06/26/2018      Kasmoor Reddy         Implemented best practices (US-0004421)
08/02/2018      Andrew Maggi            Add in Gold Fluoro POS quoting ability (US-US-0005108)
02/11/2018      Kasmoor Reddy         Checking null pointer exceptions on Product (US-0006736)
----------------------------------------------------------------------------------------------------------------*/
global class createPOSSalesQuoteLines{

    @InvocableMethod
    public static void createPOSQuoteLines(List<Id> serviceQuoteId){
    
        System.debug('serviceQuoteId:'+serviceQuoteId);
        
        List<SBQQ__QuoteLine__c> posQuoteLineList = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
        
        SBQQ__Quote__c quote;
        
        if(serviceQuoteId.size()>0){
        //Get serviceQuote Details
        quote = [SELECT Id, POS_Quote__c, Quote_Calc_Trigger__c from SBQQ__Quote__c where Id IN :serviceQuoteId];
        }
        System.debug('quote:'+quote);
        
         
        if(quote != null){
        //Get QuoteLines related to POS Quote
        quoteLineList = [SELECT Id, SBQQ__Product__r.Name , SBQQ__Product__c, isPOSQL__c, SBQQ__ListPrice__c, SBQQ__Product__r.Product_Source_Division__c, SBQQ__Product__r.Product_Source_Division__r.Source_Division_Number__c, Name, LongDescription__c from SBQQ__QuoteLine__c where SBQQ__Quote__c = :quote.POS_Quote__c and POS_Coverage_Eligible_Flag__c = True];
        }
        System.debug('quoteLineList:'+quoteLineList);
        
        //Get Product Records
        Map<String, Product2> productMap = new Map<String, Product2>();
        
        for(Product2 prod : [SELECT Id, Name, LongDescription__c, ProductCode, Service_Class__c, Service_Level__c from Product2 where Name IN ('PLATINUM BONE', 'PLATINUM BREVERA', 'PLATINUM MAMMO', 'GOLD FLUORO', 'FAXITRON SERVICE CONTRACT', 'LOCALIZER SERVICE CONTRACT')])
            productMap.put(prod.Name, prod);
       
        System.debug('productMap:'+productMap);
        
        SBQQ__QuoteLine__c posQL;
        Product2 p2;
        if(quoteLineList.size()>0){
            for(SBQQ__QuoteLine__c ql : quoteLineList){
        System.debug('productName:'+ql.SBQQ__Product__r.Name);
               if(ql.SBQQ__Product__r.Name == 'BIOVISION10X15' || ql.SBQQ__Product__r.Name == 'BIOVISION+12X15' || ql.SBQQ__Product__r.Name == 'COREVISION5X10' || ql.SBQQ__Product__r.Name == 'PATHVISION23X29' || ql.SBQQ__Product__r.Name == 'VERSAVISION10X15' || ql.SBQQ__Product__r.Name == 'VERSAVISION12X15' || ql.SBQQ__Product__r.Name == 'VERSAVISION6X15' || ql.SBQQ__Product__r.Name == 'MULTIFOCUS10X15' || ql.SBQQ__Product__r.Name == 'MULTIFOCUS12X15' || ql.SBQQ__Product__r.Name == 'ULTRAFOCUS10X15' || ql.SBQQ__Product__r.Name == 'ULTRAFOCUS10X15DXA' || ql.SBQQ__Product__r.Name == 'ULTRAFOCUS23X29' || ql.SBQQ__Product__r.Name == null)
                    p2 = productMap.get('FAXITRON SERVICE CONTRACT');            
               else if(ql.SBQQ__Product__r.Name == '09-0001' || ql.SBQQ__Product__r.Name == null)
                   p2 = productMap.get('LOCALIZER SERVICE CONTRACT');
               else if(ql.SBQQ__Product__r.Product_Source_Division__r.Source_Division_Number__c == '300' || ql.SBQQ__Product__r.Product_Source_Division__r.Source_Division_Number__c == '305' || ql.SBQQ__Product__r.Product_Source_Division__c == null)
                   p2 = productMap.get('PLATINUM MAMMO');
               else if(ql.SBQQ__Product__r.Product_Source_Division__r.Source_Division_Number__c == '200')
                   p2 = productMap.get('PLATINUM BONE');
               else if(ql.SBQQ__Product__r.Product_Source_Division__r.Source_Division_Number__c == '210')
                   p2 = productMap.get('GOLD FLUORO');
               else if(ql.SBQQ__Product__r.Product_Source_Division__r.Source_Division_Number__c == '310')
                   p2 = productMap.get('PLATINUM BREVERA');
                //02/11/2018      Kasmoor Reddy         Checking null pointer exceptions on Product (US-0006736)
                if(p2!=null)
                {
                
                posQL = new SBQQ__QuoteLine__c();
                posQL.LongDescription__c = p2.LongDescription__c;
                posQL.POS_Quote_Line__c = ql.Id;
                posQL.SBQQ__Bundle__c = True;
                posQL.SBQQ__DefaultSubscriptionTerm__c = 12;
                posQL.SBQQ__ListPrice__c = 0;
                posQL.SBQQ__Product__c = p2.Id;
                posQL.SBQQ__Quantity__c = 1;
                posQL.SBQQ__Quote__c = quote.Id;
                posQL.SBQQ__StartDate__c = date.today();
                posQL.SBQQ__SubscriptionBase__c = 'List';
                posQL.SBQQ__SubscriptionPricing__c = 'Fixed Price';
                posQL.Service_Level__c = p2.Service_Level__c;
                posQL.isPOSQL__c = true;
                
                posQuoteLineList.add(posQL);
                }
                 
            } 
        } 
        List<SBQQ__QuoteLine__c> qlList = new List<SBQQ__QuoteLine__c>();
        if(posQuoteLineList.size() > 0)
            for(Integer i = 0; i<posQuoteLineList.size(); i++)
                qlList.add(posQuoteLineList[i]);
                    
        if(qlList.size() > 0){
           Database.SaveResult[] lsr = Database.insert(qlList, false);
                

                for (Integer index = 0; index<lsr.size(); index++) {
                    if (!lsr[index].isSuccess()) {
                        quoteLineList[index].addError('Failed to create quote line: ' + lsr[index].getErrors() [0].getMessage());
                    }
                }
            
        }
        /*for(SBQQ__QuoteLine__c ql : posQuoteLineList){    
            if(ql.SBQQ__Product__r.Name == 'PLATINUM BONE')
                ql.SBQQ__ListPrice__c = 8500;
        }
        update posQuoteLineList;*/
          
       
       
    }
    
}