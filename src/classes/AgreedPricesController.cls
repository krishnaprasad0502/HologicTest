/*--------------------------------------------------------------------------------------------------------------------
Author:     Gerald Ricciardi
Company:    Apps Associates
Description:  Custom controller to get Agreed Prices for an Account
Test Class:    Test_AgreedPricesController

History:
<Date>      <Authors Name>    <Brief Description of Change>
07/27/2017   Gerald Ricciardi    Initial Creation (US-0003129)

----------------------------------------------------------------------------------------------------------------------*/
public with sharing class AgreedPricesController {
    @AuraEnabled
    public static List<Agreed_Price__c> getAgreedPrices(Id accountId) {
        
        //System.debug('in controller ID'+accountId);
        List<Id> contractsList = new List<Id>();
        List<Agreed_Price__c> agreedPricesBasedonTier = new List<Agreed_Price__c>();
        
        
        List<Customer_Eligible_Contract__c> cecList = [SELECT Id, Tier__c, Contract__c
                                                       FROM Customer_Eligible_Contract__c
                                                       WHERE Customer_Account__r.Id = :accountId AND 
                                                       Agreement_Active__c = TRUE];
        
        //System.debug('in controller CEC size'+cecList.size());
        
        for (Customer_Eligible_Contract__c cec  : cecList) {
            contractsList.add(cec.Contract__c);
            
        }       
        
        //System.debug('Contract List:'+contractsList);
        
        List<Agreed_Price__c> agreedPrices = [SELECT Contract__r.Id, Contract__r.Name, Contract__r.ContractNumber, 
                                              Name, Product__r.Name, Product__r.Brand__c, Product__r.ShortDescription__c, 
                                              List_Price__c, Price__c, Active__c, Start_Date__c, End_Date__c, Tier_Formula__c,Division__c
                                              FROM Agreed_Price__c
                                              WHERE Contract__c IN :contractsList AND 
                                              Division__c LIKE 'Surgical%' AND
                                              Active__c = TRUE 
                                              ORDER BY Product__r.Brand__c ASC, Product__r.Name ASC
                                             ];
        
        //System.debug('in agreedprices size'+agreedPrices.size());
        
        for(Customer_Eligible_Contract__c cec  : cecList) {
            if(cec.Tier__c == null){
                cec.Tier__c = 1;
            }
            for(Agreed_Price__c agreedPrice : agreedPrices){
                System.debug('Division:'+agreedPrice.Division__c);
                if(String.valueOf(agreedPrice.Contract__c).equals(String.valueOf(cec.Contract__c))) {
                    if(agreedPrice.Tier_Formula__c == cec.Tier__c){
                        System.debug('in controller tier'+agreedPrice.Tier_Formula__c);
                        agreedPricesBasedonTier.add(agreedPrice);
                    }
                }
                
            }
        }
        //System.debug('final values*****:'+agreedPricesBasedonTier.size());

        return agreedPricesBasedonTier;
        
    }
}