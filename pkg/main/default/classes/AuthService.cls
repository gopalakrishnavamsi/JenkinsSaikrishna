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
				if (body == 'Bad Request') { // Less-fragile method of checking this?
					e = new AuthError(APIErrorCode.USER_NOT_ACTIVATED, Label.MustBeActivated);
				} else {
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

		@TestVisible
		private List<Url> setInstanceRedirectUris(
			final String clientId,
			final List<Url> redirectUris,
			final String accessToken) {

			List<Url> result = new List<Url>();
			if (redirectUris == null) return result;

			List<String> uris = new List<String>();
			for (Url u : redirectUris) {
				if (u != null) uris.add(u.toExternalForm());
			}

			RestAPI.Response response = this.post(
				this.baseUrl,
				new List<Object> { 'v1', 'applications', clientId },
				QueryString.empty,
				new Map<String, String> {
					'Authorization' => 'Bearer ' + accessToken,
					'Content-Type' => 'application/json; charset=utf-8'
				},
				JSON.serialize(new Map<String, Object> {
					'name' => 'DocuSign for Salesforce',
					'redirect_uris' => uris,
					'is_client_app' => true
				}),
				AUTH_TIMEOUT);
			if (response.hasError) {
				this.log.error('Failed to set instance redirect uris: ' + response.error);
				throw new APIException(response.error);
			}

			Object rus = ((Map<String, Object>)JSON.deserializeUntyped(response.body)).get('redirect_uris');
			if (rus != null && rus instanceof List<Object>) {
				for (Object o : (List<Object>)rus) {
					String ru = String.valueOf(o);
					if (String.isNotBlank(ru)) result.add(new Url(ru));
				}
			}
			return result;
		}

		public Credentials.ClientCredentials getInstanceCredentials(
			final String rootClientId,
			final UUID accountId,
			final List<Url> redirectUris,
			final String accessToken) {

			String clientId = this.getInstanceClientId(rootClientId, accountId, accessToken);
			this.setInstanceRedirectUris(clientId, redirectUris, accessToken);
			return new Credentials.ClientCredentials(
				clientId,
				this.getInstanceClientSecret(clientId, accessToken),
				this.getInstancePrivateKey(clientId, accessToken));
		}
	}

	@TestVisible
	private class APIPermissionProfile {
		public String permissionProfileId;
		public String permissionProfileName;
	}

	@TestVisible
	private class APIPermissionProfiles {
		public List<APIPermissionProfile> permissionProfiles;

		public PermissionProfileIds toExternalForm() {
			Long adminId = null, senderId = null;
			for (APIPermissionProfile pp : this.permissionProfiles == null
				? new List<APIPermissionProfile>() : this.permissionProfiles) {

				if (pp == null) continue;
				// TODO: Determine if this breaks for non-English users.
				if (pp.permissionProfileName == 'Account Administrator') {
					adminId = Long.valueOf(pp.permissionProfileId);
				} else if (pp.permissionProfileName == 'DocuSign Sender') {
					senderId = Long.valueOf(pp.permissionProfileId);
				}
			}
			return new PermissionProfileIds(adminId, senderId);
		}
	}

	@TestVisible
	private class PermissionProfileIds {
		public Long administratorId { get; private set; }
		public Long senderId { get; private set; }

		public PermissionProfileIds(
			final Long administratorId,
			final Long senderId) {

			this.administratorId = administratorId;
			this.senderId = senderId;
		}
	}

	@TestVisible
	private class AccountAPI extends DocuSignAPI {

		private final String accessToken;

		public AccountAPI(
			final Url baseUrl,
			final UUID accountId,
			final String accessToken) {

			super(new Url(baseUrl, '/restapi/v2/accounts/' + accountId + '/'));

			this.accessToken = accessToken;
		}

		public PermissionProfileIds getPermissionProfileIds() {
			RestAPI.Response response = this.get(
				this.getBaseUrl(),
				new List<Object> { 'permission_profiles' },
				QueryString.empty,
				new Map<String, String> {
					'Authorization' => 'Bearer ' + this.accessToken,
					'Accept' => 'application/json'
				},
				AUTH_TIMEOUT);
			if (response.hasError) {
				this.log.error('Failed to read DocuSign permission profile IDs: ' + response.error);
				throw new APIException(response.error);
			}

			return ((APIPermissionProfiles)JSON.deserialize(response.body, APIPermissionProfiles.class))
				.toExternalForm();
		}
	}

	@TestVisible
	private static final AuthService.Database DB = new AuthService.Database();
	private static final LoggerService LOG = LoggerService.getInstance();
	@TestVisible
	private static final String JWT_HEADER;
	@TestVisible
	private static final String SCOPE_ADMIN = 'account_product_read signature impersonation account_product_activate '
		+ 'spring_write spring_read manage_app_keys spring_content group_management_read group_management_write';
	@TestVisible
	private static final String SCOPE_USER = 'signature impersonation spring_write spring_read spring_content';
	@TestVisible
	private static final String SCOPE_CONTENT = 'spring_content';
	private static final Integer AUTH_TIMEOUT = 5000; // TODO: Move to config
	private static AuthAPI api;
	private static SpringOAuthAPI springoauth;
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

		public AccountSettings__c updateSettings(
			final PermissionProfileIds permissionProfileIds,
			final Url scmAuthBaseUrl,
			final Url scmApiBaseUrl) {

			AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
			settings.AdministratorProfileId__c = permissionProfileIds == null
				? null : permissionProfileIds.administratorId;
			settings.SenderProfileId__c = permissionProfileIds == null
				? null : permissionProfileIds.senderId;
			settings.ScmAuthBaseUrl__c = scmAuthBaseUrl == null
				? null : canonicalizeBaseUrl(scmAuthBaseUrl).toExternalForm();
			settings.ScmApiBaseUrl__c = scmApiBaseUrl == null
				? null : canonicalizeBaseUrl(scmApiBaseUrl).toExternalForm();
			upsert settings;

			return settings;
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
		final String scope,
		final String clientId,
		final Blob jwtSigningKey) {

		String payload = base64UrlEncode(Blob.valueOf(JSON.serialize(new Map<String, Object> {
			'iss' => clientId,
			'sub' => String.valueOf(userId),
			'iat' => Datetime.now().getTime() / 1000,
			'exp' => Datetime.now().addHours(1).getTime() / 1000,
			'aud' => host,
			'scope' => scope
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
			c.client.privateKey).token;
	}

	@TestVisible
	private static Credentials.AccessToken getAccessToken(
		final Credentials.AccessToken token,
		final Url accountBaseUrl,
		final UUID userId,
		final Boolean canManageAccount,
		final String clientId,
		final Blob jwtSigningKey) {

		if (accountBaseUrl == null || UUID.isEmpty(userId) || String.isBlank(clientId) || jwtSigningKey == null) {
			throw new DocuSignException(Label.AccountNotConfigured);
		}

		if (token != null && token.isValid) return token;

		String jwtToken = generateJwt(
			accountBaseUrl.getHost(),
			userId,
			canManageAccount ? SCOPE_ADMIN : SCOPE_USER,
			clientId,
			jwtSigningKey);
		Credentials.AccessToken newToken = getAuthAPI(accountBaseUrl).exchangeJwt(jwtToken);

		Credentials.setToken(newToken);
		return newToken;
	}

	public static String getContentAccessToken() {
		Permissions.verifyIsDocuSignNegotiator();
		Credentials c = Credentials.getInstance();
		return getAuthAPI(c.environment.accountBaseUrl).exchangeJwt(generateJwt(
			c.environment.accountBaseUrl.getHost(),
			c.user.id,
			SCOPE_CONTENT,
			c.client.id,
			c.client.privateKey)).token;
	}

	@Future
	private static void clearPermissions(final Set<Id> userIds) {
		Permissions.clear(userIds);
	}

	/**
	 * Clears all DocuSign account credentials and optionally user credentials as well. This is an irreversible action,
	 * so invoke only after confirming with the administrator.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param resetUsers Whether or not to also reset user credentials and clear any permission set assignments.
	 *
	 * @return The IDs for any users whose credentials were cleared.
	 */
	public static Set<Id> resetAccount(final Boolean resetUsers) {
		Permissions.verifyIsDocuSignAdministrator();

		Set<Id> result = Credentials.clear(resetUsers);
		if (resetUsers) {
			// Ensure users with the DocuSign Sender permission set are also cleared. They don't have a DS user ID, so
			// they are not picked up by credential clearing.
			for (PermissionSetAssignment psa : [
				SELECT AssigneeId
				FROM PermissionSetAssignment
				WHERE PermissionSet.Name = 'DocuSign_Sender'
				AND PermissionSet.NamespacePrefix = :Application.packageNamespace
			]) {
				result.add(psa.AssigneeId);
			}
			// This must be done in a @Future context to avoid MIXED_DML errors.
			clearPermissions(result);
		}
		return result;
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

	@TestVisible
	private class State {
		public String target { get; private set; }
		public DocuSign.Environment environment { get; private set; }
		public Url baseUrl { get; private set; }
		public Boolean setup { get; private set; }
		public Boolean isValid {
			get {
				return Salesforce.isValidTarget(target)
					&& DocuSign.isValidEnvironment(environment, baseUrl);
			}
		}

		public State(
			final String target,
			final DocuSign.Environment environment,
			final Url baseUrl,
			final Boolean setup) {

			this.target = target;
			this.environment = environment;
			this.baseUrl = baseUrl;
			this.setup = setup;
		}
	}

	/**
	 * Retrieves the DocuSign login URL for initial setup.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param target Salesforce location where OAuth events will be handled.
	 * @param environment The target DocuSign environment.
	 * @param otherUrl Optional account URL for the DocuSign environment, used with
	 * <code>Environment.Target.Other</code>.
	 *
	 * @return The DocuSign login URL. The user should be redirected here to complete authorization.
	 */
	public static Url getLoginUrl(
		final String target,
		final DocuSign.Environment environment,
		final Url otherUrl) {

		Permissions.verifyIsDocuSignAdministrator();

		if (!Salesforce.isValidTarget(target)) throw new DocuSignException(Label.InvalidTarget);
		if (!DocuSign.isValidEnvironment(environment, otherUrl)) throw new DocuSignException(Label.InvalidEnvironment);

		// 1) Retrieve root client credentials.
		RootCredentials rc = getRootCredentials(environment, otherUrl);

		// 2) Build login URL
		PageReference pg = new PageReference(new Url(rc.accountBaseUrl, '/oauth/auth').toExternalForm());
		pg.getParameters().putAll(new Map<String, String> {
			'response_type' => 'code',
			'scope' => SCOPE_ADMIN,
			'client_id' => rc.clientId,
			'redirect_uri' => 'https://' + (Salesforce.isSandbox ? 'test' : 'login') + '.salesforce.com'
				+ '/apex/' + Application.namespacePrefix + 'completeoauth',
			'state' => encodeState(generateNonce(), new State(target, rc.environment, rc.accountBaseUrl, true))
		});
		return new Url(pg.getUrl());
	}

	@TestVisible
	private static Url getOAuthRedirectUrl() {
		return new Url(Salesforce.baseUrl, Page.CompleteOAuth.getUrl());
	}

	/**
	 * Retrieves the DocuSign login URL to initiate the user OAuth and consent flow. This is an optional post-setup
	 * step for end-users.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set.
	 *
	 * @param target Salesforce location where OAuth events will be handled.
	 *
	 * @return The DocuSign login URL. The user should be redirected here to complete authorization.
	 */
	public static Url getLoginUrl(final String target) {
		Permissions.verifyIsDocuSignUser();

		if (!Salesforce.isValidTarget(target)) throw new DocuSignException(Label.InvalidTarget);

		Credentials c = Credentials.getInstance();
		PageReference pg = new PageReference(new Url(c.environment.accountBaseUrl, '/oauth/auth').toExternalForm());
		pg.getParameters().putAll(new Map<String, String> {
			'response_type' => 'code',
			'scope' => SCOPE_ADMIN,
			'client_id' => c.client.id,
			'redirect_uri' => getOAuthRedirectUrl().toExternalForm(),
			'state' => encodeState(generateNonce(), new State(
				target,
				c.environment.environment,
				c.environment.accountBaseUrl,
				false))
		});
		return new Url(pg.getUrl());
	}

	@TestVisible
	private static String encodeState(
		final String nonce,
		final State state) {

		if (state == null || !state.isValid) throw new DocuSignException(Label.InvalidAuthState);

		return SecureUtils.encrypt(nonce
			+ '|' + state.target
			+ '|' + state.environment.name()
			+ '|' + state.baseUrl.toExternalForm()
			+ '|' + state.setup);
	}

	@TestVisible
	private static State decodeState(
		final String state,
		final String nonce) {

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

		// 3) Verify 5 state tokens
		List<String> toks = decrypted.split('\\|');
		if (Collection.size(toks) != 5) {
			LOG.error('Unexpected state: ' + decrypted);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 4) Verify nonce
		if (nonce != toks[0]) {
			LOG.error('Nonce mismatch: ' + nonce + ' != ' + toks[0]);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 5) Verify Salesforce target.
		String target = toks[1];
		if (!Salesforce.isValidTarget(target)) {
			LOG.error('Invalid Salesforce target: ' + target);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 6) Verify DocuSign environment
		DocuSign.Environment environment = DocuSign.parseEnvironment(toks[2]);
		if (environment == null || environment == DocuSign.Environment.Invalid) {
			LOG.error('Invalid DocuSign environment: ' + toks[2]);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 7) Verify URL format
		Url baseUrl;
		try {
			baseUrl = new Url(toks[3]);
		} catch (Exception ex) {
			LOG.exception(ex, 'Invalid base URL: ' + toks[3]);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 8) Verify whitelisted DocuSign URL
		if (!DocuSign.isValidUrl(baseUrl)) {
			LOG.error('Invalid DocuSign base URL: ' + baseUrl.toExternalForm());
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 9) Parse setup boolean
		Boolean setup = Boolean.valueOf(toks[4]);

		return new State(target, environment, baseUrl, setup);
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
		// FIXME: Creating Account and Provisioning remote sites twice?
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
				'API',
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
		final Url scmAuthBaseUrl,
		final Url scmApiBaseUrl,
		final Url clmAdminUrl,
		final Url clmLandingPageUrl,
		final String rootClientId,
		final LoginInformation loginInfo,
		final LoginInformation.Account acct,
		final Credentials.AccessToken token) {

		if (environment == null
			|| environment == DocuSign.Environment.Invalid
			|| !DocuSign.isValidUrl(accountBaseUrl)
			|| !DocuSign.isValidUrl(provisioningBaseUrl)
			|| (scmAuthBaseUrl != null && !DocuSign.isValidUrl(scmAuthBaseUrl))
			|| (scmApiBaseUrl != null && !DocuSign.isValidUrl(scmApiBaseUrl))
			|| (clmAdminUrl != null && !DocuSign.isValidUrl(clmAdminUrl))
			|| (clmLandingPageUrl != null && !DocuSign.isValidUrl(clmLandingPageUrl))) {

			throw new DocuSignException(Label.InvalidEnvironment);
		}

		if (String.isBlank(rootClientId) || loginInfo == null || acct == null || token == null || !token.isValid) {
			throw new DocuSignException(Label.UndefinedArgument);
		}

		// Create remote sites
		Url aBaseUrl = canonicalizeBaseUrl(accountBaseUrl);
		Url pBaseUrl = canonicalizeBaseUrl(provisioningBaseUrl);
		Url eSignatureBaseUrl = String.isBlank(acct.eSignatureBaseUrl)
			? null : canonicalizeBaseUrl(new Url(acct.eSignatureBaseUrl));
		Url sAuthBaseUrl = scmAuthBaseUrl == null ? null : canonicalizeBaseUrl(scmAuthBaseUrl);
		Url sApiBaseUrl = scmApiBaseUrl == null ? null : canonicalizeBaseUrl(scmApiBaseUrl);
		List<MetadataService.RemoteSite> sites = getRemoteSites(
			environment,
			aBaseUrl,
			pBaseUrl,
			eSignatureBaseUrl,
			sAuthBaseUrl,
			sApiBaseUrl);
		if (Collection.isNotEmpty(sites)) MetadataService.createRemoteSites(sites);

		// Get instance credentials and new access token
		Credentials.ClientCredentials instanceCredentials = getAuthAPI(aBaseUrl)
			.getInstanceCredentials(
				rootClientId,
				acct.id,
				new List<Url> {
					getOAuthRedirectUrl()
				},
				token.token);
		Credentials.AccessToken newToken = getAccessToken(
			null,
			aBaseUrl,
			loginInfo.id,
			true,
			instanceCredentials.id,
			instanceCredentials.privateKey);

		DB.updateSettings(
			new AuthService.AccountAPI(eSignatureBaseUrl, acct.id, newToken.token).getPermissionProfileIds(),
			sAuthBaseUrl,
			sApiBaseUrl);

		return Credentials.save(
			new Credentials.Environment(
				environment,
				aBaseUrl,
				pBaseUrl,
				eSignatureBaseUrl,
				scmAuthBaseUrl,
				scmApiBaseUrl,
				clmAdminUrl,
				clmLandingPageUrl),
			instanceCredentials,
			new Credentials.AccountCredentials(
				acct.id,
				acct.accountNumber,
				acct.name,
				loginInfo.email,
				null),
			new Credentials.UserCredentials(
				loginInfo.id,
				loginInfo.name,
				loginInfo.email,
				Account.USER_STATUS_ACTIVE,
				true),
			newToken);
	}

	@TestVisible
	private static List<String> createRemoteSites(final RootCredentials rootCredentials) {
		return MetadataService.createRemoteSites(new List<MetadataService.RemoteSite> {
			MetadataService.newRemoteSite(
				rootCredentials.environment,
				'Account',
				Label.AccountServiceDescription,
				rootCredentials.accountBaseUrl),
			MetadataService.newRemoteSite(
				rootCredentials.environment,
				'Provisioning',
				Label.AccountServiceDescription,
				rootCredentials.provisioningBaseUrl)
		});
	}

	@TestVisible
	private class Login {
		public Credentials.AccessToken token { get; private set; }
		public LoginInformation loginInformation { get; private set; }

		public Login(
			final Credentials.AccessToken token,
			final LoginInformation loginInformation) {

			this.token = token;
			this.loginInformation = loginInformation;
		}
	}

	@TestVisible
	private static Login loginToDocuSign(
		final RootCredentials rootCredentials,
		final String authorizationCode) {

		AuthService.AuthAPI client = getAuthAPI(rootCredentials.accountBaseUrl);

		Credentials.AccessToken token = client.exchangeCode(
			authorizationCode,
			rootCredentials.clientId,
			rootCredentials.clientSecret);

		LoginInformation li = client.getLoginInformation(token.token);
		if (li == null || li.status == LoginInformation.STATUS_FAILURE) {
			LOG.warn('No valid accounts for user '
				+ (li == null ? 'UNKNOWN' : li.email + '. Login URL = '
				+ rootCredentials.accountBaseUrl.toExternalForm()));
			throw new DocuSignException(Label.NoValidAccounts);
		}

		return new Login(token, li);
	}

	@TestVisible
	private static LoginInformation saveSetupCredentials(
		final String authorizationCode,
		final State state) {

		RootCredentials rc = getRootCredentials(state.environment, state.baseUrl);

		createRemoteSites(rc);

		Login l = loginToDocuSign(rc, authorizationCode);
		// If one valid account is returned, store result. Else, user must select account.
		if (l != null
			&& l.token != null
			&& l.loginInformation != null
			&& l.loginInformation.accounts != null
			&& l.loginInformation.accounts[0] != null
			&& l.loginInformation.status == LoginInformation.STATUS_SUCCESS) {

			try {
				AccountProducts aps = AccountProducts.getInstance(
					rc.provisioningBaseUrl,
					canonicalizeBaseUrl(new Url(l.loginInformation.accounts[0].eSignatureBaseUrl)),
					l.loginInformation.accounts[0].id,
					l.token.token);
				save(
					rc.environment,
					rc.accountBaseUrl,
					rc.provisioningBaseUrl,
					aps.getScmAuthBaseUrl(),
					aps.getScmApiBaseUrl(),
					aps.getClmAdminUrl(),
					aps.getClmLandingPageUrl(),
					rc.clientId,
					l.loginInformation,
					l.loginInformation.accounts[0],
					l.token);
			} finally {
				AccountProducts.save();
			}
		} else if (l.token != null) { // Multiple accounts. Save root access token for subsequent calls.
			Credentials.setToken(l.token);
			Credentials.save();
		}

		return l == null ? null : l.loginInformation;
	}

	private static User activateUser(final Id userId) {
		User user = (User)Collection.head([SELECT Status__c FROM User WHERE Id = :userId LIMIT 1]);
		if (user == null) throw new DocuSignException(Label.UserNotFound);
		if (user.Status__c != Account.USER_STATUS_ACTIVE) {
			user.Status__c = Account.USER_STATUS_ACTIVE;
			update user;
		}
		return user;
	}

	@TestVisible
	private static Credentials saveUserCredentials(
		final String authorizationCode,
		final Url baseUrl) {

		Credentials c = Credentials.getInstance();
		Credentials.AccessToken token = getAuthAPI(baseUrl).exchangeCode(
			authorizationCode,
			c.client.id,
			c.client.secret);

		Credentials.setToken(token);

		activateUser(UserInfo.getUserId());

		return Credentials.save();
	}

	/**
	 * Attempts login to DocuSign with the supplied credentials. This must be invoked successfully prior to any other
	 * DocuSign for Salesforce actions. If the login is successful and maps to a single valid
	 * DocuSign account, DocuSign for Salesforce will be updated with these credentials. If the login is successful and
	 * maps to valid multiple accounts, those account options are returned to the caller to select the desired account
	 * in a subsequent call to this method.
	 * <p>
	 * If setup is not yet complete, the caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 * Otherwise, the caller must be assigned the <code>DocuSign User</code> permission set.
	 *
	 * @param authorizationCode The authorization code returned by DocuSign after successful login and consent.
	 * @param state The state passed through the DocuSign authorization service. This value is opaque to the caller and
	 * may not be tampered with.
	 *
	 * @return The result of the login. This may succeed with a single account (no additional action is
	 * required to configure DocuSign for Salesforce), or with multiple accounts in which case the
	 * <code>setAccount</code> method should be called after the user selects the desired account.
	 */
	public static LoginInformation redeemCode(
		final String authorizationCode,
		final String state) {

		LoginInformation result = null;
		UserSettings__c us = UserSettings__c.getInstance();
		try {
			State s = decodeState(state, us.Nonce__c);
			if (s.setup) {
				Permissions.verifyIsDocuSignAdministrator();
				result = saveSetupCredentials(authorizationCode, s);
			} else {
				Permissions.verifyIsDocuSignUser();
				saveUserCredentials(authorizationCode, s.baseUrl);
			}
			return result == null
				? new LoginInformation(LoginInformation.STATUS_SUCCESS, null, s.target)
				: result.withTarget(s.target);
		} finally {
			if (String.isNotBlank(us.Nonce__c)) {
				us.Nonce__c = null;
				update us;
			}
		}
	}

	/**
	 * Completes a DocuSign OAuth transaction with an error.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set.
	 *
	 *
	 * @param errorCode The error code returned by the DocuSign account service.
	 * @param errorMessage The error message returned by the DocuSign account service.
	 * @param state The state passed through the DocuSign authorization service. This value is opaque to the caller and
	 * may not be tampered with.
	 *
	 * @return The failure result of the login with event target specified.
	 */
	public static LoginInformation redeemError(
		final String errorCode,
		final String errorMessage,
		final String state) {

		Permissions.verifyIsDocuSignUser();

		LoginInformation result = null;
		UserSettings__c us = UserSettings__c.getInstance();
		try {
			State s = decodeState(state, us.Nonce__c);
			result = new LoginInformation(
				LoginInformation.STATUS_FAILURE,
				errorCode == 'consent_required' || errorCode == 'access_denied' || String.isBlank(errorMessage)
					? Label.ConsentRequired : errorMessage,
				s.target);
		} finally {
			if (String.isNotBlank(us.Nonce__c)) {
				us.Nonce__c = null;
				update us;
			}
		}
		return result;
	}

	public static LoginInformation setAccount(
		final DocuSign.Environment environment,
		final Url otherUrl,
		final Long accountNumber) {

		Permissions.verifyIsDocuSignAdministrator();

		if (!DocuSign.isValidEnvironment(environment, otherUrl)) {
			LOG.error('Invalid DocuSign environment: ' + (environment == null ? 'null' : environment.name()) + ' => '
				+ (otherUrl == null ? 'null' : otherUrl.toExternalForm()));
			throw new DocuSignException(Label.InvalidEnvironment);
		}

		if (accountNumber == null || accountNumber <= 0L) {
			throw new DocuSignException(Label.InvalidAccount);
		}

		Credentials.AccessToken token = Credentials.getToken();
		if (token == null || !token.isValid) throw UnauthorizedException.accountNotConfigured();

		RootCredentials rc = getRootCredentials(environment, otherUrl);
		LoginInformation result = getAuthAPI(rc.accountBaseUrl).getLoginInformation(token.token);
		if (result == null || result.status == LoginInformation.STATUS_FAILURE) {
			LOG.warn('No valid accounts for user '
				+ (result == null ? 'UNKNOWN' : result.email + '. Login URL = '
				+ rc.accountBaseUrl.toExternalForm()));
			throw new DocuSignException(Label.NoValidAccounts);
		}
		LoginInformation.Account selected = null;
		for (LoginInformation.Account a : result.accounts) {
			if (a.accountNumber == accountNumber) {
				selected = a;
				break;
			}
		}

		if (selected == null) throw new DocuSignException(Label.AccountNotFound);

		try {
			AccountProducts aps = AccountProducts.getInstance(
				rc.provisioningBaseUrl,
				canonicalizeBaseUrl(new Url(selected.eSignatureBaseUrl)),
				selected.id,
				token.token);
			save(
				rc.environment,
				rc.accountBaseUrl,
				rc.provisioningBaseUrl,
				aps.getScmAuthBaseUrl(),
				aps.getScmApiBaseUrl(),
				aps.getClmAdminUrl(),
				aps.getClmLandingPageUrl(),
				rc.clientId,
				result,
				selected,
				token);
		} finally {
			AccountProducts.save();
		}

		return new LoginInformation(
			result.id,
			result.name,
			result.email,
			new List<LoginInformation.Account> { selected });
	}

	@TestVisible
	private class SpringOAuthAPI extends RestAPI {
		private Url baseUrl;

		public SpringOAuthAPI(final Url baseUrl) {
			this.baseUrl = baseUrl;
		}

		public SpringOAuthLoginInformation completeSpringOAuth(final String authorizationCode) {
			SpringOAuthLoginInformation results;
			try {
				Credentials c = Credentials.getInstance();
				if (c != null && c.environment.scmAuthBaseUrl != null && String.isNotBlank(c.environment.scmAuthBaseUrl.toExternalForm())) {
					Map<String, Object> body = new Map<String, Object> {
						'code' => authorizationCode,
						'orgUrl' => Salesforce.baseUrl.toExternalForm()
					};
					Response response = super.post(
						this.baseUrl,
						new List<Object> { 'SetupSalesforce', 'UnifiedAppIntegration' },
						QueryString.empty,
						new Map<String, String> { 'Content-Type' => 'application/json' },
						JSON.serialize(body),
						RestAPI.defaultTimeout);

					if (response.hasError) {
						LoggerService.getInstance().error('Failed to setup SCM to Salesforce OAuth: ' + response.error);
						results = SpringOAuthLoginInformation.failure(Label.UnableToConnectDocuSignGen);
					} else {
						results = SpringOAuthLoginInformation.success(Label.SuccessDocuSignGenAuthorization);
					}
					//TODO update the custom setting to reflect that Spring OAuth has been completed successfully. To be added after Momentum Beta
				} else {
					results = SpringOAuthLoginInformation.failure(Label.MissingDocuSignGenAuthorizationSettings);
				}

			} catch (Exception ex) {
				LoggerService.getInstance().exception(ex, 'Failed to setup SCM to Salesforce OAuth');
				results = SpringOAuthLoginInformation.failure(ex.getMessage());
			}
			return results;
		}

	}

	@TestVisible
	private static SpringOAuthAPI getSpringOAuthAPI(final Url baseUrl) {
		if (springoauth == null) {
			springoauth = new SpringOAuthAPI(baseUrl);
		}
		return springoauth;
	}

	/**
	 * Retrieves the URL to start Salesforce and Spring OAuth Flow
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The Salesforce OAuth Url along with redirection to completeOauth
	 */
	public static Url getSpringOAuthUrl(final String state) {
		Permissions.verifyIsDocuSignAdministrator();
		PageReference pg = new PageReference(Salesforce.oauthUrl.toExternalForm());
		pg.getParameters().putAll(new Map<String, String> {
			'response_type' => 'code',
			'state' => state,
			'client_id' => [
				SELECT ConnectedAppId__c
				FROM Organization__mdt
				WHERE DeveloperName = 'Current'
				LIMIT 1
			].ConnectedAppId__c,
			'redirect_uri' => 'https://' + (Salesforce.isSandbox ? 'test' : 'login') + '.salesforce.com'
				+ '/apex/' + Application.namespacePrefix + 'CompleteSpringOAuth'
		});
		return new Url(pg.getUrl());
	}

	public static SpringOAuthLoginInformation completeSpringOAuth(final String authorizationCode) {
		Permissions.verifyIsDocuSignAdministrator();
		Credentials c = Credentials.getInstance();
		SpringOAuthLoginInformation result = getSpringOAuthAPI(c.environment.scmAuthBaseUrl)
			.completeSpringOAuth(authorizationCode);
		if (result.success) {
			AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
			settings.IsPlatformAuthorized__c = true;
			update settings;
		}
		return result;
	}
}
