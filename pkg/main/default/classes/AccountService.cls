/**
 * Primary interface point for DocuSign for Salesforce account management.
 */
global with sharing class AccountService {

	@TestVisible
	private static final Database DB = new AccountService.Database();
	private static final LoggerService LOG = LoggerService.getInstance();
	private static Account currentAccount;

	private class Database {

		private Account.User convert(final User u) {
			if (u == null) return null;

			return new Account.User(
				UUID.tryParse(u.Username__c),
				u.Id,
				u.Email,
				u.FirstName,
				u.LastName,
				u.Status__c,
				UUID.tryParse(u.InviteId__c),
				u.InviteDate__c,
				u.CanManageAccount__c,
				u.Profile.Name,
				APIError.none);
		}

		public List<Account.User> queryUsers() {
			Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> {
				'Id', 'Email', 'FirstName', 'LastName',
				Application.namespacePrefix + 'Username__c',
				Application.namespacePrefix + 'Status__c',
				Application.namespacePrefix + 'CanManageAccount__c',
				Application.namespacePrefix + 'InviteId__c',
				Application.namespacePrefix + 'InviteDate__c'
			});
			Permissions.verifyIsQueryable(Profile.getSObjectType(), new List<String> { 'Name' });

			List<Account.User> result = new List<Account.User>();
			for (User u : [
				SELECT Id, Email, FirstName, LastName, Profile.Name,
					Username__c, Status__c, CanManageAccount__c, InviteId__c, InviteDate__c
				FROM User
				WHERE Username__c != NULL
				LIMIT 1000
			]) {
				result.add(convert(u));
			}
			return result;
		}

		public List<SystemSender> queryAvailableSystemSenders() {
			Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> {
				'Id', 'Name', 'Email', Application.namespacePrefix + 'Username__c'
			});

			List<SystemSender> result = new List<SystemSender>();
			for (User u : [
				SELECT Name, Email, Username__c
				FROM User
				WHERE Username__c != NULL
				AND IsActive = TRUE
				AND CanManageAccount__c = TRUE
				ORDER BY Name ASC
				LIMIT 1000
			]) {
				result.add(new SystemSender(
					UUID.parse(u.Username__c),
					u.Name,
					u.Email));
			}
			return result;
		}
	}

	/**
	 * Retrieves information for the current DocuSign account. This includes DocuSign trial status if the current
	 * account is a trial account.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The current DocuSign account.
	 */
	public static Account getAccount() {
		Permissions.verifyIsDocuSignAdministrator();

		if (currentAccount == null) {
			try {
				Account a = AccountAPI.getInstance().getAccount();
				if (a.isTrial) {
					Account.TrialStatus ts = getTrialStatus(a);
					currentAccount = a.withTrialStatus(ts);
				} else {
					currentAccount = a;
				}
			} finally {
				Credentials.save();
			}
		}
		return currentAccount;
	}

	@TestVisible
	private static Account.TrialStatus getTrialStatus(final Account account) {
		Boolean isExpired = false;
		String message = null;
		if (account != null && account.isTrial) {
			Integer intDays = Date.today().daysBetween(account.billing.endDate);
			if (intDays < 0) {
				isExpired = true;
				message = Label.TrialAccountExpired;
			} else if (intDays == 0) {
				message = Label.TrialAccountExpiresToday;
			} else if (intDays == 1) {
				message = Label.TrialAccountExpiresOneDay;
			} else if (intDays < 7) {
				message = String.format(Label.TrialAccountExpiresSoon_1, new List<String> { String.valueOf(intDays) });
			}
		}
		return new Account.TrialStatus(isExpired, message);
	}

	/**
	 * Retrieves a URL that can be used to display the DocuSign console. This URL can only be used once.
	 * <p>
	 * The caller must be assigned the <code>DocuSign User</code> permission set, and must be an active member of the
	 * DocuSign account.
	 *
	 * @return The DocuSign console URL.
	 */
	global static Url getDocuSignUrl() {
		if (!Permissions.isDocuSignUser()) throw new UnauthorizedException(Label.UnauthorizedPageAccess);

		try {
			return AccountAPI.getInstance().getConsoleViewUrl();
		} finally {
			Credentials.save();
		}
	}

	/**
	 * Retrieves DocuSign for Salesforce account settings.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The account settings.
	 */
	public static AccountSettings getSettings() {
		Permissions.verifyIsDocuSignAdministrator();

		return AccountSettings.getInstance();
	}

	/**
	 * Updates DocuSign for Salesforce account settings.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param settings The settings to update.
	 *
	 * @return The updated settings.
	 */
	public static AccountSettings saveSettings(final AccountSettings settings) {
		Permissions.verifyIsDocuSignAdministrator();

		if (settings == null) throw new DocuSignException(Label.UndefinedArgument);

		return AccountSettings.save(settings);
	}

	/**
	 * Retrieves a list of DocuSign account members.
	 *
	 * @return The current DocuSign account members.
	 */
	public static List<Account.User> getUsers() {
		Permissions.verifyIsDocuSignAdministrator();

		return DB.queryUsers();
	}

	@TestVisible
	private static List<Account.User> addUsers2(final List<Account.User> users) {
		if (Collection.isEmpty(users)) return users;

		// Update the username and password for the users
		List<Account.User> result = new List<Account.User>();
		Map<Id, Credentials.UserCredentials> creds = new Map<Id, Credentials.UserCredentials>();
		for (Account.User u : users) {
			// Ignore errors when user is already an account member. Something got DFS and DS out of sync.
			if (u.hasError && u.error.code != APIErrorCode.USER_ALREADY_EXISTS_IN_ACCOUNT) {
				LOG.warn('Error while adding user ' + u.email + ': ' + u.error);
				result.add(u);
			} else {
				creds.put(u.sourceId, new Credentials.UserCredentials(
					u.id,
					u.name,
					u.email,
					u.canManageAccount));
				result.add(u.withError(null));
			}
		}

		Credentials.addUsers(creds);

		return result;
	}

	/**
	 * Adds one or more users as members of the current DocuSign account.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param users A list of users to add.
	 *
	 * @return The users added. This may be partially successful with details in the returned <code>User.error</code>
	 * property.
	 * @see Account.User.error for details on any errors.
	 */
	public static List<Account.User> addUsers(final List<Account.User> users) {
		Permissions.verifyIsDocuSignAdministrator();

		try {
			return addUsers2(AccountAPI.getInstance().addUsers(users));
		} finally {
			Credentials.save();
		}
	}

	@TestVisible
	private static Set<Id> getUserIdsToRemove(final List<Account.User> users) {
		Set<Id> result = new Set<Id>();
		if (users != null) {
			String currentDSUsername = [
				SELECT Username__c
				FROM User
				WHERE Id = :UserInfo.getUserId()
				LIMIT 1
			].Username__c;
			Id currentUserId = UserInfo.getUserId();
			for (Account.User u : users) {
				if (u.sourceId == currentUserId
					|| (String.isNotBlank(currentDSUsername)
					&& String.valueOf(u.id) == currentDSUsername)) {

					throw new DocuSignException(Label.CannotRemoveSelf);
				}
				result.add(u.sourceId);
			}
		}
		return result;
	}

	/**
	 * Removes one or more users from the current DocuSign account.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param users A list of users to remove.
	 *
	 * @return The users removed. This may be partially successful with details in the returned <code>User.error</code>
	 * property.
	 * @see Account.User.error for details on any errors.
	 */
	public static List<Account.User> removeUsers(final List<Account.User> users, final Boolean closeMembership) {
		Permissions.verifyIsDocuSignAdministrator();

		Set<Id> userIds = getUserIdsToRemove(users);

		List<Account.User> result = new List<Account.User>();
		if (closeMembership) {
			try {
				for (Account.User u : AccountAPI.getInstance().removeUsers(users)) {
					// Ignore errors where user is unknown to DS. The user was already removed from the account.
					if (u.hasError && u.error.code != APIErrorCode.UNKNOWN_USER) {
						if (u.sourceId != null) userIds.remove(u.sourceId);
						result.add(u);
					} else {
						result.add(u.withError(null));
					}
				}
			} finally {
				Credentials.save();
			}
		}

		Credentials.clear(userIds);

		return result;
	}

	/**
	 * Runs all post-install scripts again if needed to solve a problem. This is a safe operation as it will not
	 * overwrite current settings if they exist.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The results of the post-install script execution.
	 */
	public static PostInstallResults executePostInstallScripts() {
		Permissions.verifyIsDocuSignAdministrator();

		return new PostInstall(true).execute(
			UserInfo.getOrganizationId(),
			UserInfo.getUserId(),
			null,
			false,
			false);
	}

	/**
	 * A DocuSign for Salesforce system sender, i.e. the sender to use when a Salesforce user is not a member of the
	 * DocuSign account.
	 */
	public class SystemSender {
		/**
		 * The DocuSign user ID.
		 */
		@AuraEnabled
		public UUID id { get; private set; }
		@AuraEnabled
		public String display { get; private set; }

		private SystemSender(
			final UUID id,
			final String name,
			final String email) {

			this.id = id;
			this.display = String.format(Label.AccountDisplay_2, new List<String> { name, email });
		}
	}

	/**
	 * Retrieves a list of users that may be used as the DocuSign for Salesforce system sender.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return
	 */
	public static List<SystemSender> getAvailableSystemSenders() {
		Permissions.verifyIsDocuSignAdministrator();

		return DB.queryAvailableSystemSenders();
	}
}
