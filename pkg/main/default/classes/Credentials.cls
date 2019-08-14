public with sharing class Credentials {

	@TestVisible
	private static Credentials self;
	@TestVisible
	private static final Credentials.Database DB = new Credentials.Database();
	@TestVisible
	private static final Integer MAX_TOKEN_LENGTH = 1530;
	@TestVisible
	private static final Integer MAX_KEY_LENGTH = 3060;

	private Boolean isDirty = false;
	public Environment environment { get; private set; }
	public ClientCredentials client { get; private set; }
	public AccountCredentials account { get; private set; }
	public UserCredentials user { get; private set; }
	public AccessToken token { get; private set; }
	public Boolean isValid {
		get {
			return this.isAccountValid && this.isUserValid;
		}
	}
	public Boolean isAccountValid {
		get {
			return this.environment != null && this.environment.isValid
				&& this.client != null && this.client.isValid
				&& this.account != null && this.account.isValid;
		}
	}
	public Boolean isUserValid {
		get {
			return UUID.isNotEmpty(this.account.systemSenderId)
				|| (this.user != null && this.user.isValid);
		}
	}
	public Boolean isTokenValid {
		get {
			return this.token != null
				&& this.token.isValid;
		}
	}

	@TestVisible
	private Credentials(
		final Environment environment,
		final ClientCredentials client,
		final AccountCredentials account,
		final UserCredentials user,
		final AccessToken token) {

		this.environment = environment;
		this.client = client;
		this.account = account;
		this.user = user;
		this.token = token;
	}

	private Credentials withToken(final AccessToken token) {
		this.token = token;
		return this;
	}

	public class Environment {
		public DocuSign.Environment environment { get; private set; }
		public Url accountBaseUrl { get; private set; }
		public Url provisioningBaseUrl { get; private set; }
		public Url eSignatureBaseUrl { get; private set; }
		public Url scmAuthBaseUrl { get; private set; }
		public Url scmApiBaseUrl { get; private set; }
		public Url clmLandingPageUrl { get; private set; }
		public Url clmAdminUrl { get; private set; }
		public Boolean isValid {
			get {
				return this.environment != null
					&& this.environment != DocuSign.Environment.Invalid
					&& DocuSign.isValidUrl(this.accountBaseUrl)
					&& DocuSign.isValidUrl(this.provisioningBaseUrl)
					&& (this.eSignatureBaseUrl == null || DocuSign.isValidUrl(this.eSignatureBaseUrl))
					&& (this.scmAuthBaseUrl == null || DocuSign.isValidUrl(this.scmAuthBaseUrl))
					&& (this.scmApiBaseUrl == null || DocuSign.isValidUrl(this.scmApiBaseUrl))
					&& (this.clmLandingPageUrl == null || DocuSign.isValidUrl(this.clmLandingPageUrl))
					&& (this.clmAdminUrl == null || DocuSign.isValidUrl(this.clmAdminUrl));
			}
		}

		public Environment(
			final DocuSign.Environment environment,
			final Url accountBaseUrl,
			final Url provisioningBaseUrl,
			final Url eSignatureBaseUrl,
			final Url scmAuthBaseUrl,
			final Url scmApiBaseUrl,
			final Url clmLandingPageUrl,
			final Url clmAdminUrl) {

			this.environment = environment;
			this.accountBaseUrl = accountBaseUrl;
			this.provisioningBaseUrl = provisioningBaseUrl;
			this.eSignatureBaseUrl = eSignatureBaseUrl;
			this.scmAuthBaseUrl = scmAuthBaseUrl;
			this.scmApiBaseUrl = scmApiBaseUrl;
			this.clmLandingPageUrl = clmLandingPageUrl;
			this.clmAdminUrl = clmAdminUrl;
		}
	}

	public class ClientCredentials {
		public String id { get; private set; }
		public String secret { get; private set; }
		public Blob privateKey { get; private set; }
		public Boolean isValid {
			get {
				return String.isNotBlank(this.id)
					&& String.isNotBlank(this.secret)
					&& this.privateKey != null;
			}
		}

		public ClientCredentials(
			final String id,
			final String secret,
			final Blob privateKey) {

			this.id = id;
			this.secret = secret;
			this.privateKey = privateKey;
		}
	}

	public class AccountCredentials {
		public UUID id { get; private set; }
		public Long accountNumber { get; private set; }
		public String name { get; private set; }
		public String email { get; private set; }
		public UUID systemSenderId { get; private set; }
		public Boolean isValid {
			get {
				return UUID.isNotEmpty(this.id);
			}
		}

		public AccountCredentials(
			final UUID id,
			final Long accountNumber,
			final String name,
			final String email,
			final UUID systemSenderId) {

			this.id = id;
			this.accountNumber = accountNumber;
			this.name = name;
			this.email = email;
			this.systemSenderId = systemSenderId;
		}
	}

	public class UserCredentials {
		public UUID id { get; private set; }
		public String name { get; private set; }
		public String email { get; private set; }
		public String status { get; private set; }
		public Boolean canManageAccount { get; private set; }
		public Boolean isValid {
			get {
				return UUID.isNotEmpty(this.id);
			}
		}

		public UserCredentials(
			final UUID id,
			final String name,
			final String email,
			final String status,
			final Boolean canManageAccount) {

			this.id = id;
			this.name = name;
			this.email = email;
			this.status = status;
			this.canManageAccount = canManageAccount;
		}
	}

	public class AccessToken {
		public String token { get; private set; }
		public Datetime expires { get; private set; }
		public Boolean isValid {
			get {
				return String.isNotBlank(this.token)
					&& (expires == null || expires > Datetime.now());
			}
		}

		public AccessToken(
			final String token,
			final Datetime expires) {

			this.token = token;
			this.expires = expires;
		}
	}

	public static Boolean isAccountValid() {
		return getInstance(UserInfo.getUserId(), false).isAccountValid;
	}

	public static Credentials getInstance() {
		return getInstance(UserInfo.getUserId(), true);
	}

	private static void validate(final Credentials c) {
		if (c == null) throw new DocuSignException(Label.UndefinedArgument);

		if (!c.isAccountValid) {
			throw UnauthorizedException.accountNotConfigured();
		} else if (UUID.isEmpty(c.account.systemSenderId) && !c.isUserValid) {
			throw UnauthorizedException.mayRequireActivation();
		}
	}

	@TestVisible
	private static Credentials getInstance(final Id userId, final Boolean validate) {
		Credentials result = null;
		if (userId == UserInfo.getUserId()) { // 99% case user needs stored DS creds for API calls\
			if (self == null) {
				result = DB.queryCredentials(userId);
				if (validate) validate(result);
				self = result;
			}
			result = self;
		} else {
			result = DB.queryCredentials(userId);
			if (validate) validate(result);
		}
		return result;
	}

	public static AccessToken getToken() {
		return DB.queryToken(UserInfo.getUserId());
	}

	@TestVisible
	private with sharing class Database {

		private Environment getEnvironment(final AccountSettings__c settings) {
			if (settings == null || String.isBlank(settings.Environment__c)) {
				return new Environment(
					DocuSign.Environment.Invalid,
					null,
					null,
					null,
					null,
					null,
					null,
					null);
			}
			return new Environment(
				DocuSign.parseEnvironment(settings.Environment__c),
				settings.AccountBaseUrl__c == null ? null : new Url(settings.AccountBaseUrl__c),
				settings.ProvisioningBaseUrl__c == null ? null : new Url(settings.ProvisioningBaseUrl__c),
				settings.ESignatureBaseUrl__c == null ? null : new Url(settings.ESignatureBaseUrl__c),
				settings.ScmAuthBaseUrl__c == null ? null : new Url(settings.ScmAuthBaseUrl__c),
				settings.ScmApiBaseUrl__c == null ? null : new Url(settings.ScmApiBaseUrl__c),
				settings.ClmLandingPageUrl__c == null ? null : new Url(settings.ClmLandingPageUrl__c),
				settings.ClmAdminUrl__c == null ? null : new Url(settings.ClmAdminUrl__c));
		}

		private ClientCredentials getClient(final AccountSettings__c settings) {
			if (settings == null) return new ClientCredentials(null, null, null);

			return new ClientCredentials(
				settings.ClientId__c,
				settings.ClientSecret__c,
				EncodingUtil.base64Decode(String.join(new List<String> {
					settings.PrivateKey0__c, settings.PrivateKey1__c, settings.PrivateKey2__c, settings.PrivateKey3__c,
					settings.PrivateKey4__c, settings.PrivateKey5__c, settings.PrivateKey6__c, settings.PrivateKey7__c,
					settings.PrivateKey8__c, settings.PrivateKey9__c, settings.PrivateKey10__c, settings.PrivateKey11__c
				}, '')));
		}

		private AccountCredentials getAccount(final AccountSettings__c settings) {
			if (settings == null) return new AccountCredentials(null, null, null, null, null);

			return new AccountCredentials(
				UUID.tryParse(settings.AccountId__c),
				(Long)settings.AccountNumber__c,
				settings.AccountName__c,
				settings.Email__c,
				UUID.tryParse(settings.SystemSenderId__c));
		}

		@TestVisible
		private AccessToken getToken(final UserSettings__c settings) {
			if (settings != null && settings.AccessTokenExpires__c > Datetime.now()) {
				return new AccessToken(
					String.join(new List<String> {
						settings.AccessToken0__c, settings.AccessToken1__c, settings.AccessToken2__c,
						settings.AccessToken3__c, settings.AccessToken4__c, settings.AccessToken5__c
					}, ''),
					settings.AccessTokenExpires__c);
			}
			return new AccessToken(null, null);
		}

		private UserCredentials queryUser(final Id userId, final UUID systemSenderId) {
			Permissions.verifyIsQueryable(Schema.User.getSObjectType(), new List<String> {
				'Name', 'Email',
				Application.namespacePrefix + 'Username__c',
				Application.namespacePrefix + 'CanManageAccount__c',
				Application.namespacePrefix + 'Status__c'
			});

			if (userId == null) return new UserCredentials(null, null, null, null, false);

			User user = (User)Collection.head([
				SELECT Username__c, Name, Email, CanManageAccount__c, Status__c
				FROM User
				WHERE Id = :userId
				LIMIT 1
			]);

			return new UserCredentials(
				String.isBlank(user.Username__c) ? systemSenderId : UUID.tryParse(user.Username__c),
				user.Name,
				user.Email,
				user.Status__c,
				user.CanManageAccount__c == true);
		}

		public Credentials queryCredentials(final Id userId) {
			AccountSettings__c accountSettings = AccountSettings__c.getOrgDefaults();
			return new Credentials(
				getEnvironment(accountSettings),
				getClient(accountSettings),
				getAccount(accountSettings),
				queryUser(userId, UUID.tryParse(accountSettings.SystemSenderId__c)),
				queryToken(userId));
		}

		public AccessToken queryToken(final Id userId) {
			return getToken(UserSettings__c.getInstance(userId));
		}

		private AccountSettings__c setEnvironment(
			final AccountSettings__c settings,
			final Environment environment) {

			if (settings == null || environment == null || !environment.isValid) return settings;

			settings.Environment__c = environment.environment == null
				? null : environment.environment.name();
			settings.AccountBaseUrl__c = environment.accountBaseUrl == null
				? null : environment.accountBaseUrl.toExternalForm();
			settings.ProvisioningBaseUrl__c = environment.provisioningBaseUrl == null
				? null : environment.provisioningBaseUrl.toExternalForm();
			settings.ESignatureBaseUrl__c = environment.eSignatureBaseUrl == null
				? null : environment.eSignatureBaseUrl.toExternalForm();
			settings.ScmAuthBaseUrl__c = environment.scmAuthBaseUrl == null
				? null : environment.scmAuthBaseUrl.toExternalForm();
			settings.ScmApiBaseUrl__c = environment.scmApiBaseUrl == null
				? null : environment.scmApiBaseUrl.toExternalForm();
			settings.ClmLandingPageUrl__c = environment.clmLandingPageUrl == null
				? null : environment.clmLandingPageUrl.toExternalForm();
			settings.ClmAdminUrl__c = environment.clmAdminUrl == null
				? null : environment.clmAdminUrl.toExternalForm();
			return settings;
		}

		private AccountSettings__c setClient(
			final AccountSettings__c settings,
			final ClientCredentials client) {

			if (settings == null || client == null || !client.isValid) return settings;

			String pvk = EncodingUtil.base64Encode(client.privateKey);
			Integer len = pvk.length();
			if (len > MAX_KEY_LENGTH) {
				throw new DocuSignException(String.format(Label.KeyTooLong_2, new List<String> {
					String.valueOf(len),
					String.valueOf(MAX_KEY_LENGTH)
				}));
			}
			settings.ClientId__c = client.id;
			settings.ClientSecret__c = client.secret;
			settings.PrivateKey0__c = pvk.mid(0, 255);
			settings.PrivateKey1__c = pvk.mid(255, 255);
			settings.PrivateKey2__c = pvk.mid(510, 255);
			settings.PrivateKey3__c = pvk.mid(765, 255);
			settings.PrivateKey4__c = pvk.mid(1020, 255);
			settings.PrivateKey5__c = pvk.mid(1275, 255);
			settings.PrivateKey6__c = pvk.mid(1530, 255);
			settings.PrivateKey7__c = pvk.mid(1785, 255);
			settings.PrivateKey8__c = pvk.mid(2040, 255);
			settings.PrivateKey9__c = pvk.mid(2295, 255);
			settings.PrivateKey10__c = pvk.mid(2550, 255);
			settings.PrivateKey11__c = pvk.mid(2805, 255);
			return settings;
		}

		private AccountSettings__c setAccount(
			final AccountSettings__c settings,
			final AccountCredentials account) {

			if (settings == null || account == null || !account.isValid) return settings;

			settings.AccountId__c = String.valueOf(account.id);
			settings.AccountNumber__c = account.accountNumber;
			settings.AccountName__c = account.name;
			settings.Email__c = account.email;
			settings.SystemSenderId__c = String.valueOf(account.systemSenderId);
			return settings;
		}

		private UserCredentials updateUser(
			final Id userId,
			final UserCredentials user) {

			Permissions.verifyIsUpdateable(Schema.User.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'Username__c',
				Application.namespacePrefix + 'CanManageAccount__c',
				Application.namespacePrefix + 'Status__c',
				Application.namespacePrefix + 'Provisioned__c'
			});

			if (userId == null || user == null) return user;

			if (userId != null && user != null) {
				update new User(
					Id = userId,
					Username__c = String.valueOf(user.id),
					CanManageAccount__c = user.canManageAccount == true,
					Provisioned__c = Date.today());
			}

			return user;
		}

		public UserSettings__c clearToken(final UserSettings__c settings) {
			if (settings == null) return null;

			settings.AccessToken0__c = null;
			settings.AccessToken1__c = null;
			settings.AccessToken2__c = null;
			settings.AccessToken3__c = null;
			settings.AccessToken4__c = null;
			settings.AccessToken5__c = null;
			settings.AccessTokenExpires__c = null;

			return settings;
		}

		public List<User> updateUsers(
			final Set<Id> userIds,
			final Boolean canManageAccount) {

			Permissions.verifyIsUpdateable(Schema.User.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'CanManageAccount__c'
			});

			List<User> result = new List<User>();
			if (userIds != null) {
				for (User u : [
					SELECT CanManageAccount__c
					FROM User
					WHERE Id IN :userIds
					LIMIT :Application.batchLimit
				]) {
					u.CanManageAccount__c = canManageAccount == true;
					result.add(u);
				}
				update result;
			}
			return result;
		}

		public List<UserSettings__c> clearTokens(final Set<Id> userIds) {
			List<UserSettings__c> result = new List<UserSettings__c>();
			if (userIds != null) {
				for (Id userId : userIds) {
					result.add(clearToken(UserSettings__c.getInstance(userId)));
				}
				upsert result;
			}
			return result;
		}

		public Credentials updateCredentials(
			final Id userId,
			final Environment environment,
			final ClientCredentials client,
			final AccountCredentials account,
			final UserCredentials user,
			final AccessToken token) {

			AccountSettings__c accountSettings = setEnvironment(AccountSettings__c.getOrgDefaults(), environment);
			accountSettings = setClient(accountSettings, client);
			accountSettings = setAccount(accountSettings, account);
			upsert accountSettings;

			updateUser(userId, user);
			updateToken(userId, token);

			return this.queryCredentials(userId);
		}

		public AccessToken updateToken(
			final Id userId,
			final AccessToken token) {

			if (userId == null) return token;

			UserSettings__c settings = clearToken(UserSettings__c.getInstance(userId));

			if (token != null && token.isValid) {
				Integer len = token.token.length();
				if (len > MAX_TOKEN_LENGTH) {
					throw new DocuSignException(String.format(Label.AccessTokenTooLong_2, new List<String> {
						String.valueOf(len),
						String.valueOf(MAX_TOKEN_LENGTH)
					}));
				}
				settings.AccessToken0__c = token.token.mid(0, 255);
				settings.AccessToken1__c = token.token.mid(255, 255);
				settings.AccessToken2__c = token.token.mid(510, 255);
				settings.AccessToken3__c = token.token.mid(765, 255);
				settings.AccessToken4__c = token.token.mid(1020, 255);
				settings.AccessToken5__c = token.token.mid(1275, 255);
				settings.AccessTokenExpires__c = token.expires;
			}

			upsert settings;

			return token;
		}

		public AccountSettings__c deleteAccountCredentials() {
			AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
			settings.Environment__c = null;
			settings.ClientId__c = null;
			settings.ClientSecret__c = null;
			settings.PrivateKey0__c = null;
			settings.PrivateKey1__c = null;
			settings.PrivateKey2__c = null;
			settings.PrivateKey3__c = null;
			settings.PrivateKey4__c = null;
			settings.PrivateKey5__c = null;
			settings.PrivateKey6__c = null;
			settings.PrivateKey7__c = null;
			settings.PrivateKey8__c = null;
			settings.PrivateKey9__c = null;
			settings.PrivateKey10__c = null;
			settings.PrivateKey11__c = null;
			settings.AccountBaseUrl__c = null;
			settings.ProvisioningBaseUrl__c = null;
			settings.ESignatureBaseUrl__c = null;
			settings.ScmAuthBaseUrl__c = null;
			settings.ScmApiBaseUrl__c = null;
			settings.ClmLandingPageUrl__c = null;
			settings.ClmAdminUrl__c = null;
			settings.AccountId__c = null;
			settings.AccountNumber__c = null;
			settings.AccountName__c = null;
			settings.Email__c = null;
			settings.SystemSenderId__c = null;
			settings.ProductsLastChecked__c = null;
			settings.AdministratorProfileId__c = null;
			settings.SenderProfileId__c = null;
			upsert settings;
			return settings;
		}

		public List<Schema.User> deleteUserCredentials(final List<Schema.User> users) {
			if (Collection.isNotEmpty(users)) {
				Permissions.verifyIsUpdateable(Schema.User.getSObjectType(), new List<String> {
					Application.namespacePrefix + 'Username__c',
					Application.namespacePrefix + 'CanManageAccount__c',
					Application.namespacePrefix + 'Status__c',
					Application.namespacePrefix + 'Provisioned__c'
				});

				List<UserSettings__c> settings = new List<UserSettings__c>();
				for (Schema.User u : users) {
					u.Username__c = null;
					u.CanManageAccount__c = false;
					u.Status__c = null;
					u.Provisioned__c = null;
					UserSettings__c us = UserSettings__c.getInstance(u.Id);
					if (us.Id != null) settings.add(us);
				}
				delete settings;
				update users;
			}
			return users;
		}

		public Map<Id, UserCredentials> updateUsers(final Map<Id, UserCredentials> users) {
			if (users == null || users.isEmpty()) return users;

			Permissions.verifyIsUpdateable(Schema.User.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'Username__c',
				Application.namespacePrefix + 'CanManageAccount__c',
				Application.namespacePrefix + 'Status__c',
				Application.namespacePrefix + 'Provisioned__c'
			});

			List<User> dbUsers = [
				SELECT Id, Username__c, CanManageAccount__c, Status__c, Provisioned__c
				FROM User
				WHERE Id IN :users.keySet()
				LIMIT :Application.batchLimit
			];
			for (User u : dbUsers) {
				UserCredentials uu = users.get(u.Id);
				if (uu == null) {
					u.Username__c = null;
					u.CanManageAccount__c = false;
					u.Status__c = null;
					u.Provisioned__c = null;
				} else {
					u.Username__c = String.valueOf(uu.id);
					u.CanManageAccount__c = uu.canManageAccount == true;
					u.Status__c = uu.status;
					u.Provisioned__c = Date.today();
				}
			}
			update dbUsers;

			return users;
		}
	}

	public static Credentials save(
		final Environment environment,
		final ClientCredentials client,
		final AccountCredentials account,
		final UserCredentials user,
		final AccessToken token) {

		return save(
			UserInfo.getUserId(),
			environment,
			client,
			account,
			user,
			token);
	}

	@TestVisible
	private static Credentials save(
		final Id userId,
		final Environment environment,
		final ClientCredentials client,
		final AccountCredentials account,
		final UserCredentials user,
		final AccessToken token) {

		self = DB.updateCredentials(
			userId,
			environment,
			client,
			account,
			user,
			token);
		return self;
	}

	public static Credentials setToken(final Credentials.AccessToken token) {
		Credentials result = getInstance(UserInfo.getUserId(), false).withToken(token);
		result.isDirty = true;
		return result;
	}

	/**
	 * Saves updated user credentials (e.g. access token) to protected settings. Invoke this after all callouts are
	 * complete to avoid <code>CalloutException</code>s.
	 *
	 * @return The updated credentials.
	 */
	public static Credentials save() {
		return save(UserInfo.getUserId());
	}

	@TestVisible
	private static Credentials save(final Id userId) {
		if (self != null && self.isDirty) {
			self = self.withToken(DB.updateToken(userId, self.token));
			self.isDirty = false;
		}
		return getInstance(userId, false);
	}

	@TestVisible
	private static Set<Id> filterNotCurrentUserId(final Set<Id> userIds) {
		if (userIds == null) return new Set<Id>();

		userIds.remove(UserInfo.getUserId());
		return userIds;
	}

	@TestVisible
	private static Set<Id> verifyMaximumBatchSize(
		final Set<Id> userIds,
		final Integer maximumSize) {

		if (userIds == null) return new Set<Id>();

		Integer max = maximumSize <= 0 ? Application.batchLimit : maximumSize;
		Integer size = userIds.size();
		if (size > max) {
			throw new DocuSignException(String.format(Label.MaximumBatchSizeExceeded_2,
				new List<Object> { size, max }));
		}
		return userIds;
	}

	public static Map<Id, UserCredentials> add(final Map<Id, Credentials.UserCredentials> users) {
		if (users == null) return new Map<Id, UserCredentials>();

		users.remove(UserInfo.getUserId());
		verifyMaximumBatchSize(users.keySet(), Application.batchLimit);

		return DB.updateUsers(users);
	}

	public static Set<Id> clear(final Boolean resetUsers) {
		Set<Id> result = new Set<Id>();
		DB.deleteAccountCredentials();
		if (resetUsers) {
			Boolean isWorking = true;
			while (isWorking) {
				List<Schema.User> users = [
					SELECT Id, Username__c, CanManageAccount__c, Status__c
					FROM User
					WHERE Username__c != NULL
					LIMIT :Application.batchLimit
				];
				if (Collection.isNotEmpty(users)) {
					DB.deleteUserCredentials(users);
					for (Schema.User u : users) {
						// Don't remove permission set from current user.
						if (u.Id != UserInfo.getUserId()) result.add(u.Id);
					}
				} else {
					isWorking = false;
				}
			}
		}
		self = null;
		return result;
	}

	/**
	 * Deletes user credentials.
	 * <p>
	 * A maximum of 2000 user IDs may be processed in one batch.
	 *
	 * @param userIds The IDs of users for which to clear credentials.
	 *
	 * @return Whether or not any credentials were cleared.
	 */
	public static Boolean clear(final Set<Id> userIds) {
		return Collection.isNotEmpty(DB.deleteUserCredentials([
			SELECT Id, Username__c, CanManageAccount__c, Status__c, Provisioned__c
			FROM User
			WHERE Username__c != NULL
			AND Id IN :verifyMaximumBatchSize(filterNotCurrentUserId(userIds), Application.batchLimit)
			LIMIT :Application.batchLimit
		]));
	}

	/**
	 * Resets user credentials and updates the administrator flag on the <code>User</code> record. This should be called
	 * when user roles change.
	 * <p>
	 * A maximum of 2000 user IDs may be processed in one batch.
	 *
	 * @param userIds The IDs of users for which to reset credentials.
	 * @param canManageAccount Whether or not the user is an administrator on the DocuSign account.
	 *
	 * @return Whether or not any credentials were reset.
	 */
	public static Boolean reset(
		final Set<Id> userIds,
		final Boolean canManageAccount) {

		// Don't reset current user's credentials and bail if the batch limit is exceeded.
		Set<Id> uIds = verifyMaximumBatchSize(filterNotCurrentUserId(userIds), Application.batchLimit);

		return Collection.isNotEmpty(DB.clearTokens(uIds))
			&& Collection.isNotEmpty(DB.updateUsers(uIds, canManageAccount));
	}
}
