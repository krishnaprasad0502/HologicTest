/*------------------------------------------------------------
Author:          Mani Sundaresan
Company:         Hologic 
Description:     Pipeline Product Trigger functions
Class Name:      PipelineProductTriggerActions
Trigger:         PipelineProductTrigger
Test Class:      PipelineProductTriggerActions_Test
History:
<Date>           <Authors Name>      <Brief Description of Change>
01/24/2019       Mani Sundaresan      Initial Creation ()
------------------------------------------------------------*/
public class PipelineProductTriggerActions  {
    
    //Variable Declaration Section
    private static Record_Type_IDs__c recordTypeIds = Record_Type_IDs__c.getOrgDefaults();
    private static final ID RECORD_TYPE_ID_INTL_BREASTHEALTH_SALES = recordTypeIds.Opportunity_Intl_Breast_Health_Sales__c;
    private static final ID RECORD_TYPE_ID_INTL_DIAGNOSTICS_SALES = recordTypeIds.Opportunity_Intl_Diagnostics_Sales__c;
    private static final ID RECORD_TYPE_ID_INTL_MA_SALES = recordTypeIds.Opportunity_Intl_MA_Sales__c;
    private static final ID RECORD_TYPE_ID_INTL_PERINATAL_SALES = recordTypeIds.Opportunity_Intl_Perinatal_Sales__c;
    private static final ID RECORD_TYPE_ID_INTL_SURGICAL_SALES = recordTypeIds.Opportunity_Intl_Surgical_Sales__c;    
    
    /*------------------------------------------------------------
    Author:         Mani Sundaresan 
    Company:        Hologic 
    Description:    Populate the Amount of Pipeline Products
    Inputs:         List of Pipeline Products being inserted/updated
                    Map of Old Pipeline Products
    Returns:        N/A
    Test Class:     PipelineProductTriggerActions_Test


    History:
    <Date>          <Authors Name>      <Brief Description of Change>
    01/24/2019      Mani Sundaresan     Logic to calculate the total on Pipeline Products  
    ------------------------------------------------------------*/
    public static void calcAmount(List<Pipeline_Products__c> pipelineProducts, Map<Id, Pipeline_Products__c> oldPipelineProducts){
    
        Set<Id> opptyIdSet = new Set<Id>();
        List<Opportunity> opptyList = new List<Opportunity>();
        
        if(pipelineProducts != null){
            for(Pipeline_Products__c pp : pipelineProducts){
                Pipeline_Products__c oldpipelineProd = oldPipelineProducts != null && oldPipelineProducts.containsKey(pp.Id) ? oldPipelineProducts.get(pp.Id) : null;
                if(oldpipelineProd == null || (oldpipelineProd != null && oldpipelineProd.Amount__c != pp.Amount__c))
                    opptyIdSet.add(pp.Opportunity__c);
            }
        }
        else if(oldPipelineProducts != null && pipelineProducts == null){
            for(Pipeline_Products__c pp : oldPipelineProducts.values()){
                opptyIdSet.add(pp.Opportunity__c);
            }        
        }
            
        System.debug('opptyIdSet:'+opptyIdSet);
        
        if(opptyIdSet != null)
            opptyList = [SELECT Id, Amount, (SELECT Id, Amount__c from Pipeline_Products__r) from Opportunity where Id IN :opptyIdSet AND (RecordTypeId = :RECORD_TYPE_ID_INTL_BREASTHEALTH_SALES OR RecordTypeId = :RECORD_TYPE_ID_INTL_DIAGNOSTICS_SALES  OR RecordTypeId = :RECORD_TYPE_ID_INTL_MA_SALES  OR RecordTypeId = :RECORD_TYPE_ID_INTL_PERINATAL_SALES  OR RecordTypeId = :RECORD_TYPE_ID_INTL_SURGICAL_SALES )  ];
            
        System.debug('opptyList :'+opptyList);
        
        if(opptyList.size() > 0)
            for(Opportunity opp : opptyList){
                Decimal ppAmount = 0;
                for(Pipeline_Products__c pp : opp.Pipeline_Products__r){
                    if(pp.Amount__c != null)
                        ppAmount += pp.Amount__c;
                }
                opp.Amount = ppAmount;
            }
        
        if(opptyList.size() > 0)
            update opptyList;
        
   }
}