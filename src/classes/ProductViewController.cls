/********************************************************************************************
Author:Sunil Kumar Sharma
Company:Hexaware Technologies
Description: Fetch products list based on the product family for Breast and Skeletal category 
and return to ProductView lightning component.

TestClass: ProductViewController_Test
Code Coverage: 92%

History:
<Date>              <Author Name>        	<Brief description of change >   <Copa.do US#>
8/22/2018			Sunil Kumar Sharma		Initial Creation				  US-0005699 
11/23/2018			Sunil Kumar Sharma		Fix to show all product family 	  US-0006169 
											product records. 
12/02/2018			Sunil Kumar Sharma		Product Load performance issue	  US-0006260 
											fixed
12/12/2018			Vrushabh Katariya		Adding Product Family Icon		  US-0006345	
*********************************************************************************************/
public with sharing class ProductViewController {
    
     /*
     * Method Name: getProducts()
     * Input Param: List<Id>
     * Return: List<ProductFamilyHeader> 
     * Description: This method is created to fetch product list based on product family.
     */
    @TestVisible private static List<ProductFamilyHeader> getProducts(Boolean showAllProducts){
        Map<String,List<Product2>> mapOfProductsGroupedByFamily = new Map<String,List<Product2>>();
        List<String> lstOfProductFamilyName = new List<String>();
        List<ProductFamilyHeader> lstOfProductFamilyWrapper = new List<ProductFamilyHeader>();
        List<Product2> listOfProduct = new List<Product2>();
        // Adding Product Family Icon ---- US-0006345 //
        // Added Community_Product_Family_Icon__c field in query
        List<ServiceProductFamilyConfig__mdt> lstOfProductFamily = new List<ServiceProductFamilyConfig__mdt>([SELECT Id, 
                MasterLabel, DeveloperName,Sort_Order__c,Community_Product_Family_Icon__c FROM ServiceProductFamilyConfig__mdt ORDER BY Sort_Order__c]);
        
        for(ServiceProductFamilyConfig__mdt strr : lstOfProductFamily){
            lstOfProductFamilyName.add(strr.MasterLabel);
        }
        Map<String,List<String>> productTempMap = new Map<String,List<String>>(); 
        if(!showAllProducts) {
            for(AggregateResult pd2 : [SELECT Product2.Community_Family_Name__c family,Product2.Community_Product_Description__c description 
                                FROM Asset 
                                WHERE Product2.Community_Family_Name__c in: lstOfProductFamilyName AND Product2.Community_Visible__c = true 
                                AND Product2.Division__c IN ('BREAST HEALTH','SKELETAL HEALTH') 
                                AND Product2.Community_Product_Description__c != null AND Status = 'Installed'
                                Group BY Product2.Community_Family_Name__c,Product2.Community_Product_Description__c]){
            	if(productTempMap.containsKey((String)pd2.get('family'))) {
                    productTempMap.get((String)pd2.get('family')).add((String)pd2.get('description'));                    
                }else{
                    List<String> tempList = new list<String>();
                    tempList.add((String)pd2.get('description'));
                    productTempMap.put((String)pd2.get('family'),tempList);       
                }
                                    
                //productTempMap.put(pd2.Community_Product_Description__c,pd2);
			}system.debug('map of values is'+ productTempMap);
        }else{
        	for(AggregateResult pd2 : [SELECT Community_Family_Name__c,Community_Product_Description__c 
                             	FROM Product2 
                             	WHERE Community_Family_Name__c in: lstOfProductFamilyName and Community_Visible__c = true AND IsActive = true 
                             	AND Division__c IN ('BREAST HEALTH','SKELETAL HEALTH') AND Community_Product_Description__c != null 
                                Group BY Community_Family_Name__c,Community_Product_Description__c]){                  
                if(productTempMap.containsKey((String)pd2.get('Community_Family_Name__c'))) {
                    productTempMap.get((String)pd2.get('Community_Family_Name__c')).add((String)pd2.get('Community_Product_Description__c'));                    
                }else{
                    List<String> tempList = new list<String>();
                    tempList.add((String)pd2.get('Community_Product_Description__c'));
                    productTempMap.put((String)pd2.get('Community_Family_Name__c'),tempList);       
                }               
                                  
            	//productTempMap.put(pd2.Community_Product_Description__c,pd2);
			}
        }
        
        //listOfProduct = productTempMap.values();
        //system.debug('The Product list size #2: '+listOfProduct.size());
        
        /*for(Product2 productRec: listOfProduct){
            if(mapOfProductsGroupedByFamily.containsKey(productRec.Community_Family_Name__c)){
                mapOfProductsGroupedByFamily.get(productRec.Community_Family_Name__c).add(productRec);
            }else{
                mapOfProductsGroupedByFamily.put(productRec.Community_Family_Name__c,new List<Product2>{productRec});
            }
        }*/
        //system.debug('The mapOfProductsGroupedByFamily is: '+mapOfProductsGroupedByFamily);
        
        // Adding Product Family Icon ---- US-0006345 //
        // Assigned value of Community_Product_Family_Icon__c field wrapper variable
        for(Integer i= 0; i< lstOfProductFamily.size(); i++){  
            Boolean doNotIncrement = false ;
            if(productTempMap.containsKey(lstOfProductFamily[i].MasterLabel) 
               && productTempMap.get(lstOfProductFamily[i].MasterLabel).size() > 0){
                ProductFamily prodFamilyWrapperRec = new ProductFamily(lstOfProductFamily[i].MasterLabel,
                    productTempMap.get(lstOfProductFamily[i].MasterLabel),lstOfProductFamily[i].Community_Product_Family_Icon__c);              
                ProductFamily prodFamilyWrapperRec1 = new ProductFamily(); 
                for(integer j = i+1 ; j<lstOfProductFamily.size() ;j++){
                    system.debug('Value of J is ' + j);
                    if((j) < lstOfProductFamily.size() && productTempMap.containsKey(lstOfProductFamily[j].MasterLabel) 
                        && productTempMap.get(lstOfProductFamily[j].MasterLabel).size() > 0){
                        prodFamilyWrapperRec1.strProductFamilyName = lstOfProductFamily[j].MasterLabel ;
                        prodFamilyWrapperRec1.strProductFamilyIconURL = lstOfProductFamily[j].Community_Product_Family_Icon__c;
                        prodFamilyWrapperRec1.lstProducts = productTempMap.get(lstOfProductFamily[j].MasterLabel);
                        break ;             
                    }
                    i = j; 
                    
                }
                ProductFamilyHeader prodFamilyHeaderWrapperRec = new ProductFamilyHeader(prodFamilyWrapperRec,prodFamilyWrapperRec1);
                lstOfProductFamilyWrapper.add(prodFamilyHeaderWrapperRec);
                system.debug('The list contains: '+lstOfProductFamilyWrapper);
            }else{
                doNotIncrement = true ; 
            }
            if(!doNotIncrement){
                i++ ;    
            }
        }
        
        return lstOfProductFamilyWrapper ;           
    }
    
    /*
     * Method Name: getSobjectRecordName()
     * Input Param: Object API name,Record Id,Field API name,Field API name
     * Return: List<ProductFamilyHeader> 
     * Description: This method is created to fetch sobject record data.
     */
    @AuraEnabled
    public static List<sObjectVar> getSobjectRecordName(String sobjname, String sobjRecId, String fieldName1, String fieldName2, String fieldName3, String fieldName4){
        list<sObjectVar> recordsList = new list<sObjectVar>();
        String queryStr='SELECT id';
        if(fieldName1 != null && fieldName1 != ''){
            queryStr = queryStr + ','+fieldName1 ;
        }
        if(fieldName2 != null && fieldName2!= ''){
            queryStr = queryStr + ','+fieldName2 ;
        }
        if(fieldName3 != null && fieldName3!= ''){
            queryStr = queryStr + ','+fieldName3 ;
        }
        if(fieldName4 != null && fieldName4!= ''){
            queryStr = queryStr + ','+fieldName4 ;
        }
        queryStr = queryStr + ' FROM ' + sobjname + ' WHERE id=\'' + sobjRecId + '\' LIMIT 1' ;
            
        system.debug('Product Query is' +queryStr );
        List<sobject> sobjRecordList = Database.query(queryStr);
        
        if(sobjRecordList.size() > 0) {
            system.debug('Product is fetched'+ sobjRecordList);
            sObjectVar sOInstance = new sObjectVar();
            if(fieldName1 != Null && fieldName1 != ''){
                sOInstance.value1 = string.valueof(sobjRecordList[0].get(fieldName1));
            }
            if(fieldName2 != Null && fieldName2 != '' && sobjRecordList[0].get(fieldName2) != null){
                sOInstance.value2 = string.valueof(sobjRecordList[0].get(fieldName2));
            }  
            if(fieldName3 != Null && fieldName3 != '' && sobjRecordList[0].get(fieldName3) != null){
                sOInstance.value3 = string.valueof(sobjRecordList[0].get(fieldName3));
            }
            if(fieldName4 != Null && fieldName4 != '' && sobjRecordList[0].get(fieldName4) != null){
                sOInstance.value4 = string.valueof(sobjRecordList[0].get(fieldName4));
            }

            recordsList.add(sOInstance);
            system.debug('size of lsit is'+ recordsList );
            return recordsList ;
        }else{
            system.debug('Product is not fetched');
           return recordsList ; 
        }
    }
    
    /*
     * Method Name: fetchConfigData()
     * Input Param: none
     * Return: Service_Community_Config__c reference 
     * Description: This method is created to fetch custom setting data.
     */
    @AuraEnabled
    public static Service_Community_Config__c fetchConfigData(){
       Service_Community_Config__c config = Service_Community_Config__c.getOrgDefaults();
       return config;
    }
    
    /*
     * Method Name: fetchOrgURL()
     * Input Param: none
     * Return: String
     * Description: This method is created to return current Salesforce org base URL.
     */
    @AuraEnabled
    public static String fetchOrgURL(){
        string urler = URL.getSalesforceBaseUrl().toExternalForm() ;
        return (urler);
    }
    
    /*
     * Method Name: getProductFamilyData()
     * Input Param: none
     * Return: List 
     * Description: This method is created to invoke getProducts() method to show all products data.
     */
    @AuraEnabled
    public static List<ProductFamilyHeader> getProductFamilyData(){
        Boolean showProducts = true ;
        return getProducts(showProducts);
    }
    
    /*
     * Method Name: getProductDescriptionRecord()
     * Input Param: String
     * Return: Product record 
     * Description: This method is created to fetch product record based on string parameter.
     */
    @AuraEnabled
    public static Id getProductDescriptionRecord(String communityDescription,String listViewName){
        if(listViewName == 'All Products'){
            List<Asset> assetRecList = new List<Asset>([SELECT id,Product2Id FROM Asset WHERE Product2.Community_Visible__c = true 
                                AND Product2.Division__c IN ('BREAST HEALTH','SKELETAL HEALTH') 
                                AND Product2.Community_Product_Description__c =: communityDescription AND Status = 'Installed' LIMIT 1]);
            if(assetRecList.size() > 0){
                return assetRecList[0].Product2Id ;
            }else{
                Product2 prodRec = [SELECT id 
                                    FROM Product2 
                                    WHERE Community_Visible__c = true AND IsActive = true AND Division__c IN ('BREAST HEALTH','SKELETAL HEALTH') 
                                    AND Community_Product_Description__c =: communityDescription LIMIT 1] ;
                return prodRec.Id; 
            }            
        }else{
            Asset assetRec = [SELECT id,Product2Id FROM Asset WHERE Product2.Community_Visible__c = true 
                                AND Product2.Division__c IN ('BREAST HEALTH','SKELETAL HEALTH') 
                                AND Product2.Community_Product_Description__c =: communityDescription AND Status = 'Installed' LIMIT 1];
            return assetRec.Product2Id ;
        }
    }
    /*
     * Method Name: getMyProductFamilyData()
     * Input Param: none
     * Return: List 
     * Description: This method is created to return product family and products records related to current user.
     */
    @AuraEnabled
    public static List<ProductFamilyHeader> getMyProductFamilyData(){
        //List<Id> listOfProduct2Id = new List<Id>();
        //String userId = UserInfo.getUserId();
        //List<User> listOfUser = [SELECT u.Id,u.ContactId FROM User u WHERE u.Id = :userId];
        /*List<Asset> listOfAsset = [SELECT id,Product2Id FROM Asset ];
        for(Asset assetRecord:listOfAsset) {
            if(assetRecord.Product2Id != null)
                listOfProduct2Id.add(assetRecord.Product2Id);
        }
        if(listOfProduct2Id.size() > 0) {
            return getProducts(listOfProduct2Id);
        }
        return new List<ProductFamilyHeader>();*/
        Boolean showProducts = false ;
        return getProducts(showProducts);
    }    
    
    /*
     * Wrapper Class Name: ProductFamily
     * Description: This wrapper class is created to hold product family name and associated list of products with them.
     */
    
    /*  Adding Product Family Icon ---- US-0006345 //
    	Added strProductFamilyIconURL variable to wrapper class to fetch URL
	*/
    public class ProductFamily{
        @AuraEnabled public String strProductFamilyName {get;set;}
        @AuraEnabled public String strProductFamilyIconURL {get;set;}
        @AuraEnabled public List<String> lstProducts {get;set;}
        @AuraEnabled public Integer productsToShow {get;set;}
        @AuraEnabled public Boolean showAllProducts {get;set;}
        public ProductFamily(){
            
        }
        public ProductFamily(String strFamilyName, List<String> lstOfProductRecs, String strProductFamilyIcon){
            strProductFamilyIconURL = strProductFamilyIcon;
            strProductFamilyName = strFamilyName ; 
            lstProducts = lstOfProductRecs ;
            productsToShow = 8;
            showAllProducts = false ; 
        }
    }
    
    /*
     * Wrapper Class Name: ProductFamilyHeader
     * Description: This wrapper class is created to hold product family data to show in two columns in lightning component.
     */
    public class ProductFamilyHeader{
        @AuraEnabled public ProductFamily prodFamilyRow1 {get;set;} 
        @AuraEnabled public ProductFamily prodFamilyRow2 {get;set;} 
        
        public ProductFamilyHeader(ProductFamily prodFamilyWrapperRec, ProductFamily prodFamilyWrapperRec1){
            prodFamilyRow1 = prodFamilyWrapperRec ;
            prodFamilyRow2 = prodFamilyWrapperRec1 ;
        }
    }
    
    /*
     * Wrapper Class Name: sObjectVar
     * Description: This wrapper class is created to hold object and field values.
     */
    public class sObjectVar{
        @AuraEnabled public string value1;
        @AuraEnabled public string value2;
        @AuraEnabled public string value3;
        @AuraEnabled public string value4;
    }   
}