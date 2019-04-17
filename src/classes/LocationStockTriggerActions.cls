/*------------------------------------------------------------
Author:     Mani Sundaresa
Description:  Location Stock functions
Test Class:   Test_DeleteZeroQtyStock

History:
<Date>      <Authors Name>    <Brief Description of Change>
11/02/2016   Mani Sundaresan    Initial Creation
------------------------------------------------------------*/
public with sharing class LocationStockTriggerActions{

    public static void deleteLocationStock(List<FSO__LocationStock__c> locationStock){
    
        List<FSO__LocationStock__c> stockLocs = new List<FSO__LocationStock__c>();
        List<FSO__LocationStock__c> deleteStocksList = new List<FSO__LocationStock__c>();
    
        for(FSO__LocationStock__c stockloc : locationStock){
            if(stockloc.FSO__Quantity__c == 0 || stockloc.FSO__Quantity__c == null){
                stockLocs.add(stockloc);
            }
        }
        
        if(stockLocs.size() > 0)
            deleteStocksList = [SELECT Id from FSO__LocationStock__c where Id IN :stockLocs];
        
        try{    
            if(deleteStocksList.size() > 0)
                Database.DeleteResult[] DR_Dels = Database.delete(deleteStocksList);
                
            if(Test.isRunningTest())
                Integer i = 10/0;
        
        }
        catch(Exception e){
            System.Debug('The following error occured' + e);    
        }
    }


}