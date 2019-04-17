/*------------------------------------------------------------
Author:         Kasmoor Reddy
Company:        Salesforce.com
Description:    Update Location based on Selected to Bill To Address (US-6149)
Test Class:     AssetTrigger_Test.AssetForBillToAddressUpdate

History:
<Date>          <Authors Name>      <Brief Description of Change>
2/13/2019       Kasmoor Reddy       Initial Creation (US-6149)
------------------------------------------------------------*/
public class AssetTriggerActions_Ext {
    public static void UpdateAssetLocation(List<Asset> newAssetList,Map<Id,Asset> oldAssetMap)
    {
        Map<Id,Id> BillToParentId=new Map<Id,Id>();
        List<Id> BillIds=new List<Id>();
        for(Asset ass:newAssetList)
        {
          if(ass.Bill_To_Address__c!=null)
          BillIds.add(ass.Bill_To_Address__c);  
        }
        system.debug('Selected Bill to Address:'+BillIds);
        List<Schema.Address> billAddress=new List<Schema.Address>([select id,ParentId from Address where id in: BillIds]);
        for(Schema.Address add:billAddress)
        {
            BillToParentId.put(add.id,add.ParentId);
        }
        system.debug('Selected Bill To Address with respective ParentId:'+BillToParentId);
        for(Asset ass:newAssetList)
        {
            
            if(ass.Bill_To_Address__c!=null && (oldAssetMap==null|| ass.Bill_To_Address__c!=oldAssetMap.get(ass.id).Bill_To_Address__c))
            {
                system.debug('In if - to update location:'+ass.Bill_To_Address__c);
                if(BillToParentId.containsKey(ass.Bill_To_Address__c))
                ass.Locationid=BillToParentId.get(ass.Bill_To_Address__c);
            }
            else
            {
                system.debug('In else - to update location as null when Bill Address is null:'+ass.Bill_To_Address__c);
                if(ass.Bill_To_Address__c==null)
                    ass.Locationid=null;
            }
        }
        
       
    }
}