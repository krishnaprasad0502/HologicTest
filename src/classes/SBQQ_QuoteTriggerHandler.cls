/*******************************************************************
// TriggerHandler Class - SBQQ_QuoteTriggerHandler
//
// 6/1/2016    Buan Consulting    
********************************************************************/
public with sharing class SBQQ_QuoteTriggerHandler {
  private boolean m_isExecuting = false;  
  private integer BatchSize = 0;
  public static Boolean isFirstRun = true;
    
  //Constructor
  public SBQQ_QuoteTriggerHandler(boolean isExecuting, integer size){
    m_isExecuting = isExecuting;
    BatchSize = size;

  }

  //On before insert trigger method
  public void OnBeforeInsert (List<SBQQ__Quote__c> newList) { 
 // Removed defaulting of primary contract       
 //       DefaultPrimaryContract (newList, null);
        createContractMapStringForSpecificContract(newList,null);
        /*
         * Commented out on 10/2/2016 to disable contract precedence. To allow contract precedence, comment out call to 
         * createContractMapStringForSpecificContract above, call the method below and uncomment createContractMapString. 
         * 
        createContractMapString(newList,null);
        */
  } 

  //On before update trigger method
  public void OnBeforeUpdate (Map<ID, SBQQ__Quote__c> oldMap, List<SBQQ__Quote__c> newList) { 
 // Removed defaulting of primary contract       
  //      DefaultPrimaryContract (newList, oldMap);
        //Commented out by Tayo Chestnut to test if Quote can be Saved without CPU Timeouts
        CleanQuoteForOrder.SetOperatingUnit(newList,oldMap);
        //Adds logic to create Order
        CleanQuoteForOrder.CreateOrder(newList, oldMap);
        createContractMapStringForSpecificContract(newList,oldMap);
        /*
         * Commented out on 10/2/2016 to disable contract precedence. To allow contract precedence, comment out call to 
         * createContractMapStringForSpecificContract above, call the method below and uncomment createContractMapString. 
         * 
        createContractMapString(newList,oldMap);
        */
  }
    
  /*
   * createContractMapStringForSpecificContract creates the agreed price maps for only the Customer Eligible contract specified on the quote
   * any other contracts associated with the account and parent account are ignored
   * 
   */
    private void createContractMapStringForSpecificContract(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap) {
      if(newList.size()==1) {
          if(newList[0].Use_List_Price__c){
             newList[0].Price_Agreement__c=null;
             newList[0].Customer_Eligible_Contract__c=null;
             newList[0].Contract_Price_Map__c='';
             newList[0].Contract_Price_Map_Discounts__c='';
             newList[0].Contract_AgreedPrice_Map__c='';
             return;
          }
          SBQQ__Quote__c quotetoUpdate=newList.get(0);
          String quoteId=quotetoUpdate.id;
          String selected_cec_id = quotetoUpdate.Customer_Eligible_Contract__c;
          String quoteType=quotetoUpdate.Quote_Type__c;
          String contractId=quotetoUpdate.Price_Agreement__c;
          if(contractID==null && selected_cec_id==null)
              return;
          selected_cec_id=(selected_cec_id==NULL) ? '' : selected_cec_id;
          contractId=(contractId==NULL) ? '' : contractId;
          quoteType=(quoteType==NULL) ? '' : quoteType;
          if(contractId == '') {
              contractId=[select Contract__c from Customer_Eligible_Contract__c where Id=:selected_cec_id].Contract__c;
          }
          Map<String,Decimal> contractOrderMap=new Map<String,Decimal>();
          Map<Decimal,List<Agreed_Price__c>> order_to_Price=new Map<Decimal,List<Agreed_Price__c>>();
          Map<String,Agreed_Price__c> finalMapping=new Map<String,Agreed_Price__c>();
          Map<Decimal,Customer_Eligible_Contract__c> prec_to_cec_final=new Map<Decimal,Customer_Eligible_Contract__c>();
          Map<String,Decimal> contract_to_Tier=new Map<String,Decimal>();
          String accid = quoteToUpdate.SBQQ__Account__c;

          String price_string='';
          String discount_string='';
          String id_string='';
          for(Agreed_Price__c price:[Select Id,Contract__c, PAProductKey__c,Price__c,Discount__c,  Tier__c, Active__c, Product__c from Agreed_Price__c where Active__c=true and Contract__c = :contractId]){
            //Set Contract_Price_Map__c, Contract_Price_Map_Discounts__c Map String

            Decimal origPrice=(price.Price__c==NULL) ? 0 : price.Price__c;
            Decimal discount=(price.Discount__c==NULL) ? 0 : price.Discount__c;

            price_string=price.PAProductKey__c + ';' + String.valueOf(origPrice) + ',' + price_string;
            discount_string=price.PAProductKey__c + ';' + String.valueOf(discount)  + ',' + discount_string;
            id_string=price.PAProductKey__c+';'+price.Id+ ',' +id_string;
          }

          quotetoUpdate.Contract_Price_Map__c=price_string.left(price_string.length()-1).trim();
          quotetoUpdate.Contract_Price_Map_Discounts__c=discount_string.left(discount_string.length()-1).trim();
          quotetoUpdate.Contract_AgreedPrice_Map__c=id_string.left(id_string.length()-1).trim();

        }
        
    }
  /* 
   * createContractMap string builds the agreed price map based on all of the Customer Eligible contracts that are assigned
   * to the Quote Account or the Quote Account's parent account if one exists.
   * 
   * Uncomment below to renable
 
  private void createContractMapString(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap){
      if(newList.size()==1) {
          if(newList[0].Use_List_Price__c){
             newList[0].Price_Agreement__c=null;
             newList[0].Customer_Eligible_Contract__c=null;
             return;
          }
          SBQQ__Quote__c quotetoUpdate=newList.get(0);
          String quoteId=quotetoUpdate.id;
          String selected_cec_id = quotetoUpdate.Customer_Eligible_Contract__c;
          String quoteType=quotetoUpdate.Quote_Type__c;
          String contractId=quotetoUpdate.Price_Agreement__c;

          selected_cec_id=(selected_cec_id==NULL) ? '' : selected_cec_id;
          contractId=(contractId==NULL) ? '' : contractId;
          quoteType=(quoteType==NULL) ? '' : quoteType;

          Map<String,Decimal> contractOrderMap=new Map<String,Decimal>();
          Map<Decimal,List<Agreed_Price__c>> order_to_Price=new Map<Decimal,List<Agreed_Price__c>>();
          Map<String,Agreed_Price__c> finalMapping=new Map<String,Agreed_Price__c>();
          Map<Decimal,Customer_Eligible_Contract__c> prec_to_cec_final=new Map<Decimal,Customer_Eligible_Contract__c>();
          Map<String,Decimal> contract_to_Tier=new Map<String,Decimal>();
          String accid = quoteToUpdate.SBQQ__Account__c;
          try {
              Account acc = [select ParentId from Account where id=:accid and ParentID!=null];
              accid = acc.parentid;
           } catch (exception e) {
           }
           
          //SBQQ__Quote__c quoteDetails=[Select SBQQ__Account__c, SBQQ__Opportunity2__r.Sales_Opp_Type__c, SBQQ__Opportunity2__r.SBQQ__AmendedContract__c, SBQQ__Opportunity2__r.SBQQ__RenewedContract__c from SBQQ__Quote__c where id=:quoteId];

          Customer_Eligible_Contract__c final_cec;
          List<Customer_Eligible_Contract__c> cecList=new List<Customer_Eligible_Contract__c>([Select Tier__c, Contract__c,Contract__r.Active_Contract__c, Customer_Account__c, Precedence_Value__c from Customer_Eligible_Contract__c where Customer_Account__c=:accid and Agreement_Active__c=true and Selected__c=true Order by Precedence_Value__c ASC ]);
          Boolean dupeFound=false;

          
          
          //if(quoteDetails.SBQQ__Opportunity2__r.SBQQ__AmendedContract__c==null && quoteDetails.SBQQ__Opportunity2__r.SBQQ__RenewedContract__c==null){


            for(Customer_Eligible_Contract__c cec:cecList){
                  //if(cec.Contract__r.Active_Contract__c==1){
                    //contractOrderMap.put(cec.Contract__c,cec.Precedence_Value__c);
                  //}

                  if(prec_to_cec_final.isEmpty()){
                            prec_to_cec_final.put(cec.Precedence_Value__c, cec);
                          }else{
                            if(prec_to_cec_final.containsKey(cec.Precedence_Value__c)){
                              prec_to_cec_final=new Map<Decimal,Customer_Eligible_Contract__c>();
                              dupeFound=true;
                            break;
                            }
                             prec_to_cec_final.put(cec.Precedence_Value__c, cec);
                         } 
                  
                }

system.debug('dupeFound '+dupeFound+ prec_to_cec_final);
                if(dupeFound && selected_cec_id!=''){
                  try{
                    final_cec=[Select Contract__c,Contract__r.Active_Contract__c, Tier__c, Customer_Account__c, Precedence_Value__c from Customer_Eligible_Contract__c where id=:selected_cec_id and Agreement_Active__c=true and Selected__c=true Order by Precedence_Value__c ASC ];
                    prec_to_cec_final.put(final_cec.Precedence_Value__c,final_cec);
                  }catch(QueryException q){
                    system.debug(q.getMessage());
                  }
                }else if((dupeFound && contractId!='') || (cecList.isEmpty() && contractId!='')){
                  Customer_Eligible_Contract__c cecTemp=new Customer_Eligible_Contract__c(Contract__c=contractId, Tier__c=null);
                  prec_to_cec_final.put(1,cecTemp);

                }

                system.debug(prec_to_cec_final);

                if(!prec_to_cec_final.isEmpty()){
                  for(Decimal d:prec_to_cec_final.keySet()){
                    Customer_Eligible_Contract__c cec=prec_to_cec_final.get(d);
                    contractOrderMap.put(cec.Contract__c,d);
                    contract_to_Tier.put(cec.Contract__c,cec.Tier__c);

                  }

                  for(Agreed_Price__c price:[Select Id,Contract__c, PAProductKey__c,Price__c,Discount__c,  Tier__c, Active__c, Product__c from Agreed_Price__c where Active__c=true and Contract__c in:contractOrderMap.keyset()]){
                    Decimal contractPrecedence=contractOrderMap.get(price.Contract__c);
                    List<Agreed_Price__c> agree_list=new List<Agreed_Price__c>();
                    //Check for Tiers Happens Here based on CEC Record
                    Decimal myTier=contract_to_Tier.get(price.Contract__c);
                    system.debug(myTier);
                    system.debug(price.Tier__c);

                    if(price.Tier__c==myTier){
                      if(order_to_Price.containsKey(contractPrecedence)){
                        agree_list=order_to_Price.get(contractPrecedence);
                        agree_list.add(price);
                        order_to_Price.put(contractPrecedence,agree_list);
                      }else{
                        agree_list.add(price);
                        order_to_Price.put(contractPrecedence,agree_list);
                      }

                    }
                    
                  }
                }

                system.debug(order_to_Price);

                  for(Decimal d:order_to_Price.keySet()){
                    for(Agreed_Price__c ap:order_to_Price.get(d)){
                        if(!finalMapping.containsKey(ap.PAProductKey__c)){
                          finalMapping.put(ap.PAProductKey__c, ap);
                        }
                    }
                  }

                  //Set Contract_Price_Map__c, Contract_Price_Map_Discounts__c Map String
                  String price_string='';
                  String discount_string='';
                  String id_string='';

                  for(String s:finalMapping.keySet()){
                    Agreed_Price__c ap=finalMapping.get(s);
                    Decimal origPrice=(ap.Price__c==NULL) ? 0 : ap.Price__c;
                    Decimal discount=(ap.Discount__c==NULL) ? 0 : ap.Discount__c;

                    price_string=s + ';' + String.valueOf(origPrice) + ',' + price_string;
                    discount_string=s + ';' + String.valueOf(discount)  + ',' + discount_string;
                    id_string=s+';'+ap.Id+ ',' +id_string;
                  }
                  
                  system.debug(price_string);

                  quotetoUpdate.Contract_Price_Map__c=price_string.left(price_string.length()-1).trim();
                  quotetoUpdate.Contract_Price_Map_Discounts__c=discount_string.left(discount_string.length()-1).trim();
                  quotetoUpdate.Contract_AgreedPrice_Map__c=id_string.left(id_string.length()-1).trim();
              }



      //}

  }
   */
    
 //Commented by Marc Goldstein since not able to deploy since missing field Contract_Auto_Assigned__c
  //select the highest priority contract associated to account (lowest Precendence value) and set this as the Primary Customer Eligible Contract
 /*
  * Commented out based on request to not default contracts and have reps select
  *
  private void DefaultPrimaryContract (List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap) {

        Set<String> accList=new Set<String>();
        Map<String,List<Customer_Eligible_Contract__c>> acc_cec_map=new Map<String,List<Customer_Eligible_Contract__c>>();
        Map<String,Customer_Eligible_Contract__c> acc_to_cec_final=new Map<String,Customer_Eligible_Contract__c>();

        Set<String> accIds=new Set<String>();
        for (SBQQ__Quote__c qte : newList) {
          if(qte.SBQQ__Account__c!=null){
            accIds.add(qte.SBQQ__Account__c);
          }
        }
        Map<Id,Account> acctParentMap = new Map<id,Account>([select Id,ParentId from Account where Id in :accIds and ParentId != null]);


        for (SBQQ__Quote__c qte : newList) {
          if(qte.SBQQ__Account__c!=null && !qte.Use_List_Price__c){
            if(acctParentMap.get(qte.SBQQ__Account__c) != null)
                accList.add(acctParentMap.get(qte.SBQQ__Account__c).parentid);
            else
                accList.add(qte.SBQQ__Account__c);
          }
        }


        for (Customer_Eligible_Contract__c d : [Select ID, Customer_Account__c, Contract__c, Precedence_Value__c, Active_Contract__c FROM Customer_Eligible_Contract__c  WHERE Customer_Account__c IN:accList and Active_Contract__c > 0 and Agreement_Active__c=true and Selected__c=true ORDER BY Precedence_Value__c ASC]) {                                 
            List<Customer_Eligible_Contract__c> temp_cec=new List<Customer_Eligible_Contract__c>();

            if(acc_cec_map.containsKey(d.Customer_Account__c)){
                temp_cec=acc_cec_map.get(d.Customer_Account__c);
                temp_cec.add(d);
                acc_cec_map.put(d.Customer_Account__c,temp_cec);
            }else{
                 temp_cec.add(d);
                 acc_cec_map.put(d.Customer_Account__c,temp_cec);
            }
        }

        for(string aid:acc_cec_map.keySet()){
            Customer_Eligible_Contract__c temp_cec;
            string accid = aid;
            Set<Decimal> prec_set=new Set<Decimal>();
            if(acctParentMap.get(aid) != null)
                accid = acctParentMap.get(aid).parentid;
            for(Customer_Eligible_Contract__c cec:acc_cec_map.get(accid)){
                if(prec_set.isEmpty()){
                  temp_cec=cec;
                  prec_set.add(cec.Precedence_Value__c);
                }else{
                  if(prec_set.contains(cec.Precedence_Value__c)){
                    temp_cec=null;
                    break;
                  }
                }             
            }

            acc_to_cec_final.put(accid, temp_cec);
        }

        for (SBQQ__Quote__c qte : newList) {
          if(qte.Use_List_Price__c)
            continue;
          if(qte.Customer_Eligible_Contract__c==NULL && qte.Price_Agreement__c==NULL){
            string accid = qte.SBQQ__Account__c;
            if(acctParentMap.get(accid) != null)
                accid = acctParentMap.get(accid).parentid;
              Customer_Eligible_Contract__c cec=acc_to_cec_final.get(accid);
              String cec_id;
              String con_id;
              if(cec==null){
                cec_id=null;
              }else{
                con_id=cec.Contract__c;
                cec_id=cec.id;
                qte.Contract_Auto_Assigned__c=true;
              }
              qte.Customer_Eligible_Contract__c=cec_id;
              qte.Price_Agreement__c=con_id;
              
          }
        }
        
  }
  */     
    
}