trigger Campaign_BU on Campaign (before insert, before update) {

    Set <ID> OwnerIDs = new set <ID>();
    Map <ID, User> Owner_Profile_Map;

    for (Campaign c : Trigger.new){
      if(c.OwnerID != null) // only if campaign has an owner
      {
        OwnerIDs.add(c.OwnerID);
      }
    }

    if(!OwnerIDs.isEmpty()){
        Owner_Profile_Map = new map <ID, user> ([Select ID, ProfileID, Profile.Name from User where ID in :OwnerIDs]);
    }
    system.debug('Owner_Profile_Map :'+Owner_Profile_Map);
    Map<String,CampaignOwner_BU_Map__c> mcs = CampaignOwner_BU_Map__c.getall(); // Custom Setting
    Set<String> BU_NamesSet = new Set<String>();
    
    for(CampaignOwner_BU_Map__c cust : mcs.values()){
        BU_NamesSet.add(cust.Business_Unit_Name__c);
    }
    
    Map<String,PAM__Business_Unit__c> BU_Map = new  Map<String,PAM__Business_Unit__c>();
    
    if(BU_NamesSet.size() !=0){
        for(PAM__Business_Unit__c bu :[Select Name, ID from PAM__Business_Unit__c where name IN :BU_NamesSet ]){
            BU_Map.put(bu.name,bu);
        }
        System.debug ('BU_Map - '+BU_Map);
    }


    for (Campaign c : Trigger.new) // Looping through all Campaigns in scope
    {
      String profName = Owner_Profile_Map.get(String.valueOf(c.OwnerID)).Profile.Name; // profile name of campaign owner
      String buName = mcs.get(profName).Business_Unit_Name__c;
      System.debug ('ProfName - '+profName);
      system.debug('buName :'+buName);
      if(BU_Map != null && BU_Map.containsKey(buName))
        c.PAM__Business_Unit__c = BU_Map.get(buName).Id; // Before Trigger, doesn't need any special handling
          
        
      
    }

}