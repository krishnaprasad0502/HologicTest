/**
* @author Salesforce.com
* @date 2016
*
* @description Utility class to interact with the database and throw errors on unsuccessful upserts.
*/
public with sharing class DBUtility {
	
	static Database.DMLOptions dml = new Database.DMLOptions();
    static {
    	dml.allowFieldTruncation = true;
    }
    
    public static void doInsert(sObject so) {
    	insertRecords(new List<sObject>{so});
    }
    
    public static void doInsert(List<sObject> so) {
    	insertRecords(so);
    }
    
    public static void doUpdate(sObject so) {
    	updateRecords(new List<sObject>{so});
    }
    
    public static void doUpdate(List<sObject> so) {
    	updateRecords(so);
    }
    
    public static void doDelete(sObject so) {
    	deleteRecords(new List<sObject>{so});
    }
    
    public static void doDelete(List<sObject> so) {
    	deleteRecords(so);
    }
    
    private static void insertRecords(List<sObject> so) {
    	processResults(Database.insert(so, dml));
    }
    
    private static void updateRecords(List<sObject> so) {
    	processResults(Database.update(so, dml));  
    }
    
    private static void deleteRecords(List<sObject> so) {
    	processResults(Database.delete(so));  
    }
    
    private static void processResults(List<Database.SaveResult> srList) {
    	for (Database.SaveResult sr : srList) {
	        if (!sr.isSuccess()) {
	        	String message = '';
	
	        	for (Database.Error e : sr.getErrors()) {
	        		message += e.getMessage() + '.';
	        	}
	
	        	system.assert(false, message);
	        	//throw new RESTException(message);
	        	
	        	// TO DO
	        	
	        	RestResponse r = System.RestContext.response; 
	        	 
	        	if (r != null) {
	        		RestContext.response.statusCode = 400;
	        		RestContext.response.responseBody = Blob.valueOf(message);
	        	}
	        }
        }
    }
    
     private static void processResults(List<Database.DeleteResult> srList) {
    	for (Database.DeleteResult sr : srList) {
	        if (!sr.isSuccess()) {
	        	String message = '';
	
	        	for (Database.Error e : sr.getErrors()) {
	        		message += e.getMessage() + '. ';
	        	}
	
	        	system.assert(false, message);
	        }
        }
    }
    
    public class RESTException extends Exception {
    	
    }
    
}