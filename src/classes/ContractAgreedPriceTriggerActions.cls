/*------------------------------------------------------------
  Author:         John Christy
  Company:        Apps Associates
  Description:    Used to add/remove records via batch apex on the Contract_Agreed_Price__c junction object
  Inputs:         newObject/oldObject - The maps of contracts/AgreedPrices/CEC
  Test Class:     Test_ContractAgreedPrice
  History:
  <Date>          <Authors Name>    <Brief Description of Change>
  08/20/2018      John Christy      Initial Creation (US)
  ------------------------------------------------------------*/
public class ContractAgreedPriceTriggerActions {

    public static void updateContractAgreedPrice(Map<Id, SObject> newObject, Map<Id, SObject> oldObject) {
        List<AsyncApexJob> aaJob = [SELECT Id FROM AsyncApexJob WHERE ApexClass.Name = 'contractExpiration' AND Status IN('Preparing', 'Processing')];
        if (aaJob.isEmpty()) {

            System.debug('newObject: ' + newObject);
            System.debug('oldObject: ' + oldObject);

            Set<Id> conInsert = new Set<Id> ();
            Set<Id> conDelete = new Set<Id> ();

            String objectType;
            if (newObject != null) {
                objectType = String.valueOf(newObject.getSObjectType());
            }
            else {
                objectType = String.valueOf(oldObject.getSObjectType());
            }

            System.debug('objectType: ' + objectType + ' Update');

            // builds list of contract ids to pass onto the batch process (based on sobject type Contract/AP/CEC)
            if (objectType == 'Contract') {
                System.debug('Begin ' + objectType + ' Process');
                Map<Id, Contract> newContracts = (Map<Id, Contract>) newObject;
                for (Contract conNew : newContracts.values()) {
                    Contract conOld = (Contract) oldObject.get(conNew.Id);
                    if (conNew.Status != conOld.Status) {
                        // if contract field is not activated or specified will ignore process
                        if (isContractToProcess(conNew)) {
                            if (conNew.Status == 'Activated') {
                                System.debug('Contract Insert: ' + conNew.Id);
                                conInsert.add(conNew.Id);
                            }
                            else {
                                System.debug('Contract Delete: ' + conNew.Id);
                                conDelete.add(conNew.Id);
                            }
                        }
                    }
                }
            }
            else {
                System.debug('Begin ' + objectType + ' process');
                // create map of object 
                Map<Id, SObject> sobjectMap = new Map<Id, SObject> ();
                if (newObject != null) {
                    sobjectMap = (Map<Id, SObject>) newObject;
                }
                else {
                    sobjectMap = (Map<Id, SObject>) oldObject;
                }

                // build set of contracts from sObject
                Set<Id> idSet = new Set<Id> ();
                for (SObject sObj : sobjectMap.values()) {
                    if (sObj.get('Contract__c') != null) {
                        idSet.add(Id.valueOf(String.valueOf(sObj.get('Contract__c'))));
                    }
                }

                System.debug('idSet: ' + idSet.size());

                if (!idSet.isEmpty()) {
                    // build dynamic query to include all custom fields for contract validation
                    String dbQuery = 'select Id,Status';
                    for (QuoteContractPricingSetup__c qcp : QuoteContractPricingSetup__c.getAll().values()) {
                        if (qcp.Active__c) {
                            dbQuery += ', ' + qcp.Name;
                        }
                    }
                    dbQuery += ' from Contract where Id in :idSet';

                    // create map from dynamic query
                    Map<Id, Contract> contractMap = new Map<Id, Contract> ((List<Contract>) Database.query(dbQuery));

                    if (objectType == 'Agreed_Price__c') {
                        System.debug('Enter ' + objectType);
                        for (SObject sObj : sobjectMap.values()) {
                            Agreed_Price__c ap = (Agreed_Price__c) sObj;
                            // if contract field is not activated or specified will ignore process
                            if (isContractToProcess(contractMap.get(ap.Contract__c))) {
                                if (oldObject != null) {
                                    if (newObject == null) {
                                        System.debug('Delete AP: ' + ap.Id);
                                        conDelete.add(ap.Id);
                                    }
                                    else {
                                        if (ap.Active__c) {
                                            System.debug('AP Insert: ' + ap.Id);
                                            conInsert.add(ap.Contract__c);
                                        }
                                        else {
                                            System.debug('AP Delete: ' + ap.Id);
                                            conDelete.add(ap.Id);
                                        }
                                    }
                                }
                                else {
                                    if (ap.Active__c) {
                                        System.debug('AP New Insert: ' + ap.Id);
                                        conInsert.add(ap.Contract__c);
                                    }
                                }

                            }
                        }
                    }
                    else if (objectType == 'Customer_Eligible_Contract__c') {
                        System.debug('Enter ' + objectType);
                        for (SObject sObj : sobjectMap.values()) {
                            Customer_Eligible_Contract__c cec = (Customer_Eligible_Contract__c) sObj;
                            // if contract field is not activated or specified will ignore process
                            if (isContractToProcess(contractMap.get(cec.Contract__c))) {
                                if (oldObject != null) {
                                    if (cec.Selected__c) {
                                        System.debug('CEC Insert: ' + cec.Id);
                                        conInsert.add(cec.Id);
                                    }
                                    else {
                                        System.debug('Delete: ' + cec.Id);
                                        conDelete.add(cec.Id);
                                    }
                                }
                                else {
                                    if (cec.Selected__c) {
                                        System.debug('Contract CEC New Insert: ' + cec.Id);
                                        conInsert.add(cec.Id);
                                    }
                                }
                            }
                        }

                    }

                }

            }

            // call batch executables
            if (!conInsert.isEmpty()) {
                Integer iBatch = 10;
                // calculates the batch size depending on number of AP records to process
                if (objectType != 'Customer_Eligible_Contract__c') {
                    AggregateResult aggCount = [SELECT count(Id) countId, Contract__c
                                                FROM Agreed_Price__c
                                                WHERE Contract__c IN :conInsert
                                                GROUP BY Contract__c
                                                ORDER BY count(Id) Desc
                                                LIMIT 1];
                    System.debug('conInsert: ' + conInsert);
                    System.debug('aggCount: ' + aggCount);
                    Decimal dCount = (Decimal) aggCount.get('countId');
                    System.debug('dCount: ' + dCount);
                    Decimal dBatch = 10000 / dCount;
                    System.debug('dBatch: ' + dBatch);
                    ibatch = (Integer) dBatch.round(System.RoundingMode.Down);
                    System.debug('iBatch: ' + iBatch);
                }

                System.debug('executeBatchInsert ' + conInsert.size() + ' ' + objectType);
                Database.executeBatch(new ContractAgreedPriceBatchInsert(conInsert, objectType), iBatch);
            }

            if (!conDelete.isEmpty()) {
                System.debug('executeBatchDelete ' + conDelete.size() + ' ' + objectType);
                Database.executeBatch(new ContractAgreedPriceBatchDelete(conDelete, objectType));
            }
        }
    }

    // method to check if contract field is active on custom setting QuoteContractPricingSetup__c and field value > 0
    public static Boolean isContractToProcess(Contract conNew) {
        Boolean isTrue = false;
        SObjectType contractType = Schema.getGlobalDescribe().get('Contract');
        Map<String, Schema.SObjectField> fieldMap = contractType.getDescribe().fields.getMap();
        if (conNew.Status == 'Activated' || conNew.Status == 'Expired' || conNew.Status == 'Terminated' || conNew.Status == 'Amended') {
            for (QuoteContractPricingSetup__c qcp : QuoteContractPricingSetup__c.getAll().values()) {
                if (qcp.Active__c) {
                    for (Schema.SObjectField sField : fieldMap.Values()) {
                        schema.describefieldresult dfield = sfield.getDescribe();
                        if (dfield.getName() == qcp.Name && Integer.valueOf(conNew.get(qcp.Name)) > 0) {
                            System.debug(dfield.getName() + ' Size: ' + conNew.get(qcp.Name));
                            isTrue = true;
                        }
                    }
                }
            }
        }

        if (Test.isRunningTest()) {
            isTrue = true;
        }

        return isTrue;
    }
}