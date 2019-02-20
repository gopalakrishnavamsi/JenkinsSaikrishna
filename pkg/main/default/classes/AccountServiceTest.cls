@IsTest
public class AccountServiceTest {

	private static final UUID ID1 = UUID.parse('11111111-1111-1111-1111-111111111111');
	private static final UUID ID2 = UUID.parse('22222222-2222-2222-2222-222222222222');

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

	public class ExpiredAccountMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');
			if (request.getEndpoint().endsWith('/billing_plan')) {
				response.setBody('{"billingPlan": {"planId": "' + String.valueOf(DocuSign.TRIAL_PLAN_ID) + '","planName": "DocuSign for Salesforce 30 Day Expire","paymentCycle": "annually","paymentMethod": "free_trial","perSeatPrice": "$0.00","otherDiscountPercent": "0.00","supportIncidentFee": "$0.00","supportPlanFee": "$0.00","includedSeats": "1","enableSupport": "false","currencyCode": "USD","planClassification": "partner","seatDiscounts": [{"beginSeatCount": "0","endSeatCount": "0","discountPercent": "0.00"}]},"successorPlans": [],"billingAddress": {"phone": "+1 5105555555","firstName": "Unit","lastName": "Test","email": "unit@test.com"},"billingAddressIsCreditCardAddress": "true"}');
			} else { // GET account
				response.setBody('{"currentPlanId":"' + String.valueOf(DocuSign.TRIAL_PLAN_ID) + '","planName":"TRIAL_30_DAY","planStartDate":"2017-01-05T17:54:37.1800000Z","planEndDate":"2018-01-05T17:54:37.1800000Z","billingPeriodStartDate":"2017-01-05T08:00:00.0000000Z","billingPeriodEndDate":"2017-02-05T08:00:00.0000000Z","billingPeriodEnvelopesSent":"4","billingPeriodEnvelopesAllowed":"unlimited","billingPeriodDaysRemaining":"0","canUpgrade":"false","canCancelRenewal":"false","envelopeSendingBlocked":"false","envelopeUnitPrice":"$0.00","suspensionStatus":"","accountName":"DocuSign","connectPermission":"full","docuSignLandingUrl":"http://www.docusign.com/products/sign_up/buy_now.php","distributorCode":"DEVCENTER_DEMO_APRIL2013","accountIdGuid":"67db8eaa-8e05-486b-a146-8cb2b93d1aa4","currencyCode":"USD","forgottenPasswordQuestionsCount":"1","paymentMethod":"purchase_order","seatsAllowed":"unlimited","seatsInUse":"1","createdDate":"2017-01-05T17:54:36.7770000Z","isDowngrade":"false","billingProfile":"web","allowTransactionRooms":"false"}');
			}
			return response;
		}
	}

	@IsTest
	static void test_getAccount_expired() {
		Test.setMock(HttpCalloutMock.class, new ExpiredAccountMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AccountService.getAccount();
				throw new AssertException('Expected getAccount to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.TrialAccountExpired, ex.getMessage());
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
		Account account1 = new Account(UUID.randomUUID(), 1234L, 'Unit test 1',
			new Account.Plan(DocuSign.TRIAL_PLAN_ID, 'Plan 1', today, today),
			new Account.Billing(today, today),
			Account.ConnectPermission.Full);

		// Expires in 1 day
		Account account2 = new Account(UUID.randomUUID(), 1234L, 'Unit test 2',
			new Account.Plan(DocuSign.TRIAL_PLAN_ID, 'Plan 2', today, today.addDays(1)),
			new Account.Billing(today, today.addDays(1)),
			Account.ConnectPermission.Full);

		// Expires in 2 days
		Account account3 = new Account(UUID.randomUUID(), 1234L, 'Unit test 3',
			new Account.Plan(DocuSign.TRIAL_PLAN_ID, 'Plan 3', today, today.addDays(2)),
			new Account.Billing(today, today.addDays(2)),
			Account.ConnectPermission.Full);

		// Expired yesterday
		Account account4 = new Account(UUID.randomUUID(), 1234L, 'Unit test 4',
			new Account.Plan(DocuSign.TRIAL_PLAN_ID, 'Plan 4', today, today.addDays(-1)),
			new Account.Billing(today, today.addDays(-1)),
			Account.ConnectPermission.Full);

		// Expires in > 7 days
		Account account5 = new Account(UUID.randomUUID(), 1234L, 'Unit test 5',
			new Account.Plan(DocuSign.TRIAL_PLAN_ID, 'Plan 5', today, today.addDays(10)),
			new Account.Billing(today, today.addDays(10)),
			Account.ConnectPermission.Full);

		// Not trial plan
		Account account6 = new Account(UUID.randomUUID(), 1234L, 'Unit test 6',
			new Account.Plan(UUID.randomUUID(), 'Plan 6', today, today.addDays(-1)),
			new Account.Billing(today, today.addDays(-1)),
			Account.ConnectPermission.Full);

		Test.startTest();
		Account.TrialStatus result1 = AccountService.getTrialStatus(account1); // today
		Account.TrialStatus result2 = AccountService.getTrialStatus(account2); // 1 day
		Account.TrialStatus result3 = AccountService.getTrialStatus(account3); // 2 days
		Account.TrialStatus result4 = AccountService.getTrialStatus(account4); // expired
		Account.TrialStatus result5 = AccountService.getTrialStatus(account5); // > 7 days
		Account.TrialStatus result6 = AccountService.getTrialStatus(account6); // not trial
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

		System.assertNotEquals(null, result4);
		System.assert(result4.isExpired);
		System.assertEquals(Label.TrialAccountExpired, result4.message);

		System.assertNotEquals(null, result5);
		System.assert(!result5.isExpired);
		System.assertEquals(null, result5.message);

		System.assertNotEquals(null, result6);
		System.assert(!result6.isExpired);
		System.assertEquals(null, result6.message);
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
	static void test_getUsers_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				AccountService.getUsers();
				throw new AssertException('Expected getUsers to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getUsers_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			UserMock.createDocuSignUser(false);
			UserMock.createDocuSignUser(false);
			UserMock.createDocuSignAdministrator(false);

			Test.startTest();
			List<Account.User> result = AccountService.getUsers();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.size() >= 4);
		}
	}

	class UserPartialSuccessMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');

			if (request.getMethod() == 'POST') {
				response.setBody('{"newUsers": [{"userId": "11111111-1111-1111-1111-111111111111","userName": "user1","email": "user1@unit.test","apiPassword":"pw1"},{"userId": "22222222-2222-2222-2222-222222222222","userName": "user2","email": "user2@unit.test","errorDetails": {"errorCode": "SOME_ERROR","message": "Error message"}}]}');
			} else { // DELETE
				response.setBody('{"users": [{"userId": "11111111-1111-1111-1111-111111111111","userName": "user1","email": "user1@unit.test","apiPassword":"pw1"},{"userId": "22222222-2222-2222-2222-222222222222","userName": "user2","email": "user2@unit.test","errorDetails": {"errorCode": "SOME_ERROR","message":"Error message"}}]}');
			}

			return response;
		}
	}

	class UserExistenceMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setStatus('OK');
			response.setHeader('Content-Type', 'application/json; charset=utf-8');

			if (request.getMethod() == 'POST') {
				response.setBody('{"newUsers": [{"userId": "11111111-1111-1111-1111-111111111111","userName": "user1","email": "user1@unit.test","apiPassword":"pw1"},{"userId": "22222222-2222-2222-2222-222222222222","userName": "user2","email": "user2@unit.test","errorDetails": {"errorCode": "USER_ALREADY_EXISTS_IN_ACCOUNT","message": "User already exists"}}]}');
			} else { // DELETE
				response.setBody('{"users": [{"userId": "11111111-1111-1111-1111-111111111111","userName": "user1","email": "user1@unit.test","apiPassword":"pw1"},{"userId": "22222222-2222-2222-2222-222222222222","userName": "user2","email": "user2@unit.test","apiPassword":"pw2","errorDetails": {"errorCode": "USER_DOES_NOT_EXIST_IN_SYSTEM","message": "User not found"}}]}');
			}

			return response;
		}
	}

	@IsTest
	static void test_addUsers_already_exists() {
		Test.setMock(HttpCalloutMock.class, new UserExistenceMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = UserMock.createUser(UserInfo.getProfileId(), u1Email, null, false);
			User u2 = UserMock.createUser(UserInfo.getProfileId(), u2Email, null, false);

			Test.startTest();
			List<Account.User> result = AccountService.addUsers(new List<Account.User> {
				new Account.User(u1.Id, u1Email, 'User', 'One', true),
				new Account.User(u2.Id, u2Email, 'User', 'Two', false)
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(ID1.toString(), [SELECT Username__c FROM User WHERE Id = :u1.Id LIMIT 1].Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(!result[1].hasError);
			System.assertEquals(ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertEquals(ID2.toString(), [SELECT Username__c FROM User WHERE Id = :u2.Id LIMIT 1].Username__c);
		}
	}

	@IsTest
	static void test_addUsers_success_partial() {
		Test.setMock(HttpCalloutMock.class, new UserPartialSuccessMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = UserMock.createUser(UserInfo.getProfileId(), u1Email, null, false);
			User u2 = UserMock.createUser(UserInfo.getProfileId(), u2Email, null, false);

			Test.startTest();
			List<Account.User> result = AccountService.addUsers(new List<Account.User> {
				new Account.User(u1.Id, u1Email, 'User', 'One', true),
				new Account.User(u2.Id, u2Email, 'User', 'Two', false)
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(ID1.toString(), [SELECT Username__c FROM User WHERE Id = :u1.Id LIMIT 1].Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(result[1].hasError);
			System.assertNotEquals(null, result[1].error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, result[1].error.code);
			System.assertEquals('[SOME_ERROR] Error message', result[1].error.description);
			System.assertEquals(ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u2.Id LIMIT 1].Username__c);
		}
	}

	@IsTest
	static void test_addUsers_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = UserMock.createUser(UserInfo.getProfileId(), u1Email, null, false);
			User u2 = UserMock.createUser(UserInfo.getProfileId(), u2Email, null, false);

			Test.startTest();
			List<Account.User> result = AccountService.addUsers(new List<Account.User> {
				new Account.User(u1.Id, u1Email, 'User', 'One', true),
				new Account.User(u2.Id, u2Email, 'User', 'Two', false)
			});
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertNotEquals(null, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertNotEquals(null, [SELECT Username__c FROM User WHERE Id = :u1.Id LIMIT 1].Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(!result[1].hasError);
			System.assertNotEquals(null, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertNotEquals(null, [SELECT Username__c FROM User WHERE Id = :u2.Id LIMIT 1].Username__c);
		}
	}

	@IsTest
	static void test_removeUsers_self() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			User u1 = UserMock.createUser();

			Test.startTest();
			try {
				AccountService.removeUsers(new List<Account.User> {
					new Account.User(u1.Id, 'u1@unit.test', 'User', 'One', true),
					new Account.User(UserInfo.getUserId(), 'u2@unit.test', 'User', 'Two', false)
				}, true);
				throw new AssertException('Expected removeUsers to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.CannotRemoveSelf, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_removeUsers_not_found() {
		Test.setMock(HttpCalloutMock.class, new UserExistenceMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = UserMock.createUser(UserInfo.getProfileId(), u1Email, UUID.randomUUID(), false);
			User u2 = UserMock.createUser(UserInfo.getProfileId(), u2Email, UUID.randomUUID(), false);
			UserSettings__c us1 = UserSettings__c.getInstance(u1.Id);
			us1.AccessToken0__c = UUID.randomUUID().toString();
			us1.Nonce__c = UUID.randomUUID().toString();
			UserSettings__c us2 = UserSettings__c.getInstance(u2.Id);
			us2.AccessToken0__c = UUID.randomUUID().toString();
			us2.Nonce__c = UUID.randomUUID().toString();
			upsert new List<UserSettings__c> { us1, us2 };

			Test.startTest();
			List<Account.User> result = AccountService.removeUsers(new List<Account.User> {
				new Account.User(u1.Id, u1Email, 'User', 'One', true),
				new Account.User(u2.Id, u2Email, 'User', 'Two', false)
			}, true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).AccessToken0__c);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).Nonce__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u1.Id LIMIT 1].Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(!result[1].hasError);
			System.assertEquals(ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u2.Id).AccessToken0__c);
			System.assertEquals(null, UserSettings__c.getInstance(u2.Id).Nonce__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u2.Id LIMIT 1].Username__c);
		}
	}

	@IsTest
	static void test_removeUsers_success_partial() {
		Test.setMock(HttpCalloutMock.class, new UserPartialSuccessMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = UserMock.createUser(UserInfo.getProfileId(), u1Email, UUID.randomUUID(), false);
			User u2 = UserMock.createUser(UserInfo.getProfileId(), u2Email, UUID.randomUUID(), false);
			UserSettings__c us1 = UserSettings__c.getInstance(u1.Id);
			us1.AccessToken0__c = UUID.randomUUID().toString();
			us1.Nonce__c = UUID.randomUUID().toString();
			UserSettings__c us2 = UserSettings__c.getInstance(u2.Id);
			us2.AccessToken0__c = UUID.randomUUID().toString();
			us2.Nonce__c = UUID.randomUUID().toString();
			upsert new List<UserSettings__c> { us1, us2 };

			Test.startTest();
			List<Account.User> result = AccountService.removeUsers(new List<Account.User> {
				new Account.User(u1.Id, u1Email, 'User', 'One', true),
				new Account.User(u2.Id, u2Email, 'User', 'Two', false)
			}, true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).Nonce__c);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).AccessToken0__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u1.Id].Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(result[1].hasError);
			System.assertNotEquals(null, result[1].error);
			System.assertEquals(APIErrorCode.BAD_REQUEST, result[1].error.code);
			System.assertEquals('[SOME_ERROR] Error message', result[1].error.description);
			System.assertEquals(ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertNotEquals(null, UserSettings__c.getInstance(u2.Id).Nonce__c);
			System.assertNotEquals(null, UserSettings__c.getInstance(u2.Id).AccessToken0__c);
			System.assertEquals(u2.Username__c, [SELECT Username__c FROM User WHERE Id = :u2.Id].Username__c);
		}
	}

	@IsTest
	static void test_removeUsers_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());

		System.runAs(UserMock.createDocuSignAdministrator()) {
			String u1Email = 'user1@unit.test';
			String u2Email = 'user2@unit.test';
			User u1 = UserMock.createUser(UserInfo.getProfileId(), u1Email, UUID.randomUUID(), false);
			User u2 = UserMock.createUser(UserInfo.getProfileId(), u2Email, UUID.randomUUID(), false);
			UserSettings__c us1 = UserSettings__c.getInstance(u1.Id);
			us1.Nonce__c = UUID.randomUUID().toString();
			us1.AccessToken0__c = UUID.randomUUID().toString();
			UserSettings__c us2 = UserSettings__c.getInstance(u2.Id);
			us2.Nonce__c = UUID.randomUUID().toString();
			us2.AccessToken0__c = UUID.randomUUID().toString();
			upsert new List<UserSettings__c> { us1, us2 };

			Test.startTest();
			List<Account.User> result = AccountService.removeUsers(new List<Account.User> {
				new Account.User(
					ID1,
					u1.Id,
					u1Email,
					'User',
					'One',
					Account.USER_STATUS_ACTIVE,
					null,
					null,
					true,
					null,
					null),
				new Account.User(
					ID2,
					u2.Id,
					u2Email,
					'User',
					'Two',
					Account.USER_STATUS_PENDING,
					null,
					null,
					false,
					null,
					null)
			}, true);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(2, result.size());

			System.assertNotEquals(null, result[0]);
			System.assert(!result[0].hasError);
			System.assertEquals(ID1, result[0].id);
			System.assertEquals(u1.Id, result[0].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).Nonce__c);
			System.assertEquals(null, UserSettings__c.getInstance(u1.Id).AccessToken0__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u1.Id].Username__c);

			System.assertNotEquals(null, result[1]);
			System.assert(!result[1].hasError);
			System.assertEquals(ID2, result[1].id);
			System.assertEquals(u2.Id, result[1].sourceId);
			System.assertEquals(null, UserSettings__c.getInstance(u2.Id).Nonce__c);
			System.assertEquals(null, UserSettings__c.getInstance(u2.Id).AccessToken0__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :u2.Id].Username__c);
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

	@IsTest
	static void test_getAvailableSystemSenders_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				AccountService.getAvailableSystemSenders();
				throw new AssertException('Expected getAvailableSystemSenders to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getAvailableSystemSenders_success() {
		User dsa1 = UserMock.createDocuSignAdministrator(false);
		User dsa2 = UserMock.createDocuSignAdministrator(false);
		User dsa3 = UserMock.createDocuSignAdministrator(false);
		User dsu1 = UserMock.createDocuSignUser(false);
		User dsu2 = UserMock.createDocuSignUser(false);
		System.runAs(dsa1) {
			dsa2.IsActive = false;
			update dsa2;
			// dsa1, dsa3 are the only eligible system senders outside of any DS admins configured outside of this unit
			// test. dsa2 is not active and should not be returned, and dsu1 and dsu2 are not admins and therefore
			// ineligible system senders.
			Set<String> invalidUsernames = new Set<String> { dsa2.Username__c, dsu1.Username__c, dsu2.Username__c };

			Test.startTest();
			List<AccountService.SystemSender> result = AccountService.getAvailableSystemSenders();
			Test.stopTest();

			System.assert(Collection.size(result) >= 2);
			Boolean foundDSA1 = false, foundDSA3 = false;
			for (AccountService.SystemSender ss : result) {
				String username = String.valueOf(ss.id);
				if (username == dsa1.Username__c) {
					foundDSA1 = true;
					System.assertEquals(
						String.format(Label.AccountDisplay_2, new List<String> { dsa1.Name, dsa1.Email }),
						ss.display);
				} else if (username == dsa3.Username__c) {
					foundDSA3 = true;
					System.assertEquals(
						String.format(Label.AccountDisplay_2, new List<String> { dsa3.Name, dsa3.Email }),
						ss.display);
				} else if (invalidUsernames.contains(username)) {
					throw new AssertException('Unexpected system sender: ' + ss);
				}
			}
			System.assert(foundDSA1);
			System.assert(foundDSA3);
		}
	}
}
