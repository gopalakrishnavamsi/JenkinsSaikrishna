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

		public Credentials.AccessToken exchangeCode(
			final String authorizationCode,
			final String clientId,
			final String clientSecret) {

			Response response = super.post(
				this.baseUrl,
				new List<Object> { 'oauth', 'token' },
				QueryString.empty,
				new Map<String, String> {
					'Authorization' => this.getBasicAuthHeader(clientId, clientSecret),
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

	private static final LoggerService LOG = LoggerService.getInstance();
	@TestVisible
	private static final String JWT_HEADER;
	private static final Integer AUTH_TIMEOUT = 5000; // TODO: Move to config
	private static AuthAPI api;
	private static Map<DocuSign.Environment, ClientCredentials> clientCredentials
		= new Map<DocuSign.Environment, ClientCredentials>();
	private static DocuSign.Environment currentEnvironment;

	static {
		JWT_HEADER = base64UrlEncode(Blob.valueOf(JSON.serialize(new Map<String, String> {
			'typ' => 'JWT',
			'alg' => 'RS256'
		})));
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
		final UUID userId,
		final String clientId,
		final Blob jwtSigningKey) {

		// TODO: Add admin, Gen, Package B, SCM scopes
		String payload = base64UrlEncode(Blob.valueOf(JSON.serialize(new Map<String, Object> {
			'iss' => clientId,
			'sub' => String.valueOf(userId),
			'iat' => Datetime.now().getTime() / 1000,
			'exp' => Datetime.now().addHours(1).getTime() / 1000,
			'aud' => host,
			'scope' => 'signature impersonation'
		})));

		String signature = base64UrlEncode(Crypto.sign('RSA-SHA256', Blob.valueOf(JWT_HEADER + '.' + payload),
			jwtSigningKey));

		return JWT_HEADER + '.' + payload + '.' + signature;
	}

	@TestVisible
	private static DocuSign.Environment getCurrentEnvironment() {
		if (currentEnvironment == null) {
			currentEnvironment = DocuSign.parseEnvironment(AccountSettings__c.getOrgDefaults().Environment__c);
		}
		return currentEnvironment;
	}

	public static String getAccessToken() {
		ClientCredentials ccs = getClientCredentials(getCurrentEnvironment(), null);
		return getAccessToken(Credentials.getInstance(), ccs.clientId, ccs.jwtSigningKey);
	}

	@TestVisible
	private static String getAccessToken(
		final Credentials creds,
		final String clientId,
		final Blob jwtSigningKey) {

		if (creds == null || !creds.isValid) throw new DocuSignException(Label.AccountNotConfigured);

		if (creds.isTokenValid) return creds.token.token;

		Credentials.AccessToken token = getAuthAPI(creds.accountBaseUrl).exchangeJwt(generateJwt(
			creds.accountBaseUrl.getHost(),
			creds.userId,
			clientId,
			jwtSigningKey));

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
	private static String generateNonce() {
		String nonce = UUID.randomUUID().toShortString();
		UserSettings__c settings = UserSettings__c.getInstance();
		settings.Nonce__c = nonce;
		upsert settings;
		return nonce;
	}

	@TestVisible
	private class ClientCredentials {

		public DocuSign.Environment environment { get; private set; }
		public Url baseUrl { get; private set; }
		public String clientId { get; private set; }
		public String clientSecret { get; private set; }
		public Blob jwtSigningKey { get; private set; }

		public ClientCredentials(
			final DocuSign.Environment environment,
			final Url baseUrl,
			final String clientId,
			final String clientSecret,
			final Blob jwtSigningKey) {

			this.environment = environment;
			this.baseUrl = baseUrl;
			this.clientId = clientId;
			this.clientSecret = clientSecret;
			this.jwtSigningKey = jwtSigningKey;
		}
	}

	@TestVisible
	private static ClientCredentials convert(
		final DocuSign.Environment environment,
		final Environment__mdt metadata,
		final Url otherUrl) {

		if (environment == null) throw new DocuSignException(Label.InvalidEnvironment);

		return new ClientCredentials(
			environment,
			environment == DocuSign.Environment.Other && otherUrl != null
				? otherUrl : new Url(metadata.AccountBaseUrl__c),
			metadata.ClientId__c,
			metadata.ClientSecret__c,
			EncodingUtil.base64Decode(metadata.JwtSigningKey__c));
	}

	@TestVisible
	private static String getQueryEnvironment(final DocuSign.Environment environment) {
		if (environment != null
			&& environment != DocuSign.Environment.Invalid
			&& environment != DocuSign.Environment.Other) {

			return environment.name();
		}
		return 'Production';
	}

	@TestVisible
	private static ClientCredentials getClientCredentials(
		final DocuSign.Environment environment,
		final Url otherUrl) {

		// Default to prod environment
		DocuSign.Environment env = DocuSign.isValidEnvironment(environment, otherUrl)
			? environment : DocuSign.Environment.Production;
		ClientCredentials result = clientCredentials.get(env);
		if (result == null) {
			result = convert(
				env,
				(Environment__mdt)Collection.head([
					SELECT AccountBaseUrl__c, ClientId__c, ClientSecret__c, JwtSigningKey__c
					FROM Environment__mdt
					WHERE DeveloperName = :getQueryEnvironment(env)
					LIMIT 1
				]),
				otherUrl);
			clientCredentials.put(env, result);
		}
		return result;
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

		if (!DocuSign.isValidEnvironment(environment, otherUrl)) throw new DocuSignException(Label.InvalidEnvironment);

		// 1) Retrieve client credentials.
		ClientCredentials cc = getClientCredentials(environment, otherUrl);

		// 2) Build login URL
		PageReference pg = new PageReference(new Url(cc.baseUrl, '/oauth/auth').toExternalForm());
		pg.getParameters().putAll(new Map<String, String> {
			'response_type' => 'code',
			'scope' => 'signature impersonation',
			'client_id' => cc.clientId,
			'redirect_uri' => 'https://' + (Salesforce.isSandbox ? 'test' : 'login') + '.salesforce.com'
				+ '/apex/' + Application.namespacePrefix + 'completeoauth',
			'state' => encodeState(generateNonce(), cc.environment, cc.baseUrl)
		});
		return new Url(pg.getUrl());
	}

	@TestVisible
	private static String encodeState(
		final String nonce,
		final DocuSign.Environment environment,
		final Url baseUrl) {

		return SecureUtils.encrypt(nonce + '|' + environment.name() + '|' + baseUrl.toExternalForm());
	}

	@TestVisible
	private static ClientCredentials decodeState(final String state, final String nonce) {
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

		// 3) Verify 3 state tokens
		List<String> toks = decrypted.split('\\|');
		if (Collection.size(toks) != 3) {
			LOG.error('Unexpected state: ' + decrypted);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 4) Verify nonce
		if (nonce != toks[0]) {
			LOG.error('Nonce mismatch: ' + nonce + ' != ' + toks[0]);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 5) Verify DocuSign environment
		DocuSign.Environment environment = DocuSign.parseEnvironment(toks[1]);
		if (environment == null || environment == DocuSign.Environment.Invalid) {
			LOG.error('Invalid DocuSign environment: ' + toks[1]);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 6) Verify URL format
		Url baseUrl;
		try {
			baseUrl = new Url(toks[2]);
		} catch (Exception ex) {
			LOG.exception(ex, 'Invalid base URL: ' + toks[2]);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 7) Verify whitelisted DocuSign URL
		if (!DocuSign.isValidUrl(baseUrl)) {
			LOG.error('Invalid DocuSign base URL: ' + baseUrl.toExternalForm());
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		return getClientCredentials(environment, baseUrl);
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
			// 1) Parse state and retrieve client credentials
			ClientCredentials cc = decodeState(state, s.Nonce__c);

			// 2) Create Account Server remote site
			MetadataService.createRemoteSites(new List<MetadataService.RemoteSite> {
				MetadataService.newRemoteSite(
					cc.environment,
					'Auth',
					Label.AccountServiceDescription,
					cc.baseUrl)
			});

			// 2) Get accounts associated with login
			AuthService.AuthAPI client = getAuthAPI(cc.baseUrl);
			accessToken = client.exchangeCode(authorizationCode, cc.clientId, cc.clientSecret);
			LoginInformation result = client.getLoginInformation(accessToken.token);
			if (result == null || result.status == LoginInformation.LoginStatus.Failure.name()) {
				LOG.warn('No valid accounts for user '
					+ (result == null ? 'UNKNOWN' : result.email + '. Login URL = '
					+ cc.baseUrl.toExternalForm()));
				throw new DocuSignException(Label.NoValidAccounts);
			}

			// 3) If one valid account is returned, store result. Else, user must select account.
			if (result.status == LoginInformation.LoginStatus.Success.name()) {
				LoginInformation.Account a = result.accounts[0];
				Credentials.save(
					cc.environment,
					cc.baseUrl,
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

		if (!DocuSign.isValidEnvironment(environment, otherUrl)) {
			LOG.error('Invalid DocuSign environment: ' + (environment == null ? 'null' : environment.name()) + ' => '
				+ (otherUrl == null ? 'null' : otherUrl.toExternalForm()));
			throw new DocuSignException(Label.InvalidEnvironment);
		}

		if (selectedAccountNumber == null || selectedAccountNumber <= 0L) {
			throw new DocuSignException(Label.InvalidAccount);
		}

		ClientCredentials cc = getClientCredentials(environment, otherUrl);
		Credentials.AccessToken token = Credentials.getToken();
		if (token == null) {
			token = getAuthAPI(cc.baseUrl)
				.exchangeJwt(generateJwt(
					cc.baseUrl.getHost(),
					userId,
					cc.clientId,
					cc.jwtSigningKey));
		}

		LoginInformation result = getAuthAPI(cc.baseUrl).getLoginInformation(token.token);
		if (result == null || result.status == LoginInformation.LoginStatus.Failure.name()) {
			LOG.warn('No valid accounts for user '
				+ (result == null ? 'UNKNOWN' : result.email + '. Login URL = '
				+ cc.baseUrl.toExternalForm()));
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
			cc.baseUrl,
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
