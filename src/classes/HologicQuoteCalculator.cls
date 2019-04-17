global class HologicQuoteCalculator implements SBQQ.QuoteCalculatorPlugin { 

    global void onInit(SObject[] lines) {
    }

    global void onBeforeCalculate(SObject quote, SObject[] lines) {

        //Query if Renewal Field or Amend Field is Null on Related Opportunity
        //If eitehr are filled out, Skip all of the price overrides below
        //If both are null this is a new quote
            //Query the Custom Object (Customer_Eligible_Contract__c) based on the Account id

            //**Check if the Precedence is Unique
                //If Precedence is not Unique, Use CEC Field on the Quote
                    //Create Product Map (Map is Product ID + Tier => Price$)
                    //Create Product Map (Map is Product ID + Tier => Discount%)
                //If Precedence is Unique, Order Precedence and Create the Map
                    //Create Product Map (Map is Product ID + Tier => Price$)
                    //Create Product Map (Map is Product ID + Tier => Discount%)
            //**If CEC Field is Blank, NOTHING HAPPENS

            //**NOTE, When check CEC's, Query is filtered by Active Agreement=true, Selected=true

            //Return all of the Contract based on Order, Create Map, 
            //Retrieve Pricing Agreement Lines in Contract Order, Attach them to a Number Map, Only retrieve Prices of "Active" Products
            //Loop lines by Order and return Final Map of Product Code to Prices based on Priority

            
        String quoteId = (String)quote.get(String.valueOf(SBQQ__Quote__c.id));
        String quoteType=(String)quote.get(String.valueOf(SBQQ__Quote__c.Quote_Type__c));

        quoteType=(quoteType==NULL) ? '' : quoteType;

        SBQQ__Quote__c quoteDetails=[Select SBQQ__Opportunity2__r.RecordType.Name,Use_List_Price__c,SBQQ__Account__c, SBQQ__Opportunity2__r.Sales_Opp_Type__c, SBQQ__Opportunity2__r.SBQQ__AmendedContract__c,Contract_AgreedPrice_Map__c, SBQQ__Opportunity2__r.SBQQ__RenewedContract__c from SBQQ__Quote__c where id=:quoteId];

        // if this is a B&SH Service Contract, contracted pricing is not used and no further actions need to take place
        if(quoteDetails.SBQQ__Opportunity2__r.RecordType.Name == 'B&SH Service Contract Opportunity')
            return;
        Set<Id> prodOptIds = new Set<Id>();
        for(SObject line : lines) {
           String po = (String)line.get(String.valueOf(SBQQ__QuoteLine__c.SBQQ__ProductOption__c));
           if(!String.isBlank(po))
               prodOptIds.add(po);
        }
        
        Map<Id,SBQQ__ProductOption__c> poMap = new Map<Id,SBQQ__ProductOption__c>(
            [select Id, SBQQ__UnitPrice__c from SBQQ__ProductOption__c where Id in: prodOptIds]);
        // if Use List Price checked, nothing to do
        if(quoteDetails.Use_List_Price__c) {
            for(SObject line : lines) {
                Decimal origPrice = (Decimal)line.get(String.valueOf(SBQQ__QuoteLine__c.SBQQ__OriginalPrice__c));
                String po = (String)line.get(String.valueOf(SBQQ__QuoteLine__c.SBQQ__ProductOption__c));
                if(!String.isBlank(po) && poMap!= null && poMap.get(po)!=null && poMap.get(po).SBQQ__UnitPrice__c != null)
                   origPrice = poMap.get(po).SBQQ__UnitPrice__c;
                else
                    origPrice=(origPrice==NULL) ? 0 : origPrice;
                line.put(SBQQ__QuoteLine__c.SBQQ__ListPrice__c, origPrice);
                line.put(SBQQ__QuoteLine__c.Agreed_Price_Line__c,null);
            }
           return;
        }

        if(quoteDetails.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c==null && quoteDetails.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c==null){
/*
            if(String.isBlank((String)quote.get(String.valueOf(SBQQ__Quote__c.Contract_Price_Map__c))) &&
               String.isBlank((String)quote.get(String.valueOf(SBQQ__Quote__c.Contract_Price_Map_Discounts__c))))
               return;
*/
            //CREATE MAPS from Fields
            Map<String,Decimal> priceMap=new Map<String,Decimal>();
            Map<String,Decimal> discountMap=new Map<String,Decimal>();
            Map<String,String> idMap=new Map<String,String>();

            String pricelist=(String)quote.get(String.valueOf(SBQQ__Quote__c.Contract_Price_Map__c));
            String discountlist=(String)quote.get(String.valueOf(SBQQ__Quote__c.Contract_Price_Map_Discounts__c));
            String idlist=(String)quote.get(String.valueOf(SBQQ__Quote__c.Contract_AgreedPrice_Map__c));
            
        
            system.debug(pricelist);
            system.debug(discountlist);

            
            if(pricelist!=null){
                List<String> pricearray = pricelist.split(',');

                for(Integer i = 0; i < pricearray.size(); i++) {
                    String prices=pricearray[i];
                    
                    List<String> pricesubarray = prices.split(';');

                    String productId;
                    Decimal contractprice;
                    productId=pricesubarray[0];
                    contractprice=Decimal.valueOf(pricesubarray[1]);
            
                    
                    
                    priceMap.put(productId, contractprice);
                }
            }

            if(discountlist!=null){
                List<String> discarray = discountlist.split(',');

                for(Integer i = 0; i < discarray.size(); i++) {
                    String discounts=discarray[i];
                    
                    List<String> discsubarray = discounts.split(';');

                    String productId;
                    Decimal contractDisc;
                    productId=discsubarray[0];
                    contractDisc=Decimal.valueOf(discsubarray[1]);
            
                    
                    
                    discountMap.put(productId, contractDisc);
                }
            }
                
            if(idlist!=null){
                List<String> idarray = idlist.split(',');

                for(Integer i = 0; i < idarray.size(); i++) {
                    String ids=idarray[i];
                    
                    List<String> idsubarray = ids.split(';');

                    String productId;
                    String apid;
                    
                    productId=idsubarray[0];
                    apid=idsubarray[1];
            
                    
                    
                    idMap.put(productId, apid);
                }
            }
                
            system.debug(discountMap);
            system.debug(priceMap);

            for(SObject line : lines) {
                String productid = (String)line.get(String.valueOf(SBQQ__QuoteLine__c.PAProductKey__c));
                String productcode = (String)line.get(String.valueOf(SBQQ__QuoteLine__c.SBQQ__ProductCode__c));
                productid=(productid==NULL) ? '' : productid;
                Decimal origPrice = (Decimal)line.get(String.valueOf(SBQQ__QuoteLine__c.SBQQ__OriginalPrice__c));
                String po = (String)line.get(String.valueOf(SBQQ__QuoteLine__c.SBQQ__ProductOption__c));
                if(!String.isBlank(po) && poMap!= null && poMap.get(po) != null && poMap.get(po).SBQQ__UnitPrice__c != null)
                   origPrice = poMap.get(po).SBQQ__UnitPrice__c;
                else
                    origPrice=(origPrice==NULL) ? 0 : origPrice;
                Decimal listPrice=0;
                
                if(quoteType=='Non-Contracted Pricing'){
                    //Agreed_Price__c ap=finalMapping.get(productid);
                    Decimal mydiscount;
                    if(discountMap.containsKey(productid)) {
                        mydiscount=discountMap.get(productid);
                        line.put(SBQQ__QuoteLine__c.Agreed_Price_Line__c,idMap.get(productId));
                    }
                    else if(discountMap.containsKey(productcode)) {
                        mydiscount=discountMap.get(productcode);
                        line.put(SBQQ__QuoteLine__c.Agreed_Price_Line__c,idMap.get(productcode));
                    }
                    mydiscount=(mydiscount==NULL) ? 0 : mydiscount;
                    listPrice=origPrice * (1-mydiscount);
                    line.put(SBQQ__QuoteLine__c.SBQQ__ListPrice__c, listPrice);
                }else if(quoteType!='Non-Contracted Pricing'){
                    Decimal myPrice = origPrice;
                    if(pricemap.get(productid)!= null) {
                        myPrice=priceMap.get(productId);
                        line.put(SBQQ__QuoteLine__c.Agreed_Price_Line__c,idMap.get(productId));
                    }
                    else if(productcode != productid && pricemap.get(productcode)!= null) {
                        myPrice=priceMap.get(productcode);
                        line.put(SBQQ__QuoteLine__c.Agreed_Price_Line__c,idMap.get(productcode));
                    }
                    line.put(SBQQ__QuoteLine__c.SBQQ__ListPrice__c, myPrice);
                }
            }

        }

    }

    global void onBeforePriceRules(SObject quote, SObject[] lines) {
        Map<Id, SObject> linesWithCoveredAssets = new Map<Id,SObject>();
        for(SObject line : lines) 
            if(!String.isBlank((String)line.get(String.valueOf(SBQQ__QuoteLine__c.Covered_Asset__c))) ||
               !String.isBlank((String)line.get(String.valueOf(SBQQ__QuoteLine__c.POS_Quote_Line__c)))) {
                linesWithCoveredAssets.put(line.Id,line);
            }
        
        for(SObject line : lines) {
            String reqBy  = (String)line.get(String.valueOf(SBQQ__QuoteLine__c.SBQQ__RequiredBy__c));
            if(!string.isBlank(reqBy)&&linesWithCoveredAssets.get(reqBy)!=null) {
                SObject parentLine = linesWithCoveredAssets.get(reqBy);
                line.put(SBQQ__QuoteLine__c.Covered_Asset__c,(string)parentLine.get(String.valueOf(SBQQ__QuoteLine__c.Covered_Asset__c)));
                line.put(SBQQ__QuoteLine__c.POS_Quote_Line__c,(string)parentLine.get(String.valueOf(SBQQ__QuoteLine__c.POS_Quote_Line__c)));
                line.put(SBQQ__QuoteLine__c.Covered_Product_Number_from_Parent__c ,(string)parentLine.get(String.valueOf(SBQQ__QuoteLine__c.Covered_Product_Number__c )));
              
            }
        }

    }

    global void onAfterPriceRules(SObject quote, SObject[] lines) {


    }

    global void onAfterCalculate(SObject quote, SObject[] lines) {
    }

    
}