@IsTest
public class BoxEnterpriseTests {
	public static testmethod void testParseMember() {
        BoxApiConnection api = new BoxApiConnection('accesstoken');
		BoxEnterprise enterprise = new BoxEnterprise(api,'10543463');
		BoxEnterprise.Info enterpriseInfo = new BoxEnterprise.Info();
		enterpriseInfo.addValue('name', 'test enterprise');
		
		Test.startTest();
		enterpriseInfo.parseMember('name', 'test enterprise');
        Test.stopTest();

		System.assertEquals('test enterprise', enterpriseInfo.name);
     }
     
     public static testmethod void testGetEnterpriseEvents() {
    	String mockResponseBody = '{"chunk_size": 3,"next_stream_position": "28893355","entries": [{"source": null,"created_by": {"type": "user","id": "181216415","name": "sean rose","login": "sean+awesome@box.com"},"created_at": "2012-12-12T10:53:43-08:00","event_id": "28893270","event_type": "ADD_LOGIN_ACTIVITY_DEVICE","ip_address": "67.218.117.3","type": "event","session_id": null},{"source": null,"created_by": {"type": "user","id": "181216415","name": "sean rose","login": "sean+awesome@box.com"},"created_at": "2012-12-12T10:53:43-08:00","event_id": "28893272","event_type": "LOGIN","ip_address": "67.218.117.3","type": "event","session_id": null},{"source": {"type": "folder","id": "387630341","sequence_id": "0","name": "A BNE"},"created_by": {"type": "user","id": "181216415","name": "sean rose","login": "sean+awesome@box.com"},"created_at": "2012-12-12T10:53:43-08:00","event_id": "28893354","event_type": "UPLOAD","ip_address": "67.218.117.3","type": "event","session_id": null}]}';
    	Test.setMock(HttpCalloutMock.class, new BoxTestMockCallout(mockResponseBody, 'OK', 200));
    	
    	BoxApiConnection api = new BoxApiConnection('accesstoken');
    	
    	BoxEnterprise enterprise = new BoxEnterprise(api,'10543463');        
		BoxEnterprise.Info enterpriseInfo = new BoxEnterprise.Info();
        enterpriseInfo.addValue('name', 'Tv Enterprise');
    		
    	Test.startTest();
    	list<BoxEvent.Info> events = enterprise.getEnterpriseEvents();
    	Test.stopTest();
    	
		System.assertEquals(3, events.size());
         
		/*Added by Nikhil - Hexaware*/
        String mockResponseBody1 = '{"type":"folder","id":"11446498","sequence_id":"1","etag":"1","name":"New Folder Name!","created_at":"2012-12-12T10:53:43-08:00","modified_at":"2012-12-12T11:15:04-08:00","description":"Some pictures I took","size":629644,"path_collection":{"total_count":1,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"}]},"created_by":{"type":"user","id":"17738362","name":"sean rose","login":"sean@box.com"},"modified_by":{"type":"user","id":"17738362","name":"sean rose","login":"sean@box.com"},"owned_by":{"type":"user","id":"17738362","name":"sean rose","login":"sean@box.com"},"shared_link":{"url":"https://www.box.com/s/vspke7y05sb214wjokpk","download_url":null,"vanity_url":null,"is_password_enabled":false,"unshared_at":null,"download_count":0,"preview_count":0,"access":"open","permissions":{"can_download":true,"can_preview":true}},"folder_upload_email":{"access":"open","email":"upload.Picture.k13sdz1@u.box.com"},"parent":{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},"item_status":"active","item_collection":{"total_count":1,"entries":[{"type":"file","id":"5000948880","sequence_id":"3","etag":"3","sha1":"134b65991ed521fcfe4724b7d814ab8ded5185dc","name":"tigers.jpeg"}],"offset":0,"limit":100}, "tags":["super", "happy"]}';
        BoxEnterprise.Info emailAliasInfo2 = new BoxEnterprise.Info(mockResponseBody);
         
		String mockResponseBody2 = '{"type":"folder","id":"11446498","sequence_id":"1","etag":"1","name":"Pictures","created_at":"2012-12-12T10:53:43-08:00","modified_at":"2012-12-12T11:15:04-08:00","description":"Some pictures I took","size":629644,"path_collection":{"total_count":1,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"}]},"created_by":{"type":"user","id":"17738362","name":"sean rose","login":"sean@box.com"},"modified_by":{"type":"user","id":"17738362","name":"sean rose","login":"sean@box.com"},"owned_by":{"type":"user","id":"17738362","name":"sean rose","login":"sean@box.com"},"shared_link":{"url":"https://www.box.com/s/vspke7y05sb214wjokpk","download_url":null,"vanity_url":null,"is_password_enabled":false,"unshared_at":null,"download_count":0,"preview_count":0,"access":"open","permissions":{"can_download":true,"can_preview":true}},"folder_upload_email":{"access":"open","email":"upload.Picture.k13sdz1@u.box.com"},"parent":{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},"item_status":"active","item_collection":{"total_count":1,"entries":[{"type":"file","id":"5000948880","sequence_id":"3","etag":"3","sha1":"134b65991ed521fcfe4724b7d814ab8ded5185dc","name":"tigers.jpeg"}],"offset":0,"limit":100}}';
    	BoxFolder.Info folderInfo = new BoxFolder.Info(mockResponseBody2);
        BoxEnterprise.Info emailAliasInfo3 = new BoxEnterprise.Info(folderInfo);
	}
}