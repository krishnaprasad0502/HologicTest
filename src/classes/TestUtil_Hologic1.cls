public with sharing class TestUtil_Hologic1 {

public static List<Account> getAccounts(integer numberOfAccounts, integer loopVariable) {

List <Account> newAccountsList = new List<Account>();

String letterStringAccount = 'abcdefghijklmnopgrstuvwxyz';

for(integer loopVariableAccount = loopVariable; loopVariableAccount < numberOfAccounts; loopVariableAccount++){

Account Acc1= new Account(
Name='Customer' + loopVariableAccount,
Facility_Type__c = 'Oncology Treatment',
BillingStreet = letterStringAccount.substring(loopVariableAccount, loopVariableAccount+3),
BillingCity = 'Austin',
BillingState = 'Texas',
BillingPostalCode = letterStringAccount.substring(loopVariableAccount, loopVariableAccount+3),
BillingCountry = 'United States',
Credit_Hold__c=False);

newAccountsList.add(Acc1); 

}

return newAccountsList;

}

public static List<Contact> getContacts(List <Account> accountList1, integer loopVariableContact ) {

List <Contact> newContactList = new List<Contact>();


String phoneNumberContact = '';
String letterStringContact = 'abcdefghijklmnopgrstuvwxyz';

for(Account Acc1:accountList1) {

 for(integer digitContact=9;digitContact >= 0; digitContact--){

phoneNumberContact = phoneNumberContact + string.valueof(digitContact);

 }


Contact Con1 = new Contact(
FirstName = 'First' + letterStringContact.substring(loopVariableContact, loopVariableContact+1),
LastName = 'LastName' + letterStringContact.substring(loopVariableContact, loopVariableContact+1),
AccountId = Acc1.Id,
Email = 'First.LastName' + letterStringContact.substring(loopVariableContact, loopVariableContact+1) + '@appsassociates.com.uat',
Phone = phoneNumberContact); 

newContactList.add(Con1);

loopVariableContact += 1;
phoneNumberContact = '';

}

return newContactList;

}


public static List<Product2> getProducts(integer numberOfProducts) {

List <Product2> newProductList = new List<Product2>();
String letterStringProduct = 'abcdefghijklmnopgrstuvwxyz';

for(integer loopVariableProduct=0; loopVariableProduct < numberOfProducts; loopVariableProduct ++){

Product2 prod1 = new Product2(
ProductCode='UTProd00' + loopVariableProduct,
Name='UTProd00' + loopVariableProduct,
Family='Family ' + letterStringProduct.substring(loopVariableProduct, loopVariableProduct+2),
Description='Description ' + letterStringProduct.substring(loopVariableProduct, loopVariableProduct+2),
IsActive=true);

newProductList.add(prod1);

}

return newProductList;

}

public static List<User> getUsers(integer numberOfUsers) {

List <User> newUserList = new List<User>();
List <Profile> profileList = new List<Profile>([Select Id FROM Profile WHERE Name like '%System Administrator%' Limit 1]);
String Profile = profileList[0].Id;
String TimeZoneSidKeyString = 'America/New_York';
String LocaleSidKeyString = 'en_US';
String EmailEncodingKeyString = 'ISO-8859-1';
String LanguageLocaleKeyString = 'en_US';

String letterStringUsers = 'abcdefghijklmnopgrstuvwxyz';

for(integer loopVariableUsers = 0; loopVariableUsers < numberOfUsers; loopVariableUsers++){

User usr1 = new User(
ProfileId = Profile, 
FirstName='Sales' + letterStringUsers.substring(loopVariableUsers,loopVariableUsers+1), 
LastName = 'Person' + letterStringUsers.substring(loopVariableUsers,loopVariableUsers+1),
Alias = 'alias' + letterStringUsers.substring(loopVariableUsers,loopVariableUsers+1),
TimeZoneSidKey = TimeZoneSidKeyString,
LocaleSidKey = LocaleSidKeyString,
EmailEncodingKey = EmailEncodingKeyString,
LanguageLocaleKey = LanguageLocaleKeyString,
UserName = 'sales.person' + + letterStringUsers.substring(loopVariableUsers,loopVariableUsers+1)+ '@company.com.sandbox', 
Email = 'sales.person' + + letterStringUsers.substring(loopVariableUsers,loopVariableUsers+1)+ '@company.com.sandbox');

newUserList.add(usr1);

}

return newUserList;

}


}