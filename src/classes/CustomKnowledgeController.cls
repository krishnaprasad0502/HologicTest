/****************************************************************************************
    Author : Niraj
    Company : Hexaware Technologies
    Description : Fetch Knowledge Articles for customers in community, 
                  includes Search, Category and Article Type filters
    Test Class : CustomKnowledgeController_Test    

    History:
    <Date>         <Author Name>      <Brief Description of Change>     	<Copa.do US#>
    8/22/2018      	Niraj            	Initial Creation                     US-0005634
    11/02/2018      Nomita Walke    	Added method fetchConfigData()       US-0006075
	12/03/2018		Vrushabh Katariya	Added category label to Item.name	 US-0006257
    12/11/2018			Niraj Wani		Article Type URL Parameter Fix		 US-0006257  
****************************************************************************************/

public with sharing class CustomKnowledgeController {
    
    @AuraEnabled
    public static Master FetchArticles(string searchVar,  string CategoryString, string ParentCategory, string SelArticleTypes, 
                                       string RecordType, string StrPageNumber ,string StrRecordToDisply, String ArticleSummaryChars, 
                                       String LimitNumOfRecords, String urlCategoryStr){ //list<string> ArtTypesInput,
                                           
        Integer pageNumber = integer.valueof(strPageNumber);
        Integer recordToDisply = integer.valueof(strRecordToDisply);
        Integer NumArticleSummaryChars = integer.valueof(ArticleSummaryChars);
        Integer NumOfRecordsLimit =  integer.valueof(LimitNumOfRecords);
        list<Knowledge__kav> KArticles = new list<Knowledge__kav>();
        map<string,string> CategoryMap = new map<string,string>();
        list<Result> Results = new list<Result>();
        list<Result> downResults = new list<Result>();
        list<Result> docuResults = new list<Result>();
        list<string> ArticleTypeList = new list<string>();
        set<string> ArticleTypesSet = new set<string>();
        Master mas = new Master();
        String strQuery;
        String str;
        String strQueryCount;
        Integer pageSize = recordToDisply;
        Integer offset = ((Integer)pageNumber - 1) * pageSize;

        for(String aType : SelArticleTypes.split(',')){
            ArticleTypeList.add(aType);
        }
        
        //If Search Term exists then use SOSL 
        if (searchVar != Null && searchVar != 'All' &&  searchVar != '')
        {
            str = 'FIND :searchVar RETURNING Knowledge__kav';
            //Removing Box Link
            //str += '(Id, Title,  Summary, UrlName, RecordTypeId, LastPublishedDate,Box_Link__c  WHERE PublishStatus=\'online\' and ValidationStatus=\'Validated\' and Language = \'en_US\'';
            str += '(Id, Title,  Summary, UrlName, RecordTypeId, LastPublishedDate, Product_Name__c  WHERE PublishStatus=\'online\' and ValidationStatus=\'External\' and Language = \'en_US\'';
            if (RecordType != Null && RecordType == 'All' && SelArticleTypes ==Null && SelArticleTypes ==''){
                //Do Nothing, query all article types 
            }
            else if (RecordType != Null && RecordType == 'All' && SelArticleTypes !=Null && SelArticleTypes !=''){
                //When component set with RecordType = All and user selected record type filters then 
                //query within selected record types
                str += ' and RecordType.Name IN :ArticleTypeList';                
            }
            else if (RecordType != Null && RecordType != 'All' && RecordType != ''){
                //Search within specific record type selected on component attributes
                str += ' and RecordType.Name = \''  ;
                str +=  RecordType + '\'';
            }
            
            //Order By Last Published Date 
            str += ' ORDER BY LastPublishedDate DESC ';
            
            //Adding Limts and Offsets 
            if(recordToDisply != Null && recordToDisply != 0 && offset != Null && offset != 0){
                str = str + ' LIMIT ' + recordToDisply + ' OFFSET ' + offset;
            }
            else{
                //Limit on maximum number of rows retruned at the time of writing this code is 2000.
                str = str + ' LIMIT ' + NumOfRecordsLimit;
            }
            str += ')';  
            
            system.debug('Check Query point 2 '+ urlCategoryStr);
            if(urlCategoryStr != Null && urlCategoryStr != ''){
                //str = str + ' WITH DATA CATEGORY Product_Classification__c Below ' + urlCategoryStr; 
                ParentCategory = 'Product_Classification__c';
                CategoryString = urlCategoryStr;
            }
            
            if(CategoryString != Null && CategoryString != ''){
                if (CategoryString != ParentCategory) //When Top Category is clicked no category filtering to be done
                    str += ' WITH DATA CATEGORY ' +  ParentCategory + ' BELOW ' + CategoryString;
            }
            
            System.debug('Article Query SOSL: ' + str );
            
            list<list<SObject>> articles = search.query(str);                                 
            KArticles = articles[0];
        }
        else //When Search term does not exists use SOQL 
        {
            //Remving box link from SOQL
            //strQuery = 'SELECT Id, Title,  Summary, UrlName, RecordTypeId, LastPublishedDate, Box_Link__c FROM Knowledge__kav WHERE PublishStatus=\'online\' and ValidationStatus=\'Validated\' and Language = \'en_US\'';  
            strQuery = 'SELECT Id, Title,  Summary, UrlName, RecordTypeId, LastPublishedDate, Product_Name__c FROM Knowledge__kav WHERE PublishStatus=\'online\' and ValidationStatus=\'External\' and Language = \'en_US\'';  
            if (RecordType != Null && RecordType == 'All' && SelArticleTypes ==Null && SelArticleTypes ==''){
                //Do Nothing, query all article types 
            }
            else if (RecordType != Null && RecordType == 'All' && SelArticleTypes !=Null && SelArticleTypes !=''){
                //When component set with RecordType = All and user selected record type filters then 
                //query within selected record types
                strQuery += ' and RecordType.Name IN :ArticleTypeList';                
            }
            else if (RecordType != Null && RecordType != 'All' && RecordType != ''){
                //Search within specific record type selected on component attributes
                strQuery += ' and RecordType.Name = \''  ;
                strQuery +=  RecordType + '\''; 
            }
            
            if(urlCategoryStr != Null && urlCategoryStr != ''){
                //str = str + ' WITH DATA CATEGORY Product_Classification__c Below ' + urlCategoryStr; 
                ParentCategory = 'Product_Classification__c';
                CategoryString = urlCategoryStr;
                System.debug('Parent Category: ' + ParentCategory + 'CategoryString: ' +  CategoryString);
            }
            
           
            
            //Add Data Category Filter if user selected any on Category Tree
            if(CategoryString != Null && CategoryString != ''){
                if (CategoryString != ParentCategory) //When Top Category is clicked no category filtering to be done
                    strQuery = strQuery + ' WITH DATA CATEGORY ' + ParentCategory + ' BELOW ' + CategoryString;               
            } 
            
            //Order By Last Published Date 
            strQuery += ' ORDER BY LastPublishedDate DESC ';
            
            //Adding Limts and Offsets 
            if(recordToDisply != Null && recordToDisply != 0 && offset != Null && offset != 0 ){
                strQuery = strQuery + ' LIMIT ' + recordToDisply + ' OFFSET ' + offset;
            }
            else{
                //Limit on maximum number of rows retruned at the time of writing this code is 2000.
                strQuery = strQuery + ' LIMIT ' + NumOfRecordsLimit;
            }
            
            System.debug('Article Query SOQL: ' + strQuery );
            
            KArticles  = Database.query(strQuery);  
        } 
        
        //Get Article Type List 
        Map<Id, string> mapArticleTypes = getArticleRecordTypeValues();
        Integer i = 0;
        Result res = new Result();
        Datetime dt;
        Integer summaryLength;
        for(Knowledge__kav dkav : KArticles){
            res = new Result();
            res.ArticleId = dkav.Id;
            /* res.ArticleType = dkav.ArticleType; */
            res.Title = dkav.Title;
            if (dkav.Summary != Null)
            {
                summaryLength = dkav.Summary.length();
                if (summaryLength > NumArticleSummaryChars)
                    res.Summary = dkav.Summary.substring(0, NumArticleSummaryChars) + ' ...';          
                else 
                    res.Summary = dkav.Summary;
            }
            res.UrlName = dkav.UrlName;
            dt = (Datetime) dkav.LastPublishedDate; 
            String strDatePub = dt.format('d-MMM-yyyy');
            res.LastPublishedDate = strDatePub;
            // 20/09/2018 - Since Box Integration to be revisited, keeping this blank 
            res.BoxLink = '';
            /*
            if (dkav.Box_Link__c == Null)
                res.BoxLink = '';
            else
                res.BoxLink = dkav.Box_Link__c;
            */
            
            //Get Article Type Name
            if( mapArticleTypes.ContainsKey(dkav.RecordTypeId) ){
                res.RecordType = mapArticleTypes.get(dkav.RecordTypeId);
            }
            //Product Name 
            res.ProductName = dkav.Product_Name__c;
            i = i+ 1;
            if (offset == 0 && i > recordToDisply )
            {  
                break;
            }
            Results.add(res);
        }
        mas.pageSize = pageSize;
        mas.page = (Integer) pageNumber;
        if (offset == 0){
            mas.total =  KArticles.size(); //TBD - This needs looked into
            //mas.total =100;
        }
        mas.Results = Results;
        mas.ArticleTypes = new list<String>(ArticleTypesSet);
        return mas;
    }
    
    @AuraEnabled
    public static Filters getFilters(){
        Filters filter = new Filters(); 
        filter.DataCategories = getDataCategoryTree();
        Map<Id, string> ArticleTypes = getArticleRecordTypeValues();
        list<string> lstArtTypes =  new list<string>(); 
        lstArtTypes.addAll (ArticleTypes.values());
        filter.ArTyps = lstArtTypes;
        return filter;
    }
    
    //Populate Tree - NW - 20 August 2018
    @AuraEnabled
    public static List<item> getDataCategoryTree(){
        list<item> items = new list<item>();
        
        // Create the data category pairs
        DataCategoryGroupSobjectTypePair pair1 = new DataCategoryGroupSobjectTypePair();
        pair1.setSobject('KnowledgeArticleVersion');
        pair1.setDataCategoryGroupName('Product_Classification');
        
        DataCategoryGroupSobjectTypePair pair2 = new DataCategoryGroupSobjectTypePair();
        pair2.setSobject('KnowledgeArticleVersion');
        pair2.setDataCategoryGroupName('Targeted_Audience');
        
        DataCategoryGroupSobjectTypePair[] pairs = new DataCategoryGroupSobjectTypePair[] {pair1, pair2};
        List<DescribeDataCategoryGroupStructureResult> categoryStructRes = Schema.describeDataCategoryGroupStructures(pairs, false);
        
        //Get Data Category Exclusion List from Custom Setting 
        Map<String,Integer> dataCategoryToExclude = new Map<String,Integer>(); 
        List<Community_Data_Category_Exclude_List__c> cusList = Community_Data_Category_Exclude_List__c.getAll().values();
        for (Integer i=0;i<cusList.Size(); i++){
            String dataCat = (String) cusList.get(i).Category_Unique_Name__c;
            dataCategoryToExclude.put(dataCat, i);
            //System.debug('DataCat: ' + dataCat);
        }
        
        for (DescribeDataCategoryGroupStructureResult struct : categoryStructRes) {
            DataCategory[] topCategories = struct.getTopCategories();
            List<item> childItems = new List<item>();
            if(topCategories.size() > 0 && topCategories[0].getName() == 'All') {
                topCategories = topCategories[0].getChildCategories();
            }
            //Level 2
            for(DataCategory dc: topCategories) {
                List<item> childItems3 = new List<item>();
                //Level 3 
                for (DataCategory dc3: dc.getChildCategories()){
                    List<item> childItems4 = new List<item>();
                    //Level 4
                    for (DataCategory dc4: dc3.getChildCategories()){
                        if(dataCategoryToExclude.containsKey(dc4.getName()) == false ){
                            item childItem4 = new item(dc4.getLabel(),  dc4.getName() + '__c', struct.getName() + '__c', false, null);
                            childItems4.add(childItem4);
                        }
                    }
                    if(dataCategoryToExclude.containsKey(dc3.getName()) == false){
                        item childItem3 = new item(dc3.getLabel(),  dc3.getName() + '__c', struct.getName() + '__c', false, childItems4);
                        childItems3.add(childItem3);  
                    }
                }
                if(dataCategoryToExclude.containsKey(dc.getName()) == false){
                    item childItem = new item(dc.getLabel(),  dc.getName() + '__c', struct.getName() + '__c', false, childItems3);
                    childItems.add(childItem); 
                }
            }
            item parentItem = new item(struct.getLabel(),  struct.getName() + '__c', struct.getName() + '__c', true, childItems);             
            items.add(parentItem);
        }
        return items;
    }
    
    @AuraEnabled
    public static Map<Id, string> getArticleRecordTypeValues() {
        Map<Id, string> ArticleTypes = new Map<Id, string>();
        /*Get List of Record Types For Knowledge*/
        Schema.DescribeSObjectResult R = Knowledge__kav.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
        //Get aggreagte of counts based on article record types 
        Map<Id, Integer> knowledgeArticleTypes = new Map<Id, Integer>();
        AggregateResult[] groupedResults = [SELECT RecordTypeId, COUNT(Id) 
                                            FROM Knowledge__kav WHERE ValidationStatus='External' GROUP BY RecordTypeId];
        for (AggregateResult ar : groupedResults)  {
            //System.debug('Aggregates: ' + ar.get('RecordTypeId') +  ar.get('expr0') );
            Id arTypeId = (Id) ar.get('RecordTypeId'); 
            Integer count = (Integer) ar.get('expr0');
            knowledgeArticleTypes.put(arTypeId, count );
        }
        Integer numArticles = 0;
        //Add default value corresponding all article types
        for( Schema.RecordTypeInfo recordType : RT ){
            if(recordType.Name!='Master') {
                numArticles = 0;
                if (recordType.isActive() && recordType.isAvailable()  ){
                    String strRecTypeName = recordType.Name;
                    Id devRecordTypeId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get(strRecTypeName).getRecordTypeId();
                     Object articleCount = knowledgeArticleTypes.get(devRecordTypeId); 
                     if (articleCount != Null)
                         numArticles =(Integer) articleCount;
                     if (numArticles != Null && numArticles > 0)
                        ArticleTypes.put(devRecordTypeId,strRecTypeName);
                }
            }
        }
        return ArticleTypes;
    }
    
    public class Master{
        @AuraEnabled public list<string> ArticleTypes;
        @AuraEnabled public list<Result> Results;
        @AuraEnabled public list<Result> Downloads;
        @AuraEnabled public list<Result> Documentations;
        @AuraEnabled public Integer pageSize {get;set;}
        @AuraEnabled public Integer page {get;set;}
        @AuraEnabled public Integer total {get;set;}
        public Master(){
            ArticleTypes = new list<string>();
            Results = new list<Result>();
            
        }
    }
    
    public class Result{
        @AuraEnabled public string ArticleId;
        @AuraEnabled public string ArticleType;
        @AuraEnabled public string Title;
        @AuraEnabled public string Summary;
        @AuraEnabled public string UrlName;
        @AuraEnabled public string RecordType;
        @AuraEnabled public string ProductName;
        @AuraEnabled public string LastPublishedDate;
        @AuraEnabled public string BoxLink;
    }
    
    public class Filters{
        @AuraEnabled public list<string> ArTyps;
        @AuraEnabled public list<item> DataCategories;
        public Filters(){
            ArTyps = new list<string>();
            DataCategories = new list<item>();
        }
    }
    
    //Item Wrapper Class
    public class item{
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public Boolean expanded {get; set;}
        @AuraEnabled public List<item> items {get; set;}
        @AuraEnabled public String topParent {get; set;}
        
        public item(String label, String name,String topParent, Boolean expanded, List<item> items){
            this.label = label;
            // US-0006257 Changes, added label to name below
            this.name = name + '~' + topParent + '~' + label;
            this.expanded = expanded;
            this.items = items;
            this.topParent = topParent;
        }
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
}