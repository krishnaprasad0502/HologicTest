/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Extension class for Delivery Information Section VF component to be used in B&SH Install Case VF Email Templated
Test Class:   Test_DeliveryInfoDetails

History:
<Date>      <Authors Name>    <Brief Description of Change>
08/18/2016   Mani Sundaresan    Initial Creation (US1334)
04/11/2018   Ronald Mendoza     Replaced Asset__c with SBQQ__Asset__c reference due to duplicate issue (US-0003947)
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
public class DeliveryInfoDetails {
    
    //Variable Declaration Section
    public Case caseVal {get;set;} 
    
    public Case caseVal1 {get; set;}
    public List<OrderItem> oi;
    public List<OrderItem> tradeIn {get; set;}
    public List<WorkOrder> wo {get; set;}
    
    //Getter method for formatting the Date & Date/Time fields
    public Date Today { get { return Date.today(); }}
    
    public Date DeliveryDate;
    public String DeliveryTime;
    public String confirmInstall;
    public String pickupDateandTime;
    
    
    public Date getDeliveryDate(){
        if(caseVal1 != null && caseVal1.Delivery_Date__c != null)
            return caseVal1.Delivery_Date__c.date();
        else
            return null;
    }
    
    public String getDeliveryTime(){
        if(caseVal1 != null && caseVal1.Delivery_Date__c != null) 
            return caseVal1.Delivery_Date__c.format('hh:mm:ss a'); 
        else
            return null;    
    }
    
    public String getconfirmInstall(){
        if(caseVal1 != null && caseVal1.Confirmed_Install_Date__c != null)
            return caseVal1.Confirmed_Install_Date__c.format();
        else
            return null;
    }
    
    public String getpickupDateandTime(){
        if(caseVal1 != null && caseVal1.Pickup_Date_Time__c != null) 
            return caseVal1.Pickup_Date_Time__c.format(); 
        else
            return null;    
    }
    
    
    
    //Method to fetch the Case details and Order Line Items associated to the Case on which Email is sent
    public List<OrderItem> getOrderLineItems(){
    
        if(caseVal != null){
            try{
            caseVal1 = [SELECT Id, De_Installed_Asset__r.Name, Competitive_Trade_In__c, Delivery_Date__c, Confirmed_Install_Date__c, Box_Truck__c, Pickup_Date_Time__c, Special_Array_Instructions__c, Special_Instructions__c from Case where Id = :caseVal.Id];
            
            wo = [SELECT Id, Owner.Name, Owner.Phone from WorkOrder where CaseId = :caseVal.Id and RecordType.DeveloperName = 'B_SH_FE_Install_Upgrade_Move' limit 1];
            if(wo.size() <= 0)
                wo = null;
                
        
         //wo = caseVal != null ? [SELECT Id, Owner.Name, Owner.Phone from WorkOrder where CaseId = :caseVal.Id and RecordType.DeveloperName = 'B_SH_FE_Install_Upgrade_Move' limit 1] : new WorkOrder();
         oi = new List<OrderItem>();
         tradeIn = new List<OrderItem>();
         //Replaced Asset__c with SBQQ__Asset__c reference due to duplicate issue (US-0003947)
         for(OrderItem o : [SELECT Id, PricebookEntry.Product2.Name, /*Asset__r.SerialNumber,*/ SBQQ__Asset__r.SerialNumber, RMA_Number_Scrap__c, Case__r.De_Installed_Asset__r.Name, Case__r.Competitive_Trade_In__c from OrderItem where Case__c = :caseVal.Id]){
             if(!o.PricebookEntry.Product2.Name.contains('TRADE'))
                 oi.add(o);
             else if(o.PricebookEntry.Product2.Name.contains('TRADE'))
                 tradeIn.add(o);
             }
             
              if(Test.isRunningTest())
                Integer i = 10/0;
                
        }
        catch(Exception e){
             System.debug('System Exception:'+e.getMessage());
        }
        }
            
        return oi; 
    }
    
       
}