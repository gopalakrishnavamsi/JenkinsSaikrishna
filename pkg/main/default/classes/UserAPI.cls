public with sharing class UserAPI extends ESignatureAPI {

	private static UserAPI self = null;

	private static final String SUCCESS = 'SUCCESS';
	private static final String INVALID_USERID = 'INVALID_USERID';
	private static final String USER_ALREADY_EXISTS_IN_ACCOUNT = 'USER_ALREADY_EXISTS_IN_ACCOUNT';
	private static final String USER_DOES_NOT_EXIST = 'USER_DOES_NOT_EXIST_IN_SYSTEM';
	private static final String USER_PENDING = 'USER_AWAITING_ACTIVATION';

	private UserAPI(
		final Url baseUrl,
		final UUID accountId) {

		super(baseUrl, 'v2', accountId);
	}

	public static UserAPI getInstance() {
		if (self == null) {
			Credentials c = Credentials.getInstance();
			self = new UserAPI(c.environment.eSignatureBaseUrl, c.account.id);
		}
		return self;
	}

	@TestVisible
	override protected APIError getError(final HttpResponse response) {
		APIError e = super.getError(response);
		if (e != APIError.none && e instanceof ESignatureAPI.Error) {
			ESignatureAPI.Error dse = (ESignatureAPI.Error)e;
			if (dse.docuSignCode == USER_ALREADY_EXISTS_IN_ACCOUNT) {
				e = new APIError(APIErrorCode.USER_ALREADY_EXISTS_IN_ACCOUNT, dse.description);
			} else if (dse.docuSignCode == USER_DOES_NOT_EXIST || dse.docuSignCode == INVALID_USERID) {
				e = new APIError(APIErrorCode.UNKNOWN_USER, dse.description);
			} else if (dse.docuSignCode == USER_PENDING) {
				e = new APIError(APIErrorCode.USER_PENDING, dse.description);
			}
		}
		return e;
	}

	@TestVisible
	private class APISetting {
		public String name;
		public String value;

		public APISetting(final String name, final String value) {
			this.name = name;
			this.value = value;
		}
	}

	@TestVisible
	private class APIUser {
		public String userId;
		public String email;
		public String firstName;
		public String lastName;
		public String userName;
		public String permissionProfileId;
		public List<APISetting> userSettings;
		public String userStatus;
		public ErrorDetails errorDetails;
		public String createdDateTime;

		public APIUser(final Account.User user) {
			this.userId = String.valueOf(user.id);
			this.email = user.email;
			this.firstName = user.firstName;
			this.lastName = user.lastName;
			this.userName = user.firstName + ' ' + user.lastName;
			Credentials c = Credentials.getInstance();
			this.permissionProfileId = String.valueOf(user.canManageAccount
				? c.account.administratorProfileId
				: c.account.senderProfileId);
			this.userSettings = new List<APISetting> {
				new APISetting('canManageAccount', String.valueOf(user.canManageAccount)),
				new APISetting('canSendEnvelope', 'true')
			};
			this.userStatus = user.status;
		}

		private APIError errorExternalForm() {
			APIError e;
			if (errorDetails == null || String.isBlank(errorDetails.errorCode) || errorDetails.errorCode == SUCCESS) {
				e = APIError.none;
			} else if (errorDetails.errorCode == USER_ALREADY_EXISTS_IN_ACCOUNT) {
				e = new APIError(APIErrorCode.USER_ALREADY_EXISTS_IN_ACCOUNT, errorDetails.message);
			} else if (errorDetails.errorCode == USER_DOES_NOT_EXIST || errorDetails.errorCode == INVALID_USERID) {
				e = new APIError(APIErrorCode.UNKNOWN_USER, errorDetails.message);
			} else if (errorDetails.errorCode == USER_PENDING) {
				e = new APIError(APIErrorCode.USER_PENDING, errorDetails.message);
			} else {
				e = new APIError(APIErrorCode.BAD_REQUEST, String.format('[{0}] {1}',
					new List<String> { errorDetails.errorCode, errorDetails.message }));
			}
			return e;
		}

		@TestVisible
		private String getStatusExternalForm() {
			String result = (this.userStatus == null ? null : this.userStatus.toLowerCase());
			switch on result {
				when 'active' {
					result = Account.USER_STATUS_ACTIVE;
				} when 'activationsent', 'activationrequired' {
					result = Account.USER_STATUS_PENDING;
				} when 'closed', 'disabled' {
					result = Account.USER_STATUS_INACTIVE;
				} when else {
					LoggerService.getInstance().warn(
						String.format('Unrecognized status for user {0} ({1}): {2}', new List<Object> {
							this.userName, this.userId, this.userStatus
						}));
				}
			}
			return result;
		}

		public Account.User toExternalForm(
			final Id sourceId,
			final String firstName,
			final String lastName,
			final Boolean canManageAccount) {

			Boolean isAdmin = canManageAccount;
			if (this.userSettings != null) {
				for (APISetting s : this.userSettings) {
					if (s.name == 'canManageAccount') {
						isAdmin = StringUtils.parseBoolean(s.value);
						break;
					}
				}
			}
			return new Account.User(
				UUID.tryParse(this.userId),
				sourceId,
				this.email,
				String.isBlank(firstName) ? this.firstName : firstName,
				String.isBlank(lastName) ? this.lastName : lastName,
				this.getStatusExternalForm(),
				StringUtils.parseDate(this.createdDateTime),
				isAdmin,
				null,
				null,
				errorExternalForm());
		}
	}

	@TestVisible
	private class NewUsers {
		public List<UserAPI.APIUser> newUsers;

		public NewUsers(final List<Account.User> users) {
			this.newUsers = new List<APIUser>();
			if (users != null) {
				for (Account.User u : users) {
					this.newUsers.add(new APIUser(u));
				}
			}
		}

		public List<Account.User> toExternalForm(final Map<String, Account.User> emailToUsers) {
			List<Account.User> result = new List<Account.User>();
			if (this.newUsers != null) {
				for (UserAPI.APIUser u : this.newUsers) {
					Account.User original = emailToUsers == null ? null : emailToUsers.get(u.email);
					result.add(u.toExternalForm(
						original == null ? null : original.sourceId,
						original == null ? null : original.firstName,
						original == null ? null : original.lastName,
						original == null ? false : original.canManageAccount));
				}
			}
			return result;
		}
	}

	private static Map<String, Account.User> getEmailToUserMap(final List<Account.User> users) {
		Map<String, Account.User> result = new Map<String, Account.User>();
		if (Collection.isNotEmpty(users)) {
			for (Account.User u : users) {
				result.put(u.email, u);
			}
		}
		return result;
	}

	@TestVisible
	private Account.User getUser(
		final Account.User user,
		final Integer timeout) {

		if (user == null || UUID.isEmpty(user.id)) return null;

		RestAPI.Response response = this.get(
			new List<Object> { 'users', user.id },
			QueryString.empty,
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get user: ' + response.error);
			throw new APIException(response.error);
		}

		return ((APIUser)JSON.deserialize(response.body, APIUser.class)).toExternalForm(
			user.sourceId,
			user.firstName,
			user.lastName,
			user.canManageAccount);
	}

	@TestVisible
	private List<Account.User> getUsers(
		final List<Account.User> users,
		final Integer timeout) {

		List<Account.User> result = new List<Account.User>();
		if (users != null) {
			for (Account.User user : users) {
				Account.User user2 = this.getUser(user, timeout);
				if (user2 != null) result.add(user2);
			}
		}
		return result;
	}

	public List<Account.User> addUsers(final List<Account.User> users) {
		return this.addUsers(users, RestAPI.defaultTimeout);
	}

	public List<Account.User> addUsers(
		final List<Account.User> users,
		final Integer timeout) {

		if (Collection.isEmpty(users)) throw new DocuSignException(Label.UndefinedUsers);

		RestAPI.Response response = this.post(
			'users',
			JSON.serialize(new NewUsers(users)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to add users: ' + response.error);
			throw new APIException(response.error);
		}

		List<Account.User> result = new List<Account.User>();
		List<Account.User> incompleteUsers = new List<Account.User>();
		Map<String, Account.User> emailToUsers = getEmailToUserMap(users);
		for (Account.User user : ((NewUsers)JSON.deserialize(response.body, NewUsers.class)).toExternalForm(emailToUsers)) {
			if (user == null) continue;

			if (user.hasError &&
				(user.error.code == APIErrorCode.USER_ALREADY_EXISTS_IN_ACCOUNT
					|| user.error.code == APIErrorCode.USER_PENDING)
				&& UUID.isNotEmpty(user.id)
				&& String.isBlank(user.status)) {

				// When the user already exists, query the user record to get status. This API doesn't return status for
				// errors.
				incompleteUsers.add(user);
			} else {
				result.add(user);
			}
		}

		if (!incompleteUsers.isEmpty()) {
			result.addAll(this.getUsers(
				incompleteUsers,
				timeout));
		}

		return result;
	}

	// Serialization objects for updateUsers/removeUsers
	@TestVisible
	private class APIUsers {
		public List<UserAPI.APIUser> users;

		public APIUsers(final List<Account.User> dsUsers) {
			this.users = new List<UserAPI.APIUser>();
			if (dsUsers != null) {
				for (Account.User u : dsUsers) {
					this.users.add(new APIUser(u));
				}
			}
		}

		public List<Account.User> toExternalForm(final List<Account.User> users) {
			Map<String, Account.User> emailToUsers = new Map<String, Account.User>();
			for (Account.User u : users) {
				emailToUsers.put(u.email, u);
			}
			List<Account.User> result = new List<Account.User>();
			if (this.users != null) {
				for (UserAPI.APIUser u : this.users) {
					Account.User original = emailToUsers.get(u.email);
					result.add(u.toExternalForm(
						original == null ? null : original.sourceId,
						original == null ? null : original.firstName,
						original == null ? null : original.lastName,
						original == null ? false : original.canManageAccount));
				}
			}
			return result;
		}
	}

	public Map<UUID, Account.User> updateUsers(final Map<UUID, Account.User> users) {
		return this.updateUsers(users, RestAPI.defaultTimeout);
	}

	public Map<UUID, Account.User> updateUsers(
		final Map<UUID, Account.User> users,
		final Integer timeout) {

		if (Collection.isEmpty(users)) throw new DocuSignException(Label.UndefinedUsers);

		final RestAPI.Response response = this.put(
			new List<Object> { 'users' },
			JSON.serialize(new APIUsers(users.values())),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to update users: ' + response.error.toString());
			throw new APIException(response.error);
		}

		Map<UUID, Account.User> result = new Map<UUID, Account.User>();
		for (Account.User u : ((APIUsers)JSON.deserialize(response.body, APIUsers.class))
			.toExternalForm(users.values())) {

			if (u != null && UUID.isNotEmpty(u.id)) result.put(u.id, u);
		}
		return result;
	}

	public List<Account.User> removeUsers(final List<Account.User> users) {
		return this.removeUsers(users, RestAPI.defaultTimeout);
	}

	public List<Account.User> removeUsers(
		final List<Account.User> users,
		final Integer timeout) {

		if (Collection.isEmpty(users)) throw new DocuSignException(Label.UndefinedUsers);

		final RestAPI.Response response = this.del(
			'users',
			JSON.serialize(new APIUsers(users)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to remove users: ' + response.error.toString());
			throw new APIException(response.error);
		}

		List<Account.User> result = ((APIUsers)JSON.deserialize(response.body, APIUsers.class))
			.toExternalForm(users);
		for (Account.User user : result) {
			if (user.hasError && user.error.code == APIErrorCode.UNKNOWN_USER) {
				// Ignore errors where user is unknown to DS. The user was already removed from the account.
				user = user.withError(null);
			}
		}
		return result;
	}
}
