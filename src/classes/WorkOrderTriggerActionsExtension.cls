/*------------------------------------------------------------
Author:     Krishna prasad
Description:  Trigger framework for WorkOrder object
Test Class:   WorkOrderTriggerActions_Test

6/02/2018   krishna Prasad      Updated the logic--  Ability to generate new Orders from a Work Order that was re-opened (US-0003810)
------------------------------------------------------------*/
public class WorkOrderTriggerActionsExtension {
    
    
    public static void UpdateWorkOrderDetails(List<WorkOrder> newWorkOrderList, Map<Id, WorkOrder> oldMap){
    List<Id> MaintenancePlanIds=new List<Id>();
    List<MaintenancePlan> mpDetailsList = new List<MaintenancePlan>();
    for(Workorder wr:newWorkOrderList){
        WorkOrder old = oldMap.get(wr.Id);
        system.debug('wr.SuggestedMaintenanceDate::'+wr.SuggestedMaintenanceDate);
        system.debug('old.SuggestedMaintenanceDate::'+old.SuggestedMaintenanceDate);
        if(wr.SuggestedMaintenanceDate != old.SuggestedMaintenanceDate){
        MaintenancePlanIds.add(wr.MaintenancePlanId );
        }
    }
   
    if(MaintenancePlanIds.size()>0){    
       mpDetailsList = [select id,Frequency,FrequencyType,(select id,MaintenancePlanId,SuggestedMaintenanceDate,WorkOrderNumber from WorkOrders where status ='New' ORDER BY WorkOrderNumber ASC)  from MaintenancePlan where id in: MaintenancePlanIds];
    }
    map<id,MaintenancePlan> mpMap = new map<id,MaintenancePlan>();
    for(MaintenancePlan mpDetails: mpDetailsList ){ 
        mpMap.put(mpDetails.id,mpDetails);
    }
    list<WorkOrder> PREworkOrderList = new list<WorkOrder> ();
    list<WorkOrder> POSTworkOrderList = new list<WorkOrder> ();
    list<WorkOrder> woListUpdate = new list<WorkOrder> ();
    for(Workorder wrl:newWorkOrderList){
        for(MaintenancePlan mpDetails: mpDetailsList ){            
            for(WorkOrder wr: mpDetails.WorkOrders){
                if(WR.WorkOrderNumber == wrl.WorkOrderNumber){                    
                }else if(WR.WorkOrderNumber < wrl.WorkOrderNumber){                    
                    PREworkOrderList.add(wr);                    
                }else{
                    POSTworkOrderList.add(wr);
                }
            }
        }
    }
    system.debug('PREworkOrderList::'+PREworkOrderList);
    system.debug('POSTworkOrderList::'+POSTworkOrderList);
    system.debug('PREworkOrderList.size()::'+PREworkOrderList.size());
    system.debug('POSTworkOrderList.size()::'+POSTworkOrderList.size());
    integer preCount = PREworkOrderList.size();
    for(Workorder wrl:newWorkOrderList){
        for(WorkOrder wr: PREworkOrderList){
            wr.SuggestedMaintenanceDate = addFrequency( wrl.SuggestedMaintenanceDate, mpMap.get(wr.MaintenancePlanId).Frequency,mpMap.get(wr.MaintenancePlanId).FrequencyType,preCount,'PRE') ;
            woListUpdate.add(wr);            
            system.debug('preCount::'+preCount);
            preCount --;
        }
        integer postCount = 1;
        for(WorkOrder wr: POSTworkOrderList){
            wr.SuggestedMaintenanceDate = addFrequency( wrl.SuggestedMaintenanceDate, mpMap.get(wr.MaintenancePlanId).Frequency, mpMap.get(wr.MaintenancePlanId).FrequencyType,postCount,'POST') ;            
            woListUpdate.add(wr);            
            system.debug('preCount::'+postCount);
            postCount ++;
        }
    }
    system.debug('woListUpdate::'+woListUpdate);
    map<id,WorkOrder> WorkOrderMap = new map<id,WorkOrder>();
    for(WorkOrder wr: woListUpdate){
        WorkOrderMap.put(wr.id,wr);
    } 
    if (woListUpdate.size() > 0) {
        Database.SaveResult[] lsr = Database.update(WorkOrderMap.values(), false);
       
        for (Integer index = 0; index<lsr.size(); index++) {
            if (!lsr[index].isSuccess()) {
                woListUpdate[index].addError('Failed to update WorkOrder: ' + lsr[index].getErrors() [0].getMessage());
            }
        }
    }
}
public static Date addFrequency(Date dat, Integer freq, String freqType,integer count,string Ref){

    if(freqType == 'Days' && Ref == 'PRE'){
        return dat.addDays(-freq *count);
    } else if(freqType == 'Days' && Ref == 'POST'){
        return dat.addDays(+freq *count);
    }else if( freqType == 'Weeks'&& Ref == 'PRE'){
        return dat.addDays(-7 * freq* count);
    }else if(freqType == 'Weeks' && Ref == 'POST'){
        return dat.addDays(+7 * freq* count);
    } else if(freqType == 'Months' && Ref == 'PRE'){
        return dat.addMonths(- freq* count);
    }else if(freqType == 'Months' && Ref == 'POST'){
        return dat.addMonths(+ freq* count);
    }else if(freqType == 'Years' && Ref == 'PRE'){
        return dat.addYears(-freq*count);
    } else if(freqType == 'Years' && Ref == 'POST'){            
        return dat.addYears(+freq*count);
    }
    return null;
}
    

}