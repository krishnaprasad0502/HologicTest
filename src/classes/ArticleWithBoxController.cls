/************************************************************************************
    Author : Niraj
    Company : Hexaware Technologies
    Description : Fetch Articles
    Test Class : TestArticleDetailsWithBoxController    

    History:
    <Date>         <Author Name>            <Brief Description of Change>    <Copa.do US#> 
    12/09/2018      Niraj                   Initial Creation                 US-0005634
*************************************************************************************/
public with sharing class ArticleWithBoxController {
    
    public class Result{
        @AuraEnabled public string ArticleId;
        @AuraEnabled public string UrlName;
        @AuraEnabled public string ArticleType;
        @AuraEnabled public string Link;
        @AuraEnabled public string Title;
        @AuraEnabled public list<articleField> Fields;
        
        public Result (){
              Fields = new List<articleField>();       
        }
    }
    
    /*
     * Method Name: FetchKnowledge()
     * Input Param: String
     * Return: Object reference 
     * Description: This method is created to fetch knowledge base articles.
     */
    @AuraEnabled
    public static Result FetchKnowledge(string id){ 
        list<Knowledge__kav> KArticles = new list<Knowledge__kav>();
        List<Schema.FieldSetMember> articleFieldSet = getFields('Community_Detail_Page');
        String sql = 'SELECT ';
        for(Schema.FieldSetMember f : articleFieldSet) {
            sql += f.getFieldPath() + ', ';  
        }
        sql += 'Id,UrlName FROM Knowledge__kav WHERE Id =\'' + id + '\'';
        System.debug('SQL:' + sql);

        KArticles  = Database.query(sql);
        Result res = new Result(); 
        for(Knowledge__kav dkav : KArticles){
            res.ArticleId = dkav.Id;
            res.UrlName = dkav.UrlName;
            //Box Link Field was decided to be removed on 20-09-2018, setting blank value for now
            //res.Link = dkav.Box_Link__c;
            res.Link ='';
            
            res.Title = dkav.title;
            for(Schema.FieldSetMember f : articleFieldSet) {
                //Only consider String Type Fields for Now (due to time limit)
                System.debug('Field and Type:' + f.getLabel() + ' ' + f.getType());
                if (f.getType() == Schema.DisplayType.String || f.getType() == Schema.DisplayType.TEXTAREA || f.getType() == Schema.DisplayType.DATETIME)
                {
                   String strFieldValue;
                   Datetime dt;
                   Object fieldValue = dkav.get(f.getFieldPath());
                    
                   if  (f.getType() == Schema.DisplayType.DATETIME)
                   { 
                       dt = (Datetime) fieldValue; 
                       strFieldValue = dt.format('d-MMM-yyyy');
                   }
                   else
                   {
                     strFieldValue = String.valueOf(fieldValue);
                   }
                   articleField aField = new articleField(f.getLabel(), f.getType() , strFieldValue);
                   res.Fields.add(aField);
                }
            }
        }
        
        return res;              
    }
    
    //Retrieve Fields in a FieldSet
    public static List<Schema.FieldSetMember> getFields(String fieldSetName) {
        Schema.FieldSet fieldSetForArticle = Schema.SObjectType.Knowledge__kav.fieldSets.getMap().get(fieldSetName);
        return fieldSetForArticle.getFields();
    }
      
    //articlefield Wrapper Class
    public class articleField{
        @AuraEnabled
        public String label {get; set;}
        @AuraEnabled
        public Schema.DisplayType type {get; set;}
        @AuraEnabled
        public String value {get; set;}
         
        public articleField(String label, Schema.DisplayType type,String value){
            this.label = label;
            this.type = type;
            this.value = value;
        }
    }

}