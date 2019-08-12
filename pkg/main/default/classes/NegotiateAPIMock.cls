@IsTest
public with sharing class NegotiateAPIMock extends OAuthTokenMock {

	private final Boolean success;
	public static final UUID FOLDER_ID = UUID.parse('56322efe-e541-e911-9c1d-3ca82a1e3f41');
	public static final Id SOURCE_OBJECT_ID = Id.valueOf('0010R00000Y1M8bQAF');
	public static final Id SOURCE_OBJECT_ID_2 = Id.valueOf('0010R00000Y1M8bQbF');
	public static final UUID FOLDER_ID_2 = UUID.parse('22222efe-e541-e911-9c1d-3ca82a1e3f41');
	public static final UUID DOCUMENT_ID = UUID.parse('382bd222-1536-e911-9c1d-3ca82a1e3f41');
	public static final UUID DOCUMENT_ID_2 = UUID.parse('382bd222-1536-e922-9c1d-3ca82a1e3f41');
	public static final UUID DOCUMENT_ID_3 = UUID.parse('382bd222-1536-e933-9c1d-3ca82a1e3f41');
	public static final UUID DOCUMENT_ID_4 = UUID.parse('222bd222-1536-e911-9c1d-3ca82a1e3f41');
	public static final UUID DOCUMENT_ID_5 = UUID.parse('333bd333-1536-e911-9c1d-3ca82a1e3f41');
	public static final UUID DOCUMENT_ID_6 = UUID.parse('444bd444-1536-e911-9c1d-3ca82a1e3f41');
	public static final UUID TASK_ID = UUID.parse('4682d399-29fe-4085-9e48-126e4ffa0566');
	public static final UUID TASK_ID_2 = UUID.parse('5632d399-39fe-3085-9e48-126e4ffa0577');
	public static final UUID TASK_ID_3 = UUID.parse('5682d399-49fe-5085-9e48-126e4ffa0577');
	public static final UUID APPROVAL_DOCUMENT_ID = UUID.parse('f39a00f9-5991-e911-9c25-3ca82a1e3f41');
	public static final UUID APPROVER_USER_1 = UUID.parse('f3964a8e-cc7c-e911-9c20-3ca82a1e3f41');
	public static final UUID APPROVER_USER_2 = UUID.parse('d46c25be-5390-e911-9c25-3ca82a1e3f41');
	public static final Url DOCUMENT_HREF = new Url('https://apiqana11.springcm.com/v2/91845ae6-14b1-4cd1-a53d-e2d63d7d20af/documents/c2cb6ce7-7d7e-e911-9c35-3863bb335c17');
	public static final String USER_EMAIL = 'TestUser@TestCompany.com';
	public static final String WORKFLOW_ID = '382bd222-e541-e911-9c1d-3ca82a1e3f41';
	public static final UUID WORKITEM_ID = UUID.parse('382bd222-e541-e911-9c1d-3ca82a1e3a66');
	public static final UUID EXTERNAL_REVIEW_ID = UUID.parse('2a2167ad-0187-e911-9c35-3863bb335c17');
	public static final Id OBJECT_ID = ID.valueOf('0061U0000058I2EQAU');
	public static final String REVIEWERS_OBJECT = '[{"email":"unittest@test.com", "name":"test user"}]';
	public static final Entity USER_ENTITY = new Entity(UserInfo.getUserId());
	public static final Recipient WORKFLOW_RECIPIENT = Recipient.newBulkRecipient('Test User', 'Test@Test.com', NegotiateAPIMock.USER_ENTITY);
	public static final String ORIGINAL_DOCUMENT_HREF = 'https://apiqana11.springcm.com/v2/013fc30e-f6ca-464e-a97c-e4765dbad495/documents/5a10a488-8fbc-e911-9c37-3863bb335c17';
	public static final String COMPARE_VERSION_HREF = 'https://apiqana11.springcm.com/v2/013fc30e-f6ca-464e-a97c-e4765dbad495/documents/6d4a28c5-8fbc-e911-9c37-3863bb335c17';
	public static final UUID COMPARE_TASK_ID = UUID.parse('233d8ee7-1135-4d63-9163-c532c4e2571a');

	public NegotiateAPIMock(final Boolean success) {
		this.success = success;
	}

	public static NegotiateAPIMock success() {
		return (NegotiateAPIMock)TestUtils.setMock(new NegotiateAPIMock(true));
	}

	public static NegotiateAPIMock failure() {
		return (NegotiateAPIMock)TestUtils.setMock(new NegotiateAPIMock(false));
	}

	/* Supported routes:
	- POST /folders - Create EOS folder in SpringCM Space
	- POST /salesforcecontentdocumentimporttasks - Create Agreement in EOS folder
	- POST /tokenregistrations - Genrates limited access token
	- GET /folders/{folderId}/documents - Get All Agreements from an EOS folder
	- GET /documents/{documentId}/versions - Get All versions of an Agreement
	- PUT /documents/{documentId} - Rename Agreement
	- DELETE /documents/{documentId} - Delete Agreement
	- GET /{accountId}/historyItems/{documentId}
	- GET /{accountId}/documents/{documentId}/workitems?expand=Assignee
	- DELETE /v2/{accoundId}/documents/{documentId}/lock
	- POST /gen/v1/{accountId}/emails
	- POST /v2/{accountId}/documentcomparetasks
 */
	override public HttpResponse getResponse(final HttpRequest request) {
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		String method = request.getMethod();
		String path = request.getEndpoint();
		String body = request.getBody();

		if (success && method == 'POST' && path.contains(NegotiateAPI.PATH_FOLDER)) {
			response.setStatusCode(201);
			response.setStatus('CREATED');
			response.setBody('{"Href":"https://unit.test/folders/' + FOLDER_ID + '"}');
		}

		else if (success && method == 'POST' && path.contains(NegotiateAPI.PATH_EMAILS)) {
			response.setStatusCode(200);
			response.setStatus('OK');
		}

		else if (success && method == 'POST' && path.contains(NegotiateAPI.PATH_AGREEMENT_IN_EOS_FOLDER)) {
			response.setStatusCode(201);
			response.setStatus('CREATED');
			response.setBody('{"Status": "Processing","Href": "https://apiuatna11.springcm.com/v201411/salesforcecontentdocumentimporttasks/4682d399-29fe-4085-9e48-126e4ffa0566"}');
		}

		else if (success && method == 'POST' && path.contains(NegotiateAPI.PATH_AGREEMENT_IN_SALESFORCE)) {
			response.setStatusCode(201);
			response.setStatus('CREATED');
			response.setBody('{"Status": "Processing","Href": "https://apiuatna11.springcm.com/v2/salesforcecontentdocumentexporttasks/4682d399-29fe-4085-9e48-126e4ffa0566"}');
		}

		else if (success && method == 'POST' && path.contains(ResourceTokenAPI.PATH_RESOURCETOKEN) && body.contains(String.valueOf(COMPARE_TASK_ID))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"secret_uri":"https://account-hqtest3.dev.docusign.net/managed_token/v1/233d8ee7-1135-4d63-9163-c532c4e2571a"}');
		}

		else if (success && method == 'POST' && path.contains(NegotiateAPI.PATH_TOKEN_REGISTRATIONS)) {
			response.setStatusCode(201);
			response.setStatus('CREATED');
			response.setBody('{"AccessToken":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IjY4MTg1ZmYxLTRlNTEtNGNlOS1hZjFjLTY4OTgxMjIwMzMxNyJ9.eyJUb2tlblR5cGUiOjUsIklzc3VlSW5zdGFudCI6MTU1ODU2NDgyMywiZXhwIjoxNTU4NTY4NDIzLCJVc2VySWQiOiIzZGVkYWM1My00OGZhLTRkZTYtODk0YS0zNWI0ODAyYWQxMGQiLCJzaXRlaWQiOjEsInNjcCI6WyJzcHJpbmdfY29udGVudCJdLCJhdWQiOiI1NzUxYzI1NS0zM2E0LTRjOGQtYmY1YS0wNjU0YTUwNDE4ODYiLCJpc3MiOiJodHRwczovL2FjY291bnQtZC5kb2N1c2lnbi5jb20vIiwic3ViIjoiM2RlZGFjNTMtNDhmYS00ZGU2LTg5NGEtMzViNDgwMmFkMTBkIiwiYWN0IjoiNTc1MWMyNTUtMzNhNC00YzhkLWJmNWEtMDY1NGE1MDQxODg2IiwiYW1yIjpbImp3dF9iciJdfQ.aBrwKSZ09AqGqCNTE4NsAY-qDhflif94kcMEdq7zosZ7HRSFIggSOdRY8d9cvznGWsCp4hk4eKlihoUaHohMRKMwNW8dsmhPbff1t4Cm5xYEDTOOOrhA5ZC6bKJXBlLB5vhEga0yShMAY7ggbCOqxdCZH9pi3hp_1Z8G_8-7vQAPLfmqJo3tcdtyDXHfpdyJs5-4toxWiFtxX1VZS3I4tVre8w0P1QIpESDv-_-qHaE-4zniddCpg_CCR90ON83ZtBTG0HLQNj52YFAjKs5wm3nQrMC4V9C3vo9uyCSeBa9Lq0AgswFNoSLn7eiviRJB9iwSBx9Vuqx8xsOaKC9CMg","APIBaseUrl":"https://apiuatna11.springcm.com/v2/63d5ccaa-67ff-452b-8e5e-ee2dd94f1a00","APIDownloadBaseUrl":"https://apidownloaduatna11.springcm.com/v2/63d5ccaa-67ff-452b-8e5e-ee2dd94f1a00","APIUploadBaseUrl":"https://apiuploaduatna11.springcm.com/v2/63d5ccaa-67ff-452b-8e5e-ee2dd94f1a00","ExpiresIn":3599}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_AGREEMENT_COMPARE)) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Status":"Success","Href":"https://apiqana11.springcm.com/v2/013fc30e-f6ca-464e-a97c-e4765dbad495/documentcompareapitasks/233d8ee7-1135-4d63-9163-c532c4e2571a"}');
		}

		else if (success && method == 'POST' && path.contains(NegotiateAPI.PATH_AGREEMENT_COMPARE)) {
			response.setStatusCode(202);
			response.setStatus('Accepted');
			response.setBody('{"Status":"Success","Href":"https://apiqana11.springcm.com/v2/013fc30e-f6ca-464e-a97c-e4765dbad495/documentcompareapitasks/233d8ee7-1135-4d63-9163-c532c4e2571a"}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_REVIEWS)) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Sender":{"Href":"https://apiqana11.springcm.com/v2/41554d72-28fd-477f-9dd9-7701c4e750b5/members/e0faebab-b56a-e911-8398-005056b97c7d"},"Documents":{"Items":[{"Href":"https://apiqana11.springcm.com/v2/41554d72-28fd-477f-9dd9-7701c4e750b5/documents/acb1e384-4886-e911-9c35-3863bb335c17"}],"Offset":0,"Limit":20,"Total":1},"Recipient":{"Name":"SamCicero","Email":"sam.cicero@docusign.com"},"Status":"Sent","DueDate":"2019-08-23T05:00:00Z","EmailMessage":"<p>Pleasereview</p>","EmailSubject":"Review-Document","AlsoNotify":[],"AddSignature":true,"HideDueDateFromEmail":false,"EmailAppearance":0,"CreatedDate":"2019-06-04T19:48:09.603Z","Href":"https://apiqana11.springcm.com/v2/41554d72-28fd-477f-9dd9-7701c4e750b5/externalreviews/2a2167ad-0187-e911-9c35-3863bb335c17"}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_AGREEMENT_VERSIONS)) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Items":[{"Name":"newName.docx","CreatedDate":"2019-03-14T19:24:52.69Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-14T19:24:52.69Z","UpdatedBy":"pratik.hatkar@docusign.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":7,"Version":"3.0","PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=213e9c1a-8f46-e911-9c1d-3ca82a1e3f41","ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41","NativeFileSize":16808,"PdfFileSize":178269,"Href":"https://apiuatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41"},{"Name":"newName.docx","CreatedDate":"2019-03-14T19:24:04.233Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-14T19:24:04.233Z","UpdatedBy":"pratik.hatkar@docusign.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":7,"Version":"2.0","PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41","ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41","NativeFileSize":16808,"PdfFileSize":178269,"Href":"https://apiuatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41"},{"Name":"newName.docx","CreatedDate":"2019-03-08T21:35:08.97Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-14T19:14:39.68Z","UpdatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":5,"Version":"1.0","PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=996e80b6-8e46-e911-9c1d-3ca82a1e3f41","ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41","NativeFileSize":20557,"PdfFileSize":160453,"Href":"https://apiuatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41"}],"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/Versions","Offset":0,"Limit":20,"First":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/Versions","Last":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/Versions","Total":3}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_DOCUMENTS) && path.contains(String.valueOf(NegotiateAPIMock.DOCUMENT_ID_2))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Name":"ServiceDoc1.docx","CreatedDate":"2019-02-21T20:58:27.637Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-13T19:26:01.787Z","UpdatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/df5300b4-6135-e911-9c1d-3ca82a1e3f41"},"HistoryItems":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/historyitems"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":5,"Lock":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/lock"},"PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=382bd222-1536-e911-9c1d-3ca82a1e3f41","Versions":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/versions"},"ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41","NativeFileSize":16897,"PdfFileSize":160568,"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e922-9c1d-3ca82a1e3f41"}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_WORK_ITEMS) && path.contains(String.valueOf(NegotiateAPIMock.DOCUMENT_ID))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Items":[{"Name":"Approve1","Type":"ApproveDocuments","Assignee":{"FirstName":"John","LastName":"Doe","Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/users/45b693e8-3b65-e911-9c20-3ca82a1e3f41"},"AssignDate":"2019-05-01T19:04:19.587Z","Documents":{"Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/workitems/3ef321ec-436c-e911-8391-005056b948f7/documents"},"Workflow":{"Name":"Negotiate_Approval_Template","Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/workflows/ef01c0e5-436c-e911-8391-005056b948f7"},"CreatedDate":"2019-05-01T19:04:24.027Z","WorkItemUrl":"https://uatna11.springcm.com/atlas/Documents/Preview.aspx?aid=10737&wfid=3ef321ec-436c-e911-8391-005056b948f7&iter=","Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/workitems/3ef321ec-436c-e911-8391-005056b948f7"},{"Name":"Approve2","Type":"ApproveDocuments","Assignee":{"FirstName":"Jane","LastName":"Doe","Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/users/45b693e8-3b65-e911-9c20-3ca82a1e3f41"},"AssignDate":"2019-05-01T19:04:19.587Z","Documents":{"Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/workitems/3ef321ec-436c-e911-8391-005056b948f7/documents"},"Workflow":{"Name":"Negotiate_Approval_Template","Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/workflows/ef01c0e5-436c-e911-8391-005056b948f7"},"CreatedDate":"2019-05-01T19:04:24.027Z","WorkItemUrl":"https://uatna11.springcm.com/atlas/Documents/Preview.aspx?aid=10737&wfid=3ef321ec-436c-e911-8391-005056b948f7&iter=","Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/workitems/3ef321ec-436c-e911-8391-005056b948f7"}],"Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/documents/06ec39af-7268-e911-9c20-3ca82a1e3f41/workitems","Offset":0,"Limit":20,"First":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/documents/06ec39af-7268-e911-9c20-3ca82a1e3f41/workitems","Last":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/documents/06ec39af-7268-e911-9c20-3ca82a1e3f41/workitems","Total":1}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_AGREEMENT_IN_EOS_FOLDER) && path.contains(String.valueOf(NegotiateAPIMock.TASK_ID_2))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Document":{"Href":"https://apiuatna11.springcm.com/v201411/documents/51962d1b-5468-e911-9c20-3ca82a1e3f41"},"Message":"ContentDocument Processing","Status":"Processing","Href":"https://apiuatna11.springcm.com/v201411/salesforcecontentdocumentimporttasks/33c0648a-7bb5-4f34-aef8-9994362ce0ae"}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_AGREEMENT_IN_EOS_FOLDER)) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Document":{"Href":"https://apiuatna11.springcm.com/v201411/documents/51962d1b-5468-e911-9c20-3ca82a1e3f41"},"Message":"ContentDocumentimportedsuccessfully","Status":"Success","Href":"https://apiuatna11.springcm.com/v201411/salesforcecontentdocumentimporttasks/33c0648a-7bb5-4f34-aef8-9994362ce0ae"}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_AGREEMENT_IN_SALESFORCE) && path.contains(String.valueOf(NegotiateAPIMock.TASK_ID_2))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Message":"Document Export Processing","Status":"Processing","Href":"https://apiuatna11.springcm.com/v2/salesforcecontentdocumentexporttasks/33c0648a-7bb5-4f34-aef8-9994362ce0ae"}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_AGREEMENT_IN_SALESFORCE)) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"SfContentVersionId":"06817000000TrbmAAC","Message":"Document exported successfully","Status":"Success","Href":"https://apiuatna11.springcm.com/v2/salesforcecontentdocumentexporttasks/33c0648a-7bb5-4f34-aef8-9994362ce0ae"}');
		}

		else if (success && method == 'GET' && path.contains(String.valueOf(NegotiateAPIMock.FOLDER_ID_2))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Items": [{"Name": "ServiceDoc1.docx","CreatedDate": "2019-03-08T21:35:08.97Z","Href": "https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e922-9c1d-3ca82a1e3f41"},{"Name": "ServiceDoc2.docx","CreatedDate": "2019-04-08T21:35:08.97Z","Href": "https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e933-9c1d-3ca82a1e3f41"}],"Href": "https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41/documents","Offset": 0,"Limit": 20,"First": "https://apiuatna11.springcm.com/v201411/folders/22222efe-e541-e911-9c1d-3ca82a1e3f41/documents","Last": "https://apiuatna11.springcm.com/v201411/folders/22222efe-e541-e911-9c1d-3ca82a1e3f41/documents","Total": 2}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_HISTORY_ITEMS) && path.contains(String.valueOf(NegotiateAPIMock.DOCUMENT_ID_2))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Items": [{"Data": {"__legacyMessage": "Agreement_2fa1c4de-04b9-4fac-8413-5ea15f92aca1.docx have been sent for External Review to someguy+externalReviewRecipient@springcm.com and the review is due on 4/24/2019.","DocumentName": "ServiceDoc1.docx","DueDate": "2019-04-24T00:00:00","EmailSubject": "For external review","EmailMessage": "Please review the document","Actor": {"FullName": "Tyler Green","EmailAddress": "tgreen+packageb@springcm.com"},"Reviewer": {"FullName": "John Doe","EmailAddress": "someguy+externalReviewRecipient@springcm.com"}},"UserEmail": "tgreen+packageb@springcm.com","Action": "ExternalReviewInitiated", "ActionType": "ExternalReviewInitiated", "MoreInfo": "Agreement_2fa1c4de-04b9-4fac-8413-5ea15f92aca1.docx have been sent for External Review to someguy+externalReviewRecipient@springcm.com and the review is due on 4/24/2019.","Comment": "","User": {"UserName": "tgreen+packageb@springcm.com","Email": "tgreen+packageb@springcm.com","FirstName": "Tyler","LastName": "Green","Href": "https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate": "2019-05-25T18:13:28.2149908Z"}, {"Data": {"__legacyMessage": "","DocumentName": "ServiceDoc1.docx","DocumentUid": "bfa512ae-294f-e911-92dc-309c23cb2dc0","ContentVersionId": "0681U000001yYfQQAU","Actor": {"FullName": "Tyler Green","EmailAddress": "tgreen+packageb@springcm.com"}},"UserEmail": "tgreen+packageb@springcm.com","Action": "DocumentImportFromSalesforce", "ActionType": "DocumentImportFromSalesforce","Comment": "Document was downloaded from Salesforce.","User": {"UserName": "tgreen+packageb@springcm.com","Email": "tgreen+packageb@springcm.com","FirstName": "Tyler","LastName": "Green","Href": "https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate": "2019-05-23T18:13:26.3391945Z"}],"Href": "https://apilocalhost/v1/historyitems/bfa512ae-294f-e911-92dc-309c23cb2dc0","Offset": 0,"Limit": 20,"First": "https://apilocalhost/v1/historyitems/bfa512ae-294f-e911-92dc-309c23cb2dc0","Last": "https://apilocalhost/v1/historyitems/bfa512ae-294f-e911-92dc-309c23cb2dc0","Total": 2}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_HISTORY_ITEMS) && path.contains(String.valueOf(NegotiateAPIMock.DOCUMENT_ID_3))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Items": [{"Data": {"__legacyMessage": "Completed with result Approved","__legacyHistoryWorkflowInstanceUid": "48720a56-294f-e911-92dc-309c23cb2dc0","DocumentName": "ServiceDoc2.docx","Result": "Approved","Comments": "Approve 1 Approve by Full Sub on 3/25/2019 at 1:11:04 PM with comment: Looks good 2019-25-3--13-11-04","Actor": {"FullName": "Full Sub","EmailAddress": "tgreen+1@springcm.com"},"Approvers": [{"FullName": "Full Sub","EmailAddress": "tgreen+1@springcm.com"}]},"Action": "WorkflowApproved", "ActionType":"WorkflowApproved","MoreInfo": "Completed with result Approved","Comment": "Workflow: Negotiate_Approval_Template Action: Approve 1","User": {"FirstName": "","LastName": "Workflow"},"CreatedDate": "2019-03-25T18:11:05.1300166Z"}, {"Data": {"__legacyMessage": ""},"Action": "ApprovalCanceledByUser","ActionType": "ApprovalCanceledByUser","Comment": "Canceling document checkout on approval completion","User": {"FirstName": "","LastName": "Workflow"},"CreatedDate": "2019-03-25T18:11:05.101989Z"}, {"Data": {"__legacyMessage": "","EmailSubject": "For approval","EmailMessage": "Please approve the documents","Actor": {"FullName": "Full Sub","EmailAddress": "tgreen+1@springcm.com"},"Approvers": [{"FullName": "Full Sub","EmailAddress": "tgreen+1@springcm.com"},{"FullName": "Full2 Sub2","EmailAddress": "tgreen+2@springcm.com"}],"DocumentName": "ServiceDoc2.docx"},"Action": "ApprovalCheckout", "ActionType":"ApprovalCheckout", "Comment": "Via Approval","User": {"FirstName": "","LastName": "Workflow"},"CreatedDate": "2019-03-25T18:11:00.3609545Z"}, {"Data": {"__legacyMessage": "","DocumentName": "ServiceDoc2.docx","DocumentUid": "40720a56-294f-e911-92dc-309c23cb2dc0","ContentVersionId": "0681U000001yYfQQAU","Actor": {"FullName": "Full Sub","EmailAddress": "tgreen+1@springcm.com"}},"UserEmail": "tgreen+1@springcm.com","Action": "DocumentImportFromSalesforce", "ActionType" :"DocumentImportFromSalesforce","Comment": "Document was downloaded from Salesforce.","User": {"UserName": "tgreen+1@springcm.com","Email": "tgreen+1@springcm.com","FirstName": "Full","LastName": "Sub","Href": "https://apilocalhost/v1/users/tgreen%2B1%40springcm.com"},"CreatedDate": "2019-03-25T18:10:58.6339427Z"}],"Href": "https://apilocalhost/v1/historyitems/40720a56-294f-e911-92dc-309c23cb2dc0","Offset": 0,"Limit": 20,"First": "https://apilocalhost/v1/historyitems/40720a56-294f-e911-92dc-309c23cb2dc0","Last": "https://apilocalhost/v1/historyitems/40720a56-294f-e911-92dc-309c23cb2dc0","Total": 4}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_HISTORY_ITEMS) && path.contains(String.valueOf(NegotiateAPIMock.DOCUMENT_ID_6))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Items": [{"Data": {"__legacyMessage": "Agreement_2fa1c4de-04b9-4fac-8413-5ea15f92aca1.docx have been sent for External Review to someguy+externalReviewRecipient@springcm.com and the review is due on 4/24/2019.","DocumentName": "Agreement_2fa1c4de-04b9-4fac-8413-5ea15f92aca1.docx","DueDate": "2019-04-24T00:00:00","EmailSubject": "For external review","EmailMessage": "Please review the document","Actor": {"FullName": "Tyler Green","EmailAddress": "tgreen+packageb@springcm.com"},"Reviewer": {"FullName": "John Doe","EmailAddress": "someguy+externalReviewRecipient@springcm.com"}},"UserEmail": "tgreen+packageb@springcm.com","Action": "ExternalReviewInitiated", "ActionType":"ExternalReviewInitiated", "MoreInfo": "Agreement_2fa1c4de-04b9-4fac-8413-5ea15f92aca1.docx have been sent for External Review to someguy+externalReviewRecipient@springcm.com and the review is due on 4/24/2019.","Comment": "","User": {"UserName": "tgreen+packageb@springcm.com","Email": "tgreen+packageb@springcm.com","FirstName": "Tyler","LastName": "Green","Href": "https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate": "2019-03-25T18:13:28.2149908Z"}, {"Data": {"__legacyMessage": "","DocumentName": "Agreement_2fa1c4de-04b9-4fac-8413-5ea15f92aca1.docx","DocumentUid": "bfa512ae-294f-e911-92dc-309c23cb2dc0","ContentVersionId": "0681U000001yYfQQAU","Actor": {"FullName": "Tyler Green","EmailAddress": "tgreen+packageb@springcm.com"}},"UserEmail": "tgreen+packageb@springcm.com","Action": "DocumentImportFromSalesforce", "ActionType":"DocumentImportFromSalesforce", "Comment": "Document was downloaded from Salesforce.","User": {"UserName": "tgreen+packageb@springcm.com","Email": "tgreen+packageb@springcm.com","FirstName": "Tyler","LastName": "Green","Href": "https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate": "2019-03-25T18:13:26.3391945Z"}],"Href": "https://apilocalhost/v1/historyitems/bfa512ae-294f-e911-92dc-309c23cb2dc0","Offset": 0,"Limit": 20,"First": "https://apilocalhost/v1/historyitems/bfa512ae-294f-e911-92dc-309c23cb2dc0","Last": "https://apilocalhost/v1/historyitems/bfa512ae-294f-e911-92dc-309c23cb2dc0","Total": 2}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_HISTORY_ITEMS) && path.contains(String.valueOf(NegotiateAPIMock.DOCUMENT_ID_5))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Items":[{"Data":{"__legacyMessage":"","EmailSubject":"For approval","EmailMessage":"Please approve the documents","Actor":{"FullName":"Tyler Green","EmailAddress":"tgreen+packageb@springcm.com"},"Approvers":[{"FullName":"Full Sub","EmailAddress":"tgreen+1@springcm.com"}],"DocumentName":"Agreement_bd4b0631-7812-4125-84ab-be40c4fa6cae.docx"},"Action":"ApprovalCheckout", "ActionType":"ApprovalCheckout","Comment":"Via Approval","User":{"FirstName":"","LastName":"Workflow"},"CreatedDate":"2019-03-25T18:10:02.4241543Z"},{"Data":{"__legacyMessage":"","DocumentName":"Agreement_bd4b0631-7812-4125-84ab-be40c4fa6cae.docx","DocumentUid":"ee1c5333-294f-e911-92dc-309c23cb2dc0","ContentVersionId":"0681U000001yYfQQAU","Actor":{"FullName":"Tyler Green","EmailAddress":"tgreen+packageb@springcm.com"}},"UserEmail":"tgreen+packageb@springcm.com","Action":"DocumentImportFromSalesforce", "ActionType":"DocumentImportFromSalesforce","Comment":"Document was downloaded from Salesforce.","User":{"UserName":"tgreen+packageb@springcm.com","Email":"tgreen+packageb@springcm.com","FirstName":"Tyler","LastName":"Green","Href":"https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate":"2019-03-25T18:10:00.4255309Z"}],"Href":"https://apilocalhost/v1/historyitems/ee1c5333-294f-e911-92dc-309c23cb2dc0","Offset":0,"Limit":20,"First":"https://apilocalhost/v1/historyitems/ee1c5333-294f-e911-92dc-309c23cb2dc0","Last":"https://apilocalhost/v1/historyitems/ee1c5333-294f-e911-92dc-309c23cb2dc0","Total":2}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_HISTORY_ITEMS) && path.contains(String.valueOf(NegotiateAPIMock.DOCUMENT_ID_4))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Items":[{"Data":{"__legacyMessage":"Agreement_e6fbb33f-6362-41da-93b6-1937c3be8763.docx","DocumentName":"Updated Agreement Name_446961c6-8ca9-40b0-80d9-595308bfa6e7.docx","DocumentOldName":"Agreement_e6fbb33f-6362-41da-93b6-1937c3be8763.docx","DocumentUid":"8ab00ad9-284f-e911-92dc-309c23cb2dc0","Actor":{"FullName":"Tyler Green","EmailAddress":"tgreen+packageb@springcm.com"}},"UserEmail":"tgreen+packageb@springcm.com","Action":"TitleChanged", "ActionType":"TitleChanged","MoreInfo":"File name changed from: Agreement_e6fbb33f-6362-41da-93b6-1937c3be8763.docx","Comment":"","User":{"UserName":"tgreen+packageb@springcm.com","Email":"tgreen+packageb@springcm.com","FirstName":"Tyler","LastName":"Green","Href":"https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate":"2019-03-25T18:07:35.3572857Z"},{"Data":{"__legacyMessage":"","DocumentName":"Agreement_e6fbb33f-6362-41da-93b6-1937c3be8763.docx","DocumentUid":"8ab00ad9-284f-e911-92dc-309c23cb2dc0","ContentVersionId":"0681U000001yYfQQAU","Actor":{"FullName":"Tyler Green","EmailAddress":"tgreen+packageb@springcm.com"}},"UserEmail":"tgreen+packageb@springcm.com","Action":"DocumentImportFromSalesforce", "ActionType":"DocumentImportFromSalesforce", "Comment":"Document was downloaded from Salesforce.","User":{"UserName":"tgreen+packageb@springcm.com","Email":"tgreen+packageb@springcm.com","FirstName":"Tyler","LastName":"Green","Href":"https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate":"2019-03-25T18:07:33.5802991Z"}],"Href":"https://apilocalhost/v1/historyitems/8ab00ad9-284f-e911-92dc-309c23cb2dc0","Offset":0,"Limit":20,"First":"https://apilocalhost/v1/historyitems/8ab00ad9-284f-e911-92dc-309c23cb2dc0","Last":"https://apilocalhost/v1/historyitems/8ab00ad9-284f-e911-92dc-309c23cb2dc0","Total":2}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_HISTORY_ITEMS)) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Items":[{"Data":{"__legacyMessage":"","DocumentName":"Agreement_7d50807b-0a38-4c8a-86dd-0c1e335d3e2e.docx","DocumentUid":"12d96fc8-284f-e911-92dc-309c23cb2dc0","ContentVersionId":"0681U000001yYfQQAU","Actor":{"FullName":"Tyler Green","EmailAddress":"tgreen+packageb@springcm.com"}},"UserEmail":"tgreen+packageb@springcm.com","Action":"DocumentImportFromSalesforce","ActionType":"DocumentImportFromSalesforce","Comment":"Document was downloaded from Salesforce.","User":{"UserName":"tgreen+packageb@springcm.com","Email":"tgreen+packageb@springcm.com","FirstName":"Tyler","LastName":"Green","Href":"https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate":"2019-03-25T18:07:01.150201Z"}],"Href":"https://apilocalhost/v1/historyitems/12d96fc8-284f-e911-92dc-309c23cb2dc0","Offset":0,"Limit":20,"First":"https://apilocalhost/v1/historyitems/12d96fc8-284f-e911-92dc-309c23cb2dc0","Last":"https://apilocalhost/v1/historyitems/12d96fc8-284f-e911-92dc-309c23cb2dc0","Total":1}');
		}

		else if (success && method == 'POST' && path.contains(NegotiateAPI.PATH_WORKFLOWS) && body.contains(String.valueOf(DOCUMENT_ID))) {
			response.setStatusCode(201);
			response.setStatus('CREATED');
			response.setBody('{"Name":"Negotiate_ExternalReview_Template","StartDate":"2019-05-06T20:49:24.577Z","Status":"Executing","Info":"","Href":"https://apiqana11.springcm.com/v2/ee3907fb-baa7-41d4-b9a5-52756b323607/workflows/' + TASK_ID_2 + '"}');
		}

		else if (success && method == 'POST' && path.contains(NegotiateAPI.PATH_WORKFLOWS) && body.contains(String.valueOf(DOCUMENT_ID_2))) {
			response.setStatusCode(201);
			response.setStatus('CREATED');
			response.setBody('{"Name":"Negotiate_ExternalReview_Template","StartDate":"2019-05-06T20:49:24.577Z","Status":"Executing","Info":"","Href":"https://apiqana11.springcm.com/v2/ee3907fb-baa7-41d4-b9a5-52756b323607/workflows/' + TASK_ID_3 + '"}');
		}

		else if (success && method == 'POST' && path.contains(NegotiateAPI.PATH_WORKFLOWS)) {
			response.setStatusCode(201);
			response.setStatus('CREATED');
			response.setBody('{"Name":"Negotiate_ExternalReview_Template","StartDate":"2019-05-06T20:49:24.577Z","Status":"Executing","Info":"","Href":"https://apiqana11.springcm.com/v2/ee3907fb-baa7-41d4-b9a5-52756b323607/workflows/4cf1f36a-4070-e911-8395-005056b946c2"}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_WORKFLOWS) && path.contains(String.valueOf(TASK_ID_3))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Name":"Negotiate_ExternalReview_Template","StartDate":"2019-05-06T20:49:24.577Z","Status":"Failed","Info":"","Href":"https://apiqana11.springcm.com/v2/ee3907fb-baa7-41d4-b9a5-52756b323607/workflows/4cf1f36a-4070-e911-8395-005056b946c2"}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_WORKFLOWS) && path.contains(String.valueOf(TASK_ID_2))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Name":"Negotiate_ExternalReview_Template","StartDate":"2019-05-06T20:49:24.577Z","Status":"Executing","Info":"","Href":"https://apiqana11.springcm.com/v2/ee3907fb-baa7-41d4-b9a5-52756b323607/workflows/4cf1f36a-4070-e911-8395-005056b946c2"}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_WORKFLOWS)) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Name":"Negotiate_ExternalReview_Template","StartDate":"2019-05-06T20:49:24.577Z","Status":"Waiting","Info":"","Href":"https://apiqana11.springcm.com/v2/ee3907fb-baa7-41d4-b9a5-52756b323607/workflows/4cf1f36a-4070-e911-8395-005056b946c2"}');
		}

		else if (success && method == 'PUT' && path.contains(NegotiateAPI.PATH_REVIEWS)) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Sender":{"Href":"https://apilocalhost/v2/681cde0b-5a84-455a-b2df-1e7ffe790003/members/0a8823c8-3147-e911-b323-309c23cb2ea4"},"Documents":{"Items":[{"Href":"https://apilocalhost/v2/681cde0b-5a84-455a-b2df-1e7ffe790003/documents/625a04ad-2882-e911-b333-309c23cb2ea4"}],"Offset":0,"Limit":20,"Total":1},"Recipient":{"Name":"","Email":"kevin.test.docusign@gmail.com"},"Status":"Complete","DueDate":"2019-06-28T05:00:00Z","EmailMessage":"Pleasereviewthedocument","EmailSubject":"YourreviewisneededforAgreement_Document.docx","Comment":"Completed","AlsoNotify":[],"AddSignature":false,"HideDueDateFromEmail":false,"EmailAppearance":0,"CreatedDate":"2019-05-29T15:44:47.753Z","Href":"https://apilocalhost/v2/681cde0b-5a84-455a-b2df-1e7ffe790003/externalreviews/6e5a04ad-2882-e911-b333-309c23cb2ea4"}');
		}

		else if (success && method == 'PUT') {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Name":"docuTestRename.docx","CreatedDate":"2019-02-21T20:58:27.637Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-13T19:26:01.787Z","UpdatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/df5300b4-6135-e911-9c1d-3ca82a1e3f41"},"HistoryItems":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/historyitems"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":5,"Lock":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/lock"},"PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=382bd222-1536-e911-9c1d-3ca82a1e3f41","Versions":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/versions"},"ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41","NativeFileSize":16897,"PdfFileSize":160568,"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41"}');
		}

		else if (success && method == 'DELETE') {
			response.setStatusCode(200);
			response.setStatus('OK');
		}

		else if (success && method == 'PUT' && path.contains(NegotiateAPI.PATH_WORK_ITEMS)) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Name":"Approve1","Type":"ApproveDocuments","Assignee":{"Href":"https://apilocalhost/v2/681cde0b-5a84-455a-b2df-1e7ffe790003/members/8f6c7260-e34c-e911-b324-309c23cb2ea4"},"AssignDate":"2019-05-29T15:36:33.65Z","Documents":{"Href":"https://apilocalhost/v2/681cde0b-5a84-455a-b2df-1e7ffe790003/workitems/52309483-2782-e911-b333-309c23cb2ea4/documents"},"Workflow":{"Name":"Negotiate_Approval_Template","Href":"https://apilocalhost/v2/681cde0b-5a84-455a-b2df-1e7ffe790003/workflows/2f309483-2782-e911-b333-309c23cb2ea4"},"CreatedDate":"2019-05-29T15:36:33.65Z","WorkItemUrl":"https://localhost/atlas/Documents/Preview.aspx?aid=30581986&wfid=52309483-2782-e911-b333-309c23cb2ea4&iter=","Href":"https://apilocalhost/v2/681cde0b-5a84-455a-b2df-1e7ffe790003/workitems/52309483-2782-e911-b333-309c23cb2ea4"}');
		}

		else if (success && method == 'GET' && path.contains(String.valueOf(APPROVAL_DOCUMENT_ID))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Items":[{"Name":"Approve 2","Type":"Approve Documents","Assignee":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/f3964a8e-cc7c-e911-9c20-3ca82a1e3f41"},"AssignDate":"2019-06-17T23:46:43.073Z","Documents":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/workitems/181f4326-5a91-e911-83a4-005056b948f7/documents"},"Workflow":{"Name":"Negotiate_Approval_Template","Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/workflows/f41e4326-5a91-e911-83a4-005056b948f7"},"CreatedDate":"2019-06-17T23:46:42.7Z","WorkItemUrl":"https://uatna11.springcm.com/atlas/Documents/Preview.aspx?aid=10925&wfid=181f4326-5a91-e911-83a4-005056b948f7&iter=","Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/workitems/181f4326-5a91-e911-83a4-005056b948f7"},{"Name":"Approve 2","Type":"Approve Documents","Assignee":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/d46c25be-5390-e911-9c25-3ca82a1e3f41"},"AssignDate":"2019-06-17T23:46:42.853Z","Documents":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/workitems/161f4326-5a91-e911-83a4-005056b948f7/documents"},"Workflow":{"Name":"Negotiate_Approval_Template","Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/workflows/f41e4326-5a91-e911-83a4-005056b948f7"},"CreatedDate":"2019-06-17T23:46:42.48Z","WorkItemUrl":"https://uatna11.springcm.com/atlas/Documents/Preview.aspx?aid=10925&wfid=161f4326-5a91-e911-83a4-005056b948f7&iter=","Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/workitems/161f4326-5a91-e911-83a4-005056b948f7"}],"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/documents/f39a00f9-5991-e911-9c25-3ca82a1e3f41/workitems","Offset":0,"Limit":20,"First":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/documents/f39a00f9-5991-e911-9c25-3ca82a1e3f41/workitems","Last":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/documents/f39a00f9-5991-e911-9c25-3ca82a1e3f41/workitems","Total":2}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_MEMBERS) && path.contains(String.valueOf(APPROVER_USER_1))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Email":"unifiedappjunedemo@dsxtr.com","FirstName":"UnifiedApp","LastName":"JuneDemo","WorkItems":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/f3964a8e-cc7c-e911-9c20-3ca82a1e3f41/workitems"},"RecentDocuments":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/current/recentdocuments"},"WatchedDocumentsProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/current/watcheddocumentsprocesstrackingactivities"},"WorkflowQueues":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/f3964a8e-cc7c-e911-9c20-3ca82a1e3f41/workflowqueues"},"Role":"SuperAdministrator","PermissionSets":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/f3964a8e-cc7c-e911-9c20-3ca82a1e3f41/permissionsets"},"WatchedDocuments":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/current/watcheddocuments"},"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/f3964a8e-cc7c-e911-9c20-3ca82a1e3f41"}');
		}

		else if (success && method == 'GET' && path.contains(NegotiateAPI.PATH_MEMBERS) && path.contains(String.valueOf(APPROVER_USER_2))) {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Email":"unifiedappjunedemouser@dsxtr.com","FirstName":"UA","LastName":"JuneDemo","WorkItems":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/d46c25be-5390-e911-9c25-3ca82a1e3f41/workitems"},"Role":"FullSubscriber","PermissionSets":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/d46c25be-5390-e911-9c25-3ca82a1e3f41/permissionsets"},"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/d46c25be-5390-e911-9c25-3ca82a1e3f41"}');
		}

		else if (success && method == 'GET') {
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setBody('{"Items":[{"Name":"docusignlogerror7-23-18-1.docx","CreatedDate":"2019-03-08T21:35:08.97Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-08T21:35:08.97Z","UpdatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41"},"HistoryItems":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/historyitems"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":5,"Lock":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/lock"},"PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=ea7ab407-ea41-e911-9c1d-3ca82a1e3f41","Versions":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/versions"},"ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41","NativeFileSize":20557,"PdfFileSize":160453,"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41"}],"Href":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41/documents","Offset":0,"Limit":20,"First":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41/documents","Last":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41/documents","Total":1}');
		}

		else {
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setBody('{"Error":{"HttpStatusCode":400,"UserMessage":"Test user message","DeveloperMessage":"Test developer message","ErrorCode":1234,"ReferenceId":"' + UUID.randomUUID() + '"}}');
		}

		return response;
	}

}
