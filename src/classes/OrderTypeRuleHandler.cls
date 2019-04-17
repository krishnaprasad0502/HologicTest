/*------------------------------------------------------------
Author:         Greg Hardin
Company:        AppsAssociates 
Description:    To get the list of orderitem records through LineType .
Class:          OrderTypeRuleHandler
Test Class:     OrderItemProductSearch_Test

History:
<Date>          <Authors Name>          <Brief Description of Change>
04/17/2017       Greg Hardin            Initial Creation(US-0002725)
------------------------------------------------------------*/
public with sharing class OrderTypeRuleHandler {
    private final String STRING_COMMA = ',';
    private final String STRING_SPACE = ' ';
    private final String STRING_BLANK = '';

    private Map<String,Order_Type_Rule__mdt> orderTypeToRule_Map;
    private List<String> itemLineType_List;
/*------------------------------------------------------------
Author:       Greg Hardin
Company:      AppsAssociates 
Description:  In this constructor,the soql query for ordertypeRule.
Inputs:       N/A
Returns:      N/A   
History:
<Date>          <Authors Name>      <Brief Description of Change>
04/17/2017      Greg Hardin        Initial Creation(US-0002725)
------------------------------------------------------------*/
    public OrderTypeRuleHandler() {
        //OrderTypeRuleHandler CONTSTRUCTOR START
        orderTypeToRule_Map = new Map<String,Order_Type_Rule__mdt>();
        itemLineType_List = new List<String>();
        System.debug('OrderTypeRuleQuery: ' + OrderTypeRuleQuery());
        for(Order_Type_Rule__mdt typeRule : Database.query(OrderTypeRuleQuery())) {
            orderTypeToRule_Map.put(typeRule.Order_Type__c,typeRule);
        }
        //OrderTypeRuleHandler CONTSTRUCTOR END 
    }
    public Boolean OrderTypeHasRule(String orderType) {

        return orderTypeToRule_Map.containsKey(orderType);
    }
    
/*------------------------------------------------------------
Author:       Greg Hardin
Company:      AppsAssociates 
Description:  In this method,we are retrieving the list of orderitems .
Inputs:       Order
Returns:      Order Item list
History:
<Date>          <Authors Name>      <Brief Description of Change>
04/17/2017      Greg Hardin        Initial Creation(US-0002725)
------------------------------------------------------------*/
    public List<OrderItem> getOrderItems(Order parentOrder) {
        //getOrderItems START
        List<OrderItem> orderItem_List = new List<OrderItem>();
        if(String.isNotBlank(parentOrder.Type) && orderTypeToRule_Map.containsKey(parentOrder.Type)) {
            Order_Type_Rule__mdt typeRule = orderTypeToRule_Map.get(parentOrder.Type);
            if(typeRule.Order_Item_Types__r != NULL && !typeRule.Order_Item_Types__r.isEmpty()) {
                for(Order_Item_Type__mdt itemTypeRule : typeRule.Order_Item_Types__r) {
                    for(Integer i = 0; i < itemTypeRule.Line_Count__c; i++) {
                        OrderItem item = getBaseOrderItem();
                            item.OrderId = parentOrder.Id;
                            item.Line_Type__c = itemTypeRule.Line_Type__c;
                            if(String.isNotBlank(item.Line_Type__c)) {
                                System.debug('item.Line_Type__c: ' + item.Line_Type__c);
                            } else {
                                System.debug('item.Line_Type__c IS BLANK');
                            }
                            itemLineType_List.add(itemTypeRule.Line_Type__c);
                            if(itemTypeRule.Default_Quantity__c != NULL) {
                                item.Quantity = itemTypeRule.Default_Quantity__c;
                            }
                            if(itemTypeRule.Default_Unit_Price__c != NULL) {
                                item.UnitPrice = itemTypeRule.Default_Unit_Price__c;
                            }
                            orderItem_List.add(item);
                    }
                }
            }
        }
       //getOrderItems END
       return orderItem_List;
    }
    // It will return the orderitemvalue
    @TestVisible
    private OrderItem getBaseOrderItem() {
        return new OrderItem();
    }
    //Preparing the soql query on ordertyperule in the string
    @TestVisible
    private String OrderTypeRuleQuery() {
        List<String> typeRule_List = new List<String>();
            typeRule_List.add('SELECT');
            typeRule_List.add(OrderTypeRuleFields());
            typeRule_List.add('FROM');
            typeRule_List.add('Order_Type_Rule__mdt');
            typeRule_List.add(OrderTypeRuleFilter());
        return String.join(typeRule_List,STRING_SPACE);
    }
    //adding all the fields on ordertyperule in the string
    @TestVisible
    private String OrderTypeRuleFields() {
        List<String> typeRuleFields_List = new List<String>();            
            typeRuleFields_List.add('Id');
            typeRuleFields_List.add('MasterLabel');
            typeRuleFields_List.add('Label');
            typeRuleFields_List.add('DeveloperName');           
            typeRuleFields_List.add('QualifiedApiName');
            typeRuleFields_List.add('isActive__c');
            typeRuleFields_List.add('Order_Type__c');
            typeRuleFields_List.add(OrderLineChildQuery());
        return String.join(typeRuleFields_List,STRING_COMMA);        
    }
    //adding the filter criteria in list of string on ordertyperule in the string
    @TestVisible
    private String OrderTypeRuleFilter() {
        List<String> typeRuleFilter_List = new List<String>();
            typeRuleFilter_List.add('WHERE');
            typeRuleFilter_List.add('isActive__c');
            typeRuleFilter_List.add('=');
            typeRuleFilter_List.add('TRUE');
        return String.join(typeRuleFilter_List,STRING_SPACE);        
    }
    //Preparing the soql query on orderitemtypes in the string
    @TestVisible
    private String OrderLineChildQuery() {
        List<String> orderLineChild_List = new List<String>();
            orderLineChild_List.add('SELECT');
            orderLineChild_List.add(OrderLineFields());
            orderLineChild_List.add('FROM');
            orderLineChild_List.add('Order_Item_Types__r');
        return '('+ String.join(orderLineChild_List,STRING_SPACE) + ')';        
    }
    //adding all the fields on orderitemtypes in the string
    @TestVisible
    private String OrderLineFields() {
        List<String> orderLineFields_List = new List<String>();            
            orderLineFields_List.add('Id');
            orderLineFields_List.add('MasterLabel');
            orderLineFields_List.add('Label');
            orderLineFields_List.add('DeveloperName');           
            orderLineFields_List.add('QualifiedApiName');
            orderLineFields_List.add('Default_Quantity__c');  
            orderLineFields_List.add('Default_Unit_Price__c');  
            orderLineFields_List.add('Line_Type__c');    
            orderLineFields_List.add('Line_Count__c');            
        return String.join(orderLineFields_List,STRING_COMMA); 
    }
}