global with sharing class AuthService {

	@TestVisible
	private static final String DOMAIN_ERROR_PAYLOAD = JSON.serialize(
		new Map<String, String> {
			'message' => Label.InvalidTarget,
			'detail' => Label.MyDomainHelpMessage
		});

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
				false,
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
	private class InstanceProperties {
		public String clientId { get; private set; }
		public String secret { get; private set; }
		public Blob privateKey { get; private set; }

		private InstanceProperties(
			final String clientId,
			final String secret,
			final Blob privateKey) {

			this.clientId = clientId;
			this.secret = secret;
			this.privateKey = privateKey;
		}
	}

	@TestVisible
	private class APIInstanceProperties {
		public List<APISecrets> secrets;
		public String client_id;
		public String private_key;

		public InstanceProperties toExternalForm() {
			return new InstanceProperties(
				this.client_id,
				getInstanceClientSecret(this.secrets),
				getInstancePrivateKey(this.private_key));
		}
	}

	@TestVisible
	private class APISecrets {
		public String id;
		public String secret;
		public String type;
	}

	@TestVisible
	private static String getInstanceClientSecret(
		final List<APISecrets> secretsList) {
		String result = null;
		for (APISecrets secretObj : secretsList) {
			// find first non-scrubbed secret
			String value = secretObj.secret;
			if (String.isNotBlank(value) && !value.startsWith('**********')) {
				result = value;
				break;
			}
		}

		return result;
	}

	@TestVisible
	private static Blob getInstancePrivateKey(
		final String privateKey) {
		Blob result = null;
		if (String.isNotBlank(privateKey)) {
			result = EncodingUtil.base64Decode(privateKey
				.remove('-----BEGIN RSA PRIVATE KEY-----')
				.remove('\n')
				.remove('-----END RSA PRIVATE KEY-----'));
		}

		return result;
	}

	@TestVisible
	private class AuthAPI extends RestAPI {

		private Url baseUrl;

		public AuthAPI(final Url baseUrl) {
			if (!DocuSign.isValidUrl(baseUrl)) throw new DocuSignException(Label.InvalidEnvironment);

			this.baseUrl = baseUrl;
		}

		private String getErrorMessage(final Map<String, Object> errorResponse) {
			if (errorResponse == null) return null;

			return errorResponse.containsKey('error_description')
				? (String)errorResponse.get('error_description') : (String)errorResponse.get('error_message');
		}

		@TestVisible
		override protected virtual APIError getError(final HttpResponse response) {
			APIError e = super.getError(response);
			if (e != APIError.none) {
				String body = response.getBody();
				this.log.warn('Authorization service error:\n' + body);
				if (body == 'Bad Request') { // Less-fragile method of checking this?
					e = new APIError(APIErrorCode.USER_NOT_ACTIVATED, Label.MustBeActivated);
				} else {
					try {
						Map<String, Object> errResp = (Map<String, Object>)JSON.deserializeUntyped(body);
						String errMsg = getErrorMessage(errResp);
						switch on (String)errResp.get('error') {
							when 'consent_required' {
								e = new APIError(APIErrorCode.CONSENT_REQUIRED, Label.ConsentRequired);
							} when 'invalid_grant' {
								if (errMsg == 'user_not_found') {
									e = new APIError(APIErrorCode.UNKNOWN_USER, Label.MustBeActivated);
								} else {
									e = new APIError(APIErrorCode.INVALID_GRANT, String.isBlank(errMsg)
										? Label.InvalidGrant : errMsg);
								}
							} when else {
								this.log.warn('Unknown auth error');
								e = new APIError(APIErrorCode.UNAUTHORIZED, String.isBlank(errMsg)
									? response.getStatus() : errMsg);
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
		private InstanceProperties createInstance(
			final String rootClientId,
			final UUID accountId,
			final List<Url> redirectUris,
			final String accessToken) {

			List<String> uris = new List<String>();
			for (Url u : redirectUris) {
				if (u != null) uris.add(u.toExternalForm());
			}

			RestAPI.Response response = this.post(
				this.baseUrl,
				new List<Object> { 'v2', 'applications', rootClientId, 'instance' },
				QueryString.empty,
				new Map<String, String> {
					'Authorization' => 'Bearer ' + accessToken,
					'Content-Type' => 'application/json; charset=utf-8'
				},
				//updated the name of instance application to 'DocuSign' here so that it matches with the client application name of root IK
				JSON.serialize(new Map<String, Object> {
					'account_id' => String.valueOf(accountId),
					'redirect_uris' => uris
				}),
				AUTH_TIMEOUT);

			if (response.hasError) {
				this.log.error('Failed to set instance redirect uris and fetch the secret keys: ' + response.error);
				throw new APIException(response.error);
			}

			return ((APIInstanceProperties)JSON.deserialize(response.body, APIInstanceProperties.class)).toExternalForm();
		}

		public Credentials.ClientCredentials getInstanceCredentials(
			final String rootClientId,
			final UUID accountId,
			final List<Url> redirectUris,
			final String accessToken) {

			InstanceProperties instanceProperties = this.createInstance(rootClientId, accountId, redirectUris, accessToken);
			return new Credentials.ClientCredentials(
				instanceProperties.clientId,
				instanceProperties.secret,
				instanceProperties.privateKey);
		}

		public Boolean deleteInstance(
			final String clientId,
			final String accessToken) {

			Boolean result = true;
			RestAPI.Response response = this.del(
				this.baseUrl,
				new List<Object> { 'v1', 'applications', clientId },
				QueryString.empty,
				new Map<String, String> { 'Authorization' => 'Bearer ' + accessToken },
				null,
				AUTH_TIMEOUT);
			if (response.hasError) {
				// We get a weird error response when the instance app is not found. Just log and move on.
				this.log.error('Failed to delete instance application: ' + response.error);
				result = false;
			}
			return result;
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

	private static final LoggerService LOG = LoggerService.getInstance();
	@TestVisible
	private static final String JWT_HEADER;
	@TestVisible
	private static final String SCOPE_ADMIN = 'account_product_read signature impersonation account_product_activate '
		+ 'spring_write spring_read manage_app_keys spring_content group_management_read group_management_write clm_ui';
	@TestVisible
	private static final String SCOPE_USER = 'signature impersonation spring_write spring_read spring_content clm_ui';
	@TestVisible
	private static final String SCOPE_CONTENT = 'spring_content';
	private static final Integer AUTH_TIMEOUT = 5000; // TODO: Move to config
	private static AuthAPI api;
	private static ScmSetupAPI scmClient;
	private static Map<DocuSign.Environment, RootCredentials> rootCredentials
		= new Map<DocuSign.Environment, RootCredentials>();

	static {
		JWT_HEADER = StringUtils.base64UrlEncode(Blob.valueOf(JSON.serialize(new Map<String, String> {
			'typ' => 'JWT',
			'alg' => 'RS256'
		})));
	}

	private static AuthAPI getAuthAPI(final Url baseUrl) {
		if (api == null) {
			api = new AuthAPI(UrlUtils.canonicalizeBaseUrl(baseUrl));
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

		String payload = StringUtils.base64UrlEncode(Blob.valueOf(JSON.serialize(new Map<String, Object> {
			'iss' => clientId,
			'sub' => String.valueOf(userId),
			'iat' => Datetime.now().getTime() / 1000,
			'exp' => Datetime.now().addHours(1).getTime() / 1000,
			'aud' => host,
			'scope' => scope
		})));

		String signature = StringUtils.base64UrlEncode(Crypto.sign('RSA-SHA256', Blob.valueOf(JWT_HEADER + '.' + payload),
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
		// No need to check permissions here. Credentials.getInstance() will throw an exception if the user is not
		// provisioned and exchangeJwt will fail if the user is invalid or has not granted consent.
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

	private static void clearFolderConfiguration() {
		Database.executeBatch(new ClearFolderConfiguration());
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

		// delete instance application if this is the original org where DAL was installed (i.e. not refreshed sandbox)
		if (Credentials.isAccountValid()
			&& AccountSettings__c.getOrgDefaults().OrganizationId__c == UserInfo.getOrganizationId()) {

			Credentials c = Credentials.getInstance();
			getAuthAPI(c.environment.accountBaseUrl).deleteInstance(
				c.client.id,
				getAccessToken(
					c.token,
					c.environment.accountBaseUrl,
					c.user.id,
					true,
					c.client.id,
					c.client.privateKey).token);
		}

		AccountProducts.clear();

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

			//Clear SpringCM folder id to Salesforce Object id mapping stored in Agreement configuration object
			//This will invoke a Batch job to delete all records from the AgreementConfiguration custom object
			clearFolderConfiguration();

			// Delete OnlineEditor template folder configuration.
			OnlineEditorRoot__c ct = OnlineEditorRoot__c.getOrgDefaults();
			ct.FolderId__c = null;
			upsert ct;
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
	private static Boolean isValidType(final String type) {
		return type == LoginInformation.TYPE_USER
			|| type == LoginInformation.TYPE_DEVELOPER
			|| type == LoginInformation.TYPE_SETUP;
	}

	@TestVisible
	private static Boolean isValidTarget(
		final String type,
		final String target) {

		return String.isNotBlank(target)
			&& (type == LoginInformation.TYPE_DEVELOPER ? target.startsWith('/') : Salesforce.isValidTarget(target));
	}

	@TestVisible
	private class DocuSignOAuthState {

		public String type { get; private set; }
		public String target { get; private set; }
		public DocuSign.Environment environment { get; private set; }
		public Url baseUrl { get; private set; }
		public Boolean isValid {
			get {
				return isValidType(this.type)
					&& isValidTarget(this.type, this.target)
					&& DocuSign.isValidEnvironment(this.environment, this.baseUrl);
			}
		}

		public DocuSignOAuthState(
			final String type,
			final String target,
			final DocuSign.Environment environment,
			final Url baseUrl) {

			this.type = type;
			this.target = target;
			this.environment = environment;
			this.baseUrl = baseUrl;
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

		if (!Salesforce.isValidTarget(target)) throw new DocuSignException(DOMAIN_ERROR_PAYLOAD);
		if (!DocuSign.isValidEnvironment(environment, otherUrl)) throw new DocuSignException(Label.InvalidEnvironment);

		// 1) Retrieve root client credentials.
		RootCredentials rc = getRootCredentials(environment, otherUrl);

		// 2) Build login URL
		PageReference pg = new PageReference(new Url(rc.accountBaseUrl, '/oauth/auth').toExternalForm());
		pg.getParameters().putAll(new Map<String, String> {
			'response_type' => 'code',
			'scope' => SCOPE_ADMIN,
			'client_id' => rc.clientId,
			'redirect_uri' => getDocuSignOAuthRedirectUrl(true).toExternalForm(),
			'state' => encodeDocuSignOAuthState(
				generateNonce(),
				new DocuSignOAuthState(
					LoginInformation.TYPE_SETUP,
					target,
					rc.environment,
					rc.accountBaseUrl))
		});
		return new Url(pg.getUrl());
	}

	/**
	 * Retrieves the DocuSign login URL to initiate the user OAuth and consent flow. This is an optional post-setup
	 * step for end-users.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set.
	 *
	 * @param type The login type requested: <code>USER</code> or <code>DEVELOPER</code>.
	 * @param target Salesforce location where OAuth events will be handled. If <code>type</code> is
	 * <code>DEVELOPER</code>, this must be a local path to a Salesforce page.
	 *
	 * @return The DocuSign login URL. The user should be redirected here to complete authorization.
	 */
	public static Url getLoginUrl(
		final String type,
		final String target) {

		Permissions.verifyIsDocuSignUser();

		if (type == LoginInformation.TYPE_USER) {
			if (!Salesforce.isValidTarget(target)) throw new DocuSignException(DOMAIN_ERROR_PAYLOAD);
		} else if (type == LoginInformation.TYPE_DEVELOPER) {
			if (String.isBlank(target) || !target.startsWith('/')) throw new DocuSignException(Label.InvalidRedirectUrl);
		} else { // Only user (OOB) and developer (Apex Toolkit) logins are acceptable
			throw new DocuSignException(Label.InvalidType);
		}

		Credentials c = Credentials.getInstance();
		PageReference pg = new PageReference(new Url(c.environment.accountBaseUrl, '/oauth/auth').toExternalForm());
		pg.getParameters().putAll(new Map<String, String> {
			'response_type' => 'code',
			'scope' => SCOPE_ADMIN,
			'client_id' => c.client.id,
			'redirect_uri' => getDocuSignOAuthRedirectUrl(type == LoginInformation.TYPE_SETUP).toExternalForm(),
			'state' => encodeDocuSignOAuthState(generateNonce(), new DocuSignOAuthState(
				type,
				target,
				c.environment.environment,
				c.environment.accountBaseUrl))
		});
		return new Url(pg.getUrl());
	}

	/**
	 * Generates a DocuSign login URL where a user can grant consent to this application. The calling application should
	 * redirect the user to this URL. Once login is complete, the user will be redirected to the path specified by
	 * <code>redirectTo</code>.
	 * <p>
	 * The <code>redirectTo</code> parameter must be a path to a page in the current Salesforce org. The org domain base
	 * URL will be prepended to this. Upon redirect, two additional parameters are appended:
	 * <ul>
	 *     <li><code>dfsle__status</code>: either <code>Success</code> or <code>Failure</code>.</li>
	 * 	   <li><code>dfsle__message</code>: additional details in the case of failures.
	 * </ul>
	 * <p>
	 * The resulting URL is valid for only a single use by the current user.
	 * <p>
	 * Callers must be assigned the <code>DocuSign User</code> permission set or better.
	 * <p>
	 * Example:
	 * <pre>
	 * Url loginUrl = dfsle.AuthService.getLoginUrl('/apex/MyReturnPage');
	 *
	 * // Redirect the user to loginUrl. There they can authenticate with DocuSign and grant consent to the application.
	 *
	 * // After successful authorization, the user is redirected to
	 * // https://your-domain.my.salesforce.com/apex/MyReturnPage?dfsle__status=Success.
	 * </pre>
	 *
	 * @param redirectTo Where to redirect the user to after login. This must be a local path to a page that will
	 * handle the authorization result.
	 *
	 * @return The DocuSign login URL.
	 */
	global static Url getLoginUrl(final String redirectTo) {
		Permissions.verifyIsDocuSignUser();

		if (String.isBlank(redirectTo)) throw new DocuSignException(Label.InvalidRedirectUrl);

		// Prevent double-slash in case browser allows it as a valid external redirect
		String target = redirectTo;
		if (target.startsWith('/')) {
			target = target.replaceFirst('/+', '');
		}

		return getLoginUrl(LoginInformation.TYPE_DEVELOPER, '/' + target); // Ensure local redirect only
	}

	@TestVisible
	private static String encodeDocuSignOAuthState(
		final String nonce,
		final DocuSignOAuthState state) {

		if (state == null || !state.isValid) throw new DocuSignException(Label.InvalidAuthState);

		return SecureUtils.encrypt(nonce
			+ '|' + state.type
			+ '|' + state.target
			+ '|' + state.environment.name()
			+ '|' + state.baseUrl.toExternalForm());
	}

	@TestVisible
	private static DocuSignOAuthState decodeDocuSignOAuthState(
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

		// 5) Parse type
		String type = toks[1];
		if (!isValidType(type)) {
			LOG.error('Invalid login type: ' + type);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 6) Verify Salesforce event target or redirect URL.
		String target = toks[2];
		if (!isValidTarget(type, target)) {
			LOG.error('Invalid Salesforce target: ' + target);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 7) Verify DocuSign environment
		DocuSign.Environment environment = DocuSign.parseEnvironment(toks[3]);
		if (environment == null || environment == DocuSign.Environment.Invalid) {
			LOG.error('Invalid DocuSign environment: ' + toks[3]);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 8) Verify DocuSign URL format
		Url baseUrl;
		try {
			baseUrl = new Url(toks[4]);
		} catch (Exception ex) {
			LOG.exception(ex, 'Invalid base URL: ' + toks[4]);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 9) Verify if baseUrl is included in allowed List of URL's
		if (!DocuSign.isValidUrl(baseUrl)) {
			LOG.error('Invalid DocuSign base URL: ' + baseUrl.toExternalForm());
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		return new DocuSignOAuthState(type, target, environment, baseUrl);
	}

	@TestVisible
	private static Credentials save(
		final DocuSign.Environment environment,
		final Url accountBaseUrl,
		final Url provisioningBaseUrl,
		final Url eSignatureBaseUrl,
		final String rootClientId,
		final LoginInformation loginInfo,
		final LoginInformation.Account acct,
		final Credentials.AccessToken token) {

		if (environment == null
			|| environment == DocuSign.Environment.Invalid
			|| !DocuSign.isValidUrl(accountBaseUrl)
			|| !DocuSign.isValidUrl(provisioningBaseUrl)
			|| !DocuSign.isValidUrl(eSignatureBaseUrl)) {

			throw new DocuSignException(Label.InvalidEnvironment);
		}

		if (String.isBlank(rootClientId) || loginInfo == null || acct == null || token == null || !token.isValid) {
			throw new DocuSignException(Label.UndefinedArgument);
		}

		Url aBaseUrl = UrlUtils.canonicalizeBaseUrl(accountBaseUrl);
		Url pBaseUrl = UrlUtils.canonicalizeBaseUrl(provisioningBaseUrl);
		Url eBaseUrl = UrlUtils.canonicalizeBaseUrl(eSignatureBaseUrl);

		// Get instance credentials and new access token
		Credentials.ClientCredentials instanceCredentials = getAuthAPI(aBaseUrl)
			.getInstanceCredentials(
				rootClientId,
				acct.id,
				new List<Url> { getDocuSignOAuthRedirectUrl(false) },
				token.token);
		Credentials.AccessToken newToken = getAccessToken(
			null,
			aBaseUrl,
			loginInfo.id,
			true,
			instanceCredentials.id,
			instanceCredentials.privateKey);

		PermissionProfileIds ppIds = new AuthService.AccountAPI(
			eBaseUrl,
			acct.id,
			newToken.token)
			.getPermissionProfileIds();

		return Credentials.save(
			new Credentials.Environment(
				environment,
				aBaseUrl,
				pBaseUrl,
				eBaseUrl),
			instanceCredentials,
			new Credentials.AccountCredentials(
				acct.id,
				acct.accountNumber,
				acct.name,
				loginInfo.email,
				null,
				ppIds == null ? null : ppIds.administratorId,
				ppIds == null ? null : ppIds.senderId),
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
				MetadataService.REMOTE_SITE_ACCOUNT,
				Label.AccountServiceDescription,
				rootCredentials.accountBaseUrl),
			MetadataService.newRemoteSite(
				rootCredentials.environment,
				MetadataService.REMOTE_SITE_PROVISIONING,
				Label.AccountServiceDescription,
				rootCredentials.provisioningBaseUrl)
		});
	}

	@TestVisible
	private static String createRemoteSite(
		final DocuSign.Environment environment,
		final Url eSignatureBaseUrl) {

		return (String)Collection.head(MetadataService.createRemoteSites(new List<MetadataService.RemoteSite> {
			MetadataService.newRemoteSite(
				environment,
				MetadataService.REMOTE_SITE_ESIGNATURE,
				Label.ESignatureServiceDescription,
				eSignatureBaseUrl)
		}));
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

	@Future
	private static void assignClmAdministratorPermissionSet(final Id userId) {
		if (String.isBlank(userId)) return;

		Permissions.assignPermissionSets(new Set<Id> { userId }, new Set<String> { Permissions.CLM_ADMINISTRATOR });
	}

	@TestVisible
	private static Boolean completeSetup(
		final RootCredentials rootCredentials,
		final LoginInformation loginInfo,
		final LoginInformation.Account account,
		final Credentials.AccessToken accessToken) {

		if (rootCredentials == null
			|| loginInfo == null
			|| account == null
			|| accessToken == null
			|| !accessToken.isValid) {

			throw new DocuSignException(Label.UndefinedArgument);
		}

		// Create remote site for eSignature
		Url eSignatureBaseUrl = UrlUtils.canonicalizeBaseUrl(new Url(account.eSignatureBaseUrl));
		createRemoteSite(rootCredentials.environment, eSignatureBaseUrl);

		Boolean result = false;
		try {
			AccountProducts aps = AccountProducts.initialize(
				rootCredentials.environment,
				rootCredentials.provisioningBaseUrl,
				eSignatureBaseUrl,
				account.id,
				accessToken.token);

			if (aps.isConnectEnabled()) {
				ConnectService.createConfiguration(
					eSignatureBaseUrl,
					account.id,
					accessToken.token);
			}

			save(
				rootCredentials.environment,
				rootCredentials.accountBaseUrl,
				rootCredentials.provisioningBaseUrl,
				eSignatureBaseUrl,
				rootCredentials.clientId,
				loginInfo,
				account,
				accessToken);

			// DFS-6068: Make sure setup user has CLM Administrator role; DFS-6296: Assign CLM admin perm set only if not already assigned
			if (aps.isClmEnabled() && !Permissions.isClmAdministrator()) {
				assignClmAdministratorPermissionSet(UserInfo.getUserId());
			}
		} finally {
			result = AccountProducts.save();
		}

		return result;
	}

	@TestVisible
	private static LoginInformation saveSetupCredentials(
		final String authorizationCode,
		final DocuSignOAuthState state) {

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

			completeSetup(
				rc,
				l.loginInformation,
				l.loginInformation.accounts[0],
				l.token);
		} else if (l.token != null) { // Multiple accounts. Save root access token for subsequent calls.
			Credentials.setToken(l.token);
			Credentials.save();
		}

		return l == null ? null : l.loginInformation;
	}

	private static User activateUser(final Id userId) {
		Permissions.verifyIsUpdateable(User.getSObjectType(), new List<String> {
			Application.namespacePrefix + 'Status__c'
		});

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
	 * DocuSign actions. If the login is successful and maps to a single valid DocuSign account, no further action is
	 * necessary. If the login is successful and maps to valid multiple accounts, those account options are returned to
	 * the caller to select the desired account in a subsequent call to this method.
	 * <p>
	 * If setup is not yet complete, the caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 * Otherwise, the caller must be assigned the <code>DocuSign User</code> permission set.
	 *
	 * @param authorizationCode The authorization code returned by DocuSign after successful login and consent.
	 * @param state The state passed through the DocuSign authorization service. This value is opaque to the caller and
	 * may not be tampered with.
	 *
	 * @return The result of the login. This may succeed with a single account (no additional action is
	 * required), or with multiple accounts in which case the <code>setAccount</code> method should be called after the
	 * user selects the desired account.
	 */
	public static LoginInformation redeemDocuSignCode(
		final String authorizationCode,
		final String state) {

		LoginInformation result = null;
		DocuSignOAuthState s = decodeDocuSignOAuthState(state, UserSettings__c.getInstance().Nonce__c);
		if (s.type == LoginInformation.TYPE_SETUP) {
			Permissions.verifyIsDocuSignAdministrator();
			result = saveSetupCredentials(authorizationCode, s);
		} else {
			Permissions.verifyIsDocuSignUser();
			saveUserCredentials(authorizationCode, s.baseUrl);
		}
		return result == null
			? new LoginInformation(s.type, LoginInformation.STATUS_SUCCESS, null, null, s.target)
			: result.withTarget(s.target);
	}

	/**
	 * Completes a DocuSign OAuth transaction with an error.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set.
	 *
	 * @param errorCode The error code returned by the DocuSign account service.
	 * @param errorMessage The error message returned by the DocuSign account service.
	 * @param state The state passed through the DocuSign authorization service. This value is opaque to the caller and
	 * may not be tampered with.
	 *
	 * @return The failure result of the login with event target specified.
	 */
	public static LoginInformation redeemDocuSignError(
		final String errorCode,
		final String errorMessage,
		final String state) {

		Permissions.verifyIsDocuSignUser();

		LoginInformation result = null;
		UserSettings__c us = UserSettings__c.getInstance();
		try {
			DocuSignOAuthState s = decodeDocuSignOAuthState(state, us.Nonce__c);
			result = new LoginInformation(
				s.type,
				LoginInformation.STATUS_FAILURE,
				errorCode == 'consent_required' || errorCode == 'access_denied' || String.isBlank(errorMessage)
					? Label.ConsentRequired : errorMessage,
				null,
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

		completeSetup(
			rc,
			result,
			selected,
			token);

		AccountSettings__c settings = AccountSettings__c.getOrgDefaults();

		return new LoginInformation(
			result.id,
			result.name,
			result.email,
			settings.IsPlatformAuthorized__c,
			new List<LoginInformation.Account> { selected });
	}

	@TestVisible
	private class ScmSetupAPI extends ScmAPI {

		public ScmSetupAPI(final Url baseUrl) {
			super(baseUrl);
		}

		public LoginInformation completeSetup(final String authorizationCode) {
			LoginInformation result;
			try {
				AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
				Map<String, Object> body = new Map<String, Object> {
					'accountId' => settings.AccountId__c,
					'code' => authorizationCode,
					'orgUrl' => Salesforce.baseUrl.toExternalForm()
				};
				RestAPI.Response response = this.post(
					new List<Object> { 'SetupSalesforce', 'DALIntegration' },
					JSON.serialize(body),
					RestAPI.defaultTimeout);

				if (response.hasError) {
					this.log.error('Failed to setup SCM to Salesforce OAuth: ' + response.error);
					result = new LoginInformation(
						LoginInformation.TYPE_SETUP,
						LoginInformation.STATUS_FAILURE,
						Label.UnableToConnectDocuSignGen,
						String.valueOf(response.error),
						null);
				} else {
					result = new LoginInformation(
						LoginInformation.TYPE_SETUP,
						LoginInformation.STATUS_SUCCESS,
						Label.SuccessDocuSignAuthorization,
						null,
						null);
				}
			} catch (Exception ex) {
				LoggerService.getInstance().exception(ex, 'Failed to setup SCM to Salesforce OAuth');
				result = new LoginInformation(
					LoginInformation.TYPE_SETUP,
					LoginInformation.STATUS_FAILURE,
					Label.UnableToConnectDocuSignGen,
					ex.getMessage(),
					null);
			}
			return result;
		}
	}

	@TestVisible
	private static ScmSetupAPI getScmSetupAPI(final Url baseUrl) {
		if (scmClient == null) {
			scmClient = new ScmSetupAPI(baseUrl);
		}
		return scmClient;
	}

	@TestVisible
	private class SalesforceOAuthState {
		public String type { get; private set; }
		public String target { get; private set; }
		public Boolean isValid {
			get {
				return isValidType(this.type)
					&& isValidTarget(this.type, this.target);
			}
		}

		public SalesforceOAuthState(
			final String type,
			final String target) {

			this.type = type;
			this.target = target;
		}
	}

	@TestVisible
	private static String encodeSalesforceOAuthState(
		final String nonce,
		final SalesforceOAuthState state) {

		if (state == null || !state.isValid) throw new DocuSignException(Label.InvalidAuthState);

		return SecureUtils.encrypt(nonce
			+ '|' + state.type
			+ '|' + state.target);
	}

	@TestVisible
	private static SalesforceOAuthState decodeSalesforceOAuthState(
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

		// 5) Parse type
		String type = toks[1];
		if (!isValidType(type)) {
			LOG.error('Invalid login type: ' + type);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		// 6) Verify target.
		String target = toks[2];
		if (!isValidTarget(type, target)) {
			LOG.error('Invalid target: ' + target);
			throw new UnauthorizedException(Label.InvalidAuthState);
		}

		return new SalesforceOAuthState(type, target);
	}

	@TestVisible
	private static Url getDocuSignOAuthRedirectUrl(final Boolean isSetup) {
		Url baseUrl = isSetup
			? new Url('https://' + (Salesforce.isSandbox ? 'test' : 'login') + '.salesforce.com/')
			: UrlUtils.canonicalizeBaseUrl(Salesforce.baseUrl);
		return new Url(baseUrl, (isSetup ? '' : Salesforce.sitePrefix.removeEndIgnoreCase('/s'))
			+ '/apex/' + Application.namespacePrefix + 'completeoauth'); // case-sensitive?
	}

	@TestVisible
	private static Url getSalesforceOAuthRedirectUrl() {
		return new Url('https://' + (Salesforce.isSandbox ? 'test' : 'login') + '.salesforce.com/apex/'
			+ Application.namespacePrefix + 'CompleteSpringOAuth'); // case-sensitive!
	}

	/**
	 * Retrieves the URL to start the Salesforce OAuth flow.
	 * <p>
	 * For Community users, this method does not work as the redirect URI cannot be pre-authorized. Instead, grant
	 * admin consent for these users.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param type The login type requested: <code>USER</code> or <code>DEVELOPER</code>.
	 * @param target Where to redirect the user to after login. This must be a local path to a page that will
	 * handle the authorization result.
	 *
	 * @return The Salesforce OAuth Url along with redirection to completeOauth
	 */
	public static Url getSalesforceOAuthUrl(
		final String type,
		final String target) {

		Permissions.verifyIsDocuSignUser();

		String safeTarget = target;
		if (type == LoginInformation.TYPE_DEVELOPER
			&& (String.isBlank(target) || !target.startsWith('/'))) {

			throw new DocuSignException(Label.InvalidRedirectUrl);
		} else if (target.startsWith('/')) {
			// Prevent double-slash in case browser allows it as a valid external redirect
			safeTarget = target.replaceFirst('/+', '/');
		}

		PageReference pg = new PageReference(Salesforce.baseUrl.toExternalForm() + '/services/oauth2/authorize');
		pg.getParameters().putAll(new Map<String, String> {
			'response_type' => 'code',
			'state' => encodeSalesforceOAuthState(
				generateNonce(),
				new SalesforceOAuthState(
					type,
					safeTarget)),
			'client_id' => [
				SELECT ConnectedAppId__c
				FROM Organization__mdt
				WHERE DeveloperName = 'Current'
				LIMIT 1
			].ConnectedAppId__c,
			'redirect_uri' => getSalesforceOAuthRedirectUrl().toExternalForm()
		});
		return new Url(pg.getUrl());
	}

	@TestVisible
	private static LoginInformation completeScmSetup(final String authorizationCode) {
		LoginInformation result;
		try {
			Url baseUrl = AccountProducts.getInstance().getScmWebBaseUrl();
			if (baseUrl == null) { // eSignature-only, there will be no SCM URLs
				LoggerService.getInstance().warn('SCM web base URL is not configured');
				result = new LoginInformation(
					LoginInformation.TYPE_SETUP,
					LoginInformation.STATUS_SUCCESS,
					Label.SuccessDocuSignAuthorization,
					null,
					null);
			} else { // CLM, Gen, Negotiate
				result = getScmSetupAPI(baseUrl).completeSetup(authorizationCode);
			}

			if (result.status == LoginInformation.STATUS_SUCCESS) {
				AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
				settings.IsPlatformAuthorized__c = true;
				update settings;
			}
		} finally {
			AccountProducts.save();
		}
		return result;
	}

	/**
	 * Attempts login to Salesforce with the supplied credentials.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set.
	 *
	 * @param authorizationCode The authorization code returned by Salesforce after successful login and consent.
	 * @param state The state passed through Salesforce. This value is opaque to the caller and may not be tampered with.
	 *
	 * @return The result of the login.
	 */
	public static LoginInformation redeemSalesforceCode(
		final String authorizationCode,
		final String state) {

		Permissions.verifyIsDocuSignUser();

		LoginInformation result;
		UserSettings__c us = UserSettings__c.getInstance();
		try {
			SalesforceOAuthState s = decodeSalesforceOAuthState(state, us.Nonce__c);

			if (s.type == LoginInformation.TYPE_SETUP) {
				Permissions.verifyIsDocuSignAdministrator();
				result = completeScmSetup(authorizationCode).withTarget(s.target);
			} else {
				Permissions.verifyIsDocuSignUser();
				result = new LoginInformation(
					s.type,
					LoginInformation.STATUS_SUCCESS,
					Label.SuccessDocuSignAuthorization,
					null,
					s.target);
			}
		} finally {
			us.Nonce__c = null;
			us.IsPlatformAuthorized__c = true;
			us.PlatformAuthorizationLastChecked__c = Datetime.now();
			update us;
		}
		return result;
	}

	/**
	 * Completes a Salesforce OAuth transaction with an error.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set.
	 *
	 * @param errorCode The error code returned by Salesforce.
	 * @param errorMessage The error message returned by Salesforce.
	 * @param state The state passed through Salesforce. This value is opaque to the caller and may not be tampered with.
	 *
	 * @return The failure result of the login with event target specified.
	 */
	public static LoginInformation redeemSalesforceError(
		final String errorCode,
		final String errorMessage,
		final String state) {

		Permissions.verifyIsDocuSignUser();

		LoginInformation result;
		UserSettings__c us = UserSettings__c.getInstance();
		try {
			SalesforceOAuthState s = decodeSalesforceOAuthState(state, us.Nonce__c);
			result = new LoginInformation(
				s.type,
				LoginInformation.STATUS_FAILURE,
				errorCode == 'access_denied' || String.isBlank(errorMessage) ? Label.ConsentRequired : errorMessage,
				errorMessage,
				s.target);
		} finally {
			us.Nonce__c = null;
			us.IsPlatformAuthorized__c = false;
			us.PlatformAuthorizationLastChecked__c = Datetime.now();
			update us;
		}
		return result;
	}
}
