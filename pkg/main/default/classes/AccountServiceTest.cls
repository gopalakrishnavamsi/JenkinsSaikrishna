@IsTest
public class AccountServiceTest {

	@IsTest
	static void test_getAccount_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				AccountService.getAccount();
				throw new AssertException('Expected getAccount to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	public class TrialAccountMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			if (request.getEndpoint().endsWith('/billing_plan')) {
				response.setBody('{"billingPlan": {"planId": "' + String.valueOf(DocuSign.TRIAL_PLAN_ID) + '","planName": "DocuSign for Salesforce 30 Day Expire","paymentCycle": "annually","paymentMethod": "free_trial","perSeatPrice": "$0.00","otherDiscountPercent": "0.00","supportIncidentFee": "$0.00","supportPlanFee": "$0.00","includedSeats": "1","enableSupport": "false","currencyCode": "USD","planClassification": "partner","seatDiscounts": [{"beginSeatCount": "0","endSeatCount": "0","discountPercent": "0.00"}]},"successorPlans": [],"billingAddress": {"phone": "+1 5105555555","firstName": "Unit","lastName": "Test","email": "unit@test.com"},"billingAddressIsCreditCardAddress": "true"}');
			} else { // GET account
				Datetime billingStart = Datetime.now().addDays(-1);
				Datetime billingEnd = billingStart.addDays(10);
				response.setBody('{"currentPlanId":"' + String.valueOf(DocuSign.TRIAL_PLAN_ID) + '","planName":"TRIAL_30_DAY","planStartDate":"2017-01-05T17:54:37.1800000Z","planEndDate":"2018-01-05T17:54:37.1800000Z","billingPeriodStartDate":' + JSON.serialize(billingStart) + ',"billingPeriodEndDate":' + JSON.serialize(billingEnd) + ',"billingPeriodEnvelopesSent":"4","billingPeriodEnvelopesAllowed":"unlimited","billingPeriodDaysRemaining":"0","canUpgrade":"false","canCancelRenewal":"false","envelopeSendingBlocked":"false","envelopeUnitPrice":"$0.00","suspensionStatus":"","accountName":"DocuSign","connectPermission":"full","docuSignLandingUrl":"http://www.docusign.com/products/sign_up/buy_now.php","distributorCode":"DEVCENTER_DEMO_APRIL2013","accountIdGuid":"67db8eaa-8e05-486b-a146-8cb2b93d1aa4","currencyCode":"USD","forgottenPasswordQuestionsCount":"1","paymentMethod":"purchase_order","seatsAllowed":"unlimited","seatsInUse":"1","createdDate":"2017-01-05T17:54:36.7770000Z","isDowngrade":"false","billingProfile":"web","allowTransactionRooms":"false"}');
			}
			return response;
		}
	}

	@IsTest
	static void test_getAccount_trial() {
		Test.setMock(HttpCalloutMock.class, new TrialAccountMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Account result = AccountService.getAccount();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertNotEquals(null, result.trialStatus);
		}
	}

	@IsTest
	static void test_getAccount_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Account result1 = AccountService.getAccount();
			Account result2 = AccountService.getAccount();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assert(result1 === result2);
			System.assertEquals(null, result1.trialStatus);
		}
	}

	@IsTest
	static void test_getTrialStatus() {
		Date today = Date.today();

		// Expires today
		Account account1 = new Account(UUID.randomUUID(), 1234L, 'Unit test 1', 'active',
			new Account.Plan(DocuSign.TRIAL_PLAN_ID, 'Plan 1', today, today),
			new Account.Billing(today, today),
			Account.ConnectPermission.Full);

		// Expires in 1 day
		Account account2 = new Account(UUID.randomUUID(), 1234L, 'Unit test 2', 'active',
			new Account.Plan(DocuSign.TRIAL_PLAN_ID, 'Plan 2', today, today.addDays(1)),
			new Account.Billing(today, today.addDays(1)),
			Account.ConnectPermission.Full);

		// Expires in 2 days
		Account account3 = new Account(UUID.randomUUID(), 1234L, 'Unit test 3', 'active',
			new Account.Plan(DocuSign.TRIAL_PLAN_ID, 'Plan 3', today, today.addDays(2)),
			new Account.Billing(today, today.addDays(2)),
			Account.ConnectPermission.Full);

		// Expires in > 7 days
		Account account5 = new Account(UUID.randomUUID(), 1234L, 'Unit test 5', 'active',
			new Account.Plan(DocuSign.TRIAL_PLAN_ID, 'Plan 5', today, today.addDays(10)),
			new Account.Billing(today, today.addDays(10)),
			Account.ConnectPermission.Full);

		// Not trial plan
		Account account6 = new Account(UUID.randomUUID(), 1234L, 'Unit test 6', 'active',
			new Account.Plan(UUID.randomUUID(), 'Plan 6', today, today.addDays(-1)),
			new Account.Billing(today, today.addDays(-1)),
			Account.ConnectPermission.Full);

		// Expired
		Account account7 = new Account(UUID.randomUUID(), 1234L, 'Unit test 1', 'active',
			new Account.Plan(DocuSign.TRIAL_PLAN_ID, 'Plan 1', today, today),
			new Account.Billing(today.addDays(-10), today.addDays(-9)),
			Account.ConnectPermission.Full);

		Test.startTest();
		Account.TrialStatus result1 = AccountService.getTrialStatus(account1); // today
		Account.TrialStatus result2 = AccountService.getTrialStatus(account2); // 1 day
		Account.TrialStatus result3 = AccountService.getTrialStatus(account3); // 2 days
		Account.TrialStatus result5 = AccountService.getTrialStatus(account5); // > 7 days
		Account.TrialStatus result6 = AccountService.getTrialStatus(account6); // not trial
		Account.TrialStatus result7 = AccountService.getTrialStatus(account7); // expired
		Test.stopTest();

		System.assertNotEquals(null, result1);
		System.assert(!result1.isExpired);
		System.assertEquals(Label.TrialAccountExpiresToday, result1.message);

		System.assertNotEquals(null, result2);
		System.assert(!result2.isExpired);
		System.assertEquals(Label.TrialAccountExpiresOneDay, result2.message);

		System.assertNotEquals(null, result3);
		System.assert(!result3.isExpired);
		System.assertEquals(String.format(Label.TrialAccountExpiresSoon_1, new List<String> { '2' }), result3.message);

		System.assertNotEquals(null, result5);
		System.assert(!result5.isExpired);
		System.assertEquals(null, result5.message);

		System.assertNotEquals(null, result6);
		System.assert(!result6.isExpired);
		System.assertEquals(null, result6.message);

		System.assertNotEquals(null, result7);
		System.assert(result7.isExpired);
		System.assertEquals(Label.TrialAccountExpired, result7.message);
	}

	@IsTest
	static void test_getDocuSignUrl_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Url result = AccountService.getDocuSignUrl();
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_getDocuSignUrl_failure() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AccountService.getDocuSignUrl();
				throw new AssertException('Expected getDocuSignUrl to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.UnauthorizedPageAccess, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getSettings_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				AccountService.getSettings();
				throw new AssertException('Expected getSettings to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getSettings_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			AccountSettings result = AccountService.getSettings();
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_saveSettings_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AccountService.saveSettings(null);
				throw new AssertException('Expected save to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_saveSettings_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			UUID ssId = UUID.randomUUID();
			AccountSettings s = new AccountSettings(
				12345,
				new List<String> { 'er1', 'er2' },
				new List<String> { 'dr1', 'dr2' },
				new List<String> { 'rr1', 'rr2' },
				'CompoundMatchBeginning',
				ssId);

			Test.startTest();
			AccountSettings result = AccountService.saveSettings(s);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(!(result === s));
			System.assertEquals(12345, result.calloutTimeout);
			System.assertEquals(new List<String> { 'er1', 'er2' }, result.entityResolvers);
			System.assertEquals(new List<String> { 'dr1', 'dr2' }, result.documentResolvers);
			System.assertEquals(new List<String> { 'rr1', 'rr2' }, result.recipientResolvers);
			System.assertEquals(Recipient.SearchBehavior.CompoundMatchBeginning.name(), result.recipientSearchBehavior);
			System.assertEquals(ssId, result.systemSenderId);
		}
	}

	@IsTest
	static void test_executePostInstallScripts_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				AccountService.executePostInstallScripts();
				throw new AssertException('Expected executePostInstallScripts to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_executePostInstallScripts_success() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			PostInstallResults result = AccountService.executePostInstallScripts();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.success);
		}
	}
}
