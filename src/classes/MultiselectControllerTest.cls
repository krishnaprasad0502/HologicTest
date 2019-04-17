/*------------------------------------------------------------
Author:         Mani Sundaresan
Description:    Test class to validate MultiselectController class
                Tests Excecuted:
                
                testMultiselectController - verify that values are populated on both the columns
History:
<Date>          <Authors Name>      <Brief Description of Change>
05/04/2017      Mani Sundaresan       Initial Creation (US-2248)
------------------------------------------------------------*/
@isTest
private class MultiselectControllerTest {
    static testMethod void testMultiselectController() {
        MultiselectController c = new MultiselectController();
        
        c.leftOptions = new List<SelectOption>();
        c.rightOptions = new List<SelectOption>();

        c.leftOptionsHidden = 'A&a&b&b&C&c';
        c.rightOptionsHidden = '';
        
        System.assertEquals(c.leftOptions.size(), 3);
        System.assertEquals(c.rightOptions.size(), 0);
    }
}