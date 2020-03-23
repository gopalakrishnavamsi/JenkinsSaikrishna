@IsTest
public class ScmAPIMock extends OAuthTokenMock implements HttpCalloutMock {
	// TODO: Remove ID matching and use dynamic mock responses. This is super fragile.
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
	public static final UUID DOCUMENT_ID_7 = UUID.parse('555bd444-1536-e911-9c1d-3ca82a1e3f41');
	public static final UUID DOCUMENT_ID_8 = UUID.parse('666bd444-1536-e911-9c1d-3ca82a1e3f41');
	public static final UUID TASK_ID = UUID.parse('4682d399-29fe-4085-9e48-126e4ffa0566');
	public static final UUID TASK_ID_2 = UUID.parse('5632d399-39fe-3085-9e48-126e4ffa0577');
	public static final UUID TASK_ID_3 = UUID.parse('5682d399-49fe-5085-9e48-126e4ffa0577');
	public static final UUID APPROVAL_DOCUMENT_ID = UUID.parse('f39a00f9-5991-e911-9c25-3ca82a1e3f41');
	public static final UUID APPROVER_USER_1 = UUID.parse('f3964a8e-cc7c-e911-9c20-3ca82a1e3f41');
	public static final UUID APPROVER_USER_2 = UUID.parse('d46c25be-5390-e911-9c25-3ca82a1e3f41');
	public static final Url DOCUMENT_HREF = new Url('https://apiqana11.springcm.com/v2/91845ae6-14b1-4cd1-a53d-e2d63d7d20af/documents/c2cb6ce7-7d7e-e911-9c35-3863bb335c17');
	public static final UUID WORKITEM_ID = UUID.parse('382bd222-e541-e911-9c1d-3ca82a1e3a66');
	public static final UUID EXTERNAL_REVIEW_ID = UUID.parse('2a2167ad-0187-e911-9c35-3863bb335c17');
	public static final Id OBJECT_ID = Id.valueOf('0061U0000058I2EQAU');
	public static final String ORIGINAL_DOCUMENT_HREF = 'https://apiqana11.springcm.com/v2/013fc30e-f6ca-464e-a97c-e4765dbad495/documents/5a10a488-8fbc-e911-9c37-3863bb335c17';
	public static final String COMPARE_VERSION_HREF = 'https://apiqana11.springcm.com/v2/013fc30e-f6ca-464e-a97c-e4765dbad495/documents/6d4a28c5-8fbc-e911-9c37-3863bb335c17';
	public static final UUID COMPARE_TASK_ID = UUID.parse('233d8ee7-1135-4d63-9163-c532c4e2571a');

	private static final Map<String, String> MOCK_TYPES = new Map<String, String> {
		'emails' => Application.classNamespacePrefix + 'ScmAPIMock.EmailMock',
		'folders' => Application.classNamespacePrefix + 'ScmAPIMock.FolderMock',
		'historyitems' => Application.classNamespacePrefix + 'ScmAPIMock.HistoryMock',
		'sfdocumentxmlmergetasks' => Application.classNamespacePrefix + 'ScmAPIMock.MergeMock',
		'resourcetokenregistrations' => Application.classNamespacePrefix + 'ScmAPIMock.ResourceTokensMock',
		'tokenregistrations' => Application.classNamespacePrefix + 'ScmAPIMock.TokensMock',
		'workflows' => Application.classNamespacePrefix + 'ScmAPIMock.WorkflowMock',
		'salesforcecontentdocumentimporttasks' => Application.classNamespacePrefix + 'ScmAPIMock.ImportMock',
		'salesforcecontentdocumentexporttasks' => Application.classNamespacePrefix + 'ScmAPIMock.ExportMock',
		'documentcomparetasks' => Application.classNamespacePrefix + 'ScmAPIMock.CompareMock',
		'reviews' => Application.classNamespacePrefix + 'ScmAPIMock.ReviewMock',
		'workitems' => Application.classNamespacePrefix + 'ScmAPIMock.WorkItemMock',
		'documents' => Application.classNamespacePrefix + 'ScmAPIMock.DocumentMock',
		'members' => Application.classNamespacePrefix + 'ScmAPIMock.MemberMock',
		'changesecuritytasks' => Application.classNamespacePrefix + 'ScmAPIMock.ChangeSecurityTask',
		'templates' => Application.classNamespacePrefix + 'ScmAPIMock.TemplateMock',
		'convert' => Application.classNamespacePrefix + 'ScmAPIMock.ConvertDocumentMock'
	};
	private static final Map<String, MockResource> MOCKS = new Map<String, MockResource>();

	// Capture group 1 = gen?, group 2 = api version, group 3 = account ID, group 4 = the rest
	private static final Pattern BASE_PATH_PATTERN = Pattern.compile(
		'\\/(gen\\/|negotiate\\/api\\/)?(v[1,2])\\/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})\\/(.+)');

	private final Boolean success;

	public ScmAPIMock(final Boolean success) {
		super(!success);
		this.success = success;
	}

	private MockRequest parseRequest(final HttpRequest request) {
		Url u = new Url(request.getEndpoint());
		String p = u.getPath();

		Matcher m = BASE_PATH_PATTERN.matcher(u.getPath());
		if (!m.matches()) throw new AssertException('API request endpoint was not in expected format: ' + u.getPath());

		Integer gc = m.groupCount();
		String resource = m.group(2); // accounts | login_information
		UUID accountId = gc >= 3 ? UUID.tryParse(m.group(3)) : null;
		String path = gc >= 4 ? m.group(4) : null;
		List<String> pathComponents = String.isBlank(path) ? new List<String>() : path.split('\\/');
		if (!pathComponents.isEmpty()) {
			resource = pathComponents[0];
			pathComponents.remove(0);
		}
		String params = u.getQuery();

		return new MockRequest(
			request.getMethod(),
			m.group(2),
			accountId,
			resource,
			String.isBlank(path) ? new List<String>() : path.split('\\/'),
			String.isBlank(params) ? QueryString.empty : QueryString.parse(params),
			request.getHeader('User-Agent'),
			request.getBody());
	}

	public class EmailMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'POST') {
				response = MockResponse.ok(null); // Empty response?
			}
			return response;
		}
	}

	public class FolderMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				//Set mock for getting the url of the root folder
				if (request.path.contains('type')) {
					response = MockResponse.ok('{"Name":"Other Sources","CreatedDate":"2019-10-03T20:57:32.093Z","CreatedBy":"octdaladmin1@dsxtr.com","UpdatedDate":"2019-10-03T20:57:32.093Z","UpdatedBy":"octdaladmin1@dsxtr.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v2/645e10db-edb7-4e3b-a4a7-cbc55cab3905/folders/81e35d6a-20e6-e911-9c2b-3ca82a1e3f41"},"BrowseDocumentsUrl":"https://uatna11.springcm.com/atlas/Link/Folder/12027/8de35d6a-20e6-e911-9c2b-3ca82a1e3f41","AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"Documents":{"Href":"https://apiuatna11.springcm.com/v2/645e10db-edb7-4e3b-a4a7-cbc55cab3905/folders/8de35d6a-20e6-e911-9c2b-3ca82a1e3f41/documents"},"Folders":{"Href":"https://apiuatna11.springcm.com/v2/645e10db-edb7-4e3b-a4a7-cbc55cab3905/folders/8de35d6a-20e6-e911-9c2b-3ca82a1e3f41/folders"},"ShareLinks":{"Href":"https://apiuatna11.springcm.com/v2/645e10db-edb7-4e3b-a4a7-cbc55cab3905/folders/8de35d6a-20e6-e911-9c2b-3ca82a1e3f41/sharelinks"},"CreateDocumentHref":"https://apiuploaduatna11.springcm.com/v2/645e10db-edb7-4e3b-a4a7-cbc55cab3905/folders/8de35d6a-20e6-e911-9c2b-3ca82a1e3f41/documents{?name}","Href":"https://apiuatna11.springcm.com/v2/645e10db-edb7-4e3b-a4a7-cbc55cab3905/folders/8de35d6a-20e6-e911-9c2b-3ca82a1e3f41"}');
				} else {
					response = MockResponse.ok('{"Items":[{"Name":"docusignlogerror7-23-18-1.docx","CreatedDate":"2019-03-08T21:35:08.97Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-08T21:35:08.97Z","UpdatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","ContentCreatedDate":"2019-03-10T21:35:08.97Z","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41"},"HistoryItems":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/historyitems"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":5,"Lock":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/lock"},"PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=ea7ab407-ea41-e911-9c1d-3ca82a1e3f41","Versions":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/versions"},"ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41","NativeFileSize":20557,"PdfFileSize":160453,"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41"}],"Href":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41/documents","Offset":0,"Limit":20,"First":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41/documents","Last":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41/documents","Total":1}');
				}
			} else if (request.method == 'POST') {
				response = MockResponse.created('{"Href":"https://unit.test/folders/' + FOLDER_ID + '"}');
			}
			return response;
		}
	}

	public class TemplateMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				response = MockResponse.ok('{"name": "html_templates","id": "' + FOLDER_ID + '"}');
			}
			return response;
		}
	}

	public class HistoryMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				if (request.path.contains(String.valueOf(ScmAPIMock.DOCUMENT_ID))) {
					response = MockResponse.ok('{"Items": [{"Data": {"__legacyMessage":"Completed with result Rejected","__legacyHistoryWorkflowInstanceUid":"5bf5b5c1-76e1-e911-83b1-005056b948f7","DocumentName":"Prestige Worldwide Application (3).docx","Result":"Rejected","Comments":"Approve 2 Reject by Dimitri Blaiddyd on 9/27/2019 at 5:34:59 PM with comment: rejecting as dimitri","CommentList":[{"Commenter":"Dimitri Blaiddyd","Comment":"rejecting as dimitri","CommentDate":"9/27/2019 5:34:59 PM"}],"Actor":{"FullName":"Dimitri Blaiddyd","EmailAddress":"dimitri.blaiddyd@example.com"},"Approvers":[{"FullName":"Dimitri Blaiddyd","EmailAddress":"dimitri.blaiddyd@example.com"}]},"ActionType":"WorkflowRejected","Action":"Rejected in Workflow","MoreInfo":"Completed with result Rejected","Comment":"Workflow: Negotiate_Approval_Template Action: Approve 2","User":{"FirstName":"","LastName":"Workflow"},"CreatedDate":"2019-09-27T22:35:00.3697037Z"}],"Total": 1}');
				} else if (request.path.contains(String.valueOf(ScmAPIMock.DOCUMENT_ID_2))) {
					response = MockResponse.ok('{"Items": [{"Data": {"__legacyMessage": "Agreement_2fa1c4de-04b9-4fac-8413-5ea15f92aca1.docx have been sent for External Review to someguy+externalReviewRecipient@springcm.com and the review is due on 4/24/2019.","DocumentName": "ServiceDoc1.docx","DueDate": "2019-04-24T00:00:00","EmailSubject": "For external review","EmailMessage": "Please review the document","Actor": {"FullName": "Tyler Green","EmailAddress": "tgreen+packageb@springcm.com"},"Reviewer": {"FullName": "John Doe","EmailAddress": "someguy+externalReviewRecipient@springcm.com"}},"UserEmail": "tgreen+packageb@springcm.com","Action": "ExternalReviewInitiated", "ActionType": "ExternalReviewInitiated", "MoreInfo": "Agreement_2fa1c4de-04b9-4fac-8413-5ea15f92aca1.docx have been sent for External Review to someguy+externalReviewRecipient@springcm.com and the review is due on 4/24/2019.","Comment": "","User": {"UserName": "tgreen+packageb@springcm.com","Email": "tgreen+packageb@springcm.com","FirstName": "Tyler","LastName": "Green","Href": "https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate": "2019-05-25T18:13:28.2149908Z"}, {"Data": {"__legacyMessage": "","DocumentName": "ServiceDoc1.docx","DocumentUid": "bfa512ae-294f-e911-92dc-309c23cb2dc0","ContentVersionId": "0681U000001yYfQQAU","Actor": {"FullName": "Tyler Green","EmailAddress": "tgreen+packageb@springcm.com"}},"UserEmail": "tgreen+packageb@springcm.com","Action": "DocumentImportFromSalesforce", "ActionType": "DocumentImportFromSalesforce","Comment": "Document was downloaded from Salesforce.","User": {"UserName": "tgreen+packageb@springcm.com","Email": "tgreen+packageb@springcm.com","FirstName": "Tyler","LastName": "Green","Href": "https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate": "2019-05-23T18:13:26.3391945Z"}],"Href": "https://apilocalhost/v1/historyitems/bfa512ae-294f-e911-92dc-309c23cb2dc0","Offset": 0,"Limit": 20,"First": "https://apilocalhost/v1/historyitems/bfa512ae-294f-e911-92dc-309c23cb2dc0","Last": "https://apilocalhost/v1/historyitems/bfa512ae-294f-e911-92dc-309c23cb2dc0","Total": 2}');
				} else if (request.path.contains(String.valueOf(ScmAPIMock.DOCUMENT_ID_3))) {
					response = MockResponse.ok('{"Items": [{"Data": {"__legacyMessage": "Completed with result Approved","__legacyHistoryWorkflowInstanceUid": "48720a56-294f-e911-92dc-309c23cb2dc0","DocumentName": "ServiceDoc2.docx","Result": "Approved","Comments": "Approve 1 Approve by Full Sub on 3/25/2019 at 1:11:04 PM with comment: Looks good 2019-25-3--13-11-04","Actor": {"FullName": "Full Sub","EmailAddress": "tgreen+1@springcm.com"},"Approvers": [{"FullName": "Full Sub","EmailAddress": "tgreen+1@springcm.com"}]},"Action": "WorkflowApproved", "ActionType":"WorkflowApproved","MoreInfo": "Completed with result Approved","Comment": "Workflow: Negotiate_Approval_Template Action: Approve 1","User": {"FirstName": "","LastName": "Workflow"},"CreatedDate": "2019-03-25T18:11:05.1300166Z"}, {"Data": {"__legacyMessage": ""},"Action": "ApprovalCanceledByUser","ActionType": "ApprovalCanceledByUser","Comment": "Canceling document checkout on approval completion","User": {"FirstName": "","LastName": "Workflow"},"CreatedDate": "2019-03-25T18:11:05.101989Z"}, {"Data": {"__legacyMessage": "","EmailSubject": "For approval","EmailMessage": "Please approve the documents","Actor": {"FullName": "Full Sub","EmailAddress": "tgreen+1@springcm.com"},"Approvers": [{"FullName": "Full Sub","EmailAddress": "tgreen+1@springcm.com"},{"FullName": "Full2 Sub2","EmailAddress": "tgreen+2@springcm.com"}],"DocumentName": "ServiceDoc2.docx"},"Action": "ApprovalCheckout", "ActionType":"ApprovalCheckout", "Comment": "Via Approval","User": {"FirstName": "","LastName": "Workflow"},"CreatedDate": "2019-03-25T18:11:00.3609545Z"}, {"Data": {"__legacyMessage": "","DocumentName": "ServiceDoc2.docx","DocumentUid": "40720a56-294f-e911-92dc-309c23cb2dc0","ContentVersionId": "0681U000001yYfQQAU","Actor": {"FullName": "Full Sub","EmailAddress": "tgreen+1@springcm.com"}},"UserEmail": "tgreen+1@springcm.com","Action": "DocumentImportFromSalesforce", "ActionType" :"DocumentImportFromSalesforce","Comment": "Document was downloaded from Salesforce.","User": {"UserName": "tgreen+1@springcm.com","Email": "tgreen+1@springcm.com","FirstName": "Full","LastName": "Sub","Href": "https://apilocalhost/v1/users/tgreen%2B1%40springcm.com"},"CreatedDate": "2019-03-25T18:10:58.6339427Z"}],"Href": "https://apilocalhost/v1/historyitems/40720a56-294f-e911-92dc-309c23cb2dc0","Offset": 0,"Limit": 20,"First": "https://apilocalhost/v1/historyitems/40720a56-294f-e911-92dc-309c23cb2dc0","Last": "https://apilocalhost/v1/historyitems/40720a56-294f-e911-92dc-309c23cb2dc0","Total": 4}');
				} else if (request.path.contains(String.valueOf(ScmAPIMock.DOCUMENT_ID_6))) {
					response = MockResponse.ok('{"Items": [{"Data": {"__legacyMessage": "Agreement_2fa1c4de-04b9-4fac-8413-5ea15f92aca1.docx have been sent for External Review to someguy+externalReviewRecipient@springcm.com and the review is due on 4/24/2019.","DocumentName": "Agreement_2fa1c4de-04b9-4fac-8413-5ea15f92aca1.docx","DueDate": "2019-04-24T00:00:00","EmailSubject": "For external review","EmailMessage": "Please review the document","Actor": {"FullName": "Tyler Green","EmailAddress": "tgreen+packageb@springcm.com"},"Reviewer": {"FullName": "John Doe","EmailAddress": "someguy+externalReviewRecipient@springcm.com"}},"UserEmail": "tgreen+packageb@springcm.com","Action": "ExternalReviewInitiated", "ActionType":"ExternalReviewInitiated", "MoreInfo": "Agreement_2fa1c4de-04b9-4fac-8413-5ea15f92aca1.docx have been sent for External Review to someguy+externalReviewRecipient@springcm.com and the review is due on 4/24/2019.","Comment": "","User": {"UserName": "tgreen+packageb@springcm.com","Email": "tgreen+packageb@springcm.com","FirstName": "Tyler","LastName": "Green","Href": "https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate": "2019-03-25T18:13:28.2149908Z"}, {"Data": {"__legacyMessage": "","DocumentName": "Agreement_2fa1c4de-04b9-4fac-8413-5ea15f92aca1.docx","DocumentUid": "bfa512ae-294f-e911-92dc-309c23cb2dc0","ContentVersionId": "0681U000001yYfQQAU","Actor": {"FullName": "Tyler Green","EmailAddress": "tgreen+packageb@springcm.com"}},"UserEmail": "tgreen+packageb@springcm.com","Action": "DocumentImportFromSalesforce", "ActionType":"DocumentImportFromSalesforce", "Comment": "Document was downloaded from Salesforce.","User": {"UserName": "tgreen+packageb@springcm.com","Email": "tgreen+packageb@springcm.com","FirstName": "Tyler","LastName": "Green","Href": "https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate": "2019-03-25T18:13:26.3391945Z"}],"Href": "https://apilocalhost/v1/historyitems/bfa512ae-294f-e911-92dc-309c23cb2dc0","Offset": 0,"Limit": 20,"First": "https://apilocalhost/v1/historyitems/bfa512ae-294f-e911-92dc-309c23cb2dc0","Last": "https://apilocalhost/v1/historyitems/bfa512ae-294f-e911-92dc-309c23cb2dc0","Total": 2}');
				} else if (request.path.contains(String.valueOf(ScmAPIMock.DOCUMENT_ID_5))) {
					response = MockResponse.ok('{"Items":[{"Data":{"__legacyMessage":"","EmailSubject":"For approval","EmailMessage":"Please approve the documents","Actor":{"FullName":"Tyler Green","EmailAddress":"tgreen+packageb@springcm.com"},"Approvers":[{"FullName":"Full Sub","EmailAddress":"tgreen+1@springcm.com"}],"DocumentName":"Agreement_bd4b0631-7812-4125-84ab-be40c4fa6cae.docx"},"Action":"ApprovalCheckout", "ActionType":"ApprovalCheckout","Comment":"Via Approval","User":{"FirstName":"","LastName":"Workflow"},"CreatedDate":"2019-03-25T18:10:02.4241543Z"},{"Data":{"__legacyMessage":"","DocumentName":"Agreement_bd4b0631-7812-4125-84ab-be40c4fa6cae.docx","DocumentUid":"ee1c5333-294f-e911-92dc-309c23cb2dc0","ContentVersionId":"0681U000001yYfQQAU","Actor":{"FullName":"Tyler Green","EmailAddress":"tgreen+packageb@springcm.com"}},"UserEmail":"tgreen+packageb@springcm.com","Action":"DocumentImportFromSalesforce", "ActionType":"DocumentImportFromSalesforce","Comment":"Document was downloaded from Salesforce.","User":{"UserName":"tgreen+packageb@springcm.com","Email":"tgreen+packageb@springcm.com","FirstName":"Tyler","LastName":"Green","Href":"https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate":"2019-03-25T18:10:00.4255309Z"}],"Href":"https://apilocalhost/v1/historyitems/ee1c5333-294f-e911-92dc-309c23cb2dc0","Offset":0,"Limit":20,"First":"https://apilocalhost/v1/historyitems/ee1c5333-294f-e911-92dc-309c23cb2dc0","Last":"https://apilocalhost/v1/historyitems/ee1c5333-294f-e911-92dc-309c23cb2dc0","Total":2}');
				} else if (request.path.contains(String.valueOf(ScmAPIMock.DOCUMENT_ID_4))) {
					response = MockResponse.ok('{"Items":[{"Data":{"__legacyMessage":"Agreement_e6fbb33f-6362-41da-93b6-1937c3be8763.docx","DocumentName":"Updated Agreement Name_446961c6-8ca9-40b0-80d9-595308bfa6e7.docx","DocumentOldName":"Agreement_e6fbb33f-6362-41da-93b6-1937c3be8763.docx","DocumentUid":"8ab00ad9-284f-e911-92dc-309c23cb2dc0","Actor":{"FullName":"Tyler Green","EmailAddress":"tgreen+packageb@springcm.com"}},"UserEmail":"tgreen+packageb@springcm.com","Action":"TitleChanged", "ActionType":"TitleChanged","MoreInfo":"File name changed from: Agreement_e6fbb33f-6362-41da-93b6-1937c3be8763.docx","Comment":"","User":{"UserName":"tgreen+packageb@springcm.com","Email":"tgreen+packageb@springcm.com","FirstName":"Tyler","LastName":"Green","Href":"https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate":"2019-03-25T18:07:35.3572857Z"},{"Data":{"__legacyMessage":"","DocumentName":"Agreement_e6fbb33f-6362-41da-93b6-1937c3be8763.docx","DocumentUid":"8ab00ad9-284f-e911-92dc-309c23cb2dc0","ContentVersionId":"0681U000001yYfQQAU","Actor":{"FullName":"Tyler Green","EmailAddress":"tgreen+packageb@springcm.com"}},"UserEmail":"tgreen+packageb@springcm.com","Action":"DocumentImportFromSalesforce", "ActionType":"DocumentImportFromSalesforce", "Comment":"Document was downloaded from Salesforce.","User":{"UserName":"tgreen+packageb@springcm.com","Email":"tgreen+packageb@springcm.com","FirstName":"Tyler","LastName":"Green","Href":"https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate":"2019-03-25T18:07:33.5802991Z"}],"Href":"https://apilocalhost/v1/historyitems/8ab00ad9-284f-e911-92dc-309c23cb2dc0","Offset":0,"Limit":20,"First":"https://apilocalhost/v1/historyitems/8ab00ad9-284f-e911-92dc-309c23cb2dc0","Last":"https://apilocalhost/v1/historyitems/8ab00ad9-284f-e911-92dc-309c23cb2dc0","Total":2}');
				} else if (request.path.contains(String.valueOf(ScmAPIMock.DOCUMENT_ID_7))) {
					response = MockResponse.ok('{"Items": [{"Data": {"__legacyMessage": "Agreement_2fa1c4de-04b9-4fac-8413-5ea15f92aca1.docx have been sent for External Review to someguy+externalReviewRecipient@springcm.com and the review is due on 4/24/2019.","DocumentName": "ServiceDoc1.docx","DueDate": "2019-04-24T00:00:00","EmailSubject": "For external review","EmailMessage": "Please review the document","Actor": {"FullName": "Tyler Green","EmailAddress": "tgreen+packageb@springcm.com"},"Reviewer": {"FullName": "John Doe","EmailAddress": "someguy+externalReviewRecipient@springcm.com"}},"UserEmail": "tgreen+packageb@springcm.com","Action": "ExternalReviewCompletedDocumentAndComments", "ActionType": "ExternalReviewCompletedDocumentAndComments", "MoreInfo": "Agreement_2fa1c4de-04b9-4fac-8413-5ea15f92aca1.docx have been sent for External Review to someguy+externalReviewRecipient@springcm.com and the review is due on 4/24/2019.","Comment": "","User": {"UserName": "tgreen+packageb@springcm.com","Email": "tgreen+packageb@springcm.com","FirstName": "Tyler","LastName": "Green","Href": "https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate": "2019-05-25T18:13:28.2149908Z"}, {"Data": {"__legacyMessage": "","DocumentName": "ServiceDoc1.docx","DocumentUid": "bfa512ae-294f-e911-92dc-309c23cb2dc0","ContentVersionId": "0681U000001yYfQQAU","Actor": {"FullName": "Tyler Green","EmailAddress": "tgreen+packageb@springcm.com"}},"UserEmail": "tgreen+packageb@springcm.com","Action": "DocumentImportFromSalesforce", "ActionType": "DocumentImportFromSalesforce","Comment": "Document was downloaded from Salesforce.","User": {"UserName": "tgreen+packageb@springcm.com","Email": "tgreen+packageb@springcm.com","FirstName": "Tyler","LastName": "Green","Href": "https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate": "2019-05-23T18:13:26.3391945Z"}],"Href": "https://apilocalhost/v1/historyitems/bfa512ae-294f-e911-92dc-309c23cb2dc0","Offset": 0,"Limit": 20,"First": "https://apilocalhost/v1/historyitems/bfa512ae-294f-e911-92dc-309c23cb2dc0","Last": "https://apilocalhost/v1/historyitems/bfa512ae-294f-e911-92dc-309c23cb2dc0","Total": 2}');
				} else if (request.path.contains(String.valueOf(ScmAPIMock.DOCUMENT_ID_8))) {
					response = MockResponse.ok('{"Items": [{"Data": {"__legacyMessage":"User choice completed with: Approved","__legacyHistoryWorkflowInstanceUid":"g1f5ba45-9a17-da11-c876-48df378a9c69","Comments":"approving on behalf of user one (non admin)","Result":"Approved","Actor":{"FullName":"Estelle Bright","EmailAddress":"estelle.bright@liberl.com"},"Approvers":[{"FullName":"Joshua Bright","EmailAddress":"joshua.bright@liberl.com"}]},"ActionType":"CompletedHumanActivity","Action":"Completed Human Activity","MoreInfo":"User choice completed with: Approved","Comment":"Workflow: Negotiate_Approval_Template Action: Approve 2","User":{"FirstName":"","LastName":"Workflow"},"CreatedDate":"2019-12-05T20:34:41.6106296Z"}]}');
				} else {
					response = MockResponse.ok('{"Items":[{"Data":{"__legacyMessage":"","DocumentName":"Agreement_7d50807b-0a38-4c8a-86dd-0c1e335d3e2e.docx","DocumentUid":"12d96fc8-284f-e911-92dc-309c23cb2dc0","ContentVersionId":"0681U000001yYfQQAU","Actor":{"FullName":"Tyler Green","EmailAddress":"tgreen+packageb@springcm.com"}},"UserEmail":"tgreen+packageb@springcm.com","Action":"DocumentImportFromSalesforce","ActionType":"DocumentImportFromSalesforce","Comment":"Document was downloaded from Salesforce.","User":{"UserName":"tgreen+packageb@springcm.com","Email":"tgreen+packageb@springcm.com","FirstName":"Tyler","LastName":"Green","Href":"https://apilocalhost/v1/users/tgreen%2Bpackageb%40springcm.com"},"CreatedDate":"2019-03-25T18:07:01.150201Z"}],"Href":"https://apilocalhost/v1/historyitems/12d96fc8-284f-e911-92dc-309c23cb2dc0","Offset":0,"Limit":20,"First":"https://apilocalhost/v1/historyitems/12d96fc8-284f-e911-92dc-309c23cb2dc0","Last":"https://apilocalhost/v1/historyitems/12d96fc8-284f-e911-92dc-309c23cb2dc0","Total":1}');
				}
			}
			return response;
		}
	}

	public class MergeMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'POST') {
				response = MockResponse.created('{"Href":"https://unit.test/gen/' + UUID.randomUUID() + '"}');
			} else if (request.method == 'GET') {
				// Return last modified ContentVersion.Id. No good way to mock this without mixing in test code.
				ContentVersion cv = (ContentVersion)Collection.head([SELECT Id FROM ContentVersion ORDER BY LastModifiedDate DESC LIMIT 1]);
				Id cvId = cv == null ? null : cv.Id;
				response = MockResponse.ok('{"SfContentVersionId":' + JSON.serialize(cvId) + ',"Status":"Success","Message":"Test success message"}');
			}
			return response;
		}
	}

	public class ResourceTokensMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'POST') {
				Map<String, Object> req = (Map<String, Object>)JSON.deserializeUntyped(request.body);
				response = MockResponse.created('{"secret_uri":"https://unit.test/gen/' + req.get('objectid') + '"}');
			}
			return response;
		}
	}

	public class TokensMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'POST') {
				ScmTokenAPI.APILimitedAccessToken tok = new ScmTokenAPI.APILimitedAccessToken();
				tok.accessToken = UUID.randomUUID().toString();
				tok.APIBaseUrl = 'https://api.test.springcm.com';
				tok.APIUploadBaseUrl = 'https://api.test.springcm.com/upload';
				tok.APIDownloadBaseUrl = 'https://api.test.springcm.com/download';
				response = MockResponse.created(tok);
			}
			return response;
		}
	}

	public class WorkflowMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				if (request.path.contains(String.valueOf(TASK_ID_3))) {
					response = MockResponse.ok('{"Name":"Negotiate_ExternalReview_Template","StartDate":"2019-05-06T20:49:24.577Z","Status":"Failed","Info":"","Href":"https://apiqana11.springcm.com/v2/ee3907fb-baa7-41d4-b9a5-52756b323607/workflows/4cf1f36a-4070-e911-8395-005056b946c2"}');
				} else if (request.path.contains(String.valueOf(TASK_ID_2))) {
					response = MockResponse.ok('{"Name":"Negotiate_ExternalReview_Template","StartDate":"2019-05-06T20:49:24.577Z","Status":"Executing","Info":"","Href":"https://apiqana11.springcm.com/v2/ee3907fb-baa7-41d4-b9a5-52756b323607/workflows/4cf1f36a-4070-e911-8395-005056b946c2"}');
				} else {
					response = MockResponse.ok('{"Name":"Negotiate_ExternalReview_Template","StartDate":"2019-05-06T20:49:24.577Z","Status":"Waiting","Info":"","Href":"https://apiqana11.springcm.com/v2/ee3907fb-baa7-41d4-b9a5-52756b323607/workflows/4cf1f36a-4070-e911-8395-005056b946c2"}');
				}
			} else if (request.method == 'POST') {
				if (request.body.contains(String.valueOf(DOCUMENT_ID))) {
					response = MockResponse.created('{"Name":"Negotiate_ExternalReview_Template","StartDate":"2019-05-06T20:49:24.577Z","Status":"Executing","Info":"","Href":"https://apiqana11.springcm.com/v2/ee3907fb-baa7-41d4-b9a5-52756b323607/workflows/' + TASK_ID_2 + '"}');
				} else if (request.body.contains(String.valueOf(DOCUMENT_ID_2))) {
					response = MockResponse.created('{"Name":"Negotiate_ExternalReview_Template","StartDate":"2019-05-06T20:49:24.577Z","Status":"Executing","Info":"","Href":"https://apiqana11.springcm.com/v2/ee3907fb-baa7-41d4-b9a5-52756b323607/workflows/' + TASK_ID_3 + '"}');
				} else {
					response = MockResponse.created('{"Name":"Negotiate_ExternalReview_Template","StartDate":"2019-05-06T20:49:24.577Z","Status":"Executing","Info":"","Href":"https://apiqana11.springcm.com/v2/ee3907fb-baa7-41d4-b9a5-52756b323607/workflows/4cf1f36a-4070-e911-8395-005056b946c2"}');
				}
			}
			return response;
		}
	}

	public class ImportMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				if (request.path.contains(String.valueOf(ScmAPIMock.TASK_ID_2))) {
					response = MockResponse.ok('{"Document":{"Href":"https://apiuatna11.springcm.com/v201411/documents/51962d1b-5468-e911-9c20-3ca82a1e3f41"},"Message":"ContentDocument Processing","Status":"Processing","Href":"https://apiuatna11.springcm.com/v201411/salesforcecontentdocumentimporttasks/33c0648a-7bb5-4f34-aef8-9994362ce0ae"}');
				} else {
					response = MockResponse.ok('{"Document":{"Href":"https://apiuatna11.springcm.com/v201411/documents/51962d1b-5468-e911-9c20-3ca82a1e3f41"},"Message":"ContentDocumentimportedsuccessfully","Status":"Success","Href":"https://apiuatna11.springcm.com/v201411/salesforcecontentdocumentimporttasks/33c0648a-7bb5-4f34-aef8-9994362ce0ae"}');
				}
			} else if (request.method == 'POST') {
				response = MockResponse.created('{"Status": "Processing","Href": "https://apiuatna11.springcm.com/v201411/salesforcecontentdocumentimporttasks/4682d399-29fe-4085-9e48-126e4ffa0566"}');
			}
			return response;
		}
	}

	public class ExportMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				if (request.path.contains(String.valueOf(ScmAPIMock.TASK_ID_2))) {
					response = MockResponse.ok('{"Message":"Document Export Processing","Status":"Processing","Href":"https://apiuatna11.springcm.com/v2/salesforcecontentdocumentexporttasks/33c0648a-7bb5-4f34-aef8-9994362ce0ae"}');
				} else {
					response = MockResponse.ok('{"SfContentVersionId":"06817000000TrbmAAC","Message":"Document exported successfully","Status":"Success","Href":"https://apiuatna11.springcm.com/v2/salesforcecontentdocumentexporttasks/33c0648a-7bb5-4f34-aef8-9994362ce0ae"}');
				}
			} else if (request.method == 'POST') {
				response = MockResponse.created('{"Status": "Processing","Href": "https://apiuatna11.springcm.com/v2/salesforcecontentdocumentexporttasks/4682d399-29fe-4085-9e48-126e4ffa0566"}');
			}
			return response;
		}
	}

	public class CompareMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				response = MockResponse.ok('{"Status":"Success","Href":"https://apiqana11.springcm.com/v2/013fc30e-f6ca-464e-a97c-e4765dbad495/documentcompareapitasks/233d8ee7-1135-4d63-9163-c532c4e2571a"}');
			} else if (request.method == 'POST') {
				response = MockResponse.created('{"Status":"Success","Href":"https://apiqana11.springcm.com/v2/013fc30e-f6ca-464e-a97c-e4765dbad495/documentcompareapitasks/233d8ee7-1135-4d63-9163-c532c4e2571a"}');
			}
			return response;
		}
	}

	public class ReviewMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'PUT') {
				response = MockResponse.ok('{"Sender":{"Href":"https://apilocalhost/v2/681cde0b-5a84-455a-b2df-1e7ffe790003/members/0a8823c8-3147-e911-b323-309c23cb2ea4"},"Documents":{"Items":[{"Href":"https://apilocalhost/v2/681cde0b-5a84-455a-b2df-1e7ffe790003/documents/625a04ad-2882-e911-b333-309c23cb2ea4"}],"Offset":0,"Limit":20,"Total":1},"Recipient":{"Name":"","Email":"kevin.test.docusign@gmail.com"},"Status":"Complete","DueDate":"2019-06-28T05:00:00Z","EmailMessage":"Pleasereviewthedocument","EmailSubject":"YourreviewisneededforAgreement_Document.docx","Comment":"Completed","AlsoNotify":[],"AddSignature":false,"HideDueDateFromEmail":false,"EmailAppearance":0,"CreatedDate":"2019-05-29T15:44:47.753Z","Href":"https://apilocalhost/v2/681cde0b-5a84-455a-b2df-1e7ffe790003/externalreviews/6e5a04ad-2882-e911-b333-309c23cb2ea4"}');
			}
			return response;
		}
	}

	public class WorkItemMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				if (request.path.contains(String.valueOf(ScmAPIMock.DOCUMENT_ID))) {
					response = MockResponse.ok('{"Items":[{"Name":"Approve1","Type":"ApproveDocuments","Assignee":{"FirstName":"John","LastName":"Doe","Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/users/45b693e8-3b65-e911-9c20-3ca82a1e3f41"},"AssignDate":"2019-05-01T19:04:19.587Z","Documents":{"Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/workitems/3ef321ec-436c-e911-8391-005056b948f7/documents"},"Workflow":{"Name":"Negotiate_Approval_Template","Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/workflows/ef01c0e5-436c-e911-8391-005056b948f7"},"CreatedDate":"2019-05-01T19:04:24.027Z","WorkItemUrl":"https://uatna11.springcm.com/atlas/Documents/Preview.aspx?aid=10737&wfid=3ef321ec-436c-e911-8391-005056b948f7&iter=","Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/workitems/3ef321ec-436c-e911-8391-005056b948f7"},{"Name":"Approve2","Type":"ApproveDocuments","Assignee":{"FirstName":"Jane","LastName":"Doe","Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/users/45b693e8-3b65-e911-9c20-3ca82a1e3f41"},"AssignDate":"2019-05-01T19:04:19.587Z","Documents":{"Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/workitems/3ef321ec-436c-e911-8391-005056b948f7/documents"},"Workflow":{"Name":"Negotiate_Approval_Template","Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/workflows/ef01c0e5-436c-e911-8391-005056b948f7"},"CreatedDate":"2019-05-01T19:04:24.027Z","WorkItemUrl":"https://uatna11.springcm.com/atlas/Documents/Preview.aspx?aid=10737&wfid=3ef321ec-436c-e911-8391-005056b948f7&iter=","Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/workitems/3ef321ec-436c-e911-8391-005056b948f7"}],"Href":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/documents/06ec39af-7268-e911-9c20-3ca82a1e3f41/workitems","Offset":0,"Limit":20,"First":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/documents/06ec39af-7268-e911-9c20-3ca82a1e3f41/workitems","Last":"https://apiuatna11.springcm.com/v2/4d468452-6aaf-4d6f-b058-c3ea47c806bf/documents/06ec39af-7268-e911-9c20-3ca82a1e3f41/workitems","Total":1}');
				}
			} else if (request.method == 'PUT') {
				response = MockResponse.ok('{"Name":"Approve1","Type":"ApproveDocuments","Assignee":{"Href":"https://apilocalhost/v2/681cde0b-5a84-455a-b2df-1e7ffe790003/members/8f6c7260-e34c-e911-b324-309c23cb2ea4"},"AssignDate":"2019-05-29T15:36:33.65Z","Documents":{"Href":"https://apilocalhost/v2/681cde0b-5a84-455a-b2df-1e7ffe790003/workitems/52309483-2782-e911-b333-309c23cb2ea4/documents"},"Workflow":{"Name":"Negotiate_Approval_Template","Href":"https://apilocalhost/v2/681cde0b-5a84-455a-b2df-1e7ffe790003/workflows/2f309483-2782-e911-b333-309c23cb2ea4"},"CreatedDate":"2019-05-29T15:36:33.65Z","WorkItemUrl":"https://localhost/atlas/Documents/Preview.aspx?aid=30581986&wfid=52309483-2782-e911-b333-309c23cb2ea4&iter=","Href":"https://apilocalhost/v2/681cde0b-5a84-455a-b2df-1e7ffe790003/workitems/52309483-2782-e911-b333-309c23cb2ea4"}');
			}
			return response;
		}
	}

	public class DocumentMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				if (request.path.contains('versions')) {
					response = MockResponse.ok('{"Items":[{"Name":"newName.docx","CreatedDate":"2019-03-14T19:24:52.69Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-14T19:24:52.69Z","UpdatedBy":"pratik.hatkar@docusign.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":7,"Version":"3.0","PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=213e9c1a-8f46-e911-9c1d-3ca82a1e3f41","ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41","NativeFileSize":16808,"PdfFileSize":178269,"Href":"https://apiuatna11.springcm.com/v201411/documents/213e9c1a-8f46-e911-9c1d-3ca82a1e3f41"},{"Name":"newName.docx","CreatedDate":"2019-03-14T19:24:04.233Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-14T19:24:04.233Z","UpdatedBy":"pratik.hatkar@docusign.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":7,"Version":"2.0","PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41","ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41","NativeFileSize":16808,"PdfFileSize":178269,"Href":"https://apiuatna11.springcm.com/v201411/documents/b56b1cd6-8e46-e911-9c1d-3ca82a1e3f41"},{"Name":"newName.docx","CreatedDate":"2019-03-08T21:35:08.97Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-14T19:14:39.68Z","UpdatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":5,"Version":"1.0","PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=996e80b6-8e46-e911-9c1d-3ca82a1e3f41","ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41","NativeFileSize":20557,"PdfFileSize":160453,"Href":"https://apiuatna11.springcm.com/v201411/documents/996e80b6-8e46-e911-9c1d-3ca82a1e3f41"}],"Href":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/Versions","Offset":0,"Limit":20,"First":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/Versions","Last":"https://apiuatna11.springcm.com/v201411/documents/ea7ab407-ea41-e911-9c1d-3ca82a1e3f41/Versions","Total":3}');
				} else if (request.path.contains('reviews')) {
					response = MockResponse.ok('{"Sender":{"Href":"https://apiqana11.springcm.com/v2/41554d72-28fd-477f-9dd9-7701c4e750b5/members/e0faebab-b56a-e911-8398-005056b97c7d"},"Documents":{"Items":[{"Href":"https://apiqana11.springcm.com/v2/41554d72-28fd-477f-9dd9-7701c4e750b5/documents/acb1e384-4886-e911-9c35-3863bb335c17"}],"Offset":0,"Limit":20,"Total":1},"Recipient":{"Name":"SamCicero","Email":"sam.cicero@docusign.com"},"Status":"Sent","DueDate":"2019-08-23T05:00:00Z","EmailMessage":"<p>Pleasereview</p>","EmailSubject":"Review-Document","AlsoNotify":[],"AddSignature":true,"HideDueDateFromEmail":false,"EmailAppearance":0,"CreatedDate":"2019-06-04T19:48:09.603Z","Href":"https://apiqana11.springcm.com/v2/41554d72-28fd-477f-9dd9-7701c4e750b5/externalreviews/2a2167ad-0187-e911-9c35-3863bb335c17"}');
				} else if (request.path.contains(String.valueOf(ScmAPIMock.APPROVAL_DOCUMENT_ID))) {
					response = MockResponse.ok('{"Items":[{"Name":"Approve 2","Type":"Approve Documents","Assignee":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/f3964a8e-cc7c-e911-9c20-3ca82a1e3f41"},"AssignDate":"2019-06-17T23:46:43.073Z","Documents":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/workitems/181f4326-5a91-e911-83a4-005056b948f7/documents"},"Workflow":{"Name":"Negotiate_Approval_Template","Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/workflows/f41e4326-5a91-e911-83a4-005056b948f7"},"CreatedDate":"2019-06-17T23:46:42.7Z","WorkItemUrl":"https://uatna11.springcm.com/atlas/Documents/Preview.aspx?aid=10925&wfid=181f4326-5a91-e911-83a4-005056b948f7&iter=","Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/workitems/181f4326-5a91-e911-83a4-005056b948f7"},{"Name":"Approve 2","Type":"Approve Documents","Assignee":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/d46c25be-5390-e911-9c25-3ca82a1e3f41"},"AssignDate":"2019-06-17T23:46:42.853Z","Documents":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/workitems/161f4326-5a91-e911-83a4-005056b948f7/documents"},"Workflow":{"Name":"Negotiate_Approval_Template","Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/workflows/f41e4326-5a91-e911-83a4-005056b948f7"},"CreatedDate":"2019-06-17T23:46:42.48Z","WorkItemUrl":"https://uatna11.springcm.com/atlas/Documents/Preview.aspx?aid=10925&wfid=161f4326-5a91-e911-83a4-005056b948f7&iter=","Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/workitems/161f4326-5a91-e911-83a4-005056b948f7"}],"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/documents/f39a00f9-5991-e911-9c25-3ca82a1e3f41/workitems","Offset":0,"Limit":20,"First":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/documents/f39a00f9-5991-e911-9c25-3ca82a1e3f41/workitems","Last":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/documents/f39a00f9-5991-e911-9c25-3ca82a1e3f41/workitems","Total":2}');
				} else if (request.path.contains(String.valueOf(DOCUMENT_ID_2))) {
					response = MockResponse.ok('{"Name":"ServiceDoc1.docx","CreatedDate":"2019-02-21T20:58:27.637Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-13T19:26:01.787Z","UpdatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/df5300b4-6135-e911-9c1d-3ca82a1e3f41"},"HistoryItems":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/historyitems"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":5,"Lock":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/lock"},"PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=382bd222-1536-e911-9c1d-3ca82a1e3f41","Versions":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/versions"},"ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41","NativeFileSize":16897,"PdfFileSize":160568,"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e922-9c1d-3ca82a1e3f41"}');
				} else if (request.path.contains(String.valueOf(FOLDER_ID_2))) {
					response = MockResponse.ok('{"Items": [{"Name": "ServiceDoc1.docx","CreatedDate": "2019-03-08T21:35:08.97Z","Href": "https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e922-9c1d-3ca82a1e3f41"},{"Name": "ServiceDoc2.docx","CreatedDate": "2019-04-08T21:35:08.97Z","Href": "https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e933-9c1d-3ca82a1e3f41"}],"Href": "https://apiuatna11.springcm.com/v201411/folders/56322efe-e541-e911-9c1d-3ca82a1e3f41/documents","Offset": 0,"Limit": 20,"First": "https://apiuatna11.springcm.com/v201411/folders/22222efe-e541-e911-9c1d-3ca82a1e3f41/documents","Last": "https://apiuatna11.springcm.com/v201411/folders/22222efe-e541-e911-9c1d-3ca82a1e3f41/documents","Total": 2}');
				}
			} else if (request.method == 'PUT') {
				response = MockResponse.ok('{"Name":"docuTestRename.docx","CreatedDate":"2019-02-21T20:58:27.637Z","CreatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","UpdatedDate":"2019-03-13T19:26:01.787Z","UpdatedBy":"raguayo+pratikhatkar_apiuser@springcm.com","Description":"","ParentFolder":{"Href":"https://apiuatna11.springcm.com/v201411/folders/df5300b4-6135-e911-9c1d-3ca82a1e3f41"},"HistoryItems":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/historyitems"},"AccessLevel":{"See":true,"Read":true,"Write":true,"Move":true,"Create":true,"SetAccess":true},"PageCount":5,"Lock":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/lock"},"PreviewUrl":"https://uatna11.springcm.com/atlas/documents/preview.aspx?aid=10250&lduid=382bd222-1536-e911-9c1d-3ca82a1e3f41","Versions":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/versions"},"ShareLinks":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/sharelinks"},"DocumentProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/documentprocesstrackingactivities"},"DocumentReminders":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/documentreminders"},"RelatedDocuments":{"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41/relateddocuments"},"DownloadDocumentHref":"https://apidownloaduatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41","NativeFileSize":16897,"PdfFileSize":160568,"Href":"https://apiuatna11.springcm.com/v201411/documents/382bd222-1536-e911-9c1d-3ca82a1e3f41"}');
			} else if (request.method == 'DELETE') {
				response = MockResponse.ok(null); // Empty body
			}
			return response;
		}
	}

	public class MemberMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				if (request.path.contains(String.valueOf(APPROVER_USER_1))) {
					response = MockResponse.ok('{"Email":"unifiedappjunedemo@dsxtr.com","FirstName":"UnifiedApp","LastName":"JuneDemo","WorkItems":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/f3964a8e-cc7c-e911-9c20-3ca82a1e3f41/workitems"},"RecentDocuments":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/current/recentdocuments"},"WatchedDocumentsProcessTrackingActivities":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/current/watcheddocumentsprocesstrackingactivities"},"WorkflowQueues":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/f3964a8e-cc7c-e911-9c20-3ca82a1e3f41/workflowqueues"},"Role":"SuperAdministrator","PermissionSets":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/f3964a8e-cc7c-e911-9c20-3ca82a1e3f41/permissionsets"},"WatchedDocuments":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/current/watcheddocuments"},"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/f3964a8e-cc7c-e911-9c20-3ca82a1e3f41"}');
				} else if (request.path.contains(String.valueOf(APPROVER_USER_2))) {
					response = MockResponse.ok('{"Email":"unifiedappjunedemouser@dsxtr.com","FirstName":"UA","LastName":"JuneDemo","WorkItems":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/d46c25be-5390-e911-9c25-3ca82a1e3f41/workitems"},"Role":"FullSubscriber","PermissionSets":{"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/d46c25be-5390-e911-9c25-3ca82a1e3f41/permissionsets"},"Href":"https://apiuatna11.springcm.com/v2/deaa63f0-1bb0-48e4-9bb3-e6ddbcd7bd71/members/d46c25be-5390-e911-9c25-3ca82a1e3f41"}');
				}
			}
			return response;
		}
	}

	public class ChangeSecurityTask implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'POST') {
				response = MockResponse.accepted('{"Status" : "Waiting","Security" : {"Roles" : [{"Item" : "FullSubscriber","AccessType" : "ViewEditDelete"}]},"Folder" : {"Href" : "https://apiuatna11.springcm.com/v2/645e10db-edb7-4e3b-a4a7-cbc55cab3905/folders/8de35d6a-20e6-e911-9c2b-3ca82a1e3f41"},"Href" : "https://apiuatna11.springcm.com/v2/645e10db-edb7-4e3b-a4a7-cbc55cab3905/changesecuritytasks/a345e77d-b3bf-4541-be31-3e9c36861e6a}');
			}
			return response;
		}
	}

	public class ConvertDocumentMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'POST') {
				response = MockResponse.ok('{"Status" : "Success", "Message":""}');
			}
			return response;
		}
	}

	private MockResource getMock(final String resource) {
		if (MOCKS.containsKey(resource)) return MOCKS.get(resource);

		String mockType = MOCK_TYPES.get(resource);
		if (String.isBlank(mockType)) throw new AssertException('Unexpected API resource to mock: ' + resource);

		MockResource mock = (MockResource)Type.forName(mockType).newInstance();
		MOCKS.put(resource, mock);

		return mock;
	}

	private MockResponse getError(final String resource) {
		return MockResponse.badRequest('{"Error":{"HttpStatusCode":400,"UserMessage":"Test user message","DeveloperMessage":"Test developer message","ErrorCode":1234,"ReferenceId":"' + UUID.randomUUID() + '"}}');
	}

	override public HttpResponse getResponse(final HttpRequest request) {
		MockRequest req = parseRequest(request);
		MockResponse resp = this.success
			? getMock(req.resource).respond(req)
			: getError(req.resource);
		if (resp == null) {
			resp = MockResponse.notImplemented(req.method, req.resource);
		}

		HttpResponse response = new HttpResponse();
		response.setStatusCode(resp.statusCode);
		response.setStatus(resp.status);
		response.setHeader('Content-Type', resp.contentType);
		response.setBody(resp.body);

		return response;
	}

	override public HttpResponse respond(final HttpRequest request) {
		return super.respond(request);
	}

	public static ScmAPIMock success() {
		return (ScmAPIMock)TestUtils.setMock(new ScmAPIMock(true));
	}

	public static ScmAPIMock failure() {
		return (ScmAPIMock)TestUtils.setMock(new ScmAPIMock(false));
	}
}
