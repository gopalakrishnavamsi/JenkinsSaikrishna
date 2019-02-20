@IsTest
private class AuthServiceTest {

	private static AuthService.AuthAPI client;

	private static AuthService.AuthAPI getAuthClient() {
		if (client == null) {
			client = new AuthService.AuthAPI(new Url('https://unit.test.docusign.com/'));
		}
		return client;
	}

	@IsTest
	static void test_base64UrlEncode() {
		System.assertEquals('', AuthService.base64UrlEncode(null));
		System.assertEquals('YWJjZA', AuthService.base64UrlEncode(Blob.valueOf('abcd')));
		System.assertEquals('YWJjZCBlZmdo', AuthService.base64UrlEncode(Blob.valueOf('abcd efgh')));
	}

	@IsTest
	static void test_database_updateSettings() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			AuthService.PermissionProfileIds ppIds = new AuthService.PermissionProfileIds(1111L, 2222L);
			Gen.Product p = new Gen.Product(
				'active',
				false,
				null,
				null,
				null,
				new Url('https://callback.test.springcm.com/'),
				new Url('https://redirect.test.springcm.com/'),
				'email subject',
				'email body');

			Test.startTest();
			AccountSettings__c result = AuthService.DB.updateSettings(ppIds, p);
			Test.stopTest();

			System.assertNotEquals(null, result);
			List<Configuration__c> cs = [
				SELECT InviteEmailSubject__c, InviteEmailBody__c
				FROM Configuration__c
				WHERE Name = 'Gen'
				LIMIT 1000
			];
			System.assertEquals(1, Collection.size(cs));
			System.assertEquals(cs[0].InviteEmailSubject__c, p.inviteEmailSubject);
			System.assertEquals(cs[0].InviteEmailBody__c, p.inviteEmailBody);
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			System.assertEquals(ppIds.administratorId, (Long)s.AdministratorProfileId__c);
			System.assertEquals(ppIds.senderId, (Long)s.SenderProfileId__c);
			System.assertEquals(p.inviteCallbackUrl.toExternalForm(), s.InviteCallbackUrl__c);
			System.assertEquals(p.inviteRedirectUrl.toExternalForm(), s.InviteRedirectUrl__c);
		}
	}

	@IsTest
	static void test_AuthAPI_constructor() {
		System.assertNotEquals(null, new AuthService.AuthAPI(new Url('https://account.docusign.com/')));
		try {
			new AuthService.AuthAPI(null);
			throw new AssertException('Expected AuthService.AuthAPI constructor to throw exception');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
		}
		try {
			new AuthService.AuthAPI(new Url('https://evil-account-docusign.com/'));
			throw new AssertException('Expected AuthService.AuthAPI constructor to throw exception');
		} catch (DocuSignException ex) {
			System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
		}
	}

	@IsTest
	static void test_AuthAPI_getError() {
		HttpResponse resp1 = new HttpResponse(), // 200
			resp2 = new HttpResponse(), // 400 consent_required
			resp3 = new HttpResponse(), // 400 invalid_grant
			resp4 = new HttpResponse(), // 400 other
			resp5 = new HttpResponse(); // 400 unknown
		resp1.setStatusCode(200);
		resp1.setHeader('Content-Type', 'application/json');
		resp2.setStatusCode(400);
		resp2.setHeader('Content-Type', 'application/json');
		resp2.setBody('{"error":"consent_required"}');
		resp3.setStatusCode(400);
		resp3.setHeader('Content-Type', 'application/json');
		resp3.setBody('{"error":"invalid_grant"}');
		resp4.setStatusCode(400);
		resp4.setHeader('Content-Type', 'application/json');
		resp4.setBody('{"error":"other","error_message":"other error"}');
		resp5.setStatusCode(400);
		resp5.setStatus('UNKNOWN');
		resp5.setHeader('Content-Type', 'application/json');
		resp5.setBody('');

		Test.startTest();
		APIError result1 = getAuthClient().getError(resp1);
		APIError result2 = getAuthClient().getError(resp2);
		APIError result3 = getAuthClient().getError(resp3);
		APIError result4 = getAuthClient().getError(resp4);
		APIError result5 = getAuthClient().getError(resp5);
		Test.stopTest();

		System.assertEquals(APIError.none, result1);

		System.assertNotEquals(null, result2);
		System.assertEquals(APIErrorCode.UNAUTHORIZED, result2.code);
		System.assert(result2 instanceof AuthService.AuthError);
		System.assertEquals(APIErrorCode.CONSENT_REQUIRED, ((AuthService.AuthError)result2).reason);
		System.assertEquals(Label.ConsentRequired, result2.description);

		System.assertNotEquals(null, result3);
		System.assertEquals(APIErrorCode.UNAUTHORIZED, result3.code);
		System.assert(result3 instanceof AuthService.AuthError);
		System.assertEquals(APIErrorCode.INVALID_GRANT, ((AuthService.AuthError)result3).reason);
		System.assertEquals(Label.InvalidGrant, result3.description);

		System.assertNotEquals(null, result4);
		System.assertEquals(APIErrorCode.UNAUTHORIZED, result4.code);
		System.assert(result4 instanceof AuthService.AuthError);
		System.assertEquals(APIErrorCode.BAD_REQUEST, ((AuthService.AuthError)result4).reason);
		System.assertEquals('other error', result4.description);

		System.assertNotEquals(null, result5);
		System.assert(!(result5 instanceof AuthService.AuthError));
		System.assertEquals(APIErrorCode.BAD_REQUEST, result5.code);
		System.assertEquals('UNKNOWN', result5.description);
	}

	@IsTest
	static void test_AuthAPI_getBasicAuthHeader() {
		System.assertEquals(
			'Basic ' + EncodingUtil.base64Encode(Blob.valueOf('username:password')),
			getAuthClient().getBasicAuthHeader('username', 'password'));
	}

	@IsTest
	static void test_getRootCredentials_undefined() {
		Test.startTest();
		AuthService.RootCredentials result = AuthService.getRootCredentials(null, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.Production, result.environment);
		System.assertNotEquals(null, result.accountBaseUrl);
		System.assertNotEquals(null, result.provisioningBaseUrl);
		AuthService.RootCredentials ccs = AuthService.convert(
			DocuSign.Environment.Production,
		[
			SELECT AccountBaseUrl__c, ProvisioningBaseUrl__c, ClientId__c, ClientSecret__c
			FROM Environment__mdt
			WHERE DeveloperName = 'Production'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.accountBaseUrl.toExternalForm(), result.accountBaseUrl.toExternalForm());
		System.assertEquals(ccs.provisioningBaseUrl.toExternalForm(), result.provisioningBaseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
	}

	@IsTest
	static void test_getRootCredentials_Invalid() {
		Test.startTest();
		AuthService.RootCredentials result = AuthService.getRootCredentials(DocuSign.Environment.Invalid, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.Production, result.environment);
		System.assertNotEquals(null, result.accountBaseUrl);
		System.assertNotEquals(null, result.provisioningBaseUrl);
		AuthService.RootCredentials ccs = AuthService.convert(
			DocuSign.Environment.Production,
		[
			SELECT AccountBaseUrl__c, ProvisioningBaseUrl__c, ClientId__c, ClientSecret__c
			FROM Environment__mdt
			WHERE DeveloperName = 'Production'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.accountBaseUrl.toExternalForm(), result.accountBaseUrl.toExternalForm());
		System.assertEquals(ccs.provisioningBaseUrl.toExternalForm(), result.provisioningBaseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
	}

	@IsTest
	static void test_getRootCredentials_Production() {
		Test.startTest();
		AuthService.RootCredentials result = AuthService.getRootCredentials(DocuSign.Environment.Production, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.Production, result.environment);
		System.assertNotEquals(null, result.accountBaseUrl);
		System.assertNotEquals(null, result.provisioningBaseUrl);
		AuthService.RootCredentials ccs = AuthService.convert(
			DocuSign.Environment.Production,
		[
			SELECT AccountBaseUrl__c, ProvisioningBaseUrl__c, ClientId__c, ClientSecret__c
			FROM Environment__mdt
			WHERE DeveloperName = 'Production'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.accountBaseUrl.toExternalForm(), result.accountBaseUrl.toExternalForm());
		System.assertEquals(ccs.provisioningBaseUrl.toExternalForm(), result.provisioningBaseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
	}

	@IsTest
	static void test_getRootCredentials_Other() {
		Url otherUrl = new Url('https://other.docusignhq.com');

		Test.startTest();
		AuthService.RootCredentials result = AuthService.getRootCredentials(DocuSign.Environment.Other, otherUrl);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.Other, result.environment);
		System.assertNotEquals(null, result.accountBaseUrl);
		System.assertNotEquals(null, result.provisioningBaseUrl);
		AuthService.RootCredentials ccs = AuthService.convert(
			DocuSign.Environment.Other,
		[
			SELECT AccountBaseUrl__c, ProvisioningBaseUrl__c, ClientId__c, ClientSecret__c
			FROM Environment__mdt
			WHERE DeveloperName = 'Production'
			LIMIT 1
		],
			otherUrl);
		System.assertEquals(ccs.accountBaseUrl.toExternalForm(), result.accountBaseUrl.toExternalForm());
		System.assertEquals(ccs.provisioningBaseUrl.toExternalForm(), result.provisioningBaseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
	}

	@IsTest
	static void test_getRootCredentials_Demo() {
		Test.startTest();
		AuthService.RootCredentials result = AuthService.getRootCredentials(DocuSign.Environment.Demo, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.Demo, result.environment);
		System.assertNotEquals(null, result.accountBaseUrl);
		System.assertNotEquals(null, result.provisioningBaseUrl);
		AuthService.RootCredentials ccs = AuthService.convert(
			DocuSign.Environment.Demo,
		[
			SELECT AccountBaseUrl__c, ProvisioningBaseUrl__c, ClientId__c, ClientSecret__c
			FROM Environment__mdt
			WHERE DeveloperName = 'Demo'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.accountBaseUrl.toExternalForm(), result.accountBaseUrl.toExternalForm());
		System.assertEquals(ccs.provisioningBaseUrl.toExternalForm(), result.provisioningBaseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
	}

	@IsTest
	static void test_getRootCredentials_Stage() {
		Test.startTest();
		AuthService.RootCredentials result = AuthService.getRootCredentials(DocuSign.Environment.Stage, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.Stage, result.environment);
		System.assertNotEquals(null, result.accountBaseUrl);
		System.assertNotEquals(null, result.provisioningBaseUrl);
		AuthService.RootCredentials ccs = AuthService.convert(
			DocuSign.Environment.Stage,
		[
			SELECT AccountBaseUrl__c, ProvisioningBaseUrl__c, ClientId__c, ClientSecret__c
			FROM Environment__mdt
			WHERE DeveloperName = 'Stage'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.accountBaseUrl.toExternalForm(), result.accountBaseUrl.toExternalForm());
		System.assertEquals(ccs.provisioningBaseUrl.toExternalForm(), result.provisioningBaseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
	}

	@IsTest
	static void test_getRootCredentials_QA() {
		Test.startTest();
		AuthService.RootCredentials result = AuthService.getRootCredentials(DocuSign.Environment.QA, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.QA, result.environment);
		System.assertNotEquals(null, result.accountBaseUrl);
		System.assertNotEquals(null, result.provisioningBaseUrl);
		AuthService.RootCredentials ccs = AuthService.convert(
			DocuSign.Environment.QA,
		[
			SELECT AccountBaseUrl__c, ProvisioningBaseUrl__c, ClientId__c, ClientSecret__c
			FROM Environment__mdt
			WHERE DeveloperName = 'QA'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.accountBaseUrl.toExternalForm(), result.accountBaseUrl.toExternalForm());
		System.assertEquals(ccs.provisioningBaseUrl.toExternalForm(), result.provisioningBaseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
	}

	@IsTest
	static void test_getRootCredentials_HQTEST0() {
		Test.startTest();
		AuthService.RootCredentials result = AuthService.getRootCredentials(DocuSign.Environment.HQTEST0, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.HQTEST0, result.environment);
		System.assertNotEquals(null, result.accountBaseUrl);
		System.assertNotEquals(null, result.provisioningBaseUrl);
		AuthService.RootCredentials ccs = AuthService.convert(
			DocuSign.Environment.HQTEST0,
		[
			SELECT AccountBaseUrl__c, ProvisioningBaseUrl__c, ClientId__c, ClientSecret__c
			FROM Environment__mdt
			WHERE DeveloperName = 'HQTEST0'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.accountBaseUrl.toExternalForm(), result.accountBaseUrl.toExternalForm());
		System.assertEquals(ccs.provisioningBaseUrl.toExternalForm(), result.provisioningBaseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
	}

	@IsTest
	static void test_getRootCredentials_HQTEST1() {
		Test.startTest();
		AuthService.RootCredentials result = AuthService.getRootCredentials(DocuSign.Environment.HQTEST1, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.HQTEST1, result.environment);
		System.assertNotEquals(null, result.accountBaseUrl);
		System.assertNotEquals(null, result.provisioningBaseUrl);
		AuthService.RootCredentials ccs = AuthService.convert(
			DocuSign.Environment.HQTEST1,
		[
			SELECT AccountBaseUrl__c, ProvisioningBaseUrl__c, ClientId__c, ClientSecret__c
			FROM Environment__mdt
			WHERE DeveloperName = 'HQTEST1'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.accountBaseUrl.toExternalForm(), result.accountBaseUrl.toExternalForm());
		System.assertEquals(ccs.provisioningBaseUrl.toExternalForm(), result.provisioningBaseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
	}

	@IsTest
	static void test_getRootCredentials_HQTEST2() {
		Test.startTest();
		AuthService.RootCredentials result = AuthService.getRootCredentials(DocuSign.Environment.HQTEST2, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.HQTEST2, result.environment);
		System.assertNotEquals(null, result.accountBaseUrl);
		System.assertNotEquals(null, result.provisioningBaseUrl);
		AuthService.RootCredentials ccs = AuthService.convert(
			DocuSign.Environment.HQTEST2,
		[
			SELECT AccountBaseUrl__c, ProvisioningBaseUrl__c, ClientId__c, ClientSecret__c
			FROM Environment__mdt
			WHERE DeveloperName = 'HQTEST2'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.accountBaseUrl.toExternalForm(), result.accountBaseUrl.toExternalForm());
		System.assertEquals(ccs.provisioningBaseUrl.toExternalForm(), result.provisioningBaseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
	}

	@IsTest
	static void test_getRootCredentials_HQTEST3() {
		Test.startTest();
		AuthService.RootCredentials result = AuthService.getRootCredentials(DocuSign.Environment.HQTEST3, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.HQTEST3, result.environment);
		System.assertNotEquals(null, result.accountBaseUrl);
		System.assertNotEquals(null, result.provisioningBaseUrl);
		AuthService.RootCredentials ccs = AuthService.convert(
			DocuSign.Environment.HQTEST3,
		[
			SELECT AccountBaseUrl__c, ProvisioningBaseUrl__c, ClientId__c, ClientSecret__c
			FROM Environment__mdt
			WHERE DeveloperName = 'HQTEST3'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.accountBaseUrl.toExternalForm(), result.accountBaseUrl.toExternalForm());
		System.assertEquals(ccs.provisioningBaseUrl.toExternalForm(), result.provisioningBaseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
	}

	@IsTest
	static void test_generateJwt_user() {
		System.runAs(UserMock.createDocuSignUser()) {
			String aud = 'unit.test.docusign.com';
			String sub = [SELECT Username__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Username__c;
			String iss = UUID.randomUUID().toString();
			Blob jwtSigningKey = TestUtils.TEST_RSA_PRIVATE_KEY;

			Test.startTest();
			String result = AuthService.generateJwt(aud, UUID.parse(sub), false, iss, jwtSigningKey);
			Test.stopTest();

			System.assertNotEquals(null, result);

			List<String> toks = result.split('\\.');
			System.assertEquals(3, Collection.size(toks));

			System.assertEquals(AuthService.JWT_HEADER, toks[0]);

			Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(EncodingUtil.base64Decode(toks[1]).toString());
			System.assertEquals(iss, (String)payload.get('iss'));
			System.assertEquals(sub, (String)payload.get('sub'));
			System.assertNotEquals(null, (Long)payload.get('iat'));
			System.assertNotEquals(null, (Long)payload.get('exp'));
			System.assertEquals(aud, (String)payload.get('aud'));
			System.assertEquals(AuthService.SCOPE_USER, (String)payload.get('scope'));

			String signature = AuthService.base64UrlEncode(Crypto.sign('RSA-SHA256', Blob.valueOf(toks[0] + '.' + toks[1]),
				jwtSigningKey));
			System.assertEquals(signature, toks[2]);
		}
	}

	@IsTest
	static void test_generateJwt_administrator() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			String aud = 'unit.test.docusign.com';
			String sub = [SELECT Username__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Username__c;
			String iss = UUID.randomUUID().toString();
			Blob jwtSigningKey = TestUtils.TEST_RSA_PRIVATE_KEY;

			Test.startTest();
			String result = AuthService.generateJwt(aud, UUID.parse(sub), true, iss, jwtSigningKey);
			Test.stopTest();

			System.assertNotEquals(null, result);

			List<String> toks = result.split('\\.');
			System.assertEquals(3, Collection.size(toks));

			System.assertEquals(AuthService.JWT_HEADER, toks[0]);

			Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(EncodingUtil.base64Decode(toks[1]).toString());
			System.assertEquals(iss, (String)payload.get('iss'));
			System.assertEquals(sub, (String)payload.get('sub'));
			System.assertNotEquals(null, (Long)payload.get('iat'));
			System.assertNotEquals(null, (Long)payload.get('exp'));
			System.assertEquals(aud, (String)payload.get('aud'));
			System.assertEquals(AuthService.SCOPE_ADMIN, (String)payload.get('scope'));

			String signature = AuthService.base64UrlEncode(Crypto.sign('RSA-SHA256', Blob.valueOf(toks[0] + '.' + toks[1]),
				jwtSigningKey));
			System.assertEquals(signature, toks[2]);
		}
	}

	@IsTest
	static void test_AuthAPI_exchangeJwt_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			Credentials.AccessToken result = getAuthClient().exchangeJwt('test');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isValid);
		}
	}

	@IsTest
	static void test_AuthAPI_exchangeJwt_error() {
		ApplicationAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				getAuthClient().exchangeJwt('test');
				throw new AssertException('Expected AuthAPI.exchangeJwt to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.UNAUTHORIZED, ex.error.code);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_AuthAPI_exchangeCode_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			Credentials.AccessToken result = getAuthClient().exchangeCode('1234', null, null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isValid);
		}
	}

	private class ConsentRequiredErrorMock implements HttpCalloutMock {
		public HttpResponse respond(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(400);
			response.setHeader('Content-Type', 'application/json');
			response.setBody('{"error":"consent_required"}');
			return response;
		}
	}

	@IsTest
	static void test_AuthAPI_exchangeCode_error() {
		Test.setMock(HttpCalloutMock.class, new ConsentRequiredErrorMock());
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				getAuthClient().exchangeCode('1234', UUID.randomUUID().toString(), UUID.randomUUID().toString());
				throw new AssertException('Expected AuthAPI.exchangeCode to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assert(ex.error instanceof AuthService.AuthError);
				System.assertEquals(APIErrorCode.CONSENT_REQUIRED, ((AuthService.AuthError)ex.error).reason);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_AuthAPI_getLoginInformation_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			LoginInformation result = getAuthClient().getLoginInformation('test');
			Test.stopTest();

			System.assertNotEquals(null, result);
			UUID userId = UUID.tryParse([SELECT Username__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Username__c);
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			System.assertEquals(userId, result.id);
			System.assertEquals(s.Email__c, result.email);
			System.assertEquals(1, Collection.size(result.accounts));
			System.assertEquals(UUID.tryParse(s.AccountId__c), result.accounts[0].id);
			System.assertEquals(s.AccountNumber__c, result.accounts[0].accountNumber);
			System.assertEquals(s.AccountName__c, result.accounts[0].name);
			System.assertEquals(s.ESignatureBaseUrl__c, result.accounts[0].eSignatureBaseUrl);
			System.assert(result.accounts[0].isDefault);
			System.assertEquals(String.format(Label.AccountDisplay_2, new List<String> {
				result.accounts[0].name, String.valueOf(result.accounts[0].accountNumber)
			}), result.accounts[0].display);
		}
	}

	@IsTest
	static void test_AuthAPI_getLoginInformation_error() {
		DocuSignAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				getAuthClient().getLoginInformation('test');
				throw new AssertException('Expected AuthAPI.getLoginInformation to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.UNAUTHORIZED, ex.error.code);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_AuthAPI_getInstanceClientId_failure() {
		ApplicationAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				getAuthClient().getInstanceClientId(UUID.randomUUID().toString(), UUID.randomUUID(), 'test');
				throw new AssertException('Expected AuthAPI.getInstanceClientId to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.unauthorized, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_AuthAPI_getInstanceClientId_success() {
		ApplicationAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			String result = getAuthClient().getInstanceClientId(UUID.randomUUID().toString(), UUID.randomUUID(), 'test');
			Test.stopTest();

			System.assert(String.isNotBlank(result));
		}
	}

	@IsTest
	static void test_AuthAPI_getInstanceClientSecret_failure() {
		ApplicationAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				getAuthClient().getInstanceClientSecret(UUID.randomUUID().toString(), 'test');
				throw new AssertException('Expected AuthAPI.getInstanceClientSecret to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.unauthorized, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_AuthAPI_getInstanceClientSecret_success() {
		ApplicationAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			String result = getAuthClient().getInstanceClientSecret(UUID.randomUUID().toString(), 'test');
			Test.stopTest();

			System.assert(String.isNotBlank(result));
		}
	}

	@IsTest
	static void test_AuthAPI_getInstancePrivateKey_failure() {
		ApplicationAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				getAuthClient().getInstancePrivateKey(UUID.randomUUID().toString(), 'test');
				throw new AssertException('Expected AuthAPI.getInstancePrivateKey to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.unauthorized, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_AuthAPI_getInstancePrivateKey_success() {
		ApplicationAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Blob result = getAuthClient().getInstancePrivateKey(UUID.randomUUID().toString(), 'test');
			Test.stopTest();

			System.assertNotEquals(null, result);
		}
	}

	@IsTest
	static void test_AuthAPI_setInstanceRedirectUris_failure() {
		ApplicationAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				getAuthClient().setInstanceRedirectUris(UUID.randomUUID().toString(), new List<Url>(), 'test');
				throw new AssertException('Expected AuthAPI.setInstanceRedirectUris to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.unauthorized, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_AuthAPI_setInstanceRedirectUris_success() {
		ApplicationAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			List<Url> redirectUris = new List<Url> {
				new Url('https://redirect1.unit.test'),
				new Url('https://redirect2.unit.test')
			};

			Test.startTest();
			List<Url> result = getAuthClient().setInstanceRedirectUris(UUID.randomUUID().toString(), redirectUris, 'test');
			Test.stopTest();

			System.assertEquals(2, Collection.size(result));
			System.assertEquals(redirectUris[0].toExternalForm(), result[0].toExternalForm());
			System.assertEquals(redirectUris[1].toExternalForm(), result[1].toExternalForm());
		}
	}

	@IsTest
	static void test_AuthAPI_getInstanceCredentials() {
		ApplicationAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Credentials.ClientCredentials result = getAuthClient().getInstanceCredentials(
				UUID.randomUUID().toString(),
				UUID.randomUUID(),
				new List<Url> {
					new Url('https://invite.callback.test.springcm.com/'),
					new Url('https://invite.redirect.test.springcm.com/')
				},
				'test');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isValid);
		}
	}

	@IsTest
	static void test_AccountAPI_getPermissionProfileIds_failure() {
		ESignatureAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				new AuthService.AccountAPI(
					new Url('https://esign.test.docusign.net'),
					UUID.randomUUID(),
					'test')
					.getPermissionProfileIds();
				throw new AssertException('Expected AccountAPI.getPermissionProfileIds to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_AccountAPI_getPermissionProfileIds_success() {
		ESignatureAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			AuthService.PermissionProfileIds result = new AuthService.AccountAPI(
				new Url('https://esign.test.docusign.net'),
				UUID.randomUUID(),
				'test')
				.getPermissionProfileIds();
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(1111L, result.administratorId);
			System.assertEquals(2222L, result.senderId);
		}
	}

	@IsTest
	static void test_getAccessToken_failure() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				AuthService.getAccessToken(null, null, null, false, null, null);
				throw new AssertException('Expected getAccessToken to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.AccountNotConfigured, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getAccessToken_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignUser()) {
			UserSettings__c s = UserSettings__c.getInstance();
			s.AccessTokenExpires__c = Datetime.now();
			update s;

			Test.startTest();
			String result1 = AuthService.getAccessToken();
			String result2 = AuthService.getAccessToken();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertEquals(result1, result2);
		}
	}

	@IsTest
	static void test_resetCredentials_unauthorized() {
		System.runAs(UserMock.createUser()) {
			Test.startTest();
			try {
				AuthService.resetCredentials(true);
				throw new AssertException('Expected resetCredentials to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_resetCredentials_success() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			AuthService.resetCredentials(true);
			Test.stopTest();

			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			System.assertEquals(null, s.AccountId__c);
			System.assertEquals(null, [SELECT Username__c FROM User WHERE Id = :UserInfo.getUserId()].Username__c);
		}
	}

	@IsTest
	static void test_generateNonce() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			String result1 = AuthService.generateNonce();
			System.assertNotEquals(null, result1);
			System.assertEquals(UserSettings__c.getInstance().Nonce__c, result1);
			String result2 = AuthService.generateNonce();
			System.assertNotEquals(null, result2);
			System.assertNotEquals(result1, result2);
			System.assertEquals(UserSettings__c.getInstance().Nonce__c, result2);
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getLoginUrl_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				AuthService.getLoginUrl(null, null);
				throw new AssertException('Expected getLoginUrl to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getLoginUrl_invalid_environment() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				AuthService.getLoginUrl(null, null);
				throw new AssertException('Expected getLoginUrl to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			try {
				AuthService.getLoginUrl(DocuSign.Environment.Other, null);
				throw new AssertException('Expected getLoginUrl to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			try {
				AuthService.getLoginUrl(DocuSign.Environment.Other, new Url('https://evil-docusign.net/'));
				throw new AssertException('Expected getLoginUrl to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getLoginUrl_success() {
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			TestUtils.generateKey();

			Test.startTest();
			Url result = AuthService.getLoginUrl(DocuSign.Environment.Stage, null);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals('account-s.docusign.com', result.getHost());
			System.assertEquals('/oauth/auth', result.getPath());
			QueryString params = QueryString.parse(result.getQuery());
			System.assertNotEquals(QueryString.empty, params);
			System.assertEquals('code', params.get('response_type'));
			System.assertEquals(AuthService.SCOPE_ADMIN, params.get('scope'));
			System.assertEquals([
				SELECT ClientId__c
				FROM Environment__mdt
				WHERE DeveloperName = 'Stage'
				LIMIT 1
			].ClientId__c, params.get('client_id'));
			System.assertEquals('https://' + (Salesforce.isSandbox ? 'test' : 'login') + '.salesforce.com'
				+ '/apex/' + Application.namespacePrefix + 'completeoauth', params.get('redirect_uri'));
			System.assert(String.isNotBlank(params.get('state')));
		}
	}

	@IsTest
	static void test_encodeState() {
		TestUtils.generateKey();
		String nonce = UUID.randomUUID().toString();
		Url url = new Url('https://unit.test/');

		Test.startTest();
		String state = AuthService.encodeState(nonce, DocuSign.Environment.Stage, url);
		Test.stopTest();

		System.assert(String.isNotBlank(state));
		System.assertEquals(nonce + '|Stage|' + url.toExternalForm(), SecureUtils.decrypt(state));
	}

	@IsTest
	static void test_decodeState_blank() {
		try {
			AuthService.decodeState(null, null);
			throw new AssertException('Expected decodeState to fail');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.InvalidAuthState, ex.getMessage());
		}

		try {
			AuthService.decodeState('', null);
			throw new AssertException('Expected decodeState to fail');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.InvalidAuthState, ex.getMessage());
		}

		try {
			AuthService.decodeState('\r', null);
			throw new AssertException('Expected decodeState to fail');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.InvalidAuthState, ex.getMessage());
		}
	}

	@IsTest
	static void test_decodeState_wrong_key() {
		String state = EncodingUtil.base64Encode(Crypto.encryptWithManagedIV(
			'AES256',
			Crypto.generateAesKey(256),
			Blob.valueOf('test')));
		TestUtils.generateKey();

		Test.startTest();
		try {
			AuthService.decodeState(state, 'test');
			throw new AssertException('Expected decodeState to fail');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.InvalidAuthState, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_decodeState_unexpected_state() {
		TestUtils.generateKey();
		String state = SecureUtils.encrypt('test');

		Test.startTest();
		try {
			AuthService.decodeState(state, 'test');
			throw new AssertException('Expected decodeState to fail');
		} catch (UnauthorizedException ex) {
			System.assertEquals(Label.InvalidAuthState, ex.getMessage());
		}
		Test.stopTest();
	}

	@IsTest
	static void test_decodeState_invalid_nonce() {
		System.runAs(UserMock.createUser()) {
			TestUtils.generateKey();
			String state = SecureUtils.encrypt('test|Demo|https://unit.test');

			Test.startTest();
			try {
				AuthService.decodeState(state, UUID.randomUUID().toString());
				throw new AssertException('Expected decodeState to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.InvalidAuthState, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_decodeState_invalid_environment() {
		System.runAs(UserMock.createUser()) {
			TestUtils.generateKey();
			String state = SecureUtils.encrypt('test|Bad|https://unit.test');

			Test.startTest();
			try {
				AuthService.decodeState(state, 'test');
				throw new AssertException('Expected decodeState to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.InvalidAuthState, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_decodeState_invalid_url() {
		System.runAs(UserMock.createUser()) {
			TestUtils.generateKey();
			String state = SecureUtils.encrypt('test|Demo|test');

			Test.startTest();
			try {
				AuthService.decodeState(state, 'test');
				throw new AssertException('Expected decodeState to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.InvalidAuthState, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_decodeState_non_whitelist_url() {
		System.runAs(UserMock.createUser()) {
			TestUtils.generateKey();
			String state = SecureUtils.encrypt('test|Production|https://evil-docusign.net/oauth/token');

			Test.startTest();
			try {
				AuthService.decodeState(state, 'test');
				throw new AssertException('Expected decodeState to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.InvalidAuthState, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_decodeState_valid() {
		System.runAs(UserMock.createUser()) {
			TestUtils.generateKey();
			String url = 'https://other.docusign.net/oauth/token';
			String state = SecureUtils.encrypt('test|Other|' + url);

			Test.startTest();
			AuthService.RootCredentials result = AuthService.decodeState(state, 'test');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(DocuSign.Environment.Other, result.environment);
			System.assertNotEquals(null, result.accountBaseUrl);
			System.assertEquals(url, result.accountBaseUrl.toExternalForm());
			System.assert(String.isNotBlank(result.clientId));
			System.assert(String.isNotBlank(result.clientSecret));
		}
	}

	@IsTest
	static void test_getGenProduct_failure() {
		DocuSignAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AuthService.getGenProduct(
					new Url('https://provisioning.test.docusign.net'),
					UUID.randomUUID(),
					'test');
				throw new AssertException('Expected getGenProduct to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.badRequest, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_getGenProduct_success() {
		DocuSignAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Gen.Product result = AuthService.getGenProduct(
				new Url('https://provisioning.test.docusign.net'),
				UUID.randomUUID(),
				'test');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(String.isNotBlank(result.status));
			System.assertNotEquals(null, result.authBaseUrl);
			System.assertNotEquals(null, result.apiBaseUrl);
			System.assertNotEquals(null, result.inviteCallbackUrl);
			System.assertNotEquals(null, result.inviteRedirectUrl);
			System.assert(String.isNotBlank(result.inviteEmailSubject));
			System.assert(String.isNotBlank(result.inviteEmailBody));
		}
	}

	@IsTest
	static void test_getRemoteSites() {
		System.assertEquals(5, Collection.size(AuthService.getRemoteSites(
			DocuSign.Environment.Production,
			new Url('https://account.test.docusign.net/'),
			new Url('https://provisioning.test.docusign.net/'),
			new Url('https://esign.test.docusign.net/'),
			new Url('https://auth.test.springcm.com/'),
			new Url('https://api.test.springcm.com/'))));
		System.assertEquals(2, Collection.size(AuthService.getRemoteSites(
			DocuSign.Environment.Production,
			new Url('https://bad-docusign.net/'),
			new Url('https://evil.domain/?q=provisioning.test.docusign.net/'),
			new Url('https://esign.test.docusign.net/'),
			new Url('https://evil-springcm.com/'),
			new Url('https://api.test.springcm.com/'))));
	}

	@IsTest
	static void test_canonicalizeBaseUrl() {
		System.assertEquals('https://unit.test/', AuthService.canonicalizeBaseUrl(new Url('https://unit.test/')).toExternalForm());
		System.assertEquals('https://unit.test:999/', AuthService.canonicalizeBaseUrl(new Url('https://unit.test:999')).toExternalForm());
		System.assertEquals('https://unit.test/p1/', AuthService.canonicalizeBaseUrl(new Url('https://unit.test/p1/')).toExternalForm());
		System.assertEquals('https://unit.test:8888/p1/', AuthService.canonicalizeBaseUrl(new Url('https://unit.test:8888/p1')).toExternalForm());
	}

	@IsTest
	static void test_save_invalid_environment() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AuthService.save(null, null, null, null, null, null, null, null);
				throw new AssertException('Expected save to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			try {
				AuthService.save(DocuSign.Environment.Invalid, null, null, null, null, null, null, null);
				throw new AssertException('Expected save to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			try {
				AuthService.save(DocuSign.Environment.Demo, new Url('https://bad-docusign.net'), new Url('https://provisioning.test.docusign.net'), null, null, null, null, null);
				throw new AssertException('Expected save to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			try {
				AuthService.save(DocuSign.Environment.Demo, new Url('https://account.testdocusign.net'), new Url('https://bad-docusign.net'), null, null, null, null, null);
				throw new AssertException('Expected save to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_save_undefined_argument() {
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			try {
				AuthService.save(
					DocuSign.Environment.Stage,
					new Url('https://account.test.docusign.net'),
					new Url('https://provisioning.test.docusign.net'),
					null,
					new LoginInformation(
						UUID.randomUUID(),
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString(),
						null),
					new LoginInformation.Account(
						UUID.randomUUID(),
						TestUtils.randomInteger(100000),
						UUID.randomUUID().toString(),
						'https://esign.test.docusign.net',
						true),
					new Gen.Product(
						'active',
						false,
						null,
						new Url('https://auth.test.springcm.com'),
						new Url('https://api.test.springcm.com'),
						new Url('https://invite.callback.test.springcm.com'),
						new Url('https://invite.redirect.test.springcm.com'),
						'email subject',
						'email body'),
					new Credentials.AccessToken(
						'test',
						Datetime.now().addHours(1)));
				throw new AssertException('Expected save to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				AuthService.save(
					DocuSign.Environment.Stage,
					new Url('https://account.test.docusign.net'),
					new Url('https://provisioning.test.docusign.net'),
					'\n ',
					new LoginInformation(
						UUID.randomUUID(),
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString(),
						null),
					new LoginInformation.Account(
						UUID.randomUUID(),
						TestUtils.randomInteger(100000),
						UUID.randomUUID().toString(),
						'https://esign.test.docusign.net',
						true),
					new Gen.Product(
						'active',
						false,
						null,
						new Url('https://auth.test.springcm.com'),
						new Url('https://api.test.springcm.com'),
						new Url('https://invite.callback.test.springcm.com'),
						new Url('https://invite.redirect.test.springcm.com'),
						'email subject',
						'email body'),
					new Credentials.AccessToken(
						'test',
						Datetime.now().addHours(1)));
				throw new AssertException('Expected save to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				AuthService.save(
					DocuSign.Environment.Stage,
					new Url('https://account.test.docusign.net'),
					new Url('https://provisioning.test.docusign.net'),
					UUID.randomUUID().toString(),
					null,
					new LoginInformation.Account(
						UUID.randomUUID(),
						TestUtils.randomInteger(100000),
						UUID.randomUUID().toString(),
						'https://esign.test.docusign.net',
						true),
					new Gen.Product(
						'active',
						false,
						null,
						new Url('https://auth.test.springcm.com'),
						new Url('https://api.test.springcm.com'),
						new Url('https://invite.callback.test.springcm.com'),
						new Url('https://invite.redirect.test.springcm.com'),
						'email subject',
						'email body'),
					new Credentials.AccessToken(
						'test',
						Datetime.now().addHours(1)));
				throw new AssertException('Expected save to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				AuthService.save(
					DocuSign.Environment.Stage,
					new Url('https://account.test.docusign.net'),
					new Url('https://provisioning.test.docusign.net'),
					UUID.randomUUID().toString(),
					new LoginInformation(
						UUID.randomUUID(),
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString(),
						null),
					null,
					new Gen.Product(
						'active',
						false,
						null,
						new Url('https://auth.test.springcm.com'),
						new Url('https://api.test.springcm.com'),
						new Url('https://invite.callback.test.springcm.com'),
						new Url('https://invite.redirect.test.springcm.com'),
						'email subject',
						'email body'),
					new Credentials.AccessToken(
						'test',
						Datetime.now().addHours(1)));
				throw new AssertException('Expected save to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				AuthService.save(
					DocuSign.Environment.Stage,
					new Url('https://account.test.docusign.net'),
					new Url('https://provisioning.test.docusign.net'),
					UUID.randomUUID().toString(),
					new LoginInformation(
						UUID.randomUUID(),
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString(),
						null),
					new LoginInformation.Account(
						UUID.randomUUID(),
						TestUtils.randomInteger(100000),
						UUID.randomUUID().toString(),
						'https://esign.test.docusign.net',
						true),
					new Gen.Product(
						'active',
						false,
						null,
						new Url('https://auth.test.springcm.com'),
						new Url('https://api.test.springcm.com'),
						new Url('https://invite.callback.test.springcm.com'),
						new Url('https://invite.redirect.test.springcm.com'),
						'email subject',
						'email body'),
					null);
				throw new AssertException('Expected save to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			try {
				AuthService.save(
					DocuSign.Environment.Stage,
					new Url('https://account.test.docusign.net'),
					new Url('https://provisioning.test.docusign.net'),
					UUID.randomUUID().toString(),
					new LoginInformation(
						UUID.randomUUID(),
						UUID.randomUUID().toString(),
						UUID.randomUUID().toString(),
						null),
					new LoginInformation.Account(
						UUID.randomUUID(),
						TestUtils.randomInteger(100000),
						UUID.randomUUID().toString(),
						'https://esign.test.docusign.net',
						true),
					new Gen.Product(
						'active',
						false,
						null,
						new Url('https://auth.test.springcm.com'),
						new Url('https://api.test.springcm.com'),
						new Url('https://invite.callback.test.springcm.com'),
						new Url('https://invite.redirect.test.springcm.com'),
						'email subject',
						'email body'),
					new Credentials.AccessToken(
						'test',
						Datetime.now().addHours(-1)));
				throw new AssertException('Expected save to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.UndefinedArgument, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_save_success() {
		DocuSignAPIMock.success();
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Credentials result = AuthService.save(
				DocuSign.Environment.Stage,
				new Url('https://account.test.docusign.net'),
				new Url('https://provisioning.test.docusign.net'),
				UUID.randomUUID().toString(),
				new LoginInformation(
					UUID.randomUUID(),
					UUID.randomUUID().toString(),
					UUID.randomUUID().toString(),
					null),
				new LoginInformation.Account(
					UUID.randomUUID(),
					TestUtils.randomInteger(100000),
					UUID.randomUUID().toString(),
					'https://esign.test.docusign.net',
					true),
				new Gen.Product(
					'active',
					false,
					null,
					new Url('https://auth.test.springcm.com'),
					new Url('https://api.test.springcm.com'),
					new Url('https://invite.callback.test.springcm.com'),
					new Url('https://invite.redirect.test.springcm.com'),
					'email subject',
					'email body'),
				new Credentials.AccessToken(
					'test',
					Datetime.now().addHours(1)));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isValid);
		}
	}

	@IsTest
	static void test_save_esign_only() {
		DocuSignAPIMock.success();
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator()) {
			Test.startTest();
			Credentials result = AuthService.save(
				DocuSign.Environment.Stage,
				new Url('https://account.test.docusign.net'),
				new Url('https://provisioning.test.docusign.net'),
				UUID.randomUUID().toString(),
				new LoginInformation(
					UUID.randomUUID(),
					UUID.randomUUID().toString(),
					UUID.randomUUID().toString(),
					null),
				new LoginInformation.Account(
					UUID.randomUUID(),
					TestUtils.randomInteger(100000),
					UUID.randomUUID().toString(),
					'https://esign.test.docusign.net',
					true),
				null,
				new Credentials.AccessToken(
					'test',
					Datetime.now().addHours(1)));
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assert(result.isValid);
		}
	}

	@IsTest
	static void test_redeemCode_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				AuthService.redeemCode('test', 'test');
				throw new AssertException('Expected redeemCode to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_redeemCode_api_error() {
		MetadataAPIMock.success();
		DocuSignAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			String state = TestUtils.generateState();

			Test.startTest();
			try {
				AuthService.redeemCode('test', state);
				throw new AssertException('Expected redeemCode to fail');
			} catch (APIException ex) {
				System.assertNotEquals(null, ex.error);
				System.assertEquals(APIErrorCode.UNAUTHORIZED, ex.error.code);
			}
			Test.stopTest();
		}
	}

	private class NoAccountsMock extends OAuthTokenMock {
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setHeader('Content-Type', 'application/json');
			response.setBody('{"sub":"11111111-1111-1111-1111-111111111111","name":"Unit Test","email":"test@unit.test","accounts":[]}');
			return response;
		}
	}

	@IsTest
	static void test_redeemCode_no_accounts() {
		MetadataAPIMock.success();
		Test.setMock(HttpCalloutMock.class, new NoAccountsMock());
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			String state = TestUtils.generateState();

			Test.startTest();
			try {
				AuthService.redeemCode('test', state);
				throw new AssertException('Expected redeemCode to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.NoValidAccounts, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	private class MultipleAccountsMock extends OAuthTokenMock {

		private DocuSignAPIMock baseMock;

		public MultipleAccountsMock() {
			this.baseMock = new DocuSignAPIMock(true);
		}

		override public HttpResponse getResponse(final HttpRequest request) {
			if (new Url(request.getEndpoint()).getPath().startsWith('/oauth/userinfo')) {
				HttpResponse response = new HttpResponse();
				response.setStatusCode(200);
				response.setHeader('Content-Type', 'application/json');
				response.setBody('{"sub":"11111111-1111-1111-1111-111111111111","name":"Unit Test","email":"test@unit.test","accounts":[{"account_id":"11111111-1111-1111-1111-111111111111","friendly_id":"11111","is_default":true,"account_name":"Account 1","base_uri":"https://unit.test.docusign.net/restapi/v2/accounts/11111111-1111-1111-1111-111111111111"},{"account_id":"22222222-2222-2222-2222-222222222222","friendly_id":"22222","is_default":false,"account_name":"Account 2","base_uri":"https://unit.test.docusign.net/restapi/v2/accounts/22222222-2222-2222-2222-222222222222/"}]}');
				return response;
			}
			return this.baseMock.getResponse(request);
		}
	}

	@IsTest
	static void test_redeemCode_multiple_accounts() {
		MetadataAPIMock.success();
		Test.setMock(HttpCalloutMock.class, new MultipleAccountsMock());
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			String state = TestUtils.generateState();

			Test.startTest();
			LoginInformation result = AuthService.redeemCode('test', state);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(LoginInformation.LoginStatus.SelectAccount.name(), result.status);
			System.assertEquals(2, Collection.size(result.accounts));

			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			System.assertEquals(null, s.AccountId__c);
			System.assertEquals(null, s.AccountBaseUrl__c);
			System.assertEquals(null, s.ESignatureBaseUrl__c);
			System.assertEquals(null, s.AccountNumber__c);
			System.assertEquals(null, s.AccountName__c);
			System.assertEquals(null, s.Email__c);

			System.assertEquals(null, UserSettings__c.getInstance().Nonce__c);
		}
	}

	@IsTest
	static void test_redeemCode_success() {
		DocuSignAPIMock.success();
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			String state = TestUtils.generateState();

			Test.startTest();
			LoginInformation result = AuthService.redeemCode('test', state);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(LoginInformation.LoginStatus.Success.name(), result.status);
			System.assertEquals(1, Collection.size(result.accounts));

			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			System.assertNotEquals(null, s.AccountId__c);
			System.assertNotEquals(null, s.AccountBaseUrl__c);
			System.assertNotEquals(null, s.ESignatureBaseUrl__c);
			System.assertNotEquals(null, s.AccountNumber__c);
			System.assertNotEquals(null, s.AccountName__c);
			System.assertNotEquals(null, s.Email__c);

			System.assertEquals(null, UserSettings__c.getInstance().Nonce__c);
		}
	}

	@IsTest
	static void test_selectAccount_unauthorized() {
		System.runAs(UserMock.createDocuSignUser(false)) {
			Test.startTest();
			try {
				AuthService.selectAccount(null, null, null);
				throw new AssertException('Expected selectAccount to fail');
			} catch (UnauthorizedException ex) {
				System.assertEquals(Label.MustBeDocuSignAdministrator, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_selectAccount_invalid_environment() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				AuthService.selectAccount(DocuSign.Environment.Other, null, 1234L);
				throw new AssertException('Expected selectAccount to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidEnvironment, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_selectAccount_invalid_account() {
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				AuthService.selectAccount(DocuSign.Environment.Demo, null, null);
				throw new AssertException('Expected selectAccount to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidAccount, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_selectAccount_api_error() {
		DocuSignAPIMock.failure();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				AuthService.selectAccount(DocuSign.Environment.Demo, null, 1234L);
				throw new AssertException('Expected selectAccount to fail');
			} catch (APIException ex) {
				System.assertEquals(APIError.unauthorized, ex.error);
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_selectAccount_no_accounts() {
		Test.setMock(HttpCalloutMock.class, new NoAccountsMock());
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				AuthService.selectAccount(DocuSign.Environment.Demo, null, 1234L);
				throw new AssertException('Expected selectAccount to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.NoValidAccounts, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_selectAccount_account_not_found() {
		Test.setMock(HttpCalloutMock.class, new MultipleAccountsMock());
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				AuthService.selectAccount(DocuSign.Environment.Demo, null, 99999L);
				throw new AssertException('Expected selectAccount to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.AccountNotFound, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_selectAccount_success() {
		Test.setMock(HttpCalloutMock.class, new MultipleAccountsMock());
		MetadataAPIMock.success();
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			LoginInformation result = AuthService.selectAccount(DocuSign.Environment.Demo, null, 22222L);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(LoginInformation.LoginStatus.Success.name(), result.status);
			Credentials c = Credentials.getInstance(UserInfo.getUserId(), false);
			System.assert(c.isAccountValid);
			System.assert(c.isUserValid);
			System.assert(c.isTokenValid);
			System.assertEquals(22222L, c.account.accountNumber);
		}
	}
}
