@IsTest(IsParallel = true)
private class ESignatureProductAPITest {

	@IsTest
	static void test_getInstance_setup_valid() {
		Test.startTest();
		ESignatureProductAPI result1 = ESignatureProductAPI.getInstance(
			new Url('https://test.docusign.com'), UUID.randomUUID(), 'unit.test');
		ESignatureProductAPI result2 = ESignatureProductAPI.getInstance(
			new Url('https://test.docusign.com'), UUID.randomUUID(), 'unit.test');
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assertNotEquals(null, result2);
		System.assert(result1 !== result2);
	}

	@IsTest
	static void test_getInstance_setup_invalid() {
		Test.startTest();
		try {
			ESignatureProductAPI.getInstance(null, UUID.randomUUID(), 'unit.test');
			throw new AssertException('Expected getInstance to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			ESignatureProductAPI.getInstance(new Url('https://test.docusign.com'), null, 'unit.test');
			throw new AssertException('Expected getInstance to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.UndefinedArgument, ex.getMessage());
		}
		try {
			ESignatureProductAPI.getInstance(new Url('https://invalid.url'), UUID.randomUUID(), 'unit.test');
			throw new AssertException('Expected getInstance to fail');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_getConnectPermission() {
		ESignatureProductAPI.APIAccount a = new ESignatureProductAPI.APIAccount();

		Test.startTest();
		a.connectPermission = null;
		System.assertEquals(Account.ConnectPermission.None, a.getConnectPermission());
		a.connectPermission = '';
		System.assertEquals(Account.ConnectPermission.None, a.getConnectPermission());
		a.connectPermission = '  ';
		System.assertEquals(Account.ConnectPermission.None, a.getConnectPermission());
		a.connectPermission = 'NONE';
		System.assertEquals(Account.ConnectPermission.None, a.getConnectPermission());
		a.connectPermission = 'none';
		System.assertEquals(Account.ConnectPermission.None, a.getConnectPermission());
		a.connectPermission = 'whatever';
		System.assertEquals(Account.ConnectPermission.None, a.getConnectPermission());
		a.connectPermission = 'Full';
		System.assertEquals(Account.ConnectPermission.Full, a.getConnectPermission());
		a.connectPermission = 'SendOnly';
		System.assertEquals(Account.ConnectPermission.SendOnly, a.getConnectPermission());
		Test.stopTest();
	}

	static ESignatureProductAPI getClient() {
		return ESignatureProductAPI.getInstance(
			new Url('https://esign.test.docusign.net/'),
			UUID.randomUUID(),
			'unit.test');
	}

	@IsTest
	static void test_getAccount_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		Test.startTest();
		Account result = getClient().getAccount(RestAPI.defaultTimeout);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertNotEquals(null, result.plan);
		System.assertNotEquals(null, result.billing);
		System.assertNotEquals(null, result.id);
		System.assertNotEquals(null, result.name);
		System.assertNotEquals(null, result.plan.id);
		System.assertNotEquals(null, result.plan.name);
		System.assertNotEquals(null, result.plan.startDate);
		System.assertNotEquals(null, result.plan.endDate);
		System.assertNotEquals(null, result.billing.startDate);
		System.assertNotEquals(null, result.billing.endDate);
		System.assertEquals(Account.ConnectPermission.Full, result.connect);
	}

	@IsTest
	static void test_getAccount_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		Test.startTest();
		try {
			getClient().getAccount(RestAPI.defaultTimeout);
			throw new AssertException('Expected getAccount to fail');
		} catch (APIException ex) {
			System.assertEquals(APIError.badRequest, ex.error);
		}
		Test.stopTest();
	}

	private class TrialExpiredMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			if (request.getEndpoint().endsWith('/billing_plan')) {
				response.setBody('{"billingPlan": {"planId": "' + String.valueOf(DocuSign.TRIAL_PLAN_ID) + '","planName": "DocuSign 30 Day Expire","paymentCycle": "annually","paymentMethod": "free_trial","perSeatPrice": "$0.00","otherDiscountPercent": "0.00","supportIncidentFee": "$0.00","supportPlanFee": "$0.00","includedSeats": "1","enableSupport": "false","currencyCode": "USD","planClassification": "partner","seatDiscounts": [{"beginSeatCount": "0","endSeatCount": "0","discountPercent": "0.00"}]},"successorPlans": [],"billingAddress": {"phone": "+1 5105555555","firstName": "Unit","lastName": "Test","email": "unit@test.com"},"billingAddressIsCreditCardAddress": "true"}');
			} else { // GET account
				response.setBody('{"currentPlanId":"' + String.valueOf(DocuSign.TRIAL_PLAN_ID) + '","planName":"TRIAL_30_DAY","planStartDate":"2017-01-05T17:54:37.1800000Z","planEndDate":"2018-01-05T17:54:37.1800000Z","billingPeriodStartDate":"2030-01-05T08:00:00.0000000Z","billingPeriodEndDate":"2030-02-05T08:00:00.0000000Z","billingPeriodEnvelopesSent":"4","billingPeriodEnvelopesAllowed":"unlimited","billingPeriodDaysRemaining":"0","canUpgrade":"false","canCancelRenewal":"false","envelopeSendingBlocked":"false","envelopeUnitPrice":"$0.00","suspensionStatus":"freetrialexpired","suspensionDate":"2017-02-05T17:54:37.1800000Z","accountName":"DocuSign","connectPermission":"full","docuSignLandingUrl":"http://www.docusign.com/products/sign_up/buy_now.php","distributorCode":"DEVCENTER_DEMO_APRIL2013","accountIdGuid":"67db8eaa-8e05-486b-a146-8cb2b93d1aa4","currencyCode":"USD","forgottenPasswordQuestionsCount":"1","paymentMethod":"purchase_order","seatsAllowed":"unlimited","seatsInUse":"1","createdDate":"2017-01-05T17:54:36.7770000Z","isDowngrade":"false","billingProfile":"web","allowTransactionRooms":"false"}');
			}
			return response;
		}
	}

	@IsTest
	static void test_getAccount_trial_expired() {
		Test.setMock(HttpCalloutMock.class, new TrialExpiredMock());

		Test.startTest();
		Account result = getClient().getAccount(RestAPI.defaultTimeout);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.isTrial);
		System.assertNotEquals(null, result.billing);
		System.assertEquals(Date.newInstance(2017, 1, 5), result.billing.startDate);
		System.assertEquals(Date.newInstance(2017, 2, 5), result.billing.endDate);
	}

	@IsTest
	static void test_addPlanId_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		Account a = new Account(
			UUID.randomUUID(),
			1234L,
			'UNIT TEST',
			'active',
			new Account.Plan(
				UUID.randomUUID(),
				'UNIT TEST PLAN',
				Date.newInstance(1, 1, 2017),
				Date.newInstance(1, 1, 2018)),
			new Account.Billing(
				Date.newInstance(7, 1, 2017),
				Date.newInstance(8, 1, 2017)),
			Account.ConnectPermission.Full);

		Test.startTest();
		Account result = getClient().addPlanId(a, 30000);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertNotEquals(null, result.plan);
		System.assertNotEquals(null, result.plan.id);
	}

	@IsTest
	static void test_addPlanId_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		Account a = new Account(
			UUID.randomUUID(),
			1234L,
			'UNIT TEST',
			'active',
			new Account.Plan(
				UUID.randomUUID(),
				'UNIT TEST PLAN',
				Date.newInstance(1, 1, 2017),
				Date.newInstance(1, 1, 2018)),
			new Account.Billing(
				Date.newInstance(7, 1, 2017),
				Date.newInstance(8, 1, 2017)),
			Account.ConnectPermission.Full);

		Test.startTest();
		try {
			getClient().addPlanId(a, 30000);
			throw new AssertException('Expected addPlanId to fail');
		} catch (APIException ex) {
			System.assertEquals(APIError.badRequest, ex.error);
		}
		Test.stopTest();
	}

	private class AddPlanIdErrorMock extends OAuthTokenMock {
		override public HttpResponse getResponse(HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setBody('{"billingPlan":{"planId":""}}');
			return response;
		}
	}

	@IsTest
	static void test_addPlanId_error() {
		Test.setMock(HttpCalloutMock.class, new AddPlanIdErrorMock());

		UUID initialPlanId = UUID.randomUUID();
		Account a = new Account(
			UUID.randomUUID(),
			1234L,
			'UNIT TEST',
			'active',
			new Account.Plan(
				initialPlanId,
				'UNIT TEST PLAN',
				Date.newInstance(1, 1, 2017),
				Date.newInstance(1, 1, 2018)),
			new Account.Billing(
				Date.newInstance(7, 1, 2017),
				Date.newInstance(8, 1, 2017)),
			Account.ConnectPermission.Full);

		Test.startTest();
		Account result = getClient().addPlanId(a, 30000);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(a === result); // Same reference
		System.assertNotEquals(null, result.plan);
		System.assertEquals(initialPlanId, result.plan.id);
	}

	@IsTest
	static void test_getProduct_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(true));

		Test.startTest();
		ESignatureProduct result = getClient().getProduct();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(result.connect);
	}

	@IsTest
	static void test_getProduct_failure() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));

		Test.startTest();
		try {
			getClient().getProduct();
			throw new AssertException('Expected getProduct to fail');
		} catch (APIException ex) {
			System.assertEquals(APIError.badRequest, ex.error);
		}
		Test.stopTest();
	}

	class ConnectDisabledMock extends OAuthTokenMock {

		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			response.setStatusCode(200);
			response.setStatus('OK');

			if (request.getMethod() == 'GET') {
				if (request.getEndpoint().contains('/settings')) {
					response.setBody(JSON.serialize(new Map<String, Object> {
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
					}));
				} else { // GET account
					ESignatureProductAPI.APIAccount a = new ESignatureProductAPI.APIAccount();
					a.currentPlanId = 'd1d8e549-4f0f-464a-a474-813b21c659da';
					a.planName = 'DEVCENTER_DEMO_APRIL2013';
					a.planStartDate = StringUtils.formatDatetime(Datetime.now().addDays(-10));
					a.planEndDate = StringUtils.formatDatetime(Datetime.now().addYears(1));
					a.billingPeriodStartDate = StringUtils.formatDatetime(Datetime.now().addDays(-10));
					a.billingPeriodEndDate = StringUtils.formatDatetime(Datetime.now().addYears(1));
					a.accountName = UUID.randomUUID().toString();
					a.accountIdGuid = UUID.randomUUID().toString();
					a.externalAccountId = String.valueOf(TestUtils.randomInteger(1000000));
					a.connectPermission = 'sendOnly'; // "full" is required as we have to create a Connect config
					a.suspensionStatus = null;
					a.suspensionDate = null;
					response.setBody(JSON.serialize(a));
				}
			}
			return response;
		}
	}

	@IsTest
	static void test_getProduct_connect_disabled() {
		Test.setMock(HttpCalloutMock.class, new ConnectDisabledMock());
		ESignatureProductAPI client = ESignatureProductAPI.getInstance(
			new Url('https://unit.test.docusign.com'),
			UUID.randomUUID(),
			'unit.test');

		Test.startTest();
		ESignatureProduct result = client.getProduct();
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assert(!result.connect);
	}
}
