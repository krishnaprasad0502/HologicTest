/*--------------------------------------------------------------------------------------------------------------------
Author:     Mani Sundaresan
Description:  Extension Class to waypointAssignment VF page. Distributes waypoints across teams based on the allocation.
Test Class:    Test_addOrderLineItems

History:
<Date>      <Authors Name>    <Brief Description of Change>
12/03/2018   Mani Sundaresan    Initial Creation ()
----------------------------------------------------------------------------------------------------------------------*/
public class waypointAssignment {

    //Variable Declaration Section    
    public Swarm_Zone__c sz{get; set;}
    public List<Swarm_Zone_Team__c> szt{get; set;}
    public List<Swarm_Zone_Team__c> deleteszt = new List<Swarm_Zone_Team__c>();
    public List<Swarm_Waypoint__c> swpList{get; set;}
    Map<String, Decimal> dayPercent = new Map<String, Decimal>();
    Map<String, Decimal> monMap = new Map<String, Decimal>();
    Map<String, Decimal> tueMap = new Map<String, Decimal>();
    Map<String, Decimal> wedMap = new Map<String, Decimal>();
    Map<String, Decimal> thurMap = new Map<String, Decimal>();
    Map<String, Decimal> friMap = new Map<String, Decimal>();
    public Boolean allocated{get; set;}
    public Id sztId{get; set;}
    public Integer rowNum{get;set;}
    
    //Constructor
    public waypointAssignment(ApexPages.StandardController controller) {
        
        allocated = false;
        sz = new Swarm_Zone__c();
        //rowNum = 0;
        this.sz = (Swarm_Zone__c)controller.getRecord();
        sz = [SELECT Id, Name, Fiscal_Year__c, Monday__c, Tuesday__c, Wednesday__c, Thursday__c, Friday__c, Days_to_Distribute__c, Swarm_Territory__r.OwnerId, Swarm_Territory__r.Name, Start_Call_Date__c, Start_Optimal_Date__c,  Num_of_Waypoints__c, (SELECT Id, Name, User__c, User__r.Name, Day_Monday__c, Day_Tuesday__c, Day_Wednesday__c, Day_Thursday__c, Day_Friday__c, Sequence__c from Swarm_Zone_Teams__r ORDER BY Sequence__c ASC), (SELECT Id, Name, OwnerId, Owner.Name, Target_Call_Date__c, Optimal_Date__c, Order__c, Status__c from Swarm_Waypoints__r where Status__c IN ( 'Open', 'Valid', 'Call Back' ) ORDER BY Name, Order__c ASC) from Swarm_Zone__c where Id = :sz.id];
        
        szt = new List<Swarm_Zone_Team__c>();
        swpList = new List<Swarm_Waypoint__c>();
        
        if(sz.getSObjects('Swarm_Zone_Teams__r') != null)
            szt = sz.getSObjects('Swarm_Zone_Teams__r');
        
        if(sz.getSObjects('Swarm_Waypoints__r') != null)    
            swpList = sz.getSObjects('Swarm_Waypoints__r');
    }
    
    //Method to add a new team member
    public void addRow(){
        szt.add(new Swarm_Zone_Team__c(Swarm_Zone__c = sz.Id));
    }
    
    //Method to remove a team member
    public void delRow(){
        Integer indexVal = Integer.valueof(system.currentpagereference().getparameters().get('index'));
        //If the team member is an existing record then add it to the list to delete from the databse
        if(szt[indexVal - 1].Id != null)
            deleteszt.add(szt[indexVal - 1]);
        //Remove the team member from the table    
        szt.remove(indexVal - 1);            
    }       
    
    public PageReference waypointDistribution() {
        
        //Variables Declared
        Decimal mon = 0;
        Decimal tue = 0;
        Decimal wed = 0;
        Decimal thur = 0;
        Decimal fri = 0;
        PageReference pg;
        allocated = null;
        swpList.clear();
        Decimal dailyRecordCount;
        System.debug('sz:'+sz);
        
        //Validations
        if(szt.size() == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please add a team member to the zone for allocation.'));
            return null;
        }
        if(sz.getSObjects('Swarm_Waypoints__r') == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please add waypoint records to the zone for allocation.'));
            return null;
        }
        if(sz.Days_to_Distribute__c == 0 && szt == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please update team member percent allocations.'));
            return null;
        }
        if(sz.Start_Call_Date__c == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select a start date to begin calling.'));
            return null;
        }
        if(sz.Start_Optimal_Date__c == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select an appropriate optimal start date to establish meetings.'));
            return null;
        }
        
        if(sz.getSObjects('Swarm_Waypoints__r') != null && sz.Days_to_Distribute__c != 0)
            dailyRecordCount = sz.getSObjects('Swarm_Waypoints__r').size()/Integer.valueOf(sz.Days_to_Distribute__c);
        if(sz.Days_to_Distribute__c == 0 || Test.isRunningTest()){
            Integer mont = 0;
            Integer tuet = 0;
            Integer wedt = 0;
            Integer thurt = 0;
            Integer frit = 0;
            
            for(Swarm_Zone_Team__c stz : szt){
                if(stz.Day_Monday__c > 0)
                    mont = 1;
                if(stz.Day_Tuesday__c > 0)
                    tuet = 1;
                if(stz.Day_Wednesday__c > 0)
                    wedt = 1;
                if(stz.Day_Thursday__c > 0)
                    thurt = 1;
                if(stz.Day_Friday__c > 0)
                    frit = 1;
            }
            dailyRecordCount = sz.getSObjects('Swarm_Waypoints__r').size()/(mont+tuet+wedt+thurt+frit);
        
        }
        System.debug('dailyRecordCount:'+dailyRecordCount);
        
        //Sort Swarm Zone Team in ascending order based on sequence field value
        for(Integer i = 0 ; i < szt.size() ; i ++) {
            for(integer j = i+1 ; j <= szt.size() -1 ; j ++ ){
              Swarm_Zone_Team__c x ;
              if(szt[i].Sequence__c >  szt[j].Sequence__c){
               x = szt[i]  ;
               szt[i] = szt[j]  ;
               szt[j]  = x;
               system.debug('szt:'+szt) ;
              }
            }
        }
        
        for(Swarm_Zone_Team__c szt : szt){
            if(szt.Day_Monday__c != null){
                monMap.put(szt.User__c+'-mon',((szt.Day_Monday__c/100)*dailyRecordCount).round(System.RoundingMode.UP));
                mon += szt.Day_Monday__c;
                System.debug('mon:'+mon); 
            }
            if(szt.Day_Tuesday__c != null){
                tueMap.put(szt.User__c+'-tue',((szt.Day_Tuesday__c/100)*dailyRecordCount).round(System.RoundingMode.UP));
                tue += szt.Day_Tuesday__c;
                System.debug('tue:'+tue);
            }
            if(szt.Day_Wednesday__c != null){
                wedMap.put(szt.User__c+'-wed',((szt.Day_Wednesday__c/100)*dailyRecordCount).round(System.RoundingMode.UP));
                wed += szt.Day_Wednesday__c;
                System.debug('wed:'+wed);
            }
            if(szt.Day_Thursday__c != null){
                thurMap.put(szt.User__c+'-thur',((szt.Day_Thursday__c/100)*dailyRecordCount).round(System.RoundingMode.UP));
                thur += szt.Day_Thursday__c;
                System.debug('thur:'+thur); 
            }
            if(szt.Day_Friday__c != null){
                friMap.put(szt.User__c+'-fri',((szt.Day_Friday__c/100)*dailyRecordCount).round(System.RoundingMode.UP));
                fri += szt.Day_Friday__c;
                System.debug('fri:'+fri); 
            }
        }
        
        System.debug('mon:'+mon);
        System.debug('tue:'+tue);
        System.debug('wed:'+wed);
        System.debug('thur:'+thur);
        System.debug('fri:'+fri);
        
        
        if((mon != 100 && mon != 0)||(tue != 100 && tue != 0)||(wed != 100 && wed != 0)||(thur != 100 && thur != 0)||(fri != 100 && fri != 0)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please update the percent allocation. The sum of each day should be equal to 100%.'));
            return null;
        }
        
        System.debug('monMap:'+monMap);
        System.debug('tueMap:'+tueMap);
        System.debug('wedMap:'+wedMap);
        System.debug('thurMap:'+thurMap);
        System.debug('friMap:'+friMap);
        
        
        List<Swarm_Waypoint__c> swpList1 = sz.getSObjects('Swarm_Waypoints__r');
        List<Swarm_Waypoint__c> swpList2 = swpList1;
        List<Integer> countList = new List<Integer>();
        
        System.debug('swpList1 size:'+swpList1.size());
        System.debug('swpList2 size:'+swpList2.size());
        
        if(monMap.size() > 0){
            Integer count = 0;
            Integer count1 = 0;
            for(String s : monMap.keySet()){
                for(Integer i=0; i<swpList2.size(); i++){
                    if(count < monMap.get(s) && count1 < swpList2.size()){
                        System.debug('count1:'+count1);
                        System.debug('Order#:'+swpList2[count1].Order__c);
                        swpList2[count1].OwnerId = s.split('-')[0];
                        swpList2[count1].Target_Call_Date__c = sz.Start_Call_Date__c;
                        //swpList2[count1].Optimal_Date__c = sz.Start_Optimal_Date__c;
                        swpList.add(swpList2[count1]);
                        countList.add(count1);
                        count++;
                        count1++;
                        System.debug('count:'+count);
                        System.debug('count1:'+count1);
                    }
                }
                count = 0;
            }
            System.debug('swpList3 size:'+countList.size());
            System.debug('swpList4 size:'+swpList2.size());
            System.debug('swpList1 size:'+swpList1.size());
            System.debug('swpList size:'+swpList.size());
            
            if(countList.size() > 0)
                for(Integer i = countList.size()-1; i>=0; i--){
                    System.debug('list val:'+swpList1.get(i));
                    swpList1.remove(i);
                }
            
            System.debug('swpList99 size:'+swpList1.size());
        }
        
        if(tueMap.size() > 0){
            System.debug('swpList1 size:'+swpList1);
            swpList2 = null;
            swpList2 = swpList1;
            Integer count = 0;
            Integer count1 = 0;
            countList.clear();
            for(String s : tueMap.keySet()){
                for(Integer i=0; i<swpList2.size(); i++){
                    if(count < tueMap.get(s) && count1 < swpList2.size()){
                        System.debug('count1:'+count1);
                        System.debug('Order#:'+swpList2[count1].Order__c);
                        swpList2[count1].OwnerId = s.split('-')[0];
                        swpList2[count1].Target_Call_Date__c = sz.Start_Call_Date__c.addDays(1);
                        //swpList2[count1].Optimal_Date__c = sz.Start_Optimal_Date__c.addDays(1);
                        swpList.add(swpList2[count1]);
                        countList.add(count1);
                        count++;
                        count1++;
                        System.debug('count:'+count);
                        System.debug('count1:'+count1);
                    }
                }
                count = 0;
            }
            System.debug('swpList3 size:'+countList.size());
            System.debug('swpList4 size:'+swpList2.size());
            System.debug('swpList1 size:'+swpList1.size());
            System.debug('swpList size:'+swpList.size());
            
            if(countList.size() > 0)
                for(Integer i = countList.size()-1; i>=0; i--){
                    System.debug('list val:'+swpList1.get(i));
                    swpList1.remove(i);
                }
            
            System.debug('swpList99 size:'+swpList1.size());
        }
        
        
        if(wedMap.size() > 0){
            System.debug('swpList1 size:'+swpList1);
            swpList2 = null;
            swpList2 = swpList1;
            Integer count = 0;
            Integer count1 = 0;
            countList.clear();
            for(String s : wedMap.keySet()){
                for(Integer i=0; i<swpList2.size(); i++){
                    if(count < wedMap.get(s) && count1 < swpList2.size()){
                        System.debug('count1:'+count1);
                        System.debug('Order#:'+swpList2[count1].Order__c);
                        swpList2[count1].OwnerId = s.split('-')[0];
                        swpList2[count1].Target_Call_Date__c = sz.Start_Call_Date__c.addDays(2);
                        //swpList2[count1].Optimal_Date__c = sz.Start_Optimal_Date__c.addDays(2);
                        swpList.add(swpList2[count1]);
                        countList.add(count1);
                        count++;
                        count1++;
                        System.debug('count:'+count);
                        System.debug('count1:'+count1);
                    }
                }
                count = 0;
            }
            System.debug('swpList3 size:'+countList.size());
            System.debug('swpList4 size:'+swpList2.size());
            System.debug('swpList1 size:'+swpList1.size());
            System.debug('swpList size:'+swpList.size());
            
            if(countList.size() > 0)
                for(Integer i = countList.size()-1; i>=0; i--){
                    System.debug('list val:'+swpList1.get(i));
                    swpList1.remove(i);
                }
            
            System.debug('swpList99 size:'+swpList1.size());
        }
        
        if(thurMap.size() > 0){
            System.debug('swpList1 size:'+swpList1);
            swpList2 = null;
            swpList2 = swpList1;
            Integer count = 0;
            Integer count1 = 0;
            countList.clear();
            for(String s : thurMap.keySet()){
                for(Integer i=0; i<swpList2.size(); i++){
                    if(count < thurMap.get(s) && count1 < swpList2.size()){
                        System.debug('count1:'+count1);
                        System.debug('Order#:'+swpList2[count1].Order__c);
                        swpList2[count1].OwnerId = s.split('-')[0];
                        swpList2[count1].Target_Call_Date__c = sz.Start_Call_Date__c.addDays(3);
                        //swpList2[count1].Optimal_Date__c = sz.Start_Optimal_Date__c.addDays(3);
                        swpList.add(swpList2[count1]);
                        countList.add(count1);
                        count++;
                        count1++;
                        System.debug('count:'+count);
                        System.debug('count1:'+count1);
                    }
                }
                count = 0;
            }
            System.debug('swpList3 size:'+countList.size());
            System.debug('swpList4 size:'+swpList2.size());
            System.debug('swpList1 size:'+swpList1.size());
            System.debug('swpList size:'+swpList.size());
            
            if(countList.size() > 0)
                for(Integer i = countList.size()-1; i>=0; i--){
                    System.debug('list val:'+swpList1.get(i));
                    swpList1.remove(i);
                }
            
            System.debug('swpList99 size:'+swpList1.size());
        }
        
        if(friMap.size() > 0){
            System.debug('swpList1 size:'+swpList1);
            swpList2 = null;
            swpList2 = swpList1;
            Integer count = 0;
            Integer count1 = 0;
            countList.clear();
            for(String s : friMap.keySet()){
                for(Integer i=0; i<swpList2.size(); i++){
                    if(count < friMap.get(s) && count1 < swpList2.size()){
                        System.debug('count1:'+count1);
                        System.debug('Order#:'+swpList2[count1].Order__c);
                        swpList2[count1].OwnerId = s.split('-')[0];
                        swpList2[count1].Target_Call_Date__c = sz.Start_Call_Date__c.addDays(4);
                        //swpList2[count1].Optimal_Date__c = sz.Start_Optimal_Date__c.addDays(4);
                        swpList.add(swpList2[count1]);
                        countList.add(count1);
                        count++;
                        count1++;
                        System.debug('count:'+count);
                        System.debug('count1:'+count1);
                    }
                }
                count = 0;
            }
            System.debug('swpList3 size:'+countList.size());
            System.debug('swpList4 size:'+swpList2.size());
            System.debug('swpList1 size:'+swpList1.size());
            System.debug('swpList size:'+swpList.size());
            
            if(countList.size() > 0)
                for(Integer i = countList.size()-1; i>=0; i--){
                    System.debug('list val:'+swpList1.get(i));
                    swpList1.remove(i);
                }
            
            System.debug('swpList99 size:'+swpList1.size());
        }
        
        
        
        //update sz;
        Database.SaveResult updateZone = Database.update(sz, false);

        if(!updateZone.isSuccess())
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Failed to update Zone: '+updateZone.getErrors()));
        
            

        //upsert szt;
        Database.UpsertResult [] upsertResult = Database.upsert(szt, false);

        for (Database.UpsertResult r : upsertResult){
            if(!r.isSuccess()){
                for(Database.Error err : r.getErrors()) {
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Failed to update Team: '+err.getMessage()));
                }   
            }
        }
        
        Database.DeleteResult [] deleteResult = Database.delete(deleteszt, false);

        for (Database.DeleteResult r : deleteResult){
            if(!r.isSuccess()){
                for(Database.Error err : r.getErrors()) {
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Failed to remove the team members: '+err.getMessage()));
                }   
            }
        }

        if(swpList.size() > 0){
            //update swpList;
            Database.SaveResult [] updateResult = Database.update(swpList, false);
            
            for (Database.SaveResult r : updateResult)
            {
                if(r.isSuccess()){
                    ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Waypoint records allocated successfully!.'));
                    allocated = true;
                }
                else{
                    for(Database.Error err : r.getErrors()) {
                        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Waypoint records allocation failed!: '+err.getMessage()));
                    }   
                    allocated = false;
                }
            }         
        }
        return null;
    }
    
}