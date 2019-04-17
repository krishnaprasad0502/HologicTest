/*------------------------------------------------------------
Author          Dave Mansell
Company:        Salesforce.com
Description:    Functions related to ServiceContract records

History:
<Date           <Authors Name       <Brief Description of Change>
10/03/2018      Dave Mansell        Initial Creation (rework of previous code by Tayo Chestnut and Ronald Mendoza)
------------------------------------------------------------*/

public with sharing class ServiceContractTriggerHandler {
	
	public static void updatePayments(List<ServiceContract> scons){
		//Filter to ensure quote value is provided
		Map<Id, ServiceContract> validSconsByQuoteId = new Map<Id, ServiceContract>();
		for(ServiceContract scon : scons){
			if(scon.SBQQSC__Quote__c != null){
				validSconsByQuoteId.put(scon.SBQQSC__Quote__c, scon);
			}
		}
		
		//Query for related payments
		List<Payment__c> payments = [
			SELECT Id
				  ,Quote__c
			  FROM Payment__c
			 WHERE Quote__c IN :validSconsByQuoteId.keySet()
		];
		
		//Update value on payment records
		for(Payment__c payment : payments){
			payment.Service_Contract__c = validSconsByQuoteId.get(payment.Quote__c).Id;
		}
		
		update payments;
	}

	public static void checkToCreateContracts(List<ServiceContract> scons, Map<Id, ServiceContract> oldMap){
		//Filter incoming records to find those newly activated
		List<ServiceContract> validScons = new List<ServiceContract>();
		for(ServiceContract scon : scons){
			ServiceContract old = oldMap.get(scon.Id);
			if(scon.ApprovalStatus == 'Activated' && old.ApprovalStatus != 'Activated'){
				validScons.add(scon);
			}
		}
		
		if(validScons.size() > 0){
			createContracts(validScons);
		}
	}
	
	public static void createContracts(List<ServiceContract> scons){
		//Query for field values on ServiceContract and child records
		scons = [
			SELECT Id
				  ,AccountId
				  ,ContractNumber
				  ,CurrencyIsoCode
				  ,EndDate
				  ,Operating_Unit__c
				  ,StartDate
				  ,Term
				  ,(SELECT Id
				  		  ,Name
				  		  ,Coverage_Group__c
				  		  ,Coverage_Group__r.Category_Product_for_Pricing__c
				  		  ,Discount__c
				  		  ,EndDate
				  		  ,StartDate
					  FROM Entitlements
					 WHERE Name LIKE 'Svc Discount%'
				   )
				  ,(SELECT Id
					  FROM Contracts__r
					 LIMIT 1
				   )
			  FROM ServiceContract
			 WHERE Id IN :scons
		];
		
		Map<Id, Contract> contractsToInsertBySconId = new Map<Id, Contract>();
		for(ServiceContract scon : scons){
			//As long as there are at least 1 entitlement and no contracts, create contract
			if(!scon.Entitlements.isEmpty() && scon.Contracts__r.isEmpty()){
				Contract newCon = new Contract();
				
	            newCon.AccountId						= scon.AccountId;
	            newCon.Automatic_Renewal__c				= false;
	            newCon.Contract_End_Date__c				= scon.EndDate;
	            newCon.Contract_Pricing_Source__c		= 'Other';
	            newCon.Contract_Source__c				= scon.ContractNumber;
	            newCon.ContractTerm						= scon.Term;
	            newCon.CurrencyIsoCode					= scon.CurrencyIsoCode;
	            newCon.Division__c						= 'Medical Aesthetics';
	            newCon.Intent_to_Renew__c				= '';
	            newCon.Intent_to_Terminate__c			= '';
	            newCon.Local_Pricing_Allowed__c			= true;
	            newCon.Name								= 'Service Contract Entitlement Discount';
	            newCon.Operating_Unit__c				= scon.Operating_Unit__c;
	            newCon.Payment_Terms_AR__c				= '';
	            newCon.Payment_Terms_Freight__c			= '';
	            newCon.RecordTypeId						= GlobalUtility.getRecordTypeId('Contract', 'Service_Entitlement_Contract');
				newCon.Related_Service_Contract__c		= scon.Id;
	            newCon.StartDate						= scon.StartDate;
	
	            contractsToInsertBySconId.put(scon.Id, newCon);
			}
		}
		
		insert contractsToInsertBySconId.values();
		
		//Update statuses
		for(Contract newCon : contractsToInsertBySconId.values()){
			newCon.Status = 'Activated';
		}
		update contractsToInsertBySconId.values();
		
		List<Customer_Eligible_Contract__c> cecsToInsert = new List<Customer_Eligible_Contract__c>();
		List<Agreed_Price__c> agpsToInsert = new List<Agreed_Price__c>();
		for(ServiceContract scon : scons){
			Contract newCon = contractsToInsertBySconId.get(scon.Id);
			if(newCon != null){
	            //Create Customer_Eligible_Contract__c
	            Customer_Eligible_Contract__c cec = new Customer_Eligible_Contract__c();
	            cec.RecordTypeId				= GlobalUtility.getRecordTypeId('Customer_Eligible_Contract__c', 'Contract_CEC');
	            cec.Contract__c					= newCon.Id;
	            cec.Customer_Account__c			= newCon.AccountId;
	            cec.Effective_Date__c			= newCon.StartDate;
	            cec.Expiration_Date__c			= newCon.Contract_End_Date__c;
	            cec.Precedence_Value__c			= 25;
	            cec.Contract_Activated__c		= true;
	            cec.Selected__c					= true;
	            cec.CurrencyIsoCode				= newCon.CurrencyIsoCode;
	
	            cecsToInsert.add(cec);
	            
				//Create agreed prices, one for each entitlement
				for(Entitlement ent : scon.Entitlements){
	                Agreed_Price__c agp = new Agreed_Price__c();
	
	                agp.Discount__c							= 0;
	                if(ent.Discount__c != null){
	                	agp.Discount__c						= ent.Discount__c;
	                }
	                agp.Contract__c							= newCon.Id;
	                agp.Contract_Activated__c				= true;
	                agp.Coverage_Group__c					= ent.Coverage_Group__c;
	                agp.CurrencyIsoCode						= scon.CurrencyIsoCode;
	                agp.End_Date__c							= ent.EndDate;
	                if(ent.Coverage_Group__c != null){
	                	agp.Product__c						= ent.Coverage_Group__r.Category_Product_for_Pricing__c;
	                }
	                agp.Service_Contract_Entitlement__c		= ent.Id;
	                agp.Start_Date__c						= ent.StartDate;
	
	                agpsToInsert.add(agp);
	            }
			}
		}
		
		insert cecsToInsert;
		insert agpsToInsert;
	}
	
}


/*---------------------------------------------------------------------------------------------------------------------------------------------
Author:     Tayo Chestnut
Description:

Test Class:

History:
<Date>      <Authors Name>    <Brief Description of Change>
02/17/2018   Tayo Chestnut      US-0003737 - Create Sales Contract from Service Entitlement for Medical Aesthetics - Initial Creation
05/2/2018    Ronald Mendoza     US-0003737 - Contract Mapping Updates
------------------------------------------------------------------------------------------------------------------------------------------------*/
/*
public with sharing class ServiceContractTriggerHandler {


    public static void handleAfterUpdate(List<ServiceContract> servcons){
        //If Insert and Activated then check for entitlements that contain Medical Aestics 
        //If yes, create Sales Contract w/ Agreed Prices, else do nothing

        Map<String,ServiceContract> servconMap=new Map<String,ServiceContract>();
        Map<String,List<ContractLineItem>> cLineItemsMap=new Map<String,List<ContractLineItem>>();
        List<ContractLineItem> cLineItemsAll=new List<ContractLineItem>();
        Map<String,Set<Entitlement>> entitleItemsMap=new Map<String,Set<Entitlement>>();

        Set<String> servconSelected=new Set<String>();
        Map<String,Contract> servContoSalesCon=new Map<String,Contract>();
        Map<String,Contract> servContoSalesConNew=new Map<String,Contract>();
        List<Contract> consUpsert=new List<Contract>();
        List<Contract> consUpdate=new List<Contract>();
        List<Customer_Eligible_Contract__c> cecUpsert = new List<Customer_Eligible_Contract__c>();
        List<Agreed_Price__c> agreedPriceLines=new List<Agreed_Price__c>();

        //String conRecId=[Select id from RecordType where SObjectType='Contract' and Name='Service Entitlement Contract'].id;
        //String cecRecId=[Select id from RecordType where SObjectType='Customer_Eligible_Contract__c' and Name='Contract CEC'].id;
        String conRecId = GlobalUtility.getRecordTypeId('Contract', 'Service_Entitlement_Contract');
        String cecRecId = GlobalUtility.getRecordTypeId('Customer_Eligible_Contract__c', 'Contract_CEC');

        //Get Activate Service Contracts, Place in Map
        for(ServiceContract servcon:servcons){
            if(servcon.ApprovalStatus=='Activated'){
                servconMap.put(servcon.id,servcon);
            }
        }
        
        //Check if Service Contract has Medical Aesthetics, if so add to "Selected Service Contract"
        for(Entitlement ent:[Select id, Name,ServiceContractId, Coverage_Group__c,Discount__c, StartDate, EndDate, Coverage_Group__r.Category_Product_for_Pricing__c, ServiceContract.CurrencyIsoCode from Entitlement where ServiceContractId IN:servconMap.keyset() and Name LIKE 'Svc Discount%']){
            Set<Entitlement> tempLines=new Set<Entitlement>();
            tempLines=(entitleItemsMap.containsKey(ent.ServiceContractid))==true ? entitleItemsMap.get(ent.ServiceContractid) : tempLines;
            tempLines.add(ent);
            entitleItemsMap.put(ent.ServiceContractid, tempLines);
            servconSelected.add(ent.ServiceContractid);
        }

        //Get all Existing Sales Contracts that are tied to Service Contracts, If tied, only update Sales Contract, Else Create Sales Contracts and Agreed Price Lines
        for(Contract con:[Select id, Related_Service_Contract__c, Accountid, ActivatedDate, ContractTerm, Operating_Unit__c, ContractNumber, StartDate, EndDate from Contract where Related_Service_Contract__c IN: servconSelected]){
            servContoSalesCon.put(con.Related_Service_Contract__c, con);
        }

        for(String s:servconSelected){
            Boolean salesConExists=false;
            Contract salesCon=new Contract();
            ServiceContract servCon=servconMap.get(s);

            if(servContoSalesCon.containsKey(s)){
                continue; //added continue to skip sales contract creation if one already exists
                //salesCon=servContoSalesCon.get(s);
            }

            salesCon.Related_Service_Contract__c = s;
            salesCon.Accountid = servCon.Accountid;
            salesCon.RecordTypeId = conRecId;
            salesCon.ContractTerm = servCon.term;
            salesCon.Name = 'Service Contract Entitlement Discount';
            salesCon.Contract_Source__c = servCon.ContractNumber;
            salesCon.Operating_Unit__c = servCon.Operating_Unit__c;
            salesCon.Payment_Terms_AR__c = '';
            salesCon.Payment_Terms_Freight__c = '';
            salesCon.Contract_Pricing_Source__c = 'Other';
            salesCon.Local_Pricing_Allowed__c = true;
            salesCon.StartDate = servCon.StartDate;
            salesCon.Contract_End_Date__c = servCon.EndDate;
            salesCon.Intent_to_Terminate__c = '';
            salesCon.Intent_to_Renew__c = '';
            salesCon.Automatic_Renewal__c = false;
            salesCon.Division__c = 'Medical Aesthetics';
            salesCon.CurrencyIsoCode = servCon.CurrencyIsoCode;

            consUpsert.add(salesCon);

        

            //upsert newCEC;
            //if (cecUpsert.size() < 1)
                //cecUpsert.add(newCEC);
        }
        //create new Sales Contracts leveraging Service Contract info
        upsert consUpsert;

        //create new CECs for Sales Contracts
        //upsert cecUpsert;

        for(Contract con: consUpsert){
            servContoSalesConNew.put(con.Related_Service_Contract__c, con);
        }

        for(String s:servconSelected){
            if(!servContoSalesCon.containsKey(s)){
                //Create Agreed Price Lines for Sales Contract
                for(Entitlement eLineItem:entitleItemsMap.get(s)){
                    Agreed_Price__c agPrice=new Agreed_Price__c();

                    //Map Fields from Contract Line Item to Agreed Price
                    agPrice.Coverage_Group__c=eLineItem.Coverage_Group__c;
                    system.debug(eLineItem);
                    agPrice.Discount__c=(eLineItem.Discount__c==NULL) ? 0 : eLineItem.Discount__c;
                    agPrice.Contract__c=servContoSalesConNew.get(s).id;
                    agPrice.Service_Contract_Entitlement__c = eLineItem.Id;
                    agPrice.Start_Date__c = eLineItem.StartDate;
                    agPrice.End_Date__c = eLineItem.EndDate;
                    agPrice.Product__c = eLineItem.Coverage_Group__r.Category_Product_for_Pricing__c;
                    agPrice.Contract_Activated__c = true;
                    agPrice.CurrencyIsoCode = eLineItem.ServiceContract.CurrencyIsoCode;
    
                    agreedPriceLines.add(agPrice);
                }
                
            }       
        }

        insert agreedPriceLines;

        //Activate newly created Sales Contracts and update records
        for(Contract con: consUpsert){
            con.Status = 'Activated';

            consUpdate.add(con);

            Customer_Eligible_Contract__c newCEC = new Customer_Eligible_Contract__c();
            newCEC.RecordTypeId = cecRecId;
            newCEC.Contract__c = con.Id;
            newCEC.Customer_Account__c = con.AccountId;
            newCEC.Effective_Date__c = con.StartDate;
            newCEC.Expiration_Date__c = con.Contract_End_Date__c;
            newCEC.Precedence_Value__c = 25;
            newCEC.Contract_Activated__c = true;
            newCEC.Selected__c = true;
            newCEC.CurrencyIsoCode = con.CurrencyIsoCode;

            cecUpsert.add(newCEC);
        }

        update consUpdate;

        upsert cecUpsert;

    }
    
     public static void insertPayments(List<ServiceContract> servcons){
     
         Map<Id, Id> quoteIdMap = new Map<Id, Id>();
         List<Payment__c> paymentList = new List<Payment__c>();
         Boolean updated = false;
         
         for(ServiceContract sc : servcons){
             if(sc.SBQQSC__Quote__c != null)
                 quoteIdMap.put(sc.SBQQSC__Quote__c,sc.Id);
         }
         
         if(quoteIdMap.size() > 0)
             paymentList = [SELECT Id, Quote__c, Service_Contract__c from Payment__c where Quote__c IN :quoteIdMap.keySet()];
         
         System.debug('paymentList:'+paymentList);
         
         if(paymentList.size() > 0)
             for(Payment__c pay : paymentList){
                 if(quoteIdMap.get(pay.Quote__c) != null){
                     pay.Service_Contract__c = quoteIdMap.get(pay.Quote__c);
                     updated = true;
                 }
             }
             
         if(updated)
             update paymentList;    
         
             
     }
    
    
}
*/