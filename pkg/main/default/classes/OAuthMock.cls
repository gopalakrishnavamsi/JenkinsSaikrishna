@IsTest
public class OAuthMock extends OAuthTokenMock {

	private final Boolean success;

	public OAuthMock(final Boolean success) {
		super(!success);
		this.success = success;
	}

	public static OAuthMock success() {
		return (OAuthMock)TestUtils.setMock(new OAuthMock(true));
	}

	public static OAuthMock failure() {
		return (OAuthMock)TestUtils.setMock(new OAuthMock(false));
	}

	/*
		Supported paths:
			- GET /oauth/userinfo
	 */
	override public HttpResponse getResponse(final HttpRequest request) {
		HttpResponse response = new HttpResponse();
		response.setHeader('Content-Type', 'application/json');
		if (this.success) {
			String method = request.getMethod();
			String path = new Url(request.getEndpoint()).getPath();
			if (method == 'GET' && path == '/oauth/userinfo') {
				Credentials c = Credentials.isAccountValid() ? Credentials.getInstance() : null;
				AuthService.APIAccount a = new AuthService.APIAccount();
				a.account_id = c == null ? UUID.randomUUID().toString() : c.account.id.toString();
				a.friendly_id = c == null ? String.valueOf(TestUtils.randomInteger(1000000)) : String.valueOf(c.account.accountNumber);
				a.is_default = true;
				a.account_name = c == null ? TestUtils.randomString(10) : c.account.name;
				a.base_uri = c == null ? 'https://unit.test.docusign.net/' : c.environment.eSignatureBaseUrl.toExternalForm();
				AuthService.APIUser u = new AuthService.APIUser();
				u.sub = c == null || UUID.isEmpty(c.user.id) ? UUID.randomUUID().toString() : c.user.id.toString();
				u.name = UserInfo.getName();
				u.email = c == null ? UserInfo.getUserEmail() : c.account.email;
				u.accounts = new List<AuthService.APIAccount> { a };
				response.setStatusCode(200);
				response.setStatus('OK');
				response.setBody(JSON.serialize(u));
			} else {
				throw new AssertException('Unexpected OAuth request: ' + method + ' ' + path);
			}
		} else {
			response.setStatusCode(400);
			response.setStatus('BAD_REQUEST');
			response.setBody('{"error":"unit_test","error_message":"Unit test error"}');
		}
		return response;
	}
}
