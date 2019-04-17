/*------------------------------------------------------------
Author:        Mani Sundaresan
Company:       Hologic
Description:   Profile Data functions
Test Class:    ProfileDataTrigger_Test

History:
<Date>        <Authors Name>    <Brief Description of Change>
01/15/2019    Mani Sundaresan     Initial Creation (US-0006881)
------------------------------------------------------------*/
public class ProfileDataTriggerActions {

    /*------------------------------------------------------------
    Author:         Mani Sundaresan 
    Company:        Hologic
    Description:    Update Profile Data's segment volume
    Inputs:         List of Profile Data being inserted/updated
                    Map of Old Profile Data 
    Returns:        N/A
    Test Class:     ProfileDataTrigger_Test


    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    01/15/2019       Mani Sundaresan     Logic to stamp Segment Volume on Profile Data records()  
    ------------------------------------------------------------*/
      public static void setProfileTotalVolume(List<Profile_Data__c> profData, Map<Id, Profile_Data__c> oldMap){
    
        List<Id> profAccIdList = new List<Id>();
        List<Profile_Data__c> profDataList = new List<Profile_Data__c>();
        Set<Profile_Data__c> finalProfDataSet = new Set<Profile_Data__c>();
        List<Profile_Data__c> finalProfDataList = new List<Profile_Data__c>();
        Decimal finalVol = 0;
        Decimal finalThreshold = 0;
        Profile_Data__c oldProfData = new Profile_Data__c();
        
        for(Profile_Data__c pd : profData){
            if(oldMap != null)
                oldProfData = oldMap.get(pd.Id);
           
            if(pd.Volume__c != oldProfData.Volume__c)    
                profAccIdList.add(pd.Account_Site__c);
        } 
            
        System.debug('profAccIdList:'+profAccIdList);
        
        if(profAccIdList != null)
            profDataList = [SELECT Id, Name, Account_Site__c, Division__c, Volume__c, Profile__c, Profile__r.Exclude_from_Segmentation__c, Segment_Contribution__c, Segment_Total_Volume__c, Segment_ASP__c from Profile_Data__c where Account_Site__c IN :profAccIdList and Profile__r.Exclude_from_Segmentation__c = false];
        
        System.debug('profDataList:'+profDataList);
        
        if(profDataList != null)
            for(Profile_Data__c pd : profData){
                Decimal totalVol = 0;
                Decimal totalThreshold = 0;
                for(Profile_Data__c pdl : profDataList){
                    if(pd.Account_Site__c == pdl.Account_Site__c && pd.Division__c == pdl.Division__c){
                        if(pdl.Volume__c != null)
                            totalVol += pdl.Volume__c;
                        if(pdl.Segment_Contribution__c != null)
                            totalThreshold += pdl.Segment_Contribution__c;
                       
                        System.debug('profDataName:'+pdl.Name);
                        
                        finalProfDataSet.add(pdl);
                    }
                }
                finalVol  = totalVol;
                finalThreshold  = totalThreshold;
                
                System.debug('finalVol:'+finalVol);
                System.debug('finalThreshold:'+finalThreshold);
                System.debug('finalProfDataList:'+finalProfDataList);
            }
        
        if(finalProfDataSet != null){
            finalProfDataList.addAll(finalProfDataSet);
            for(Profile_Data__c pd : finalProfDataList){
                pd.Segment_Total_Volume__c = finalVol; 
                pd.Segment_Total_Threshold__c = finalThreshold; 
            }
        }
        
        update finalProfDataList;
        
    }
    
    /*------------------------------------------------------------
    Author:         Mani Sundaresan 
    Company:        Hologic
    Description:    Update Profile Data's average selling price
    Inputs:         List of Profile Data being inserted/updated
                    Map of Old Profile Data 
    Returns:        N/A
    Test Class:     ProfileDataTrigger_Test


    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    01/15/2019       Mani Sundaresan     Logic to stamp Average Selling Price on Profile Data records()  
    ------------------------------------------------------------*/
    public static void setProfileASP(List<Profile_Data__c> profData){


System.debug('SetProfileASP');

    
        List<Profile_ASP__c> profASPList = new List<Profile_ASP__c>();
        List<Id> profileIdList = new List<Id>();
        
        //Get the profile Id's
        for(Profile_Data__c pd : profData)
            profileIdList.add(pd.Profile__c);
        
        System.debug('profileIdList:'+profileIdList);
        
        //Query to fetch all the Profile ASP records based on the ProfileIdList
        profASPList = [SELECT Id, ASP__c, Profile__c, Country__c, CurrencyIsoCode from Profile_ASP__c where Profile__c = :profileIdList];
        
        System.debug('profASPList:'+profASPList.size());
        
        //Loop through the records to assign the Segment ASP
        if(profASPList.size() > 0){
            for(Profile_Data__c pd : profData){
                for(Profile_ASP__c pasp : profASPList){
                    if(pd.Segment_Country__c == pasp.Country__c && pd.Profile__c == pasp.Profile__c){
                        System.debug('paspId:'+pasp.Id);
                        pd.Segment_ASP__c = pasp.ASP__c; 
                      /*  pd.CurrencyIsoCode = pasp.CurrencyIsoCode; */
                        break;
                    }
                }
            }
        }        
         
    } 
}