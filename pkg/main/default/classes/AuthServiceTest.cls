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
		System.assertEquals(APIErrorCode.FAILURE, ((AuthService.AuthError)result4).reason);
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
	static void test_getClientCredentials_undefined() {
		Test.startTest();
		AuthService.ClientCredentials result = AuthService.getClientCredentials(null, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.Production, result.environment);
		System.assertNotEquals(null, result.baseUrl);
		AuthService.ClientCredentials ccs = AuthService.convert(
			DocuSign.Environment.Production,
		[
			SELECT AccountBaseUrl__c, ClientId__c, ClientSecret__c, JwtSigningKey__c
			FROM Environment__mdt
			WHERE DeveloperName = 'Production'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.baseUrl.toExternalForm(), result.baseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
		System.assertEquals(ccs.jwtSigningKey, result.jwtSigningKey);
	}

	@IsTest
	static void test_getClientCredentials_Invalid() {
		Test.startTest();
		AuthService.ClientCredentials result = AuthService.getClientCredentials(DocuSign.Environment.Invalid, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.Production, result.environment);
		System.assertNotEquals(null, result.baseUrl);
		AuthService.ClientCredentials ccs = AuthService.convert(
			DocuSign.Environment.Production,
		[
			SELECT AccountBaseUrl__c, ClientId__c, ClientSecret__c, JwtSigningKey__c
			FROM Environment__mdt
			WHERE DeveloperName = 'Production'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.baseUrl.toExternalForm(), result.baseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
		System.assertEquals(ccs.jwtSigningKey, result.jwtSigningKey);
	}

	@IsTest
	static void test_getClientCredentials_Production() {
		Test.startTest();
		AuthService.ClientCredentials result = AuthService.getClientCredentials(DocuSign.Environment.Production, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.Production, result.environment);
		System.assertNotEquals(null, result.baseUrl);
		AuthService.ClientCredentials ccs = AuthService.convert(
			DocuSign.Environment.Production,
		[
			SELECT AccountBaseUrl__c, ClientId__c, ClientSecret__c, JwtSigningKey__c
			FROM Environment__mdt
			WHERE DeveloperName = 'Production'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.baseUrl.toExternalForm(), result.baseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
		System.assertEquals(ccs.jwtSigningKey, result.jwtSigningKey);
	}

	@IsTest
	static void test_getClientCredentials_Other() {
		Url otherUrl = new Url('https://other.docusignhq.com');

		Test.startTest();
		AuthService.ClientCredentials result = AuthService.getClientCredentials(DocuSign.Environment.Other, otherUrl);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.Other, result.environment);
		System.assertNotEquals(null, result.baseUrl);
		AuthService.ClientCredentials ccs = AuthService.convert(
			DocuSign.Environment.Other,
		[
			SELECT AccountBaseUrl__c, ClientId__c, ClientSecret__c, JwtSigningKey__c
			FROM Environment__mdt
			WHERE DeveloperName = 'Production'
			LIMIT 1
		],
			otherUrl);
		System.assertEquals(ccs.baseUrl.toExternalForm(), result.baseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
		System.assertEquals(ccs.jwtSigningKey, result.jwtSigningKey);
	}

	@IsTest
	static void test_getClientCredentials_Demo() {
		Test.startTest();
		AuthService.ClientCredentials result = AuthService.getClientCredentials(DocuSign.Environment.Demo, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.Demo, result.environment);
		System.assertNotEquals(null, result.baseUrl);
		AuthService.ClientCredentials ccs = AuthService.convert(
			DocuSign.Environment.Demo,
		[
			SELECT AccountBaseUrl__c, ClientId__c, ClientSecret__c, JwtSigningKey__c
			FROM Environment__mdt
			WHERE DeveloperName = 'Demo'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.baseUrl.toExternalForm(), result.baseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
		System.assertEquals(ccs.jwtSigningKey, result.jwtSigningKey);
	}

	@IsTest
	static void test_getClientCredentials_Stage() {
		Test.startTest();
		AuthService.ClientCredentials result = AuthService.getClientCredentials(DocuSign.Environment.Stage, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.Stage, result.environment);
		System.assertNotEquals(null, result.baseUrl);
		AuthService.ClientCredentials ccs = AuthService.convert(
			DocuSign.Environment.Stage,
		[
			SELECT AccountBaseUrl__c, ClientId__c, ClientSecret__c, JwtSigningKey__c
			FROM Environment__mdt
			WHERE DeveloperName = 'Stage'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.baseUrl.toExternalForm(), result.baseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
		System.assertEquals(ccs.jwtSigningKey, result.jwtSigningKey);
	}

	@IsTest
	static void test_getClientCredentials_QA() {
		Test.startTest();
		AuthService.ClientCredentials result = AuthService.getClientCredentials(DocuSign.Environment.QA, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.QA, result.environment);
		System.assertNotEquals(null, result.baseUrl);
		AuthService.ClientCredentials ccs = AuthService.convert(
			DocuSign.Environment.QA,
		[
			SELECT AccountBaseUrl__c, ClientId__c, ClientSecret__c, JwtSigningKey__c
			FROM Environment__mdt
			WHERE DeveloperName = 'QA'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.baseUrl.toExternalForm(), result.baseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
		System.assertEquals(ccs.jwtSigningKey, result.jwtSigningKey);
	}

	@IsTest
	static void test_getClientCredentials_HQTEST0() {
		Test.startTest();
		AuthService.ClientCredentials result = AuthService.getClientCredentials(DocuSign.Environment.HQTEST0, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.HQTEST0, result.environment);
		System.assertNotEquals(null, result.baseUrl);
		AuthService.ClientCredentials ccs = AuthService.convert(
			DocuSign.Environment.HQTEST0,
		[
			SELECT AccountBaseUrl__c, ClientId__c, ClientSecret__c, JwtSigningKey__c
			FROM Environment__mdt
			WHERE DeveloperName = 'HQTEST0'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.baseUrl.toExternalForm(), result.baseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
		System.assertEquals(ccs.jwtSigningKey, result.jwtSigningKey);
	}

	@IsTest
	static void test_getClientCredentials_HQTEST1() {
		Test.startTest();
		AuthService.ClientCredentials result = AuthService.getClientCredentials(DocuSign.Environment.HQTEST1, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.HQTEST1, result.environment);
		System.assertNotEquals(null, result.baseUrl);
		AuthService.ClientCredentials ccs = AuthService.convert(
			DocuSign.Environment.HQTEST1,
		[
			SELECT AccountBaseUrl__c, ClientId__c, ClientSecret__c, JwtSigningKey__c
			FROM Environment__mdt
			WHERE DeveloperName = 'HQTEST1'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.baseUrl.toExternalForm(), result.baseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
		System.assertEquals(ccs.jwtSigningKey, result.jwtSigningKey);
	}

	@IsTest
	static void test_getClientCredentials_HQTEST2() {
		Test.startTest();
		AuthService.ClientCredentials result = AuthService.getClientCredentials(DocuSign.Environment.HQTEST2, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.HQTEST2, result.environment);
		System.assertNotEquals(null, result.baseUrl);
		AuthService.ClientCredentials ccs = AuthService.convert(
			DocuSign.Environment.HQTEST2,
		[
			SELECT AccountBaseUrl__c, ClientId__c, ClientSecret__c, JwtSigningKey__c
			FROM Environment__mdt
			WHERE DeveloperName = 'HQTEST2'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.baseUrl.toExternalForm(), result.baseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
		System.assertEquals(ccs.jwtSigningKey, result.jwtSigningKey);
	}

	@IsTest
	static void test_getClientCredentials_HQTEST3() {
		Test.startTest();
		AuthService.ClientCredentials result = AuthService.getClientCredentials(DocuSign.Environment.HQTEST3, null);
		Test.stopTest();

		System.assertNotEquals(null, result);
		System.assertEquals(DocuSign.Environment.HQTEST3, result.environment);
		System.assertNotEquals(null, result.baseUrl);
		AuthService.ClientCredentials ccs = AuthService.convert(
			DocuSign.Environment.HQTEST3,
		[
			SELECT AccountBaseUrl__c, ClientId__c, ClientSecret__c, JwtSigningKey__c
			FROM Environment__mdt
			WHERE DeveloperName = 'HQTEST3'
			LIMIT 1
		],
			null);
		System.assertEquals(ccs.baseUrl.toExternalForm(), result.baseUrl.toExternalForm());
		System.assertEquals(ccs.clientId, result.clientId);
		System.assertEquals(ccs.clientSecret, result.clientSecret);
		System.assertEquals(ccs.jwtSigningKey, result.jwtSigningKey);
	}

	@IsTest
	static void test_getCurrentEnvironment() {
		System.runAs(UserMock.createDocuSignUser()) {
			Test.startTest();
			DocuSign.Environment result1 = AuthService.getCurrentEnvironment();
			DocuSign.Environment result2 = AuthService.getCurrentEnvironment();
			Test.stopTest();

			System.assertNotEquals(null, result1);
			System.assertNotEquals(DocuSign.Environment.Invalid, result1);
			System.assert(result1 === result2);
		}
	}

	@IsTest
	static void test_generateJwt() {
		System.runAs(UserMock.createDocuSignUser()) {
			String aud = 'unit.test.docusign.com';
			String sub = [SELECT Username__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Username__c;
			String iss = UUID.randomUUID().toString();
			Blob jwtSigningKey = EncodingUtil.base64Decode([
				SELECT JwtSigningKey__c
				FROM Environment__mdt
				WHERE DeveloperName = 'Stage'
				LIMIT 1
			].JwtSigningKey__c);

			Test.startTest();
			String result = AuthService.generateJwt(aud, UUID.parse(sub), iss, jwtSigningKey);
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
			System.assertEquals('signature impersonation', (String)payload.get('scope'));

			String signature = AuthService.base64UrlEncode(Crypto.sign('RSA-SHA256', Blob.valueOf(toks[0] + '.' + toks[1]),
				jwtSigningKey));
			System.assertEquals(signature, toks[2]);
		}
	}

	@IsTest
	static void test_AuthAPI_exchangeJwt_success() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());
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
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));
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
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());
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
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());
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
			System.assertEquals(s.ESignatureBaseUrl__c, result.accounts[0].baseUrl);
			System.assert(result.accounts[0].isDefault);
			System.assertEquals(String.format(Label.AccountDisplay_2, new List<String> {
				result.accounts[0].name, String.valueOf(result.accounts[0].accountNumber)
			}), result.accounts[0].display);
		}
	}

	@IsTest
	static void test_AuthAPI_getLoginInformation_error() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));
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
	static void test_getAccessToken() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock());
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
			System.assertEquals('signature impersonation', params.get('scope'));
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
			AuthService.ClientCredentials result = AuthService.decodeState(state, 'test');
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(DocuSign.Environment.Other, result.environment);
			System.assertNotEquals(null, result.baseUrl);
			System.assertEquals(url, result.baseUrl.toExternalForm());
			System.assert(String.isNotBlank(result.clientId));
			System.assert(String.isNotBlank(result.clientSecret));
			System.assertNotEquals(null, result.jwtSigningKey);
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
		ESignatureAPIMock.failure();
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
		override public HttpResponse getResponse(final HttpRequest request) {
			HttpResponse response = new HttpResponse();
			response.setStatusCode(200);
			response.setHeader('Content-Type', 'application/json');
			response.setBody('{"sub":"11111111-1111-1111-1111-111111111111","name":"Unit Test","email":"test@unit.test","accounts":[{"account_id":"11111111-1111-1111-1111-111111111111","friendly_id":"11111","is_default":true,"account_name":"Account 1","base_uri":"https://unit.test.docusign.net/restapi/v2/accounts/11111111-1111-1111-1111-111111111111"},{"account_id":"22222222-2222-2222-2222-222222222222","friendly_id":"22222","is_default":false,"account_name":"Account 2","base_uri":"https://unit.test.docusign.net/restapi/v2/accounts/22222222-2222-2222-2222-222222222222/"}]}');
			return response;
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
		ESignatureAPIMock.success();
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
				AuthService.selectAccount(null, null, null, null);
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
				AuthService.selectAccount(DocuSign.Environment.Other, null, UUID.randomUUID(), 1234L);
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
				AuthService.selectAccount(DocuSign.Environment.Demo, null, UUID.randomUUID(), null);
				throw new AssertException('Expected selectAccount to fail');
			} catch (DocuSignException ex) {
				System.assertEquals(Label.InvalidAccount, ex.getMessage());
			}
			Test.stopTest();
		}
	}

	@IsTest
	static void test_selectAccount_api_error() {
		Test.setMock(HttpCalloutMock.class, new ESignatureAPIMock(false));
		System.runAs(UserMock.createDocuSignAdministrator(false)) {
			Test.startTest();
			try {
				AuthService.selectAccount(DocuSign.Environment.Demo, null, UUID.randomUUID(), 1234L);
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
			UserSettings__c s = UserSettings__c.getInstance();
			s.AccessToken0__c = null;
			s.AccessTokenExpires__c = null;
			upsert s;

			Test.startTest();
			try {
				AuthService.selectAccount(DocuSign.Environment.Demo, null, UUID.randomUUID(), 1234L);
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
				AuthService.selectAccount(DocuSign.Environment.Demo, null, UUID.randomUUID(), 99999L);
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
			LoginInformation result = AuthService.selectAccount(DocuSign.Environment.Demo, null, UUID.randomUUID(), 22222L);
			Test.stopTest();

			System.assertNotEquals(null, result);
			System.assertEquals(LoginInformation.LoginStatus.Success.name(), result.status);
			Credentials c = Credentials.getInstance(UserInfo.getUserId(), false);
			System.assert(c.isAccountValid);
			System.assert(c.isUserValid);
			System.assert(c.isTokenValid);
			System.assertEquals(22222L, c.accountNumber);
		}
	}
}
