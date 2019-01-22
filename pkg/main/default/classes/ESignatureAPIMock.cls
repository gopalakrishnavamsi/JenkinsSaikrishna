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
 *     // Call DocuSign for Salesforce service methods
 *   }
 * }
 * </pre>
 */
@IsTest
global class ESignatureAPIMock extends OAuthTokenMock {

	private static final Map<String, String> MOCK_TYPES = new Map<String, String> {
		'accounts' => Application.classNamespacePrefix + 'ESignatureAPIMock.AccountsMock',
		'billing_plan' => Application.classNamespacePrefix + 'ESignatureAPIMock.BillingPlanMock',
		'bulk_envelopes' => Application.classNamespacePrefix + 'ESignatureAPIMock.BulkEnvelopesMock',
		'bulk_send_lists' => Application.classNamespacePrefix + 'ESignatureAPIMock.BulkSendListsMock',
		'custom_fields' => Application.classNamespacePrefix + 'ESignatureAPIMock.CustomFieldsMock',
		'envelopes' => Application.classNamespacePrefix + 'ESignatureAPIMock.EnvelopesMock',
		'service_information' => Application.classNamespacePrefix + 'ESignatureAPIMock.ServiceInformationMock',
		'settings' => Application.classNamespacePrefix + 'ESignatureAPIMock.SettingsMock',
		'signing_groups' => Application.classNamespacePrefix + 'ESignatureAPIMock.SigningGroupsMock',
		'tab_definitions' => Application.classNamespacePrefix + 'ESignatureAPIMock.TabDefinitionsMock',
		'templates' => Application.classNamespacePrefix + 'ESignatureAPIMock.TemplatesMock',
		'users' => Application.classNamespacePrefix + 'ESignatureAPIMock.UsersMock',
		'views' => Application.classNamespacePrefix + 'ESignatureAPIMock.ViewsMock'
	};
	private static final Map<String, MockResource> MOCKS = new Map<String, MockResource>();

	// Capture group 1 = API version, group 2 = account ID, group 3 = ignore, group 4 = path
	private static final Pattern BASE_PATH_PATTERN = Pattern.compile(
		'\\/restapi\\/([^\\/]+)\\/(accounts|login_information)(\\/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|\\d+)(\\/?(.+))?)?');

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
			request.getBody());
	}

	private static String randomPassword() {
		return EncodingUtil.base64Encode(Blob.valueOf(TestUtils.randomString(32)));
	}

	public class AccountsMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				AccountSettings__c s = AccountSettings__c.getOrgDefaults();
				AccountAPI.APIAccount a = new AccountAPI.APIAccount();
				a.currentPlanId = 'd1d8e549-4f0f-464a-a474-813b21c659da';
				a.planName = 'DEVCENTER_DEMO_APRIL2013';
				a.planStartDate = StringUtils.formatDatetime(Datetime.now().addDays(-10));
				a.planEndDate = StringUtils.formatDatetime(Datetime.now().addYears(1));
				a.billingPeriodStartDate = StringUtils.formatDatetime(Datetime.now().addDays(-10));
				a.billingPeriodEndDate = StringUtils.formatDatetime(Datetime.now().addYears(1));
				a.accountName = UUID.randomUUID().toString();
				a.accountIdGuid = UUID.isEmpty(request.accountId)
					? UUID.randomUUID().toString()
					: request.accountId.toString();
				a.externalAccountId = String.valueOf(TestUtils.randomInteger(1000000));
				a.connectPermission = 'full';
				a.suspensionStatus = null;
				a.suspensionDate = null;
				response = MockResponse.ok(a);
			}
			return response;
		}
	}

	public class BillingPlanMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				AccountAPI.PlanId pid = new AccountAPI.PlanId();
				pid.planId = '8b7c743b-5321-401f-8615-275021832201';
				AccountAPI.BillingPlans bps = new AccountAPI.BillingPlans();
				bps.billingPlan = pid;
				response = MockResponse.ok(bps);
			}
			return response;
		}
	}

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

	public class CustomFieldsMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				AccountAPI.ListCustomField lf1 = new AccountAPI.ListCustomField();
				lf1.name = 'listField1';
				lf1.required = 'true';
				lf1.show = 'true';
				lf1.value = 'listField1Item1';
				lf1.listItems = new List<String> { 'listField1Item1', 'listField1Item2' };
				AccountAPI.ListCustomField lf2 = new AccountAPI.ListCustomField();
				lf2.name = 'listField2';
				lf2.required = 'true';
				lf2.show = 'true';
				lf2.value = 'listField2Item2';
				lf2.listItems = new List<String> { 'listField2Item1', 'listField2Item2', 'listField2Item3' };
				AccountAPI.TextCustomField tf1 = new AccountAPI.TextCustomField();
				tf1.name = 'textField1';
				tf1.required = 'false';
				tf1.show = 'true';
				tf1.value = 'textValue1';
				AccountAPI.CustomFields cfs = new AccountAPI.CustomFields();
				cfs.listCustomFields = new List<AccountAPI.ListCustomField> { lf1, lf2 };
				cfs.textCustomFields = new List<AccountAPI.TextCustomField> { tf1 };
				response = MockResponse.ok(cfs);
			}
			return response;
		}
	}

	public class EnvelopesMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				UUID id = UUID.tryParse((String)Collection.last(request.path));
				if (id != null) { // get status
					EnvelopeAPI.APIRecipient r1 = new EnvelopeAPI.APIRecipient(null, null, false, false);
					r1.name = UUID.randomUUID().toString();
					r1.email = UUID.randomUUID() + '@unit.test';
					r1.recipientId = '1';
					r1.status = 'completed';
					r1.routingOrder = '1';
					r1.deliveredDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-10));
					r1.declinedDateTime = '';
					r1.signedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-10).addMinutes(30));
					r1.declinedReason = '';
					EnvelopeAPI.APIRecipient r2 = new EnvelopeAPI.APIRecipient(null, null, false, false);
					r2.name = UUID.randomUUID().toString();
					r2.email = UUID.randomUUID() + '@unit.test';
					r2.recipientId = '2';
					r2.status = 'completed';
					r2.routingOrder = '2';
					r2.deliveredDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-9));
					r2.declinedDateTime = '';
					r2.signedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-9).addMinutes(30));
					r2.declinedReason = '';
					EnvelopeAPI.APIRecipient r3 = new EnvelopeAPI.APIRecipient(null, null, false, false);
					r3.name = UUID.randomUUID().toString();
					r3.email = UUID.randomUUID() + '@unit.test';
					r3.recipientId = '3';
					r3.status = 'completed';
					r3.routingOrder = '3';
					r3.deliveredDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-8));
					r3.declinedDateTime = '';
					r3.signedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-8).addMinutes(30));
					r3.declinedReason = '';
					EnvelopeAPI.APIRecipient r4 = new EnvelopeAPI.APIRecipient(null, null, false, false);
					r4.name = UUID.randomUUID().toString();
					r4.email = UUID.randomUUID() + '@unit.test';
					r4.recipientId = '4';
					r4.status = 'completed';
					r4.routingOrder = '4';
					r4.deliveredDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-7));
					r4.declinedDateTime = '';
					r4.signedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-7).addMinutes(30));
					r4.declinedReason = '';
					EnvelopeAPI.APIRecipient r5 = new EnvelopeAPI.APIRecipient(null, null, false, false);
					r5.name = UUID.randomUUID().toString();
					r5.email = UUID.randomUUID() + '@unit.test';
					r5.recipientId = '5';
					r5.status = 'completed';
					r5.routingOrder = '5';
					r5.deliveredDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-6));
					r5.declinedDateTime = '';
					r5.signedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-6).addMinutes(30));
					r5.declinedReason = '';
					EnvelopeAPI.APIRecipient r6 = new EnvelopeAPI.APIRecipient(null, null, false, false);
					r6.name = UUID.randomUUID().toString();
					r6.email = UUID.randomUUID() + '@unit.test';
					r6.recipientId = '6';
					r6.status = 'completed';
					r6.routingOrder = '6';
					r6.deliveredDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-5));
					r6.declinedDateTime = '';
					r6.signedDateTime = StringUtils.formatDatetime(Datetime.now().addDays(-5).addMinutes(30));
					r6.declinedReason = '';
					EnvelopeAPI.APIRecipient r7 = new EnvelopeAPI.APIRecipient(null, null, false, false);
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
					EnvelopeAPI.Recipients rs = new EnvelopeAPI.Recipients(null, null, false, false);
					rs.signers = new List<EnvelopeAPI.APIRecipient> { r1 };
					rs.agents = new List<EnvelopeAPI.APIRecipient> { r2 };
					rs.editors = new List<EnvelopeAPI.APIRecipient> { r3 };
					rs.intermediaries = new List<EnvelopeAPI.APIRecipient> { r4 };
					rs.carbonCopies = new List<EnvelopeAPI.APIRecipient> { r5 };
					rs.certifiedDeliveries = new List<EnvelopeAPI.APIRecipient> { r6 };
					rs.inPersonSigners = new List<EnvelopeAPI.APIRecipient> { r7 };
					EnvelopeAPI.Expirations exp = new EnvelopeAPI.Expirations(null);
					exp.expireAfter = '30';
					EnvelopeAPI.EnvelopeNotification notif = new EnvelopeAPI.EnvelopeNotification(null, false);
					notif.expirations = exp;
					EnvelopeAPI.APIEnvelope e = new EnvelopeAPI.APIEnvelope(null, false, false, false, false);
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
					AccountAPI.ViewResponse vr = new AccountAPI.ViewResponse();
					vr.url = 'https://unit.test/views/sender';
					response = MockResponse.ok(vr);
				} else if (v == 'recipient') { // recipient view
					AccountAPI.ViewResponse vr = new AccountAPI.ViewResponse();
					vr.url = 'https://unit.test/views/recipient';
					response = MockResponse.ok(vr);
				} else if (v == 'correct') { // correct view
					AccountAPI.ViewResponse vr = new AccountAPI.ViewResponse();
					vr.url = 'https://unit.test/views/correct';
					response = MockResponse.ok(vr);
				} else { // Create envelope
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
					EnvelopeAPI.ResendResults rrs = new EnvelopeAPI.ResendResults();
					rrs.recipientUpdateResults = new List<EnvelopeAPI.ResendResult>();
					EnvelopeAPI.Recipients rs = (EnvelopeAPI.Recipients)JSON.deserialize(
						request.body, EnvelopeAPI.Recipients.class);
					if (rs != null) {
						for (Integer i = 0; i < Collection.size(rs.agents); i++) {
							EnvelopeAPI.ResendResult rr = new EnvelopeAPI.ResendResult();
							rr.recipientId = String.valueOf(rs.agents[i].recipientId);
							rrs.recipientUpdateResults.add(rr);
						}
						for (Integer i = 0; i < Collection.size(rs.carbonCopies); i++) {
							EnvelopeAPI.ResendResult rr = new EnvelopeAPI.ResendResult();
							rr.recipientId = String.valueOf(rs.carbonCopies[i].recipientId);
							rrs.recipientUpdateResults.add(rr);
						}
						for (Integer i = 0; i < Collection.size(rs.certifiedDeliveries); i++) {
							EnvelopeAPI.ResendResult rr = new EnvelopeAPI.ResendResult();
							rr.recipientId = String.valueOf(rs.certifiedDeliveries[i].recipientId);
							rrs.recipientUpdateResults.add(rr);
						}
						for (Integer i = 0; i < Collection.size(rs.editors); i++) {
							EnvelopeAPI.ResendResult rr = new EnvelopeAPI.ResendResult();
							rr.recipientId = String.valueOf(rs.editors[i].recipientId);
							rrs.recipientUpdateResults.add(rr);
						}
						for (Integer i = 0; i < Collection.size(rs.inPersonSigners); i++) {
							EnvelopeAPI.ResendResult rr = new EnvelopeAPI.ResendResult();
							rr.recipientId = String.valueOf(rs.inPersonSigners[i].recipientId);
							rrs.recipientUpdateResults.add(rr);
						}
						for (Integer i = 0; i < Collection.size(rs.intermediaries); i++) {
							EnvelopeAPI.ResendResult rr = new EnvelopeAPI.ResendResult();
							rr.recipientId = String.valueOf(rs.intermediaries[i].recipientId);
							rrs.recipientUpdateResults.add(rr);
						}
						for (Integer i = 0; i < Collection.size(rs.signers); i++) {
							EnvelopeAPI.ResendResult rr = new EnvelopeAPI.ResendResult();
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

	public class ServiceInformationMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				response = MockResponse.ok(null);
			}
			return response;
		}
	}

	public class SettingsMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				response = MockResponse.ok(new Map<String, Object> {
					'accountSettings' => new List<AccountAPI.Setting> {
						new AccountAPI.Setting('allowMergeFields', 'true'),
						new AccountAPI.Setting('sharedCustomTabsEnabled', 'true'),
						new AccountAPI.Setting('savingCustomTabsEnabled', 'true'),
						new AccountAPI.Setting('dataFieldRegexEnabled', 'true'),
						new AccountAPI.Setting('dataFieldSizeEnabled', 'true'),
						new AccountAPI.Setting('tabTextFormattingEnabled', 'true'),
						new AccountAPI.Setting('allowSigningGroups', 'true'),
						new AccountAPI.Setting('tabDataLabelEnabled', 'true'),
						new AccountAPI.Setting('enableSMSAuthentication', 'true'),
						new AccountAPI.Setting('allowServerTemplates', 'true'),
						new AccountAPI.Setting('allowBulkSend', 'true')
					}
				});
			}
			return response;
		}
	}

	public class SigningGroupsMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				EnvelopeAPI.SigningGroupMember sg1m1 = new EnvelopeAPI.SigningGroupMember();
				sg1m1.userName = UUID.randomUUID().toString();
				sg1m1.email = UUID.randomUUID().toString() + '@unit.test';
				EnvelopeAPI.SigningGroupMember sg1m2 = new EnvelopeAPI.SigningGroupMember();
				sg1m2.userName = UUID.randomUUID().toString();
				sg1m2.email = UUID.randomUUID().toString() + '@unit.test';
				EnvelopeAPI.APISigningGroup sg1 = new EnvelopeAPI.APISigningGroup();
				sg1.signingGroupId = String.valueOf(TestUtils.randomInteger(1000000));
				sg1.groupName = 'SG1';
				sg1.users = new List<EnvelopeAPI.SigningGroupMember> { sg1m1, sg1m2 };
				EnvelopeAPI.APISigningGroup sg2 = new EnvelopeAPI.APISigningGroup();
				sg2.signingGroupId = String.valueOf(TestUtils.randomInteger(1000000));
				sg2.groupName = 'SG2';
				EnvelopeAPI.SigningGroupMember sg3m1 = new EnvelopeAPI.SigningGroupMember();
				sg3m1.userName = UUID.randomUUID().toString();
				sg3m1.email = UUID.randomUUID().toString() + '@unit.test';
				EnvelopeAPI.APISigningGroup sg3 = new EnvelopeAPI.APISigningGroup();
				sg3.signingGroupId = String.valueOf(TestUtils.randomInteger(1000000));
				sg3.groupName = 'SG3';
				sg3.users = new List<EnvelopeAPI.SigningGroupMember> { sg3m1 };
				EnvelopeAPI.SigningGroups sgs = new EnvelopeAPI.SigningGroups();
				sgs.groups = new List<EnvelopeAPI.APISigningGroup> { sg1, sg2, sg3 };
				response = MockResponse.ok(sgs);
			}
			return response;
		}
	}

	public class TabDefinitionsMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				AccountAPI.MergeField mf1 = new AccountAPI.MergeField(null);
				mf1.configurationType = 'salesforce';
				mf1.path = 'Opportunity.Id';
				mf1.writeBack = 'false';
				mf1.allowSenderToEdit = 'false';
				AccountAPI.MergeField mf2 = new AccountAPI.MergeField(null);
				mf2.configurationType = 'salesforce';
				mf2.path = 'Account.Name';
				mf2.writeBack = 'true';
				mf2.allowSenderToEdit = 'true';
				AccountAPI.CustomTab ct1 = new AccountAPI.CustomTab(null);
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
				AccountAPI.CustomTab ct2 = new AccountAPI.CustomTab(null);
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
				AccountAPI.CustomTab ct3 = new AccountAPI.CustomTab(null);
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
				AccountAPI.CustomTabs cts = new AccountAPI.CustomTabs();
				cts.tabs = new List<AccountAPI.CustomTab> { ct1, ct2, ct3 };
				response = MockResponse.ok(cts);
			} else if (request.method == 'POST') {
				AccountAPI.CustomTab ct = (AccountAPI.CustomTab)JSON.deserialize(
					request.body, AccountAPI.CustomTab.class);
				if (ct != null) {
					ct.customTabId = UUID.randomUUID().toString();
					ct.lastModified = StringUtils.formatDatetime(Datetime.now());
				}
				response = MockResponse.created(ct);
			} else if (request.method == 'PUT') {
				AccountAPI.CustomTab ct = (AccountAPI.CustomTab)JSON.deserialize(
					request.body, AccountAPI.CustomTab.class);
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

	public class TemplatesMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'GET') {
				UUID id = UUID.tryParse((String)Collection.last(request.path));
				if (id != null) {
					TemplateAPI.TemplateId tid = new TemplateAPI.TemplateId();
					tid.templateId = id.toString();
					tid.name = 'template 1';
					tid.lastModified = StringUtils.formatDatetime(Datetime.now().addDays(-1));
					TemplateAPI.TextCustomField tf1 = new TemplateAPI.TextCustomField();
					tf1.name = 'textField1';
					tf1.show = 'true';
					tf1.required = 'false';
					tf1.value = 'textValue1';
					TemplateAPI.TextCustomField tf2 = new TemplateAPI.TextCustomField();
					tf2.name = 'textField2';
					tf2.show = 'false';
					tf2.required = 'false';
					tf2.value = 'textValue2';
					TemplateAPI.ListCustomField lf1 = new TemplateAPI.ListCustomField();
					lf1.name = 'listField1';
					lf1.show = 'true';
					lf1.required = 'true';
					lf1.value = 'listField1Value2';
					lf1.listItems = new List<String> { 'listField1Value1', 'listField1Value2', 'listField1Value3' };
					TemplateAPI.CustomFields cfs = new TemplateAPI.CustomFields();
					cfs.textCustomFields = new List<TemplateAPI.TextCustomField> { tf1, tf2 };
					cfs.listCustomFields = new List<TemplateAPI.ListCustomField> { lf1 };
					TemplateAPI.APIReminders rem = new TemplateAPI.APIReminders();
					rem.reminderEnabled = 'true';
					rem.reminderDelay = '10';
					rem.reminderFrequency = '5';
					TemplateAPI.APIExpirations exp = new TemplateAPI.APIExpirations();
					exp.expireEnabled = 'true';
					exp.expireAfter = '11';
					exp.expireWarn = '6';
					TemplateAPI.APINotification n = new TemplateAPI.APINotification();
					n.reminders = rem;
					n.expirations = exp;
					TemplateAPI.APIEmailSettings bg = new TemplateAPI.APIEmailSettings();
					bg.supportedLanguage = 'bg';
					bg.emailSubject = 'bg subject';
					bg.emailBody = 'bg message';
					TemplateAPI.APIEmailSettings fr = new TemplateAPI.APIEmailSettings();
					fr.supportedLanguage = 'fr';
					fr.emailSubject = 'fr subject';
					fr.emailBody = 'fr message';
					TemplateAPI.APIPhoneAuthentication pa = new TemplateAPI.APIPhoneAuthentication();
					pa.senderProvidedNumbers = new List<String> { '+1 415-555-5555' };
					TemplateAPI.APIRecipient agent = new TemplateAPI.APIRecipient();
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
					TemplateAPI.APIRecipient cc = new TemplateAPI.APIRecipient();
					cc.name = '';
					cc.email = '';
					cc.roleName = 'CARBON_COPY';
					cc.routingOrder = '3';
					cc.accessCode = '';
					cc.requireIdLookup = 'true';
					cc.phoneAuthentication = pa;
					cc.note = '';
					cc.templateLocked = 'false';
					cc.templateRequired = 'false';
					cc.emailNotification = null;
					TemplateAPI.APIRecipient cd = new TemplateAPI.APIRecipient();
					cd.name = '';
					cd.email = '';
					cd.roleName = 'CERTIFIED_DELIVERY';
					cd.routingOrder = '4';
					cd.accessCode = '';
					cd.requireIdLookup = 'false';
					cd.phoneAuthentication = null;
					cd.note = 'unit test';
					cd.templateLocked = 'false';
					cd.templateRequired = 'false';
					TemplateAPI.APIRecipient editor = new TemplateAPI.APIRecipient();
					editor.name = '';
					editor.email = '';
					editor.roleName = 'EDITOR';
					editor.routingOrder = '6';
					editor.accessCode = '';
					editor.requireIdLookup = 'false';
					editor.phoneAuthentication = null;
					editor.note = '';
					editor.templateLocked = 'false';
					editor.templateRequired = 'false';
					TemplateAPI.APIRecipient ips = new TemplateAPI.APIRecipient();
					ips.roleName = 'IN_PERSON_SIGNER';
					ips.routingOrder = '2';
					ips.hostName = '';
					ips.hostEmail = 'h1@unit.test';
					ips.signerName = 'In-Person Signer';
					ips.signerEmail = '';
					ips.accessCode = '';
					ips.requireIdLookup = 'false';
					ips.phoneAuthentication = null;
					ips.note = '';
					ips.templateLocked = 'false';
					ips.templateRequired = 'false';
					ips.emailNotification = null;
					TemplateAPI.APIRecipient intermediary = new TemplateAPI.APIRecipient();
					intermediary.name = '';
					intermediary.email = '';
					intermediary.roleName = 'INTERMEDIARY';
					intermediary.routingOrder = '1';
					intermediary.accessCode = '1234';
					intermediary.requireIdLookup = 'false';
					intermediary.note = '';
					intermediary.templateLocked = 'false';
					intermediary.templateRequired = 'false';
					TemplateAPI.APIRecipient signer = new TemplateAPI.APIRecipient();
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
					TemplateAPI.APIRecipients rs = new TemplateAPI.APIRecipients();
					rs.agents = new List<TemplateAPI.APIRecipient> { agent };
					rs.carbonCopies = new List<TemplateAPI.APIRecipient> { cc };
					rs.certifiedDeliveries = new List<TemplateAPI.APIRecipient> { cd };
					rs.editors = new List<TemplateAPI.APIRecipient> { editor };
					rs.inPersonSigners = new List<TemplateAPI.APIRecipient> { ips };
					rs.intermediaries = new List<TemplateAPI.APIRecipient> { intermediary };
					rs.signers = new List<TemplateAPI.APIRecipient> { signer };
					TemplateAPI.APITemplate t = new TemplateAPI.APITemplate();
					t.envelopeTemplateDefinition = tid;
					t.customFields = cfs;
					t.notification = n;
					t.emailSubject = UUID.randomUUID().toString();
					t.emailBlurb = UUID.randomUUID().toString();
					t.recipients = rs;
					response = MockResponse.ok(t);
				} else { // list templates
					TemplateAPI.APITemplateListResult t1 = new TemplateAPI.APITemplateListResult();
					t1.templateId = UUID.randomUUID().toString();
					t1.name = 'template 1';
					t1.emailSubject = 'subject 1';
					t1.emailBlurb = 'message 1';
					t1.lastModified = StringUtils.formatDatetime(Datetime.now().addDays(-1));
					TemplateAPI.APITemplateListResult t2 = new TemplateAPI.APITemplateListResult();
					t2.templateId = UUID.randomUUID().toString();
					t2.name = 'template 2';
					t2.emailSubject = 'subject 2';
					t2.emailBlurb = 'message 2';
					t2.lastModified = StringUtils.formatDatetime(Datetime.now().addDays(-2));
					TemplateAPI.APITemplateListResult t3 = new TemplateAPI.APITemplateListResult();
					t3.templateId = UUID.randomUUID().toString();
					t3.name = 'template 3';
					t3.emailSubject = 'subject 3';
					t3.emailBlurb = 'message 3';
					t3.lastModified = StringUtils.formatDatetime(Datetime.now().addDays(-3));
					TemplateAPI.Templates ts = new TemplateAPI.Templates();
					ts.envelopeTemplates = new List<TemplateAPI.APITemplateListResult> { t1, t2, t3 };
					ts.resultSetSize = '3';
					ts.startPosition = '1';
					ts.endPosition = '3';
					ts.totalSetSize = '3';
					response = MockResponse.ok(ts);
				}
			}
			return response;
		}
	}

	public class UsersMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'POST') {
				AccountAPI.NewUsers nu = (AccountAPI.NewUsers)JSON.deserialize(request.body, AccountAPI.NewUsers.class);
				if (nu != null && nu.newUsers != null) {
					for (AccountAPI.APIUser u : nu.newUsers) {
						u.userId = UUID.randomUUID().toString();
						u.userStatus = 'ActivationSent';
						u.apiPassword = randomPassword();
					}
				}
				response = MockResponse.created(nu);
			} else if (request.method == 'DELETE') {
				response = MockResponse.ok(request.body);
			}
			return response;
		}
	}

	public class ViewsMock implements MockResource {

		public MockResponse respond(final MockRequest request) {
			MockResponse response = null;
			if (request.method == 'POST') {
				String v = (String)Collection.last(request.path);
				if (v == 'console') {
					AccountAPI.ViewResponse vr = new AccountAPI.ViewResponse();
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
