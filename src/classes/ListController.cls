/**************************************************************************************
    Author       : Nikhil Mutyam
    Company      : Hexaware Technologies
    Created Date : 8/13/2018 7:30 AM
    Description  : Fetch Object records from database and return to Lightning Component
    Test Class   : ListController_Test    
    Coverage     : 86%  

    History:
    <Date>          <Author Name>           <Brief Description of Change>   <Copa.do US#>
    8/13/2018       Nikhil Mutyam           Initial Creation                US-0005633
    11/13/2018        Sunil Sharma            Updated fetchRecords for Discussion forums    US-0006076
	27/12/2018		Sunil Sharma			DF-388 fix 						US-0006345
**************************************************************************************/ 

public  class ListController {
    
    /*Returns Custom Setting Records and list of records requested*/
    public class Master{
        @AuraEnabled public Service_Community_Config__c communityConfig;
        @AuraEnabled public list<sObjectVar> sobjectLists;
        public Master(){
            communityConfig = new Service_Community_Config__c();
            sobjectLists = new list<sObjectVar>();
        }
    }
    
    /*Return Object structure declaration*/
    public class sObjectVar{
        @AuraEnabled public string Title;
        @AuraEnabled public string Value1;
        @AuraEnabled public string Value2;
        @AuraEnabled public string Value3;
        @AuraEnabled public string Id;
        @AuraEnabled public string SOType;
        @AuraEnabled public string urlName;
    }
    
    /*
    * Method Name: fetchDataCategory()
    * Input Param: Current Record Id and Data Category storage field name
    * Return: string 
    * Description: Fetch data category associated to the record based on the input parameters.
    */
    @AuraEnabled
    public static string fetchDataCategory(string RecordId, string ObjectName, string FieldAPI){
        string str = 'SELECT id, ';
        if(FieldAPI != Null && FieldAPI != ''){
            str += ' '+FieldAPI+' ';
        }
        str += ' FROM '+String.escapeSingleQuotes(objectName)+' WHERE Id =: RecordId';
        list<sObject> dynamicRecs = new list<sObject>();
        for(sObject SO : Database.query(str)){
            dynamicRecs.add(SO);
        }    
        system.debug('The value is: '+string.valueof(dynamicRecs[0].get(FieldAPI)));
        return string.valueof(dynamicRecs[0].get(FieldAPI));
    }
    
     /*
     * Method Name: FetchRecords()
     * Input Param: Includes ObjectType, Field API's, Sort Api, Limit Api, Filter Fields, Data Category related field api's 
     * Return: Master 
     * Description: Fetch records from an object based on input values. The method also supports Filtering and Sorting.
     */
    @AuraEnabled
    public static Master fetchRecords(string ObjectName, string FieldAPI, string FieldAPI2, string FieldAPI3, string FieldAPI4, 
                                            string SortByAPI, string LimitAPI, string RelationshipFieldName, string RelatedRecordId, 
                                            string FilterFieldAPI, string FilterOperatorAPI, string FilterValueAPI, boolean DCFilter, 
                                            string DCField, string CurrentRecId, string LandingObjType){
        list<sObjectVar> Records = new list<sObjectVar>();
        String favArticleString ;                                        
        string str = 'SELECT id, ';
        if(ObjectName == 'Knowledge__kav'){
            str = 'SELECT id,UrlName, ';
        }
        if(FieldAPI != Null && FieldAPI != ''){
            str += ' '+FieldAPI+' ';
        }
        if(FieldAPI2 != Null && FieldAPI2 != ''){
            str += ', '+FieldAPI2;
        }
        if(FieldAPI3 != Null && FieldAPI3 != ''){
            str += ', '+FieldAPI3;
        }
        if(FieldAPI4 != Null && FieldAPI4 != ''){
            str += ', '+FieldAPI4;
        }                                            
        
        favArticleString = str ;
        if(ObjectName != 'Community_Favorite_Articles__c'){
        str += ' FROM '+String.escapeSingleQuotes(objectName)+' WHERE '+ FieldAPI + ' != null ';
        }
        if(ObjectName == 'Community_Favorite_Articles__c'){
            str += ' FROM '+String.escapeSingleQuotes(objectName)+' WHERE Id != null ';
        } 
        if(ObjectName == 'Knowledge__kav'){
            str += ' AND PublishStatus = \'online\' AND Language = \'en_US\' ';                                                
        }
                                                
        if(ObjectName == 'FeedItem'){
            Network communityName ;
            if(Test.isRunningTest()){
                communityName = [SELECT id, name FROM Network WHERE Name = 'Hologic Support Portal'];
            }else{ communityName = [SELECT id, name FROM Network WHERE Id =:Network.getNetworkId()];
            }
            
			system.debug('@@@@@coomuni'+ communityName);
            Id communityId = communityName.Id ;
            Map<Id,List<Id>> map_TopicHeirarchy = new Map<Id,List<Id>>();
            ConnectAPI.ManagedTopicCollection mTopicCollection = ConnectAPI.ManagedTopics.getManagedTopics(communityId, 
                                                                 ConnectApi.ManagedTopicType.Navigational,3);
            
            for(ConnectApi.ManagedTopic mtopic : mTopicCollection.managedTopics){
                system.debug('44'+ mtopic.topic.Id);
                if(!map_TopicHeirarchy.containsKey(mtopic.topic.Id)){map_TopicHeirarchy.put(mtopic.topic.Id,new List<Id>{mtopic.topic.Id});}
                for(ConnectApi.ManagedTopic mtop: mtopic.children){
                    map_TopicHeirarchy.get(mtopic.topic.Id).add(mtop.topic.Id); map_TopicHeirarchy.put(mtop.topic.Id,new List<Id>{mtop.topic.Id});
                    for(ConnectApi.ManagedTopic mtop2: mtop.children){
                        map_TopicHeirarchy.get(mtopic.topic.Id).add(mtop2.topic.Id);map_TopicHeirarchy.get(mtop.topic.Id).add(mtop2.topic.Id);map_TopicHeirarchy.put(mtop2.topic.Id,new List<Id>{mtop2.topic.Id}); }
                }
            }
            
            if(RelatedRecordId != Null && RelatedRecordId != '' && RelatedRecordId.startsWith('0TO')){
                List<Id> topicIdList = map_TopicHeirarchy.get(RelatedRecordId);
                str += ' AND Id IN (SELECT EntityId FROM TopicAssignment WHERE EntityType = \'FeedItem\' AND '+'TopicId =: topicIdList ) ';                                                         
            }else{
                str += ' AND Id IN (SELECT EntityId FROM TopicAssignment WHERE EntityType = \'FeedItem\' AND '+'NetworkId =: communityId ) ';                                                        
            }
        }
                                                    
        if(RelationshipFieldName != Null && RelationshipFieldName != '' && RelatedRecordId != Null && RelatedRecordId != ''){str += ' AND '+RelationshipFieldName+ ' =: RelatedRecordId';
        }
        
        if(FilterFieldAPI != Null && FilterFieldAPI != '' && FilterOperatorAPI != Null && FilterOperatorAPI != '' && FilterValueAPI != Null && 
           FilterValueAPI != ''){
               if(ObjectName != 'Community_Favorite_Articles__c'){
                  str += ' AND ' + FilterFieldAPI + ' ' + FilterOperatorAPI + ' \'' + FilterValueAPI + '\''; 
               }else if(FilterValueAPI == 'currentuser'){
                  str += ' AND ' + FilterFieldAPI + ' ' + FilterOperatorAPI + ' \'' + userinfo.getuserid() + '\''; 
                   str += ' AND Community_Favourite__c= true' ;  
               }
               
        }                                            
        
        if(ObjectName == 'Knowledge__kav' && DCFilter){
            sObject svar = database.query('SELECT id, '+ DCField +' FROM '+LandingObjType+ ' WHERE Id =: CurrentRecId ');
            system.debug('The product contains'+svar.get(DCField));
            if(svar.get(DCField) != Null && svar.get(DCField) != ''){
                string dynamicsel = string.valueof(svar.get(DCField));
                str += ' WITH DATA CATEGORY Product_Classification__c AT '+dynamicsel; 
            }
        }
        
        if(SortByAPI != Null && SortByAPI != ''){
            str += ' ORDER BY '+ SortByAPI + ' Desc';                                                      
        }   
                                                
        str += ' LIMIT ' +integer.valueOf(LimitAPI);
        system.debug('Query Is' + str); 
                                                    
        Schema.SObjectType t = Schema.getGlobalDescribe().get(ObjectName); 
        Schema.DescribeSObjectResult r = t.getDescribe();
        Set<Id> favArticleIdList = new Set<Id>();                                       
        for(sObject SO : Database.query(str)){
            if(ObjectName != 'Community_Favorite_Articles__c'){
                system.debug('The Account Name is: '+SO.get(FieldAPI));
                sObjectVar sOInstance = new sObjectVar();
                sOInstance.Title = string.valueof(SO.get(FieldAPI));
                
                if(FieldAPI2 != Null && FieldAPI2 != ''){
                    sOInstance.Value1 = string.valueof(SO.get(FieldAPI2));  
                }   
                if(FieldAPI3 != Null && FieldAPI3 != ''){
                    sOInstance.Value2 = string.valueof(SO.get(FieldAPI3));
                }
                if(FieldAPI4 != Null && FieldAPI4 != ''){
                    sOInstance.Value3 = string.valueof(SO.get(FieldAPI4));
                }
                sOInstance.Id = string.valueof(SO.get('Id'));
            if(ObjectName == 'Knowledge__kav'){sOInstance.urlName = string.valueof(SO.get('UrlName'));
            }    
            sOInstance.SOType = ObjectName;
            Records.add(sOInstance);
            }else{
                favArticleIdList.add(string.valueof(SO.get('Community_Article_Name__c')));
            }
        }
        if(ObjectName == 'Community_Favorite_Articles__c' && favArticleIdList.size() > 0){
            system.debug('Id list is'+ favArticleIdList);
            for(Knowledge__kav SO : [Select Id,Community_LastPublishedDate__c ,UrlName, Title, Product_Name__c, Summary FROM Knowledge__kav WHERE Id IN:favArticleIdList LIMIT 5]){
                sObjectVar sOInstance = new sObjectVar();
                sOInstance.Title = so.Community_LastPublishedDate__c;
                
                if(FieldAPI2 != Null && FieldAPI2 != ''){
                    sOInstance.Value1 = so.Title;  
                }   
                if(FieldAPI3 != Null && FieldAPI3 != ''){
                    sOInstance.Value2 = so.Product_Name__c;
                }
                if(FieldAPI4 != Null && FieldAPI4 != ''){
                    sOInstance.Value3 = so.Summary;
                }
                sOInstance.urlName = so.UrlName ;
                sOInstance.Id = so.Id ;
                sOInstance.SOType = 'Knowledge__kav';
                Records.add(sOInstance);
            }
        }
            
        Service_Community_Config__c config = Service_Community_Config__c.getOrgDefaults();
        Master MInstance = new Master();
        MInstance.sobjectLists = Records;
        MInstance.communityConfig = config;
        system.debug('The instance contains: '+MInstance); 
        return MInstance;
    }
}