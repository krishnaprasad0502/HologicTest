/**************************************************************************************
    Author       : Sunil Kumar Sharma
    Company      : Hexaware Technologies
    Created Date : 10/29/2018 
    Description  : Fetch managed topic heirarchy and return the list of topics as breadcrumbs.
    Test Class   :     
    Coverage     : 100% 

    History:
    <Date>          <Author Name>           <Brief Description of Change>   <Copa.do US#>
    10/29/2018       Sunil Kumar Sharma      Initial Creation                US-0006008
    11/13/2018        Sunil Sharma            Updated for Discussion forums    US-0006076
	27/12/2018		Sunil Sharma			DF-388 fix 						US-0006345
**************************************************************************************/
public class BreadcrumbContainerController {
    /*
    * Method Name: fetchBreadCrumbData()
    * Input Param: Topid id
    * Return: List
    * Description: fetch breadcrumbs for the current selected topic.
    */
    @AuraEnabled
    public static List<BreadcrumbContainerController.BreadcrumbsItem> fetchBreadCrumbData(Id topicId){
        system.debug('Topic Id is '+ topicId);
        List<BreadcrumbContainerController.BreadcrumbsItem> breadCrumbsList = new List<BreadcrumbContainerController.BreadcrumbsItem>();
        Network communityName ;
        if(Test.isRunningTest()){
            communityName = [SELECT id, name FROM Network WHERE Name = 'Hologic Support Portal'];
        }else{
            communityName = [SELECT id, name FROM Network WHERE Id =:Network.getNetworkId()];
        }
        Id communityId = communityName.Id ;
        
        Map<Id,List<BreadcrumbContainerController.BreadcrumbsItem>> map_TopicHeirarchy = new Map<Id,List<BreadcrumbContainerController.BreadcrumbsItem>>();
        ConnectAPI.ManagedTopicCollection mTopicCollection = ConnectAPI.ManagedTopics.getManagedTopics(communityId,ConnectApi.ManagedTopicType.Navigational,4);

        for(ConnectApi.ManagedTopic mtopic : mTopicCollection.managedTopics){
            if(!map_TopicHeirarchy.containsKey(mtopic.topic.Id)){
                BreadcrumbContainerController.BreadcrumbsItem breadcrumbValue = new BreadcrumbContainerController.BreadcrumbsItem('Discussion Home','/s/discussionforum');
                map_TopicHeirarchy.put(mtopic.topic.Id,new List<BreadcrumbContainerController.BreadcrumbsItem>{breadcrumbValue});
            }
            
            for(ConnectApi.ManagedTopic mtop: mtopic.children){
                List<BreadcrumbContainerController.BreadcrumbsItem> topicParentList = new List<BreadcrumbContainerController.BreadcrumbsItem>(); 
                topicParentList.addAll(map_TopicHeirarchy.get(mtopic.topic.Id));
                BreadcrumbContainerController.BreadcrumbsItem brdCrumItem = new BreadcrumbContainerController.BreadcrumbsItem(mtopic.topic.name,'/s/topic/'+mtopic.topic.Id);
                topicParentList.add(brdCrumItem);
                map_TopicHeirarchy.put(mtop.topic.Id,topicParentList);
                for(ConnectApi.ManagedTopic mtop2: mtop.children){
                    BreadcrumbContainerController.BreadcrumbsItem brdCrumItem1 = new BreadcrumbContainerController.BreadcrumbsItem(mtop.topic.name,'/s/topic/'+mtop.topic.Id);
                    topicParentList.add(brdCrumItem1);map_TopicHeirarchy.put(mtop2.topic.Id,topicParentList);                        
                }
            }
            system.debug('Values are '+ map_TopicHeirarchy.get(mtopic.topic.Id)); 
        }
        return map_TopicHeirarchy.get(topicId);
    }
    
    /*
    * Method Name: fetchConfigData()
    * Input Param: No inputs required
    * Return: Service_Community_Config__c 
    * Description: fetch Global Menu from Custom Setting
    */
    @AuraEnabled
    public static Service_Community_Config__c fetchConfigData(){
       Service_Community_Config__c config = Service_Community_Config__c.getOrgDefaults();
       return config;
    }
    /*
     * Wrapper class to hold topic name and topic url to be used to create breadcrumbs.
     */
    public Class BreadcrumbsItem{
        @AuraEnabled public string topicLabel;
        @AuraEnabled public string topicId;
        
        public BreadcrumbsItem(String topicName,String topicUrl){
            topicLabel  = topicName;
            topicId = topicUrl;
        }
    }
}