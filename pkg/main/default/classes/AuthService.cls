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
			if (e != APIError.none) {
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
							e = new AuthError(response.getStatusCode(), errResp.containsKey('error_message')
								? (String)errResp.get('error_message') : response.getStatus());
						}
					}
				} catch (Exception ex) {
					this.log.exception(ex, 'Failed to parse response as a DocuSign auth error');
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
				this.log.error('Failed to exchange JWT for access token: ' + response.error);
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

		@TestVisible
		private String getInstanceClientId(
			final String rootClientId,
			final UUID accountId,
			final String accessToken) {

			RestAPI.Response response = this.post(
				this.baseUrl,
				new List<Object> { 'v1', 'applications', rootClientId, 'instance' },
				QueryString.empty,
				new Map<String, String> {
					'Authorization' => 'Bearer ' + accessToken,
					'Content-Type' => 'application/json; charset=utf-8'
				},
				JSON.serialize(new Map<String, String> {
					'account_id' => String.valueOf(accountId)
				}),
				AUTH_TIMEOUT);
			if (response.hasError) {
				this.log.error('Failed to get instance client ID: ' + response.error);
				throw new APIException(response.error);
			}
			return (String)((Map<String, Object>)JSON.deserializeUntyped(response.body)).get('client_id');
		}

		@TestVisible
		private String getInstanceClientSecret(
			final String clientId,
			final String accessToken) {

			RestAPI.Response response = this.post(
				this.baseUrl,
				new List<Object> { 'v1', 'applications', clientId, 'secrets' },
				QueryString.empty,
				new Map<String, String> {
					'Authorization' => 'Bearer ' + accessToken,
					'Content-Type' => 'application/json; charset=utf-8'
				},
				'{}',
				AUTH_TIMEOUT);
			if (response.hasError) {
				this.log.error('Failed to get instance client secret: ' + response.error);
				throw new APIException(response.error);
			}

			List<Object> secrets = (List<Object>)((Map<String, Object>)JSON.deserializeUntyped(
				response.body)).get('secrets');
			String result = null;
			for (Object secret : (secrets == null ? new List<Object>() : secrets)) {
				// find first non-scrubbed secret
				String value = (String)((Map<String, Object>)secret).get('secret');
				if (String.isNotBlank(value) && !value.startsWith('**********')) {
					result = value;
					break;
				}
			}
			return result;
		}

		@TestVisible
		private Blob getInstancePrivateKey(
			final String clientId,
			final String accessToken) {

			RestAPI.Response response = this.post(
				this.baseUrl,
				new List<Object> { 'v1', 'applications', clientId, 'keys' },
				QueryString.empty,
				new Map<String, String> {
					'Authorization' => 'Bearer ' + accessToken,
					'Content-Type' => 'application/json; charset=utf-8'
				},
				'{}',
				AUTH_TIMEOUT);
			if (response.hasError) {
				this.log.error('Failed to get instance private key: ' + response.error);
				throw new APIException(response.error);
			}

			Map<String, Object> body = (Map<String, Object>)JSON.deserializeUntyped(response.body);
			String pvkBase64 = (String)body.get('private_key');
			Blob result = null;
			if (String.isNotBlank(pvkBase64)) {
				result = EncodingUtil.base64Decode(pvkBase64
					.remove('-----BEGIN RSA PRIVATE KEY-----')
					.remove('\n')
					.remove('-----END RSA PRIVATE KEY-----'));
			}
			return result;
		}

		public Credentials.ClientCredentials getInstanceCredentials(
			final String rootClientId,
			final UUID accountId,
			final String accessToken) {

			String clientId = this.getInstanceClientId(rootClientId, accountId, accessToken);
			return new Credentials.ClientCredentials(
				clientId,
				this.getInstanceClientSecret(clientId, accessToken),
				this.getInstancePrivateKey(clientId, accessToken));
		}
	}

	@TestVisible
	private static final AuthService.Database DB = new AuthService.Database();
	private static final LoggerService LOG = LoggerService.getInstance();
	@TestVisible
	private static final String JWT_HEADER;
	@TestVisible
	private static final String SCOPE_ADMIN = 'account_product_read signature impersonation account_product_activate '
		+ 'invite spring_write spring_read manage_app_keys';
	@TestVisible
	private static final String SCOPE_USER = 'signature impersonation spring_write spring_read';
	private static final Integer AUTH_TIMEOUT = 5000; // TODO: Move to config
	private static AuthAPI api;
	private static Map<DocuSign.Environment, RootCredentials> rootCredentials
		= new Map<DocuSign.Environment, RootCredentials>();

	static {
		JWT_HEADER = base64UrlEncode(Blob.valueOf(JSON.serialize(new Map<String, String> {
			'typ' => 'JWT',
			'alg' => 'RS256'
		})));
	}

	@TestVisible
	private class Database {

		private Configuration__c updateConfiguration(
			final String inviteEmailSubject,
			final String inviteEmailBody) {

			Permissions.verifyIsCreateable(Configuration__c.getSObjectType(), new List<String> {
				'Name',
				Application.namespacePrefix + 'InviteEmailSubject__c',
				Application.namespacePrefix + 'InviteEmailBody__c'
			});
			Permissions.verifyIsUpdateable(Configuration__c.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'InviteEmailSubject__c',
				Application.namespacePrefix + 'InviteEmailBody__c'
			});

			Configuration__c config = (Configuration__c)Collection.head([
				SELECT InviteEmailSubject__c, InviteEmailBody__c
				FROM Configuration__c
				WHERE Name = 'Gen'
			]);
			if (config == null) {
				config = new Configuration__c(
					Name = 'Gen',
					InviteEmailSubject__c = inviteEmailSubject,
					InviteEmailBody__c = inviteEmailBody);
			}
			config.InviteEmailSubject__c = inviteEmailSubject;
			config.InviteEmailBody__c = inviteEmailBody;
			upsert config;

			return config;
		}

		public Gen.Product updateProduct(final Gen.Product product) {
			if (product == null) return null;

			updateConfiguration(
				product.inviteEmailSubject,
				product.inviteEmailBody);

			AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
			settings.InviteCallbackUrl__c = product.inviteCallbackUrl == null
				? null : product.inviteCallbackUrl.toExternalForm();
			settings.InviteRedirectUrl__c = product.inviteRedirectUrl == null
				? null : product.inviteRedirectUrl.toExternalForm();
			upsert settings;

			return product;
		}
	}

	private static AuthAPI getAuthAPI(final Url baseUrl) {
		if (api == null) {
			api = new AuthAPI(canonicalizeBaseUrl(baseUrl));
		}
		return api;
	}

	@TestVisible
	private static String generateJwt(
		final String host,
		final UUID userId,
		final Boolean canManageAccount,
		final String clientId,
		final Blob jwtSigningKey) {

		String payload = base64UrlEncode(Blob.valueOf(JSON.serialize(new Map<String, Object> {
			'iss' => clientId,
			'sub' => String.valueOf(userId),
			'iat' => Datetime.now().getTime() / 1000,
			'exp' => Datetime.now().addHours(1).getTime() / 1000,
			'aud' => host,
			'scope' => canManageAccount ? SCOPE_ADMIN : SCOPE_USER
		})));

		String signature = base64UrlEncode(Crypto.sign('RSA-SHA256', Blob.valueOf(JWT_HEADER + '.' + payload),
			jwtSigningKey));

		return JWT_HEADER + '.' + payload + '.' + signature;
	}

	public static String getAccessToken() {
		Credentials c = Credentials.getInstance();
		return getAccessToken(
			c.token,
			c.environment.accountBaseUrl,
			c.user.id,
			c.user.canManageAccount,
			c.client.id,
			c.client.privateKey);
	}

	@TestVisible
	private static String getAccessToken(
		final Credentials.AccessToken token,
		final Url accountBaseUrl,
		final UUID userId,
		final Boolean canManageAccount,
		final String clientId,
		final Blob jwtSigningKey) {

		if (accountBaseUrl == null || UUID.isEmpty(userId) || String.isBlank(clientId) || jwtSigningKey == null) {
			throw new DocuSignException(Label.AccountNotConfigured);
		}

		if (token != null && token.isValid) return token.token;

		Credentials.AccessToken newToken = getAuthAPI(accountBaseUrl).exchangeJwt(generateJwt(
			accountBaseUrl.getHost(),
			userId,
			canManageAccount,
			clientId,
			jwtSigningKey));

		Credentials.setToken(newToken);
		return newToken.token;
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
	private class RootCredentials {

		public DocuSign.Environment environment { get; private set; }
		public Url accountBaseUrl { get; private set; }
		public Url provisioningBaseUrl { get; private set; }
		public String clientId { get; private set; }
		public String clientSecret { get; private set; }

		public RootCredentials(
			final DocuSign.Environment environment,
			final Url accountBaseUrl,
			final Url provisioningBaseUrl,
			final String clientId,
			final String clientSecret) {

			this.environment = environment;
			this.accountBaseUrl = accountBaseUrl;
			this.provisioningBaseUrl = provisioningBaseUrl;
			this.clientId = clientId;
			this.clientSecret = clientSecret;
		}
	}

	@TestVisible
	private static RootCredentials convert(
		final DocuSign.Environment environment,
		final Environment__mdt metadata,
		final Url otherUrl) {

		if (environment == null) throw new DocuSignException(Label.InvalidEnvironment);

		return new RootCredentials(
			environment,
			environment == DocuSign.Environment.Other && otherUrl != null
				? otherUrl : new Url(metadata.AccountBaseUrl__c),
			new Url(metadata.ProvisioningBaseUrl__c),
			metadata.ClientId__c,
			metadata.ClientSecret__c);
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
	private static RootCredentials getRootCredentials(
		final DocuSign.Environment environment,
		final Url otherUrl) {

		// Default to prod environment
		DocuSign.Environment env = DocuSign.isValidEnvironment(environment, otherUrl)
			? environment : DocuSign.Environment.Production;
		RootCredentials result = rootCredentials.get(env);
		if (result == null) {
			result = convert(
				env,
				(Environment__mdt)Collection.head([
					SELECT AccountBaseUrl__c, ProvisioningBaseUrl__c, ClientId__c, ClientSecret__c
					FROM Environment__mdt
					WHERE DeveloperName = :getQueryEnvironment(env)
					LIMIT 1
				]),
				otherUrl);
			rootCredentials.put(env, result);
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

		// 1) Retrieve root client credentials.
		RootCredentials rc = getRootCredentials(environment, otherUrl);
		// TODO: Get instance client ID and secret and use those for subsequent calls.

		// 2) Build login URL
		PageReference pg = new PageReference(new Url(rc.accountBaseUrl, '/oauth/auth').toExternalForm());
		pg.getParameters().putAll(new Map<String, String> {
			'response_type' => 'code',
			'scope' => 'signature impersonation', // TODO: Add scopes
			'client_id' => rc.clientId,
			'redirect_uri' => 'https://' + (Salesforce.isSandbox ? 'test' : 'login') + '.salesforce.com'
				+ '/apex/' + Application.namespacePrefix + 'completeoauth',
			'state' => encodeState(generateNonce(), rc.environment, rc.accountBaseUrl)
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
	private static RootCredentials decodeState(final String state, final String nonce) {
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

		return getRootCredentials(environment, baseUrl);
	}

	@TestVisible
	private static Gen.Product getGenProduct(
		final Url provisioningBaseUrl,
		final UUID accountId,
		final String accessToken) {

		Gen.Product result = null;
		for (Product p : ProvisioningAPI.getInstance(provisioningBaseUrl, accountId, accessToken).getProducts()) {
			if (p != null && p.name == 'gen' && p.properties != null) {
				Url authUrl, apiUrl, inviteCallbackUrl, inviteRedirectUrl;
				String inviteSubject, inviteBody;
				for (String key : p.properties.keySet()) {
					String value = p.properties.get(key);
					if (String.isBlank(value)) continue;
					switch on key {
						when 'invite_callback_uri' {
							inviteCallbackUrl = new Url(value);
						} when 'invite_redirect_uri' {
							inviteRedirectUrl = new Url(value);
						} when 'merge_uri' {
							apiUrl = new Url(value);
						} when 'web_base_uri' {
							authUrl = new Url(value);
						} when 'invite_email_subject' {
							inviteSubject = value;
						} when 'invite_email_body' {
							inviteBody = value;
						}
					}
				}
				result = new Gen.Product(
					p.status,
					p.isTrial,
					p.trialExpires,
					authUrl,
					apiUrl,
					inviteCallbackUrl,
					inviteRedirectUrl,
					inviteSubject,
					inviteBody);
				break;
			}
		}
		return result;
	}

	@TestVisible
	private static List<MetadataService.RemoteSite> getRemoteSites(
		final DocuSign.Environment environment,
		final Url accountBaseUrl,
		final Url provisioningBaseUrl,
		final Url eSignatureBaseUrl,
		final Url scmAuthBaseUrl,
		final Url scmApiBaseUrl) {

		List<MetadataService.RemoteSite> sites = new List<MetadataService.RemoteSite>();
		if (DocuSign.isValidUrl(accountBaseUrl)) {
			sites.add(MetadataService.newRemoteSite(
				environment,
				'Account',
				Label.AccountServiceDescription,
				new Url('https://' + accountBaseUrl.getAuthority())));
		}
		if (DocuSign.isValidUrl(provisioningBaseUrl)) {
			sites.add(MetadataService.newRemoteSite(
				environment,
				'Provisioning',
				Label.ProvisioningServiceDescription,
				new Url('https://' + provisioningBaseUrl.getAuthority())));
		}
		if (DocuSign.isValidUrl(eSignatureBaseUrl)) {
			sites.add(MetadataService.newRemoteSite(
				environment,
				'eSignature',
				Label.ESignatureServiceDescription,
				new Url('https://' + eSignatureBaseUrl.getAuthority())));
		}
		if (DocuSign.isValidUrl(scmAuthBaseUrl)) {
			sites.add(MetadataService.newRemoteSite(
				environment,
				'Auth',
				Label.ScmAuthServiceDescription,
				new Url('https://' + scmAuthBaseUrl.getAuthority())));
		}
		if (DocuSign.isValidUrl(scmApiBaseUrl)) {
			sites.add(MetadataService.newRemoteSite(
				environment,
				'Gen',
				Label.GenServiceDescription,
				new Url('https://' + scmApiBaseUrl.getAuthority())));
		}
		return sites;
	}

	@TestVisible
	private static Url canonicalizeBaseUrl(final Url url) {
		if (url == null) return null;

		String path = url.getPath();
		return new Url('https://' + url.getAuthority() + (path.endsWith('/') ? path : path + '/'));
	}

	@TestVisible
	private static Credentials save(
		final DocuSign.Environment environment,
		final Url accountBaseUrl,
		final Url provisioningBaseUrl,
		final String rootClientId,
		final LoginInformation loginInfo,
		final LoginInformation.Account account,
		final Gen.Product product,
		final Credentials.AccessToken token) {

		if (environment == null
			|| environment == DocuSign.Environment.Invalid
			|| !DocuSign.isValidUrl(accountBaseUrl)
			|| !DocuSign.isValidUrl(provisioningBaseUrl)) {

			throw new DocuSignException(Label.InvalidEnvironment);
		}

		if (String.isBlank(rootClientId) || loginInfo == null || account == null || token == null || !token.isValid) {
			throw new DocuSignException(Label.UndefinedArgument);
		}

		// Create remote sites
		Url aBaseUrl = canonicalizeBaseUrl(accountBaseUrl);
		Url pBaseUrl = canonicalizeBaseUrl(provisioningBaseUrl);
		Url eSignatureBaseUrl = String.isBlank(account.eSignatureBaseUrl)
			? null : canonicalizeBaseUrl(new Url(account.eSignatureBaseUrl));
		Url scmAuthBaseUrl = product == null ? null : canonicalizeBaseUrl(product.authBaseUrl);
		Url scmApiBaseUrl = product == null ? null : canonicalizeBaseUrl(product.apiBaseUrl);
		List<MetadataService.RemoteSite> sites = getRemoteSites(
			environment,
			aBaseUrl,
			pBaseUrl,
			eSignatureBaseUrl,
			scmAuthBaseUrl,
			scmApiBaseUrl);
		if (Collection.isNotEmpty(sites)) MetadataService.createRemoteSites(sites);

		Credentials.ClientCredentials instanceCredentials = getAuthAPI(aBaseUrl)
			.getInstanceCredentials(
				rootClientId,
				account.id,
				token.token);

		DB.updateProduct(product);

		return Credentials.save(
			new Credentials.Environment(
				environment,
				aBaseUrl,
				pBaseUrl,
				eSignatureBaseUrl,
				scmAuthBaseUrl,
				scmApiBaseUrl),
			instanceCredentials,
			new Credentials.AccountCredentials(
				account.id,
				account.accountNumber,
				account.name,
				loginInfo.email,
				null),
			new Credentials.UserCredentials(
				loginInfo.id,
				loginInfo.name,
				loginInfo.email,
				true),
			token);
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
	 * required to configure DocuSign for Salesforce), or with multiple accounts in which case the
	 * <code>selectAccount</code> method should be called after the user selects the desired account.
	 */
	public static LoginInformation redeemCode(
		final String authorizationCode,
		final String state) {

		Permissions.verifyIsDocuSignAdministrator();

		UserSettings__c s = UserSettings__c.getInstance();
		try {
			// 1) Parse state and retrieve client credentials
			// TODO: Use instance client credentials?
			RootCredentials rc = decodeState(state, s.Nonce__c);

			// 2) Create Account Server remote site
			MetadataService.createRemoteSites(new List<MetadataService.RemoteSite> {
				MetadataService.newRemoteSite(
					rc.environment,
					'Account',
					Label.AccountServiceDescription,
					rc.accountBaseUrl)
			});

			// 2) Get accounts associated with login
			AuthService.AuthAPI client = getAuthAPI(rc.accountBaseUrl);
			Credentials.AccessToken token = client.exchangeCode(authorizationCode, rc.clientId, rc.clientSecret);
			LoginInformation result = client.getLoginInformation(token.token);
			if (result == null || result.status == LoginInformation.LoginStatus.Failure.name()) {
				LOG.warn('No valid accounts for user '
					+ (result == null ? 'UNKNOWN' : result.email + '. Login URL = '
					+ rc.accountBaseUrl.toExternalForm()));
				throw new DocuSignException(Label.NoValidAccounts);
			}

			// 3) If one valid account is returned, store result. Else, user must select account.
			if (result.status == LoginInformation.LoginStatus.Success.name()) {
				save(
					rc.environment,
					rc.accountBaseUrl,
					rc.provisioningBaseUrl,
					rc.clientId,
					result,
					result.accounts[0],
					getGenProduct(
						rc.provisioningBaseUrl,
						result.accounts[0].id,
						token.token),
					token);
			} else { // Multiple accounts. Save access token for subsequent calls.
				Credentials.setToken(token);
				Credentials.save();
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

		Credentials.AccessToken token = Credentials.getToken();
		if (token == null || !token.isValid) throw UnauthorizedException.accountNotConfigured();

		RootCredentials rc = getRootCredentials(environment, otherUrl);
		LoginInformation result = getAuthAPI(rc.accountBaseUrl).getLoginInformation(token.token);
		if (result == null || result.status == LoginInformation.LoginStatus.Failure.name()) {
			LOG.warn('No valid accounts for user '
				+ (result == null ? 'UNKNOWN' : result.email + '. Login URL = '
				+ rc.accountBaseUrl.toExternalForm()));
			throw new DocuSignException(Label.NoValidAccounts);
		}
		LoginInformation.Account selected = null;
		for (LoginInformation.Account a : result.accounts) {
			if (a.accountNumber == selectedAccountNumber) {
				selected = a;
				break;
			}
		}

		if (selected == null) throw new DocuSignException(Label.AccountNotFound);

		save(
			rc.environment,
			rc.accountBaseUrl,
			rc.provisioningBaseUrl,
			rc.clientId,
			result,
			selected,
			getGenProduct(
				rc.provisioningBaseUrl,
				selected.id,
				token.token),
			token);

		return new LoginInformation(
			result.id,
			result.name,
			result.email,
			new List<LoginInformation.Account> { selected });
	}
}
