/**
 * Test mock for the DocuSign eSignature REST API. Numerous service methods result in a callout to DocuSign, so
 * the web service API must be mocked.
 * <p>
 * Service methods also require a user with the DocuSign Administrator or DocuSign User permission set as well as a
 * DocuSign test account configuration. The <code>dfsle.UserMock.createDocuSignAdministrator</code> and
 * <code>dfsle.UserMock.createDocuSignUser</code> test helper methods are typically used in conjunction with the web
 * service API mock to accomplish this.
 *
 * Example:
 * <pre>
 * static testMethod void myTest() {
 *   dfsle.ESignatureAPIMock().success();
 *   System.runAs(dfsle.UserMock.createDocuSignUser()) {
 *     // Call DocuSign service methods
 *   }
 * }
 * </pre>
 */
@IsTest
global class ESignatureAPIMock extends OAuthTokenMock implements HttpCalloutMock {

	private static final Map<String, String> MOCK_TYPES = new Map<String, String> {
		'accounts' => Application.classNamespacePrefix + 'ESignatureAPIMock.AccountsMock',
		'billing_plan' => Application.classNamespacePrefix + 'ESignatureAPIMock.BillingPlanMock',
		'bulk_envelopes' => Application.classNamespacePrefix + 'ESignatureAPIMock.BulkEnvelopesMock',
		'bulk_send_lists' => Application.classNamespacePrefix + 'ESignatureAPIMock.BulkSendListsMock',
		'custom_fields' => Application.classNamespacePrefix + 'ESignatureAPIMock.CustomFieldsMock',
		'envelopes' => Application.classNamespacePrefix + 'ESignatureAPIMock.EnvelopesMock',
		'folders' => Application.classNamespacePrefix + 'ESignatureAPIMock.FoldersMock',
		'permission_profiles' => Application.classNamespacePrefix + 'ESignatureAPIMock.PermissionProfilesMock',
		'service_information' => Application.classNamespacePrefix + 'ESignatureAPIMock.ServiceInformationMock',
		'settings' => Application.classNamespacePrefix + 'ESignatureAPIMock.SettingsMock',
		'signing_groups' => Application.classNamespacePrefix + 'ESignatureAPIMock.SigningGroupsMock',
		'tab_definitions' => Application.classNamespacePrefix + 'ESignatureAPIMock.TabDefinitionsMock',
		'tab_definitions' => Application.classNamespacePrefix + 'ESignatureAPIMock.TabDefinitionsMock',
		'templates' => Application.classNamespacePrefix + 'ESignatureAPIMock.TemplatesMock',
		'documents' => Application.classNamespacePrefix + 'ESignatureAPIMock.DocumentsUpdateMock',
		'users' => Application.classNamespacePrefix + 'ESignatureAPIMock.UsersMock',
		'views' => Application.classNamespacePrefix + 'ESignatureAPIMock.ViewsMock'
	};
	private static final Map<String, MockResource> MOCKS = new Map<String, MockResource>();

	// Capture group 1 = API version, group 2 = account ID, group 3 = ignore, group 4 = path
	//noinspection RegExpRedundantEscape
	private static final Pattern BASE_PATH_PATTERN = Pattern.compile(
		'/restapi/([^/]+)/(accounts|login_information)(/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|\\d+)(/?(.+))?)?');

	private final Boolean success;

	/**
	 * Constructs a new success mock for the DocuSign eSignature REST API.
	 */
	global ESignatureAPIMock() {
		this(true);
	}

	/**
	 * Constructs a new mock for the DocuSign eSignature REST API.
	 *
	 * @param success Whether the requests should be successful.
	 */
	global ESignatureAPIMock(final Boolean success) {
		super(!success);
		this.success = success;
	}

	private MockRequest parseRequest(final HttpRequest request) {
		Url u = new Url(request.getEndpoint());
		String p = u.getPath();
		if (p.startsWith('/service_information')) { // special case for ping requests
			return new MockRequest(
				request.getMethod(),
				null,
				null,
				'service_information',
				new List<String>(),
				QueryString.parse(u.getQuery()),
				request.getHeader('User-Agent'),
				request.getBody());
		}

		Matcher m = BASE_PATH_PATTERN.matcher(u.getPath());
		if (!m.matches()) throw new AssertException('API request endpoint was not in expected format: ' + u.getPath());

		Integer gc = m.groupCount();
		String resource = m.group(2); // accounts | login_information
		UUID accountId = gc >= 4 ? UUID.tryParse(m.group(4)) : null;
		String path = gc >= 6 ? m.group(6) : null;
		List<String> pathComponents = String.isBlank(path) ? new List<String>() : path.split('\\/');
		if (!pathComponents.isEmpty()) {
			resource = pathComponents[0];
			pathComponents.remove(0);
		}
		String params = u.getQuery();

		return new MockRequest(
			request.getMethod(),
			m.group(1),
			accountId,
			resource,
			String.isBlank(path) ? new List<String>() : path.split('\\/'),
			String.isBlank(params) ? QueryString.empty : QueryString.parse(params),
			request.getHeader('User-Agent'),
			request.getBody());
	}

	//noinspection ApexUnusedDeclaration
	public class AccountsMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				AccountSettings__c s = AccountSettings__c.getOrgDefaults();
				ESignatureProductAPI.APIAccount a = new ESignatureProductAPI.APIAccount();
				a.currentPlanId = 'd1d8e549-4f0f-464a-a474-813b21c659da';
				a.planName = 'DEVCENTER_DEMO_APRIL2013';
				a.planStartDate = StringUtils.formatDatetime(Datetime.now().addDays(-10));
				a.planEndDate = StringUtils.formatDatetime(Datetime.now().addYears(1));
				a.billingPeriodStartDate = StringUtils.formatDatetime(Datetime.now().addDays(-10));
				a.billingPeriodEndDate = StringUtils.formatDatetime(Datetime.now().addYears(1));
				a.accountName = String.isBlank(s.AccountName__c) ? UUID.randomUUID().toString() : s.AccountName__c;
				a.accountIdGuid = UUID.isEmpty(request.accountId)
					? (String.isBlank(s.AccountId__c) ? UUID.randomUUID().toString() : s.AccountId__c)
					: request.accountId.toString();
				a.externalAccountId = s.AccountNumber__c == null
					? String.valueOf(TestUtils.randomInteger(1000000)) : String.valueOf(s.AccountNumber__c);
				a.connectPermission = 'full';
				a.suspensionStatus = null;
				a.suspensionDate = null;
				response = MockResponse.ok(a);
			}
			return response;
		}
	}

	//noinspection ApexUnusedDeclaration
	public class BillingPlanMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				ESignatureProductAPI.PlanId pid = new ESignatureProductAPI.PlanId();
				pid.planId = '8b7c743b-5321-401f-8615-275021832201';
				ESignatureProductAPI.BillingPlans bps = new ESignatureProductAPI.BillingPlans();
				bps.billingPlan = pid;
				response = MockResponse.ok(bps);
			}
			return response;
		}
	}

	//noinspection ApexUnusedDeclaration
	public class BulkEnvelopesMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				String batchId = (String)Collection.last(request.path);
				BulkSendAPI.APIBatchStatusDetail bsd1 = new BulkSendAPI.APIBatchStatusDetail();
				bsd1.envelopeId = UUID.randomUUID().toString();
				bsd1.bulkStatus = 'sent';
				BulkSendAPI.APIBatchStatusDetail bsd2 = new BulkSendAPI.APIBatchStatusDetail();
				bsd2.envelopeId = UUID.randomUUID().toString();
				bsd2.bulkStatus = 'sent';
				BulkSendAPI.APIBatchStatusDetail bsd3 = new BulkSendAPI.APIBatchStatusDetail();
				bsd3.envelopeId = UUID.randomUUID().toString();
				bsd3.bulkStatus = 'sent';
				BulkSendAPI.APIBatchStatus bs = new BulkSendAPI.APIBatchStatus();
				bs.batchSize = '3';
				bs.batchId = batchId == null ? UUID.randomUUID().toString() : batchId;
				bs.failed = '0';
				bs.queued = '0';
				bs.sent = '3';
				bs.bulkEnvelopes = new List<BulkSendAPI.APIBatchStatusDetail> { bsd1, bsd2, bsd3 };
				bs.submittedDate = StringUtils.formatDatetime(Datetime.now().addDays(-1));
				response = MockResponse.ok(bs);
			}
			return response;
		}
	}

	//noinspection ApexUnusedDeclaration
	public class BulkSendListsMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'POST') {
				if ((String)Collection.last(request.path) == 'send') {
					BulkSendAPI.APIBulkSendResponse r = new BulkSendAPI.APIBulkSendResponse();
					r.batchId = UUID.randomUUID().toString();
					response = MockResponse.created(r);
				} else {
					BulkSendAPI.APIBulkList bl = (BulkSendAPI.APIBulkList)JSON.deserialize(
						request.body, BulkSendAPI.APIBulkList.class);
					bl.listId = UUID.randomUUID().toString();
					response = MockResponse.created(bl);
				}
			} else if (request.method == 'PUT') {
				response = MockResponse.ok(request.body);
			} else if (request.method == 'DELETE') {
				response = MockResponse.ok('{}');
			}
			return response;
		}
	}

	//noinspection ApexUnusedDeclaration
	public class CustomFieldsMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				AccountAPI.APIListCustomField lf1 = new AccountAPI.APIListCustomField();
				lf1.name = 'listField1';
				lf1.required = 'true';
				lf1.show = 'true';
				lf1.value = 'listField1Item1';
				lf1.listItems = new List<String> { 'listField1Item1', 'listField1Item2' };
				AccountAPI.APIListCustomField lf2 = new AccountAPI.APIListCustomField();
				lf2.name = 'listField2';
				lf2.required = 'true';
				lf2.show = 'true';
				lf2.value = 'listField2Item2';
				lf2.listItems = new List<String> { 'listField2Item1', 'listField2Item2', 'listField2Item3' };
				AccountAPI.APITextCustomField tf1 = new AccountAPI.APITextCustomField();
				tf1.name = 'textField1';
				tf1.required = 'false';
				tf1.show = 'true';
				tf1.value = 'textValue1';
				AccountAPI.APICustomFields cfs = new AccountAPI.APICustomFields();
				cfs.listCustomFields = new List<AccountAPI.APIListCustomField> { lf1, lf2 };
				cfs.textCustomFields = new List<AccountAPI.APITextCustomField> { tf1 };
				response = MockResponse.ok(cfs);
			}
			return response;
		}
	}

	//noinspection ApexUnusedDeclaration
	public class EnvelopesMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				UUID id = UUID.tryParse((String)Collection.last(request.path));
				if (id != null) { // get status
					EnvelopeAPI.APIRecipient r1 = new EnvelopeAPI.APIRecipient(null, null, false);
					r1.name = UUID.randomUUID().toString();
					r1.email = UUID.randomUUID() + '@unit.test';
					r1.recipientId = '1';
					r1.status = 'completed';
					r1.routingOrder = '1';
					r1.deliveredDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-10));
					r1.declinedDateTime = '';
					r1.signedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-10).addMinutes(30));
					r1.declinedReason = '';
					EnvelopeAPI.APIRecipient r2 = new EnvelopeAPI.APIRecipient(null, null, false);
					r2.name = UUID.randomUUID().toString();
					r2.email = UUID.randomUUID() + '@unit.test';
					r2.recipientId = '2';
					r2.status = 'completed';
					r2.routingOrder = '2';
					r2.deliveredDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-9));
					r2.declinedDateTime = '';
					r2.signedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-9).addMinutes(30));
					r2.declinedReason = '';
					EnvelopeAPI.APIRecipient r3 = new EnvelopeAPI.APIRecipient(null, null, false);
					r3.name = UUID.randomUUID().toString();
					r3.email = UUID.randomUUID() + '@unit.test';
					r3.recipientId = '3';
					r3.status = 'completed';
					r3.routingOrder = '3';
					r3.deliveredDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-8));
					r3.declinedDateTime = '';
					r3.signedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-8).addMinutes(30));
					r3.declinedReason = '';
					EnvelopeAPI.APIRecipient r4 = new EnvelopeAPI.APIRecipient(null, null, false);
					r4.name = UUID.randomUUID().toString();
					r4.email = UUID.randomUUID() + '@unit.test';
					r4.recipientId = '4';
					r4.status = 'completed';
					r4.routingOrder = '4';
					r4.deliveredDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-7));
					r4.declinedDateTime = '';
					r4.signedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-7).addMinutes(30));
					r4.declinedReason = '';
					EnvelopeAPI.APIRecipient r5 = new EnvelopeAPI.APIRecipient(null, null, false);
					r5.name = UUID.randomUUID().toString();
					r5.email = UUID.randomUUID() + '@unit.test';
					r5.recipientId = '5';
					r5.status = 'completed';
					r5.routingOrder = '5';
					r5.deliveredDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-6));
					r5.declinedDateTime = '';
					r5.signedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-6).addMinutes(30));
					r5.declinedReason = '';
					EnvelopeAPI.APIRecipient r6 = new EnvelopeAPI.APIRecipient(null, null, false);
					r6.name = UUID.randomUUID().toString();
					r6.email = UUID.randomUUID() + '@unit.test';
					r6.recipientId = '6';
					r6.status = 'completed';
					r6.routingOrder = '6';
					r6.deliveredDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-5));
					r6.declinedDateTime = '';
					r6.signedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-5).addMinutes(30));
					r6.declinedReason = '';
					EnvelopeAPI.APIRecipient r7 = new EnvelopeAPI.APIRecipient(null, null, false);
					r7.signerName = UUID.randomUUID().toString();
					r7.signerEmail = UUID.randomUUID() + '@unit.test';
					r7.hostName = UUID.randomUUID().toString();
					r7.hostEmail = UUID.randomUUID() + '@unit.test';
					r7.recipientId = '7';
					r7.status = 'completed';
					r7.routingOrder = '7';
					r7.deliveredDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-4));
					r7.declinedDateTime = '';
					r7.signedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-4).addMinutes(30));
					r7.declinedReason = '';
					EnvelopeAPI.APIRecipient r8 = new EnvelopeAPI.APIRecipient(null, null, false);
					r8.signerName = UUID.randomUUID().toString();
					r8.signerEmail = UUID.randomUUID() + '@unit.test';
					r8.hostName = UUID.randomUUID().toString();
					r8.hostEmail = UUID.randomUUID() + '@unit.test';
					r8.recipientId = '8';
					r8.status = 'completed';
					r8.routingOrder = '8';
					r8.deliveredDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-3));
					r8.declinedDateTime = '';
					r8.signedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-3).addMinutes(30));
					r8.declinedReason = '';
					EnvelopeAPI.APIRecipient r9 = new EnvelopeAPI.APIRecipient(null, null, false);
					r9.signerName = UUID.randomUUID().toString();
					r9.signerEmail = UUID.randomUUID() + '@unit.test';
					r9.hostName = UUID.randomUUID().toString();
					r9.hostEmail = UUID.randomUUID() + '@unit.test';
					r9.recipientId = '9';
					r9.status = 'completed';
					r9.routingOrder = '9';
					r9.deliveredDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-2));
					r9.declinedDateTime = '';
					r9.signedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-2).addMinutes(30));
					r9.declinedReason = '';
					EnvelopeAPI.APIRecipients rs = new EnvelopeAPI.APIRecipients(null, null, false);
					rs.signers = new List<EnvelopeAPI.APIRecipient> { r1 };
					rs.agents = new List<EnvelopeAPI.APIRecipient> { r2 };
					rs.editors = new List<EnvelopeAPI.APIRecipient> { r3 };
					rs.intermediaries = new List<EnvelopeAPI.APIRecipient> { r4 };
					rs.carbonCopies = new List<EnvelopeAPI.APIRecipient> { r5 };
					rs.certifiedDeliveries = new List<EnvelopeAPI.APIRecipient> { r6 };
					rs.inPersonSigners = new List<EnvelopeAPI.APIRecipient> { r7 };
					rs.seals = new List<EnvelopeAPI.APIRecipient> { r8 };
					rs.witnesses = new List<EnvelopeAPI.APIRecipient> { r9 };
					EnvelopeAPI.APINotifications notif = new EnvelopeAPI.APINotifications(null);
					EnvelopeAPI.APIEnvelope e = new EnvelopeAPI.APIEnvelope(null, false, false);
					e.envelopeId = String.valueOf(id);
					e.status = 'completed';
					e.recipients = rs;
					e.notification = notif;
					e.sentDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-10));
					e.completedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-1));
					e.emailSubject = 'email subject';
					e.voidedReason = '';
					response = MockResponse.ok(e);
				}
			} else if (request.method == 'POST') {
				String v = (String)Collection.last(request.path);
				if (v == 'sender') { // sender view
					AccountAPI.APIViewResponse vr = new AccountAPI.APIViewResponse();
					vr.url = 'https://unit.test/views/sender';
					response = MockResponse.ok(vr);
				} else if (v == 'recipient') { // recipient view
					AccountAPI.APIViewResponse vr = new AccountAPI.APIViewResponse();
					vr.url = 'https://unit.test/views/recipient';
					response = MockResponse.ok(vr);
				} else if (v == 'correct') { // correct view
					AccountAPI.APIViewResponse vr = new AccountAPI.APIViewResponse();
					vr.url = 'https://unit.test/views/correct';
					response = MockResponse.ok(vr);
				} else { // Create envelope
					System.assertNotEquals(null, request.userAgent, 'User-Agent is null for create envelope.');
					System.assert(Application.userAgent.length() < request.userAgent.length(), 'User-Agent does not contain sender token');
					EnvelopeAPI.APIEnvelope e = (EnvelopeAPI.APIEnvelope)JSON.deserialize(
						request.body, EnvelopeAPI.APIEnvelope.class);
					if (e != null) {
						e.envelopeId = UUID.randomUUID().toString();
						if (e.status == 'sent') {
							e.sentDateTime = StringUtils.formatDatetime(Datetime.now());
						}
					}
					response = MockResponse.created(e);
				}
			} else if (request.method == 'PUT') {
				Boolean isResend = request.parameters.getBoolean('resend_envelope', false);
				Boolean forRecipients = (String)Collection.last(request.path) == 'recipients';
				if (isResend && forRecipients) {
					EnvelopeAPI.APIResendResults rrs = new EnvelopeAPI.APIResendResults();
					rrs.recipientUpdateResults = new List<EnvelopeAPI.APIResendResult>();
					EnvelopeAPI.APIRecipients rs = (EnvelopeAPI.APIRecipients)JSON.deserialize(
						request.body, EnvelopeAPI.APIRecipients.class);
					if (rs != null) {
						for (Integer i = 0; i < Collection.size(rs.agents); i++) {
							EnvelopeAPI.APIResendResult rr = new EnvelopeAPI.APIResendResult();
							rr.recipientId = String.valueOf(rs.agents[i].recipientId);
							rrs.recipientUpdateResults.add(rr);
						}
						for (Integer i = 0; i < Collection.size(rs.carbonCopies); i++) {
							EnvelopeAPI.APIResendResult rr = new EnvelopeAPI.APIResendResult();
							rr.recipientId = String.valueOf(rs.carbonCopies[i].recipientId);
							rrs.recipientUpdateResults.add(rr);
						}
						for (Integer i = 0; i < Collection.size(rs.certifiedDeliveries); i++) {
							EnvelopeAPI.APIResendResult rr = new EnvelopeAPI.APIResendResult();
							rr.recipientId = String.valueOf(rs.certifiedDeliveries[i].recipientId);
							rrs.recipientUpdateResults.add(rr);
						}
						for (Integer i = 0; i < Collection.size(rs.editors); i++) {
							EnvelopeAPI.APIResendResult rr = new EnvelopeAPI.APIResendResult();
							rr.recipientId = String.valueOf(rs.editors[i].recipientId);
							rrs.recipientUpdateResults.add(rr);
						}
						for (Integer i = 0; i < Collection.size(rs.inPersonSigners); i++) {
							EnvelopeAPI.APIResendResult rr = new EnvelopeAPI.APIResendResult();
							rr.recipientId = String.valueOf(rs.inPersonSigners[i].recipientId);
							rrs.recipientUpdateResults.add(rr);
						}
						for (Integer i = 0; i < Collection.size(rs.intermediaries); i++) {
							EnvelopeAPI.APIResendResult rr = new EnvelopeAPI.APIResendResult();
							rr.recipientId = String.valueOf(rs.intermediaries[i].recipientId);
							rrs.recipientUpdateResults.add(rr);
						}
						for (Integer i = 0; i < Collection.size(rs.signers); i++) {
							EnvelopeAPI.APIResendResult rr = new EnvelopeAPI.APIResendResult();
							rr.recipientId = String.valueOf(rs.signers[i].recipientId);
							rrs.recipientUpdateResults.add(rr);
						}
					}
					response = MockResponse.ok(rrs);
				} else if (isResend) { // resend envelope
					response = MockResponse.ok(null);
				} else if (forRecipients) { // update in-person signer
					response = MockResponse.ok(null);
				} else { // void envelope
					response = MockResponse.ok(null);
				}
			}
			return response;
		}
	}

	//noinspection ApexUnusedDeclaration
	public class FoldersMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'PUT') {
				response = MockResponse.ok(null);
			}
			return response;
		}
	}

	//noinspection ApexUnusedDeclaration
	public class PermissionProfilesMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				AuthService.APIPermissionProfile adminProfile = new AuthService.APIPermissionProfile();
				adminProfile.permissionProfileId = '1111';
				adminProfile.permissionProfileName = 'Account Administrator';
				AuthService.APIPermissionProfile senderProfile = new AuthService.APIPermissionProfile();
				senderProfile.permissionProfileId = '2222';
				senderProfile.permissionProfileName = 'DocuSign Sender';
				AuthService.APIPermissionProfiles pps = new AuthService.APIPermissionProfiles();
				pps.permissionProfiles = new List<AuthService.APIPermissionProfile> { adminProfile, senderProfile };
				response = MockResponse.ok(pps);
			}
			return response;
		}
	}

	//noinspection ApexUnusedDeclaration
	public class ServiceInformationMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				response = MockResponse.ok(null);
			}
			return response;
		}
	}

	//noinspection ApexUnusedDeclaration
	public class SettingsMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				response = MockResponse.ok(new Map<String, Object> {
					'accountSettings' => new List<UserAPI.APISetting> {
						new UserAPI.APISetting('allowMergeFields', 'true'),
						new UserAPI.APISetting('sharedCustomTabsEnabled', 'true'),
						new UserAPI.APISetting('savingCustomTabsEnabled', 'true'),
						new UserAPI.APISetting('dataFieldRegexEnabled', 'true'),
						new UserAPI.APISetting('dataFieldSizeEnabled', 'true'),
						new UserAPI.APISetting('tabTextFormattingEnabled', 'true'),
						new UserAPI.APISetting('allowSigningGroups', 'true'),
						new UserAPI.APISetting('tabDataLabelEnabled', 'true'),
						new UserAPI.APISetting('enableSMSAuthentication', 'true'),
						new UserAPI.APISetting('allowServerTemplates', 'true'),
						new UserAPI.APISetting('allowBulkSend', 'true')
					}
				});
			}
			return response;
		}
	}

	//noinspection ApexUnusedDeclaration
	public class SigningGroupsMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				AccountAPI.APISigningGroupMember sg1m1 = new AccountAPI.APISigningGroupMember();
				sg1m1.userName = UUID.randomUUID().toString();
				sg1m1.email = UUID.randomUUID().toString() + '@unit.test';
				AccountAPI.APISigningGroupMember sg1m2 = new AccountAPI.APISigningGroupMember();
				sg1m2.userName = UUID.randomUUID().toString();
				sg1m2.email = UUID.randomUUID().toString() + '@unit.test';
				AccountAPI.APISigningGroup sg1 = new AccountAPI.APISigningGroup();
				sg1.signingGroupId = String.valueOf(TestUtils.randomInteger(1000000));
				sg1.groupName = 'SG1';
				sg1.users = new List<AccountAPI.APISigningGroupMember> { sg1m1, sg1m2 };
				AccountAPI.APISigningGroup sg2 = new AccountAPI.APISigningGroup();
				sg2.signingGroupId = String.valueOf(TestUtils.randomInteger(1000000));
				sg2.groupName = 'SG2';
				AccountAPI.APISigningGroupMember sg3m1 = new AccountAPI.APISigningGroupMember();
				sg3m1.userName = UUID.randomUUID().toString();
				sg3m1.email = UUID.randomUUID().toString() + '@unit.test';
				AccountAPI.APISigningGroup sg3 = new AccountAPI.APISigningGroup();
				sg3.signingGroupId = String.valueOf(TestUtils.randomInteger(1000000));
				sg3.groupName = 'SG3';
				sg3.users = new List<AccountAPI.APISigningGroupMember> { sg3m1 };
				AccountAPI.APISigningGroups sgs = new AccountAPI.APISigningGroups();
				sgs.groups = new List<AccountAPI.APISigningGroup> { sg1, sg2, sg3 };
				response = MockResponse.ok(sgs);
			}
			return response;
		}
	}

	//noinspection ApexUnusedDeclaration
	public class TabDefinitionsMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				AccountAPI.APIMergeField mf1 = new AccountAPI.APIMergeField(null);
				mf1.configurationType = 'salesforce';
				mf1.path = 'Opportunity.Id';
				mf1.writeBack = 'false';
				mf1.allowSenderToEdit = 'false';
				AccountAPI.APIMergeField mf2 = new AccountAPI.APIMergeField(null);
				mf2.configurationType = 'salesforce';
				mf2.path = 'Account.Name';
				mf2.writeBack = 'true';
				mf2.allowSenderToEdit = 'true';
				AccountAPI.APITab ct1 = new AccountAPI.APITab(null);
				ct1.anchor = 'Field 1 anchor';
				ct1.font = 'default';
				ct1.bold = 'false';
				ct1.italic = 'false';
				ct1.underline = 'false';
				ct1.fontColor = 'default';
				ct1.fontSize = 'default';
				ct1.items = new List<String> { 'one', 'two' };
				ct1.customTabId = UUID.randomUUID().toString();
				ct1.initialValue = '';
				ct1.disableAutoSize = 'false';
				ct1.concealValueOnDocument = 'false';
				ct1.locked = 'false';
				ct1.shared = 'false';
				ct1.tabLabel = 'Field 1';
				ct1.maximumLength = '';
				ct1.name = 'Field 1 name';
				ct1.type = 'text';
				ct1.validationMessage = '';
				ct1.validationPattern = '';
				ct1.lastModified = StringUtils.formatDatetime(Datetime.now().addDays(-1));
				ct1.editable = 'true';
				AccountAPI.APITab ct2 = new AccountAPI.APITab(null);
				ct2.font = 'tahoma';
				ct2.bold = 'true';
				ct2.italic = 'true';
				ct2.underline = 'true';
				ct2.fontColor = 'brightBlue';
				ct2.fontSize = 'size24';
				ct2.customTabId = UUID.randomUUID().toString();
				ct2.initialValue = 'Field 2 value';
				ct2.disableAutoSize = 'true';
				ct2.concealValueOnDocument = 'true';
				ct2.locked = 'true';
				ct2.required = 'true';
				ct2.shared = 'true';
				ct2.tabLabel = 'Field 2';
				ct2.maximumLength = '50';
				ct2.name = 'Field 2 name';
				ct2.type = 'email';
				ct2.validationMessage = 'You fail';
				ct2.validationPattern = 'w+';
				ct2.lastModified = StringUtils.formatDatetime(Datetime.now().addDays(-2));
				ct2.editable = 'true';
				ct2.mergeField = mf1;
				AccountAPI.APITab ct3 = new AccountAPI.APITab(null);
				ct3.font = 'helvetica';
				ct3.bold = 'true';
				ct3.italic = 'false';
				ct3.underline = 'false';
				ct3.fontColor = 'gold';
				ct3.fontSize = 'size11';
				ct3.customTabId = UUID.randomUUID().toString();
				ct3.initialValue = '';
				ct3.disableAutoSize = 'false';
				ct3.concealValueOnDocument = 'false';
				ct3.locked = 'false';
				ct3.shared = 'false';
				ct3.tabLabel = 'Field 3';
				ct3.maximumLength = '';
				ct3.name = 'Field 3 name';
				ct3.type = 'something';
				ct3.validationMessage = '';
				ct3.validationPattern = '';
				ct3.lastModified = StringUtils.formatDatetime(Datetime.now().addDays(-3));
				ct3.editable = 'true';
				ct3.mergeField = mf2;
				AccountAPI.APITabs cts = new AccountAPI.APITabs();
				cts.tabs = new List<AccountAPI.APITab> { ct1, ct2, ct3 };
				response = MockResponse.ok(cts);
			} else if (request.method == 'POST') {
				AccountAPI.APITab ct = (AccountAPI.APITab)JSON.deserialize(
					request.body, AccountAPI.APITab.class);
				if (ct != null) {
					ct.customTabId = UUID.randomUUID().toString();
					ct.lastModified = StringUtils.formatDatetime(Datetime.now());
				}
				response = MockResponse.created(ct);
			} else if (request.method == 'PUT') {
				AccountAPI.APITab ct = (AccountAPI.APITab)JSON.deserialize(
					request.body, AccountAPI.APITab.class);
				if (ct != null) {
					ct.lastModified = StringUtils.formatDatetime(Datetime.now());
				}
				response = MockResponse.created(ct);
			} else if (request.method == 'DELETE') {
				response = MockResponse.ok(null);
			}
			return response;
		}
	}

	//noinspection ApexUnusedDeclaration
	public class TemplatesMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				UUID id = UUID.tryParse((String)Collection.last(request.path));
				if (id != null) {
					EnvelopeAPI.APITemplateId tid = new EnvelopeAPI.APITemplateId(id, 'template 1');
					tid.lastModified = StringUtils.formatDatetime(Datetime.now().addDays(-1));
					EnvelopeAPI.APIDocument d = new EnvelopeAPI.APIDocument(null, null);
					d.documentId = '1';
					d.name = UUID.randomUUID() + '.pdf';
					d.fileExtension = 'pdf';
					d.templateLocked = 'true';
					d.templateRequired = 'true';
					EnvelopeAPI.APITextCustomField tf1 = new EnvelopeAPI.APITextCustomField(
						'textField1',
						'textValue1',
						false,
						true);
					EnvelopeAPI.APITextCustomField tf2 = new EnvelopeAPI.APITextCustomField(
						'textField2',
						'textValue2',
						false,
						false);
					EnvelopeAPI.APIListCustomField lf1 = new EnvelopeAPI.APIListCustomField(CustomField.newListField(
						'listField1',
						'listField1Value2',
						new List<String> { 'listField1Value1', 'listField1Value2', 'listField1Value3' },
						true,
						true));
					EnvelopeAPI.APICustomFields cfs = new EnvelopeAPI.APICustomFields(
						new List<EnvelopeAPI.APITextCustomField> { tf1, tf2 },
						new List<EnvelopeAPI.APIListCustomField> { lf1 });
					EnvelopeAPI.APINotifications n = new EnvelopeAPI.APINotifications(new Notifications(
						true,
						10,
						5,
						true,
						11,
						6));
					EnvelopeAPI.APIEmailSettings bg = new EnvelopeAPI.APIEmailSettings(new Recipient.EmailSettings(
						'bg',
						null,
						'bg subject',
						'bg message'));
					EnvelopeAPI.APIEmailSettings fr = new EnvelopeAPI.APIEmailSettings(new Recipient.EmailSettings(
						'fr',
						null,
						'fr subject',
						'fr message'));
					EnvelopeAPI.APISmsAuthentication pa = new EnvelopeAPI.APISmsAuthentication(new List<String> { '+1 415-555-5555' });
					EnvelopeAPI.APIRecipient agent = new EnvelopeAPI.APIRecipient(null, null, false);
					agent.name = '';
					agent.email = '';
					agent.roleName = 'AGENT';
					agent.routingOrder = '5';
					agent.accessCode = '';
					agent.requireIdLookup = 'false';
					agent.note = '';
					agent.templateLocked = 'false';
					agent.templateRequired = 'false';
					agent.emailNotification = bg;
					EnvelopeAPI.APIRecipient cc = new EnvelopeAPI.APIRecipient(null, null, false);
					cc.name = '';
					cc.email = '';
					cc.roleName = 'CARBON_COPY';
					cc.routingOrder = '3';
					cc.accessCode = '';
					cc.requireIdLookup = 'true';
					cc.smsAuthentication = pa;
					cc.note = '';
					cc.templateLocked = 'false';
					cc.templateRequired = 'false';
					cc.emailNotification = null;
					EnvelopeAPI.APIRecipient cd = new EnvelopeAPI.APIRecipient(null, null, false);
					cd.name = '';
					cd.email = '';
					cd.roleName = 'CERTIFIED_DELIVERY';
					cd.routingOrder = '4';
					cd.accessCode = '';
					cd.requireIdLookup = 'false';
					cd.smsAuthentication = null;
					cd.note = 'unit test';
					cd.templateLocked = 'false';
					cd.templateRequired = 'false';
					EnvelopeAPI.APIRecipient editor = new EnvelopeAPI.APIRecipient(null, null, false);
					editor.name = '';
					editor.email = '';
					editor.roleName = 'EDITOR';
					editor.routingOrder = '6';
					editor.accessCode = '';
					editor.requireIdLookup = 'false';
					editor.smsAuthentication = null;
					editor.note = '';
					editor.templateLocked = 'false';
					editor.templateRequired = 'false';
					EnvelopeAPI.APIRecipient ips = new EnvelopeAPI.APIRecipient(null, null, false);
					ips.roleName = 'IN_PERSON_SIGNER';
					ips.routingOrder = '2';
					ips.hostName = '';
					ips.hostEmail = 'h1@unit.test';
					ips.signerName = 'In-Person Signer';
					ips.signerEmail = '';
					ips.accessCode = '';
					ips.requireIdLookup = 'false';
					ips.smsAuthentication = null;
					ips.note = '';
					ips.templateLocked = 'false';
					ips.templateRequired = 'false';
					ips.emailNotification = null;
					EnvelopeAPI.APIRecipient intermediary = new EnvelopeAPI.APIRecipient(null, null, false);
					intermediary.name = '';
					intermediary.email = '';
					intermediary.roleName = 'INTERMEDIARY';
					intermediary.routingOrder = '1';
					intermediary.accessCode = '1234';
					intermediary.requireIdLookup = 'false';
					intermediary.note = '';
					intermediary.templateLocked = 'false';
					intermediary.templateRequired = 'false';
					EnvelopeAPI.APIRecipient signer = new EnvelopeAPI.APIRecipient(null, null, false);
					signer.name = 'SG1';
					signer.email = '';
					signer.roleName = 'SIGNER';
					signer.routingOrder = '7';
					signer.signingGroupId = String.valueOf(TestUtils.randomInteger(1000000));
					signer.signingGroupName = 'SG1';
					signer.accessCode = '';
					signer.requireIdLookup = 'false';
					signer.note = '';
					signer.templateLocked = 'true';
					signer.templateRequired = 'true';
					signer.emailNotification = fr;
					EnvelopeAPI.APIRecipient seal = new EnvelopeAPI.APIRecipient(null, null, false);
					seal.name = '';
					seal.email = '';
					seal.roleName = 'SEAL';
					seal.routingOrder = '8';
					seal.accessCode = null;
					seal.requireIdLookup = 'false';
					seal.note = '';
					seal.templateLocked = 'false';
					seal.templateRequired = 'false';
					EnvelopeAPI.APIRecipient witness = new EnvelopeAPI.APIRecipient(null, null, false);
					witness.name = '';
					witness.email = '';
					witness.roleName = 'WITNESS';
					witness.routingOrder = '9';
					witness.accessCode = null;
					witness.requireIdLookup = 'false';
					witness.note = '';
					witness.templateLocked = 'false';
					witness.templateRequired = 'false';
					EnvelopeAPI.APIRecipients rs = new EnvelopeAPI.APIRecipients(null, d.documentId, false);
					rs.agents = new List<EnvelopeAPI.APIRecipient> { agent };
					rs.carbonCopies = new List<EnvelopeAPI.APIRecipient> { cc };
					rs.certifiedDeliveries = new List<EnvelopeAPI.APIRecipient> { cd };
					rs.editors = new List<EnvelopeAPI.APIRecipient> { editor };
					rs.inPersonSigners = new List<EnvelopeAPI.APIRecipient> { ips };
					rs.intermediaries = new List<EnvelopeAPI.APIRecipient> { intermediary };
					rs.signers = new List<EnvelopeAPI.APIRecipient> { signer };
					rs.seals = new List<EnvelopeAPI.APIRecipient> { seal };
					rs.witnesses = new List<EnvelopeAPI.APIRecipient> { witness };
					EnvelopeAPI.APITemplate t = new EnvelopeAPI.APITemplate(null);
					t.envelopeTemplateDefinition = tid;
					t.documents = new List<EnvelopeAPI.APIDocument> { d };
					t.customFields = cfs;
					t.notification = n;
					t.emailSubject = UUID.randomUUID().toString();
					t.emailBlurb = UUID.randomUUID().toString();
					t.recipients = rs;
					response = MockResponse.ok(t);
				} else { // list templates
					EnvelopeAPI.APITemplateListResult t1 = new EnvelopeAPI.APITemplateListResult();
					t1.templateId = UUID.randomUUID().toString();
					t1.name = 'template 1';
					t1.emailSubject = 'subject 1';
					t1.emailBlurb = 'message 1';
					t1.lastModified = StringUtils.formatDatetime(Datetime.now().addDays(-1));
					EnvelopeAPI.APITemplateListResult t2 = new EnvelopeAPI.APITemplateListResult();
					t2.templateId = UUID.randomUUID().toString();
					t2.name = 'template 2';
					t2.emailSubject = 'subject 2';
					t2.emailBlurb = 'message 2';
					t2.lastModified = StringUtils.formatDatetime(Datetime.now().addDays(-2));
					EnvelopeAPI.APITemplateListResult t3 = new EnvelopeAPI.APITemplateListResult();
					t3.templateId = UUID.randomUUID().toString();
					t3.name = 'template 3';
					t3.emailSubject = 'subject 3';
					t3.emailBlurb = 'message 3';
					t3.lastModified = StringUtils.formatDatetime(Datetime.now().addDays(-3));
					EnvelopeAPI.APITemplates ts = new EnvelopeAPI.APITemplates();
					ts.envelopeTemplates = new List<EnvelopeAPI.APITemplateListResult> { t1, t2, t3 };
					ts.resultSetSize = '3';
					ts.startPosition = '1';
					ts.endPosition = '3';
					ts.totalSetSize = '3';
					response = MockResponse.ok(ts);
				}
			} else if (request.method == 'POST') {
				if ((String)Collection.last(request.path) == 'edit') { // template edit view url
					AccountAPI.APIViewResponse vr = new AccountAPI.APIViewResponse();
					vr.url = 'https://unit.test/templates/views/edit';
					response = MockResponse.ok(vr);
				} else { // create template
					response = MockResponse.created(new Map<String, Object> {
						'templateId' => UUID.randomUUID().toString()
					});
				}
			} else if (request.method == 'PUT') {
				EnvelopeAPI.APITemplate t = (EnvelopeAPI.APITemplate)JSON.deserialize(
					request.body,
					EnvelopeAPI.APITemplate.class);
				if (t != null && t.envelopeTemplateDefinition != null) {
					t.envelopeTemplateDefinition.lastModified = StringUtils.formatDatetime(Datetime.now());
				}
				response = MockResponse.ok(t);
			}
			return response;
		}
	}

	//noinspection ApexUnusedDeclaration
	//TODO: Implement Documents Update mock based on implementation
	//of error handling for multi-item PUT requests
	public class DocumentsUpdateMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'PUT') {
				response = MockResponse.ok(null);
			}
			return response;
		}
	}

	//noinspection ApexUnusedDeclaration
	public class UsersMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'POST') {
				UserAPI.NewUsers nu = (UserAPI.NewUsers)JSON.deserialize(request.body, UserAPI.NewUsers.class);
				if (nu != null && nu.newUsers != null) {
					for (UserAPI.APIUser u : nu.newUsers) {
						u.userId = UUID.randomUUID().toString();
						u.userStatus = 'ActivationSent';
					}
				}
				response = MockResponse.created(nu);
			} else if (request.method == 'PUT') {
				response = MockResponse.ok(request.body);
			} else if (request.method == 'DELETE') {
				response = MockResponse.ok(request.body);
			} else if (request.method == 'GET') {
				UUID userId = UUID.tryParse((String)Collection.last(request.path));
				UserAPI.APIUser apiUser = new UserAPI.APIUser(new Account.User(
					userId == null ? UUID.randomUUID() : userId,
					UserInfo.getUserId(),
					UserInfo.getUserEmail(),
					UserInfo.getFirstName(),
					UserInfo.getLastName(),
					'Active',
					Date.today().addDays(-1),
					false,
					null,
					null,
					null));
				response = MockResponse.ok(apiUser);
			}
			return response;
		}
	}

	//noinspection ApexUnusedDeclaration
	public class ViewsMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'POST') {
				String v = (String)Collection.last(request.path);
				if (v == 'console') {
					AccountAPI.APIViewResponse vr = new AccountAPI.APIViewResponse();
					vr.url = 'https://unit.test/views/console';
					response = MockResponse.ok(vr);
				}
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
		switch on resource {
			when 'service_information' {
				throw new CalloutException('test');
			} when 'oauth' {
				return MockResponse.badRequest('{"error":"mock_error","error_message":"Mock error"}');
			} when else {
				return MockResponse.badRequest('{"errorCode":"MOCK_ERROR","message":"Mock error"}');
			}
		}
	}

	override public HttpResponse getResponse(final HttpRequest request) {
		MockRequest req = parseRequest(request);
		if (req == null || String.isBlank(req.resource)) {
			throw new AssertException('Unable to parse request for ' + request.getEndpoint());
		}
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
		response.setHeader('X-DocuSign-TraceToken', UUID.randomUUID().toString());
		response.setBody(resp.body);

		return response;
	}

	override public HttpResponse respond(final HttpRequest request) {
		return super.respond(request);
	}

	/**
	 * Factory constructor for the DocuSign eSignature REST API with success responses. This also sets the test mock
	 * via <code>Test.setMock</code>.
	 *
	 * @return The success API test mock.
	 */
	public static ESignatureAPIMock success() {
		return (ESignatureAPIMock)TestUtils.setMock(new ESignatureAPIMock(true));
	}

	/**
	 * Factory constructor for the DocuSign eSignature REST API with failure responses. This also sets the test mock
	 * via <code>Test.setMock</code>.
	 *
	 * @return The failure API test mock.
	 */
	public static ESignatureAPIMock failure() {
		return (ESignatureAPIMock)TestUtils.setMock(new ESignatureAPIMock(false));
	}
}
