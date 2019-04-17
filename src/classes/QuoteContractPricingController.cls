/*
  ------------------------------------------------------------ 
  Author:        John Christy
  Company:       Apps Associates
  Description:   A controller class for the Quote object to lookup Contract_Agreed_Price__c for each Quote Line Item
  Inputs:        "quoteName" - input parameter of quote lookup
  Test Class:    QuoteContractPricingController_Test
  History
  <Date>      <Authors Name>     <Brief Description of Change>
  30-Jul-18   John Christy        Initial creation
  ------------------------------------------------------------                                  
*/
public class QuoteContractPricingController {
    public String quoteName { get; set; }
    public Map<Id, Contract_Agreed_Price__c> ContractAgreedPriceMap = new Map<Id, Contract_Agreed_Price__c> ();
    public List<Contract_Agreed_Price__c> ContractAgreedPriceList;
    public List<Contract_Agreed_Price__c> DefaultContractAgreedPriceList { get; set; }
    List<Id> ProdIds = new List<Id> ();

    public List<Contract_Agreed_Price__c> getContractAgreedPriceList() {
        ContractAgreedPriceList = new List<Contract_Agreed_Price__c> ();
        if (quoteName != null & ContractAgreedPriceList.isEmpty()) {
            // create list of all quote line items
            List<SBQQ__QuoteLine__c> listQuoteLineItems = [
                                                           SELECT Id, Name, SBQQ__Product__c, SBQQ__Quote__r.SBQQ__Account__c, Coverage_Product_Info__c, SBQQ__RequiredBy__c
                                                           FROM SBQQ__QuoteLine__c
                                                           WHERE SBQQ__Quote__r.Name = :quoteName];

            // create array of all product bundles with quote
            AggregateResult[] aggQuoteLineItemBundles = [SELECT SBQQ__RequiredBy__c
                                                         FROM SBQQ__QuoteLine__c
                                                         WHERE SBQQ__Quote__r.Name = :quoteName
                                                         GROUP BY SBQQ__RequiredBy__c];

            // add product bundles to list for ContractAgreedPriceList query
            List<String> prodBundles = new List<String> ();
            for (AggregateResult agg : aggQuoteLineItemBundles) {
                prodBundles.add(String.valueOf(agg.get('SBQQ__RequiredBy__c')));
                System.debug('Agg: ' + agg.get('SBQQ__RequiredBy__c'));
            }
            // create list of all quote line item product ids
            for (SBQQ__QuoteLine__c ql : listQuoteLineItems)
            {
                ProdIds.add(ql.SBQQ__Product__c);
            }

            Date thisDay = Date.today();

            // create list of all product prices in quote line items
            ContractAgreedPriceList = [
                                       SELECT
                                       Id,
                                       Customer_Eligible_Contract__c,
                                       Customer_Eligible_Contract__r.Name,
                                       Customer_Eligible_Contract__r.Customer_Account__c,
                                       Customer_Eligible_Contract__r.Customer_Account__r.Name,
                                       Customer_Eligible_Contract__r.Contract__c,
                                       Customer_Eligible_Contract__r.Contract__r.Name,
                                       Customer_Eligible_Contract__r.Precedence_Value__c,
                                       Agreed_Price__c,
                                       Agreed_Price__r.Price__c,
                                       Agreed_Price__r.Product__c,
                                       Agreed_Price__r.Product__r.Name,
                                       Agreed_Price__r.Product__r.Description,
                                       Agreed_Price__r.Bundle_Product__c,
                                       Agreed_Price__r.Start_Date__c,
                                       Agreed_Price__r.APLookupKeywParent__c
                                       FROM Contract_Agreed_Price__c
                                       WHERE Customer_Eligible_Contract__r.Customer_Account__c = :listQuoteLineItems[0].SBQQ__Quote__r.SBQQ__Account__c
                                       AND Agreed_Price__r.Product__c IN :ProdIds
                                       AND Agreed_Price__r.Bundle_Product__c IN :prodBundles
                                       AND Agreed_Price__r.Start_Date__c<:thisDay
                                       AND Agreed_Price__r.End_Date__c> :thisDay
                                       AND Customer_Eligible_Contract__r.Effective_Date__c<:thisDay
                                       AND Customer_Eligible_Contract__r.Expiration_Date__c> :thisDay
                                       ORDER BY Agreed_Price__r.Product__r.Name, Customer_Eligible_Contract__r.Precedence_Value__c, Agreed_Price__r.Start_Date__c DESC,
                                       Customer_Eligible_Contract__r.Contract__r.Name, Customer_Eligible_Contract__r.Contract__c];

            // create new map of grouped products
            Map<Id, AggregateResult> ContractAgreedPriceAggMap = new Map<Id, AggregateResult> ([
                                                                                               SELECT Agreed_Price__r.Product__c Id
                                                                                               FROM Contract_Agreed_Price__c
                                                                                               WHERE Id IN :ContractAgreedPriceList
                                                                                               GROUP BY Agreed_Price__r.Product__c]);

            // create new instance of default list to populate
            DefaultContractAgreedPriceList = new List<Contract_Agreed_Price__c> ();

            // loop through price list and add first item (in each product group) to default list then remove from list to avoid adding secondary items
            for (Contract_Agreed_Price__c cap : ContractAgreedPriceList) {
                if (ContractAgreedPriceAggMap.containsKey(cap.Agreed_Price__r.Product__c)) {
                    DefaultContractAgreedPriceList.add(cap);
                    ContractAgreedPriceAggMap.remove(cap.Agreed_Price__r.Product__c);
                }
            }

        }

        if (ContractAgreedPriceList.size() > 0) {
            return ContractAgreedPriceList;
        }
        else {
            return null;
        }
    }
}