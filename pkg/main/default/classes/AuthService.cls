public with sharing class AuthService {

	@TestVisible
	private class APIUser {
		public String sub;
		public String name;
		public String email;
		public List<APIAccount> accounts;

		public LoginInformation toExternalForm() {
			List<LoginInformation.Account> dsas = new List<LoginInformation.Account>();
			if (this.accounts != null) {
				for (APIAccount aa : this.accounts) {
					dsas.add(aa.toExternalForm());
				}
			}
			return new LoginInformation(
				UUID.tryParse(this.sub),
				this.name,
				this.email,
				dsas);
		}
	}

	@TestVisible
	private class APIAccount {
		public String account_id;
		public String friendly_id;
		public Boolean is_default;
		public String account_name;
		public String base_uri;

		public LoginInformation.Account toExternalForm() {
			return new LoginInformation.Account(
				UUID.tryParse(this.account_id),
				String.isBlank(this.friendly_id) ? null : Long.valueOf(this.friendly_id),
				this.account_name,
				this.base_uri,
				this.is_default);
		}
	}

	public class AuthError extends APIError {
		public Integer reason { get; private set; }

		private AuthError(final Integer reason, final String description) {
			super(APIErrorCode.UNAUTHORIZED, description);
			this.reason = reason;
		}
	}

	@TestVisible
	private static String base64UrlEncode(final Blob input) {
		if (input == null) return '';

		String output = EncodingUtil.base64Encode(input)
			.replace('+', '-')
			.replace('/', '_');
		while (output.endsWith('=')) {
			output = output.substring(0, output.length() - 1);
		}

		return output;
	}

	private class APIToken {
		public String access_token;
		public Integer expires_in;

		public Credentials.AccessToken toExternalForm() {
			return new Credentials.AccessToken(
				access_token,
				// Subtract auth timeout seconds from server expires_in value to account for worst-case latency.
				Datetime.now().addSeconds(expires_in - (AUTH_TIMEOUT / 1000)));
		}
	}

	@TestVisible
	private class AuthAPI extends RestAPI {

		private Url baseUrl;

		public AuthAPI(final Url baseUrl) {
			if (!DocuSign.isValidUrl(baseUrl)) throw new DocuSignException(Label.InvalidEnvironment);
			this.baseUrl = baseUrl;
		}

		@TestVisible
		override protected virtual APIError getError(final HttpResponse response) {
			APIError e = super.getError(response);
			if (e != APIError.none && e.code == APIErrorCode.BAD_REQUEST) {
				String body = response.getBody();
				this.log.warn('Authorization service error:\n' + body);
				try {
					Map<String, Object> errResp = (Map<String, Object>)JSON.deserializeUntyped(body);
					switch on (String)errResp.get('error') {
						when 'consent_required' {
							e = new AuthError(APIErrorCode.CONSENT_REQUIRED, Label.ConsentRequired);
						} when 'invalid_grant' {
							e = new AuthError(APIErrorCode.INVALID_GRANT, Label.InvalidGrant);
						} when else {
							this.log.warn('Unknown auth error');
							String msg = errResp.containsKey('error_message')
								? (String)errResp.get('error_message') : response.getStatus();
							e = new AuthError(APIErrorCode.FAILURE, msg);
						}
					}
				} catch (Exception ex) {
					this.log.exception(ex, 'Failed to parse 400 BAD_REQUEST as a DocuSign error');
				}
			}
			return e;
		}

		@TestVisible
		private String getBasicAuthHeader(final String username, final String password) {
			return 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(String.format('{0}:{1}', new List<String> {
				username,
				password
			})));
		}

		public Credentials.AccessToken exchangeCode(final String authorizationCode) {
			Response response = super.post(
				this.baseUrl,
				new List<Object> { 'oauth', 'token' },
				QueryString.empty,
				new Map<String, String> {
					'Authorization' => this.getBasicAuthHeader(CLIENT_ID, CLIENT_SECRET),
					'Content-Type' => 'application/x-www-form-urlencoded'
				},
				'grant_type=authorization_code&code=' + authorizationCode,
				AUTH_TIMEOUT);
			if (response.hasError) {
				this.log.error('Failed to get access token: ' + response.error.toString());
				throw new APIException(response.error);
			}

			return ((APIToken)JSON.deserialize(response.body, APIToken.class)).toExternalForm();
		}

		public Credentials.AccessToken exchangeJwt(final String jwt) {
			Response response = super.post(
				this.baseUrl,
				new List<Object> { 'oauth', 'token' },
				QueryString.empty,
				new Map<String, String> {
					'Content-Type' => 'application/x-www-form-urlencoded'
				},
				'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=' + jwt,
				AUTH_TIMEOUT);
			if (response.hasError) {
				this.log.warn('Failed to exchange JWT for access token: ' + response.error);
				throw new APIException(response.error);
			}

			return ((APIToken)JSON.deserialize(response.body, APIToken.class)).toExternalForm();
		}

		public LoginInformation getLoginInformation(final String accessToken) {
			Response response = super.get(
				this.baseUrl,
				new List<Object> { 'oauth', 'userinfo' },
				new QueryString('include_friendly', 'true'),
				new Map<String, String> {
					'Authorization' => 'Bearer ' + accessToken
				},
				AUTH_TIMEOUT);
			if (response.hasError) {
				this.log.error('Failed to get accounts: ' + response.error.toString());
				throw new APIException(response.error);
			}

			return ((APIUser)JSON.deserialize(response.body, APIUser.class)).toExternalForm();
		}
	}

	@TestVisible
	private static final String CLIENT_ID;
	private static final String CLIENT_SECRET;
	@TestVisible
	private static final Blob SIGNING_KEY;
	private static final LoggerService LOG = LoggerService.getInstance();
	@TestVisible
	private static final String JWT_HEADER;
	private static final Integer AUTH_TIMEOUT = 5000; // TODO: Move to config
	private static AuthAPI api;

	static {
		JWT_HEADER = base64UrlEncode(Blob.valueOf(JSON.serialize(new Map<String, String> {
			'typ' => 'JWT',
			'alg' => 'RS256'
		})));
		Organization__mdt ss = [
			SELECT ClientId__c, ClientSecret__c, RsaPrivateKey__c
			FROM Organization__mdt
			WHERE DeveloperName = 'SecureSettings'
			LIMIT 1
		];
		CLIENT_ID = ss.ClientId__c;
		CLIENT_SECRET = ss.ClientSecret__c;
		SIGNING_KEY = EncodingUtil.base64Decode(ss.RsaPrivateKey__c);
	}

	private static AuthAPI getAuthAPI(final Url baseUrl) {
		if (api == null) {
			api = new AuthAPI(baseUrl);
		}
		return api;
	}

	@TestVisible
	private static String generateJwt(
		final String host,
		final UUID userId) {

		// TODO: Add admin, Gen, Package B, SCM scopes
		String payload = base64UrlEncode(Blob.valueOf(JSON.serialize(new Map<String, Object> {
			'iss' => CLIENT_ID,
			'sub' => String.valueOf(userId),
			'iat' => Datetime.now().getTime() / 1000,
			'exp' => Datetime.now().addHours(1).getTime() / 1000,
			'aud' => host,
			'scope' => 'signature impersonation'
		})));

		String signature = base64UrlEncode(Crypto.sign('RSA-SHA256', Blob.valueOf(JWT_HEADER + '.' + payload),
			SIGNING_KEY));

		return JWT_HEADER + '.' + payload + '.' + signature;
	}

	public static String getAccessToken() {
		return getAccessToken(Credentials.getInstance());
	}

	@TestVisible
	private static String getAccessToken(final Credentials creds) {
		if (creds == null || !creds.isValid) throw new DocuSignException(Label.AccountNotConfigured);

		if (creds.isTokenValid) return creds.token.token;

		Credentials.AccessToken token = getAuthAPI(creds.accountBaseUrl).exchangeJwt(generateJwt(
			creds.accountBaseUrl.getHost(),
			creds.userId));

		Credentials.setToken(token);
		return token.token;
	}

	/**
	 * Clears all DocuSign account credentials and optionally user credentials as well. This is an irreversible action,
	 * so invoke only after confirming with the administrator.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param resetUsers Whether or not to also clear user credentials.
	 */
	public static void resetCredentials(final Boolean resetUsers) {
		Permissions.verifyIsDocuSignAdministrator();

		Credentials.clear(resetUsers);
	}

	@TestVisible
	private static Url getAuthBaseUrl(
		final DocuSign.Environment environment,
		final Url otherUrl) {

		if (!DocuSign.isValidEnvironment(environment, otherUrl)) {
			LOG.error('Invalid DocuSign environment: ' + (environment == null ? 'null' : environment.name()) + ' => '
				+ (otherUrl == null ? 'null' : otherUrl.toExternalForm()));
			throw new DocuSignException(Label.InvalidEnvironment);
		}
		return otherUrl == null ? DocuSign.getAuthBaseUrl(environment) : otherUrl;
	}

	@TestVisible
	private static String generateNonce() {
		String nonce = UUID.randomUUID().toShortString();
		UserSettings__c settings = UserSettings__c.getInstance();
		settings.Nonce__c = nonce;
		upsert settings;
		return nonce;
	}

	/**
	 * Retrieves the DocuSign login URL.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param environment The target DocuSign environment.
	 * @param otherUrl Optional account URL for the DocuSign environment, used with
	 * <code>Environment.Target.Other</code>.
	 *
	 * @return The DocuSign login URL. The user should be redirected here to complete authorization.
	 */
	public static Url getLoginUrl(
		final DocuSign.Environment environment,
		final Url otherUrl) {

		Permissions.verifyIsDocuSignAdministrator();

		// 1) Parse valid DocuSign environment.
		Url baseUrl = getAuthBaseUrl(environment, otherUrl);

		// 2) Build login URL
		PageReference pg = new PageReference(new Url(baseUrl, '/oauth/auth').toExternalForm());
		pg.getParameters().putAll(new Map<String, String> {
			'response_type' => 'code',
			'scope' => 'signature impersonation',
			'client_id' => CLIENT_ID,
			'redirect_uri' => 'https://' + (Salesforce.isSandbox ? 'test' : 'login') + '.salesforce.com'
				+ '/apex/' + Application.namespacePrefix + 'completeoauth',
			'state' => encodeState(generateNonce(), baseUrl)
		});
		return new Url(pg.getUrl());
	}

	@TestVisible
	private static String encodeState(final String nonce, final Url baseUrl) {
		return SecureUtils.encrypt(nonce + '|' + baseUrl.toExternalForm());
	}

	@TestVisible
	private static Url decodeState(final String state, final String nonce) {
		// 1) Verify state is non-blank.
		if (String.isBlank(state)) {
			LOG.error('OAuth state is blank');
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 2) Verify can decrypt
		String decrypted;
		try {
			decrypted = SecureUtils.decrypt(state);
		} catch (Exception ex) {
			LOG.exception(ex, 'Failed to decrypt state: ' + state);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 3) Verify 2 state tokens
		List<String> toks = decrypted.split('\\|');
		if (Collection.size(toks) != 2) {
			LOG.error('Unexpected state: ' + decrypted);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 4) Verify nonce
		if (nonce != toks[0]) {
			LOG.error('Nonce mismatch: ' + nonce + ' != ' + toks[0]);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 5) Verify URL format
		Url baseUrl;
		try {
			baseUrl = new Url(toks[1]);
		} catch (Exception ex) {
			LOG.exception(ex, 'Invalid base URL: ' + toks[1]);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 6) Verify whitelisted DocuSign URL
		if (!DocuSign.isValidUrl(baseUrl)) {
			LOG.error('Invalid DocuSign base URL: ' + baseUrl.toExternalForm());
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		return baseUrl;
	}

	/**
	 * Attempts login to DocuSign with the supplied credentials. This must be invoked successfully prior to any other
	 * DocuSign for Salesforce actions. If the login is successful and maps to a single valid
	 * DocuSign account, DocuSign for Salesforce will be updated with these credentials. If the login is successful and
	 * maps to valid multiple accounts, those account options are returned to the caller to select the desired account
	 * in a subsequent call to this method.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param authorizationCode The authorization code returned by DocuSign after successful login and consent.
	 * @param state The state passed through the DocuSign authorization service. This value is opaque to the caller and
	 * may not be tampered with.
	 *
	 * @return The result of the login. This may succeed with a single account (no additional action is
	 * required to configure DocuSign for Salesforce), or with multiple accounts in which case this method should be
	 * called again with the same parameters and <code>selectedAccountNumber</code> defined with the desired account.
	 */
	public static LoginInformation redeemCode(
		final String authorizationCode,
		final String state) {

		Permissions.verifyIsDocuSignAdministrator();

		Credentials.AccessToken accessToken;
		UserSettings__c s = UserSettings__c.getInstance();
		try {
			// 1) Parse URL from state
			Url baseUrl = decodeState(state, s.Nonce__c);

			// 2) Get accounts associated with login
			AuthService.AuthAPI client = getAuthAPI(baseUrl);
			accessToken = client.exchangeCode(authorizationCode);
			LoginInformation result = client.getLoginInformation(accessToken.token);
			if (result == null || result.status == LoginInformation.LoginStatus.Failure.name()) {
				LOG.warn('No valid accounts for user '
					+ (result == null ? 'UNKNOWN' : result.email + '. Login URL = '
					+ baseUrl.toExternalForm()));
				throw new DocuSignException(Label.NoValidAccounts);
			}

			// 3) If one valid account is returned, store result. Else, user must select account.
			if (result.status == LoginInformation.LoginStatus.Success.name()) {
				LoginInformation.Account a = result.accounts[0];
				Credentials.save(
					DocuSign.getEnvironment(baseUrl),
					baseUrl,
					new Url(a.baseUrl),
					a.id,
					a.accountNumber,
					a.name,
					result.email,
					result.id,
					true,
					accessToken);
			}

			return result;
		} finally {
			if (String.isNotBlank(s.Nonce__c)) {
				s.Nonce__c = null;
				update s;
			}
		}
	}

	public static LoginInformation selectAccount(
		final DocuSign.Environment environment,
		final Url otherUrl,
		final UUID userId,
		final Long selectedAccountNumber) {

		Permissions.verifyIsDocuSignAdministrator();

		Url baseUrl = getAuthBaseUrl(environment, otherUrl);

		if (selectedAccountNumber == null || selectedAccountNumber <= 0L) {
			throw new DocuSignException(Label.InvalidAccount);
		}

		AuthAPI client = getAuthAPI(baseUrl);
		Credentials.AccessToken token = Credentials.getToken();
		if (token == null) {
			token = client.exchangeJwt(generateJwt(baseUrl.getHost(), userId));
		}

		LoginInformation result = getAuthAPI(baseUrl).getLoginInformation(token.token);
		if (result == null || result.status == LoginInformation.LoginStatus.Failure.name()) {
			LOG.warn('No valid accounts for user '
				+ (result == null ? 'UNKNOWN' : result.email + '. Login URL = '
				+ baseUrl.toExternalForm()));
			throw new DocuSignException(Label.NoValidAccounts);
		}
		LoginInformation.Account selected = null;
		for (LoginInformation.Account a : result.accounts) {
			if (a.accountNumber == selectedAccountNumber) {
				selected = a;
				break;
			}
		}

		if (selected == null) {
			throw new DocuSignException(Label.AccountNotFound);
		}

		Credentials.save(
			environment,
			baseUrl,
			new Url(selected.baseUrl),
			selected.id,
			selected.accountNumber,
			selected.name,
			result.email,
			result.id,
			true,
			token);

		return new LoginInformation(
			result.id,
			result.name,
			result.email,
			new List<LoginInformation.Account> { selected });
	}
}
