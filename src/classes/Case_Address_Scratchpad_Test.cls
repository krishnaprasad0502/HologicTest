@isTest
private class Case_Address_Scratchpad_Test {

	private static testMethod void checkData() {
       Case cas = new Case();
       cas.Priority = 'High';
       insert cas;
        
       Case_Address_Scratchpad.getAddresses(cas.Id);
	}

}