/*------------------------------------------------------------
Author          Dave Mansell
Company:        Salesforce.com
Description:    Functions to create entitlements for WOLIs and ProductConsumeds

History:
<Date           <Authors Name       <Brief Description of Change>
03/19/201       Dave Mansell        Initial Creation (US-0004035)
------------------------------------------------------------*/

public class EntitlementLinkingHelper {
    
    public static final String TYPE_WO                      = 'TYPE_WO';
    public static final String TYPE_WOLI                    = 'TYPE_WOLI';
    public static final String TYPE_PRODUCT_CONSUMED        = 'TYPE_PRODUCT_CONSUMED';
    public static final String TYPE_PRODUCT_REQUIRED        = 'TYPE_PRODUCT_REQUIRED';
    
    public static void linkEntitlementsForRecords(List<SObject> recs, String sObjectType, Map<Integer, Id> prodIdsByListIndex, Map<Id, Id> rootAssetIdsByAssetId){
        Map<Id, Id> assetIdsByWOId = new Map<Id, Id>();
        Map<Id, Agreed_Price__c> luminaryDiscountsByWOId = new Map<Id, Agreed_Price__c>();
        Map<Id, Set<Id>> cgIdSetsByProductId = new Map<Id, Set<Id>>();
        if(rootAssetIdsByAssetId == null){
            rootAssetIdsByAssetId = new Map<Id, Id>();
        }
        
        Id luminaryExceptionProductId = (Id)Configuration_Settings__c.getInstance().Distributor_Labor_Product_Id__c;
        
        //Fill maps with null values, so that we have the keys available
        for(Integer i = 0; i < recs.size(); i++){
            SObject rec = recs[i];
            if(sObjectType == TYPE_WO){
                Id prodId = prodIdsByListIndex.get(i);
                cgIdSetsByProductId.put(prodId, null);
                if(prodId != luminaryExceptionProductId){
                	luminaryDiscountsByWOId.put((Id)rec.get('Id'), null);
                }
            } else if(sObjectType == TYPE_WOLI || sObjectType == TYPE_PRODUCT_CONSUMED){
                Id prodId = prodIdsByListIndex.get(i);
                cgIdSetsByProductId.put(prodId, null);
                assetIdsByWOId.put((Id)rec.get('WorkOrderId'), null);
                if(prodId != luminaryExceptionProductId){
                	luminaryDiscountsByWOId.put((Id)rec.get('WorkOrderId'), null);
                }
            } else if(sObjectType == TYPE_PRODUCT_REQUIRED){
                Id prodId = (Id)rec.get('Product2Id');
                cgIdSetsByProductId.put(prodId, null);
                assetIdsByWOId.put((Id)rec.get('ParentRecordId'), null);
                if(prodId != luminaryExceptionProductId){
                	luminaryDiscountsByWOId.put((Id)rec.get('ParentRecordId'), null);
                }
            }
        }
        
        //Query for luminary discounts
        for(WorkOrder wo : [
            SELECT Id
                  ,Luminary_Discount_Agreed_Price__r.Id
                  ,Luminary_Discount_Agreed_Price__r.Discount__c
              FROM WorkOrder
             WHERE Id IN :luminaryDiscountsByWOId.keySet()
        ]){
            luminaryDiscountsByWOId.put(wo.Id, wo.Luminary_Discount_Agreed_Price__r);
        	System.debug('***[0] ' + wo.Luminary_Discount_Agreed_Price__r);
        }
        
        List<Entitlement> ents;
        
        if(sObjectType != TYPE_WO){
            //Map parent work order records by Id
            for(WorkOrder wo : [
                SELECT Id,
                       Asset.RootAssetId
                  FROM WorkOrder
                WHERE Id IN :assetIdsByWOId.keySet()
                  AND Asset.RootAssetId != null
            ]){
                assetIdsByWOId.put(wo.Id, wo.Asset.RootAssetId);
            }
        
            //Query for coverage_group_product__c records and map by product Id
            Set<Id> allCGIds = new Set<Id>();
            for(Coverage_Group_Product__c cgp : [
                SELECT Id
                      ,Product__c
                      ,Coverage_Group_Name__c
                  FROM Coverage_Group_Product__c
                 WHERE Product__c IN :cgIdSetsByProductId.keySet()
            ]){
                Set<Id> cgIds = cgIdSetsByProductId.get(cgp.Product__c);
                if(cgIds == null){
                    cgIds = new Set<Id>();
                }
                cgIds.add(cgp.Coverage_Group_Name__c);
                cgIdSetsByProductId.put(cgp.Product__c, cgIds);
                
                allCGIds.add(cgp.Coverage_Group_Name__c);
            }
        
            //Query for entitlements
            ents = [
                SELECT Id
                      ,Discount__c
                      ,Max_Covered_Amount__c
                      ,AssetId
                      ,Asset.RootAssetId
                      ,Coverage_Group__c
                  FROM Entitlement
                 WHERE Coverage_Group__c IN :allCGIds
                   AND (Asset.RootAssetId IN :assetIdsByWOId.values() OR Asset.RootAssetId IN :rootAssetIdsByAssetId.values())
                   AND RecordTypeId = :GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_Discount')
                   AND StartDate <= :Date.today()
                   AND (EndDate = null OR EndDate >= :Date.today())
            ];
        } else {
            //Query for entitlements
            ents = [
                SELECT Id
                      ,Discount__c
                      ,Max_Covered_Amount__c
                      ,AssetId
                      ,Asset.RootAssetId
                      ,Coverage_Group__c
                  FROM Entitlement
                 WHERE (Asset.RootAssetId IN :assetIdsByWOId.values() OR Asset.RootAssetId IN :rootAssetIdsByAssetId.values())
                   AND RecordTypeId = :GlobalUtility.getRecordTypeId('Entitlement', 'B_SH_SLA')
                   AND StartDate <= :Date.today()
                   AND (EndDate = null OR EndDate >= :Date.today())
                   AND SlaProcess.SObjectType = 'WorkOrder'
            ];
        }
            
        //Map entitlements by key (coverage group Id | root asset Id)
        Map<String, List<Entitlement>> entsByKey = new Map<String, List<Entitlement>>();
        for(Entitlement ent : ents){
            String key;
            if(sObjectType == TYPE_WO){
                key = ent.Asset.RootAssetId;
            } else {
                key = ent.Coverage_Group__c + '|' + ent.Asset.RootAssetId;
            }
            List<Entitlement> keyEnts = entsByKey.get(key);
            if(keyEnts == null){
                keyEnts = new List<Entitlement>();
            }
            keyEnts.add(ent);
            entsByKey.put(key, keyEnts);
        }
        
        //Match entitlement to each record
        for(Integer i = 0; i < recs.size(); i++){
            SObject rec = recs[i];
            Set<String> matchKeys = new Set<String>();
            Id prodId;
            Double listPrice;
            if(sObjectType == TYPE_WO){
                //Used when records are WorkOrders
                prodId = prodIdsByListIndex.get(i);
            } else if(sObjectType == TYPE_WOLI){
                //Used when records are WOLIs
                listPrice = Double.valueOf(WorkOrderLineItemTriggerActions.newListPricesByListIndex.get(i));
                prodId = prodIdsByListIndex.get(i);
        		System.debug('***[1] ' + listPrice);
        		System.debug('***[2] ' + prodId);
                if(listPrice == null){
                	continue;
                }
            } else if(sObjectType == TYPE_PRODUCT_CONSUMED){
                //Used when records are ProductConsumeds
                listPrice = (Double)rec.get('UnitPrice');
                prodId = prodIdsByListIndex.get(i);
                if(listPrice == null){
                	continue;
                }
            } else if(sObjectType == TYPE_PRODUCT_REQUIRED){
                //Used when records are ProductRequireds
                listPrice = (Double)rec.get('List_Price__c');
                prodId = (Id)rec.get('Product2Id');
                if(listPrice == null){
                	continue;
                }
            }
            
            if(sObjectType == TYPE_WO){
                matchKeys.add(rootAssetIdsByAssetId.get((Id)rec.get('AssetId')));
            } else if(cgIdSetsByProductId.get(prodId) != null){
                for(Id cgId : cgIdSetsByProductId.get(prodId)){
                    if(sObjectType == TYPE_WOLI || sObjectType == TYPE_PRODUCT_CONSUMED){
                        matchKeys.add(cgId + '|' + assetIdsByWOId.get((Id)rec.get('WorkOrderId')));
                    } else if(sObjectType == TYPE_PRODUCT_REQUIRED){
                        matchKeys.add(cgId + '|' + assetIdsByWOId.get((Id)rec.get('ParentRecordId')));
                    }
                }
            }
            
            //Loop through entitlements with matching keys and find the one with best pricing
            Entitlement bestMatchEnt;
            if(sObjectType == TYPE_WO){
                //Used when records are WorkOrders
                for(String key : matchKeys){
                    if(entsByKey.get(key) != null){
                        for(Entitlement ent : entsByKey.get(key)){
                            bestMatchEnt = ent;
                        }
                    }
                }
            } else if(sObjectType == TYPE_WOLI || sObjectType == TYPE_PRODUCT_CONSUMED){
                //Used when records are WOLIs or ProductConsumeds
                Double lowestPrice;
                for(String key : matchKeys) {
                    if(entsByKey.get(key) != null){
                        for(Entitlement ent : entsByKey.get(key)){
                            Double currentPrice = 0;
                            if(ent.Discount__c > 0){
                                currentPrice = listPrice * (1 - (ent.Discount__c / 100));
                            } else if(ent.Max_Covered_Amount__c > 0){
                                currentPrice = listPrice - ent.Max_Covered_Amount__c;
                            }
                            
                            if(lowestPrice == null || currentPrice < lowestPrice){
                                lowestPrice = currentPrice;
                                bestMatchEnt = ent;
                            }
                        }
                    }
                }
        		System.debug('***[3] ' + lowestPrice);
        		System.debug('***[4] ' + bestMatchEnt);
            } else if(sObjectType == TYPE_PRODUCT_REQUIRED){
                //Used when incoming records are ProductRequireds
                Double lowestPrice;
                for(String key : matchKeys) {
                    if(entsByKey.get(key) != null){
                        for(Entitlement ent : entsByKey.get(key)){
                            if(listPrice != null){
                                Double currentPrice = 0;
                                if(ent.Discount__c > 0){
                                    currentPrice = listPrice * (1 - (ent.Discount__c / 100));
                                } else if(ent.Max_Covered_Amount__c > 0){
                                    currentPrice = listPrice - ent.Max_Covered_Amount__c;
                                }
                                
                                if(lowestPrice == null || currentPrice < lowestPrice){
                                    lowestPrice = currentPrice;
                                    bestMatchEnt = ent;
                                }
                            }
                        }
                    }
                }
            }
            
            //Get agreed price, if one exists
            Id woId;
            if(sObjectType == TYPE_WO){
                woId = (Id)rec.get('Id');
            } else if(sObjectType == TYPE_WOLI || sObjectType == TYPE_PRODUCT_CONSUMED){
                woId = (Id)rec.get('WorkOrderId');
            } else if(sObjectType == TYPE_PRODUCT_REQUIRED){
                woId = (Id)rec.get('ParentRecordId');
            }
            Agreed_Price__c agreedPrice = luminaryDiscountsByWOId.get(woId);
        		System.debug('***[5] ' + agreedPrice);
            
            //Test to see if luminary discount would give better price
            Double luminaryPrice = listPrice;
        		System.debug('***[6] ' + luminaryPrice);
			if(agreedPrice != null && agreedPrice.Discount__c != null && listPrice != null){
                luminaryPrice = listPrice * (1 - (agreedPrice.Discount__c / 100));
        		System.debug('***[7] ' + luminaryPrice);
        		System.debug('***[8] ' + agreedPrice.Discount__c);
            }
    		System.debug('***[9] ' + luminaryPrice);
            
            //Test entitlement price
            Double entitlementPrice = listPrice;
            if(bestMatchEnt != null){
                if(sObjectType == TYPE_WO){
                    rec.put('EntitlementId', bestMatchEnt.Id);
                } else {
                    rec.put('Entitlement__c', bestMatchEnt.Id);
                    if(sObjectType == TYPE_WOLI){
                        rec.put('AssetId', bestMatchEnt.AssetId);
                    }
                    if(bestMatchEnt.Discount__c > 0){
                        entitlementPrice = listPrice * (1 - (bestMatchEnt.Discount__c / 100));
                    } else if(bestMatchEnt.Max_Covered_Amount__c > 0){
                        entitlementPrice = listPrice - bestMatchEnt.Max_Covered_Amount__c;
                    }
                }
            }
            
            //Test for lowest price
            Double bestPrice = listPrice;
            if(luminaryPrice <= entitlementPrice){
                bestPrice = luminaryPrice;
    			System.debug('***[10a] ' + bestPrice);
            } else if(entitlementPrice < luminaryPrice){
                bestPrice = entitlementPrice;
    			System.debug('***[10b] ' + bestPrice);
            }
            
            //Set unit price
            if(sObjectType == TYPE_WOLI || sObjectType == TYPE_PRODUCT_CONSUMED){
                //Used when records are WOLIs or ProductConsumeds
                rec.put('UnitPrice', bestPrice);
    			System.debug('***[11] ' + bestPrice);
            } else if(sObjectType == TYPE_PRODUCT_REQUIRED){
                //Used when records are ProductRequireds
                rec.put('Unit_Price__c', bestPrice);
            }
                
        }
    }

}