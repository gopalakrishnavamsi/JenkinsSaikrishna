/**
 * Salesforce and DocuSign user management.
 */
public with sharing class UserService {

	@TestVisible
	private static final UserService.Database DB = new UserService.Database();
	private static final LoggerService LOG = LoggerService.getInstance();

	/**
	 * User configuration.
	 */
	public class Configuration {
		/**
		 * Salesforce user profiles.
		 */
		public List<Profile> profiles { get; private set; }
		/**
		 * Salesforce permission sets.
		 */
		public List<PermissionSet> permissionSets { get; private set; }

		private Configuration(
			final List<Profile> profiles,
			final List<PermissionSet> permissionSets) {

			this.profiles = profiles == null ? new List<Profile>() : profiles;
			this.permissionSets = permissionSets == null ? new List<PermissionSet>() : permissionSets;
		}
	}

	@TestVisible
	private class Database {

		@TestVisible
		private Account.User convert(final User user) {
			if (user == null) return null;

			return new Account.User(
				UUID.tryParse(user.Username__c),
				user.Id,
				user.Email,
				user.FirstName,
				user.LastName,
				user.Status__c,
				user.Provisioned__c,
				user.CanManageAccount__c == true,
				user.Profile.Name,
				APIError.none);
		}

		@TestVisible
		private List<Account.User> convert(final List<User> users) {
			List<Account.User> result = new List<Account.User>();
			for (User user : (users == null ? new List<User>() : users)) {
				result.add(convert(user));
			}
			return result;
		}

		public Configuration queryUserConfiguration() {
			Permissions.verifyIsQueryable(Profile.getSObjectType(), new List<String> {
				'Id', 'Name'
			});
			Permissions.verifyIsQueryable(PermissionSet.getSObjectType(), new List<String> {
				'Id', 'Label'
			});

			return new Configuration(
			[SELECT Id, Name FROM Profile ORDER BY Name LIMIT 1000],
			[SELECT Id, Label FROM PermissionSet WHERE IsOwnedByProfile = FALSE ORDER BY Label LIMIT 1000]);
		}

		public List<Account.User> queryCurrentUsers(final Integer maximumRecords) {
			Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> {
				'Id', 'FirstName', 'LastName', 'Email',
				Application.namespacePrefix + 'CanManageAccount__c',
				Application.namespacePrefix + 'Status__c',
				Application.namespacePrefix + 'Username__c',
				Application.namespacePrefix + 'Provisioned__c'
			});
			Permissions.verifyIsQueryable(Profile.getSObjectType(), new List<String> {
				'Name'
			});

			return convert([
				SELECT Id, FirstName, LastName, Email, Profile.Name,
					CanManageAccount__c, Status__c, Username__c, Provisioned__c
				FROM User
				WHERE IsActive = TRUE
				AND (Username__c != NULL)
				LIMIT :(maximumRecords > 0 && maximumRecords < 50000 ? maximumRecords : 50)
			]);
		}

		public List<Account.User> queryAvailableUsers(
			final String name,
			final String email,
			final Set<Id> profileIds,
			final Set<Id> permissionSetIds,
			final Integer maximumRecords) {

			Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> {
				'Id', 'FirstName', 'LastName', 'Email',
				Application.namespacePrefix + 'Username__c',
				Application.namespacePrefix + 'Status__c',
				Application.namespacePrefix + 'Provisioned__c',
				Application.namespacePrefix + 'CanManageAccount__c'
			});
			Permissions.verifyIsQueryable(Profile.getSObjectType(), new List<String> {
				'Name'
			});

			String query = 'SELECT Id, FirstName, LastName, Email, Profile.Name, '
				+ Application.namespacePrefix + 'Username__c, '
				+ Application.namespacePrefix + 'Status__c, '
				+ Application.namespacePrefix + 'Provisioned__c, '
				+ Application.namespacePrefix + 'CanManageAccount__c '
				+ 'FROM User '
				+ 'WHERE ' + Application.namespacePrefix + 'Username__c = NULL '
				+ 'AND IsActive = TRUE';
			String n;
			if (String.isNotBlank(name)) { // TODO: Check is filterable, encrypted
				n = String.escapeSingleQuotes(name) + '%';
				query += ' AND Name LIKE :n';
			}
			String e;
			if (String.isNotBlank(email)) {
				e = String.escapeSingleQuotes(email) + '%';
				query += ' AND Email LIKE :e';
			}
			if (Collection.isNotEmpty(profileIds)) {
				query += ' AND ProfileId IN :profileIds';
			}
			if (Collection.isNotEmpty(permissionSetIds)) {
				query += ' AND Id IN (SELECT AssigneeId FROM PermissionSetAssignment'
					+ ' WHERE PermissionSetId IN :permissionSetIds)';
			}
			Integer l = maximumRecords > 0 && maximumRecords < 50000 ? maximumRecords : 50;
			query += ' LIMIT :l';

			return convert((List<User>)System.Database.query(query));
		}

		public List<Account.User> updateUsers(final List<Account.User> users) {
			Permissions.verifyIsUpdateable(User.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'Username__c',
				Application.namespacePrefix + 'CanManageAccount__c',
				Application.namespacePrefix + 'Status__c',
				Application.namespacePrefix + 'Provisioned__c'
			});

			List<User> toUpdate = new List<User>();
			Set<Id> adminIds = new Set<Id>();
			Set<Id> senderIds = new Set<Id>();
			Set<Id> inactiveIds = new Set<Id>();
			for (Account.User user : (users == null ? new List<Account.User>() : users)) {
				if (user != null && !user.hasError && user.sourceId != null) {
					Boolean isInactive = UUID.isEmpty(user.id);
					toUpdate.add(new User(
						Id = user.sourceId,
						Username__c = isInactive ? null : String.valueOf(user.id),
						CanManageAccount__c = isInactive ? false : user.canManageAccount == true,
						Status__c = isInactive ? Account.USER_STATUS_INACTIVE : user.status,
						Provisioned__c = isInactive ? null : user.provisioned));
					if (isInactive) {
						inactiveIds.add(user.sourceId);
					} else if (user.canManageAccount) {
						adminIds.add(user.sourceId);
					} else {
						senderIds.add(user.sourceId);
					}
				}
			}

			update toUpdate;

			Permissions.removeDocuSignPermissionSets(inactiveIds);
			Permissions.assignDocuSignAdministratorPermissionSet(adminIds);
			Permissions.assignDocuSignUserPermissionSet(senderIds);

			return users;
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
	 * Retrieves Salesforce user configuration: profiles and permission sets.
	 *
	 * @return Profiles and permission sets for the current Salesforce organization.
	 */
	public static Configuration getConfiguration() {
		Permissions.verifyIsDocuSignAdministrator();

		return DB.queryUserConfiguration();
	}

	/**
	 * Retrieve current Salesforce users that have been provisioned with DocuSign.
	 * <p>
	 * Callers must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param maximumRecords Maximum number of records to return (1...50000, default 50).
	 *
	 * @return A list of current DocuSign users.
	 */
	public static List<Account.User> getCurrentUsers(final Integer maximumRecords) {
		Permissions.verifyIsDocuSignAdministrator();

		return DB.queryCurrentUsers(maximumRecords);
	}

	/**
	 * Search for Salesforce users matching specified criteria that have not been provisioned with DocuSign.
	 * <p>
	 * Callers must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param name Optional beginning of name to match.
	 * @param email Optional beginning of email address to match.
	 * @param profileIds Optional profile IDs to match.
	 * @param permissionSetIds Optional permission set IDs to match.
	 * @param maximumRecords Maximum number of records to return (1...50000, default 50).
	 *
	 * @return A list of users that may be provisioned with DocuSign.
	 */
	public static List<Account.User> getAvailableUsers(
		final String name,
		final String email,
		final Set<Id> profileIds,
		final Set<Id> permissionSetIds,
		final Integer maximumRecords) {

		Permissions.verifyIsDocuSignAdministrator();

		return DB.queryAvailableUsers(
			name,
			email,
			profileIds,
			permissionSetIds,
			maximumRecords);
	}


	/**
	 * Retrieves a list of DocuSign account members.
	 *
	 * @param maximumRecords The maximum number of records to retrieve.
	 *
	 * @return The current DocuSign account members.
	 */
	public static List<Account.User> getUsers(final Integer maximumRecords) {
		Permissions.verifyIsDocuSignAdministrator();

		return DB.queryCurrentUsers(maximumRecords);
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
			if (Collection.isEmpty(users)) return users;

			// Update the username and password for the users
			List<Account.User> result = new List<Account.User>();
			Map<Id, Credentials.UserCredentials> creds = new Map<Id, Credentials.UserCredentials>();
			for (Account.User u : UserAPI.getInstance().addUsers(users)) {
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
	public static List<Account.User> removeUsers(
		final List<Account.User> users,
		final Boolean closeMembership) {

		Permissions.verifyIsDocuSignAdministrator();

		Set<Id> userIds = getUserIdsToRemove(users);

		List<Account.User> result = new List<Account.User>();
		if (closeMembership) {
			try {
				for (Account.User u : UserAPI.getInstance().removeUsers(users)) {
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
	 * A DocuSign for Salesforce system sender, i.e. the sender to use when a Salesforce user is not a member of the
	 * DocuSign account.
	 */
	public class SystemSender {
		/**
		 * The DocuSign user ID.
		 */
		@AuraEnabled
		public UUID id { get; private set; }
		/**
		 * The user name.
		 */
		@AuraEnabled
		public String name { get; private set; }
		/**
		 * The user email.
		 */
		@AuraEnabled
		public String email { get; private set; }

		private SystemSender(
			final UUID id,
			final String name,
			final String email) {

			this.id = id;
			this.name = name;
			this.email = email;
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
