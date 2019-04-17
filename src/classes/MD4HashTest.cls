/*------------------------------------------------------------
Author: Mani Sundaresan

Description: Test Class for MD4HashTest used for Salesforce NTLM Authentication

History:
<Date>          <Authors Name>      <Brief Description of Change>
07/17/2018      Mani Sundaresan      Initial Creation (US-0004314)
------------------------------------------------------------*/
@isTest
private class MD4HashTest {

    /*
     * Test the digest method.
     */
    static testMethod void digestTest() {
        integer[] input = new integer[] { 97, 98, 99 };
        integer[] expectedOutput = new integer[] { 164, 72, 1, 122, 175, 33, 216, 82, 95, 193, 10, 232, 122, 166, 114, 157 };
        MD4Hash md4 = new MD4Hash();
        integer[] result = md4.digest(input);
        System.assertEquals(expectedOutput.size(), result.size(), 'The result size is not the same as the expected size.');
        for (integer i = 0; i < result.size(); i++) {
            System.assertEquals(expectedOutput[0], result[0], 'The byte in the following position isn\'t what was expected: ' + String.valueOf(i));
        }
    }
    
}