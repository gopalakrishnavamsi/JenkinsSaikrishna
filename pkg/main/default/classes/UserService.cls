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
				null,
				APIError.none);
		}

		@TestVisible
		private Map<Id, Account.User> convert(final List<User> users) {
			Map<Id, Account.User> result = new Map<Id, Account.User>();
			for (User user : (users == null ? new List<User>() : users)) {
				result.put(user.Id, convert(user));
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
			[
				SELECT Id, Name
				FROM Profile
				ORDER BY Name
				LIMIT :Application.batchLimit
			],
			[
				SELECT Id, Label
				FROM PermissionSet
				WHERE IsOwnedByProfile = FALSE
				ORDER BY Label
				LIMIT :Application.batchLimit
			]);
		}

		public Map<Id, Account.User> queryCurrentUsers(final Integer maximumRecords) {
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
				LIMIT :(maximumRecords > 0 && maximumRecords <= Application.batchLimit
					? maximumRecords : Application.batchLimit)
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
			Integer l = maximumRecords > 0 && maximumRecords <= Application.batchLimit
				? maximumRecords : Application.batchLimit;
			query += ' LIMIT :l';

			return convert((List<User>)System.Database.query(query)).values();
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
				LIMIT :Application.batchLimit
			]) {
				result.add(new SystemSender(
					UUID.parse(u.Username__c),
					u.Name,
					u.Email));
			}
			return result;
		}

		public Map<UUID, Account.User> queryUsers(final Set<Id> userIds) {
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

			Map<UUID, Account.User> result = new Map<UUID, Account.User>();
			for (User u : [
				SELECT Id, FirstName, LastName, Email, Profile.Name,
					CanManageAccount__c, Status__c, Username__c, Provisioned__c
				FROM User
				WHERE Id IN :userIds
				AND Username__c != NULL
				LIMIT :Application.batchLimit
			]) {
				Account.User au = convert(u);
				if (au != null && UUID.isNotEmpty(au.id)) result.put(au.id, au);
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

		Map<Id, Account.User> users = DB.queryCurrentUsers(maximumRecords);
		Map<Id, Map<String, String>> userRoles = Permissions.getUserRoles(users.keySet());
		List<Account.User> result = users.values();
		for (Account.User user : result) {
			user.withRoles(userRoles.get(user.sourceId));
		}
		return result;
	}

	@TestVisible
	private static List<Account.User> verifyBatchSize(
		final List<Account.User> users,
		final Integer batchSize) {

		if (users == null) return new List<Account.User>();

		Integer size = users.size();
		Integer max = batchSize <= 0 ? Application.batchLimit : batchSize;
		if (size > max) {
			throw new DocuSignException(String.format(Label.MaximumBatchSizeExceeded_2,
				new List<Object> { size, max }));
		}
		return users;
	}

	@TestVisible
	private static Set<Id> verifyBatchSize(
		final Set<Id> userIds,
		final Integer batchSize) {

		if (userIds == null) return new Set<Id>();

		Integer max = batchSize <= 0 ? Application.batchLimit : batchSize;
		Integer size = userIds.size();
		if (size > max) {
			throw new DocuSignException(String.format(Label.MaximumBatchSizeExceeded_2,
				new List<Object> { size, max }));
		}
		return userIds;
	}

	/**
	 * Adds one or more users as members of the current DocuSign account.
	 * <p>
	 * A maximum of 2000 users may be added at a time.
 	 * <p>
 	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param users A list of users to add.
	 * @param productRoles A map of products to roles to be assigned to the users.
 	 *
	 * @return The users added. This may be partially successful with details in the returned <code>User.error</code>
	 * property.
	 * @see Account.User.error for details on any errors.
 	 */
	public static List<Account.User> addUsers(
		final List<Account.User> users,
		final Map<String, String> productRoles) {

		Permissions.verifyIsDocuSignAdministrator();

		try {
			if (Collection.isEmpty(users)) return users;

			verifyBatchSize(users, Application.batchLimit);

			// Update the username and password for the users
			List<Account.User> result = new List<Account.User>();
			Map<Id, Credentials.UserCredentials> creds = new Map<Id, Credentials.UserCredentials>();
			Map<UUID, Account.User> newUsers = new Map<UUID, Account.User>();
			for (Account.User u : UserAPI.getInstance().addUsers(users)) {
				if (u.hasError) {
					// Don't update user permissions if there was an error when adding to the account.
					LOG.warn('Error while adding user ' + u.email + ': ' + u.error);
					result.add(u);
				} else {
					creds.put(u.sourceId, new Credentials.UserCredentials(
						u.id,
						u.name,
						u.email,
						u.status,
						u.canManageAccount));
					result.add(u.withError(null));
					if (UUID.isNotEmpty(u.id)) newUsers.put(u.id, u);
				}
			}

			Boolean hasRoles = productRoles != null && !productRoles.isEmpty();
			if (hasRoles) {
				// Update user roles in MAGNUM API
				RoleAPI.getInstance().addRoleUsers(
					newUsers,
					flattenRoles(
						AccountProducts.getRoles(productRoles.keySet()),
						productRoles));
			}

			Credentials.add(creds);
			if (hasRoles) Permissions.replaceRoles(creds.keySet(), productRoles);

			return mergeRoles(result, productRoles, productRoles);
		} finally {
			Credentials.save();
			AccountProducts.save();
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

	@Future
	private static void clearPermissions(final Set<Id> userIds) {
		Permissions.clear(userIds);
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

		Set<Id> userIds = getUserIdsToRemove(verifyBatchSize(users, Application.batchLimit));

		List<Account.User> result = new List<Account.User>();
		if (closeMembership) {
			try {
				for (Account.User u : UserAPI.getInstance().removeUsers(users)) {
					if (u.hasError && String.isNotBlank(u.sourceId)) {
						// Don't clear user credentials if the API returned an error.
						LOG.warn('Error while removing user ' + u.email + ': ' + u.error);
						userIds.remove(u.sourceId);
					}
					result.add(u);
				}
			} finally {
				Credentials.save();
			}
		}

		Credentials.clear(userIds);
		// Clearing permission sets must be done in a @Future context here to avoid mixed DML errors.
		clearPermissions(userIds);

		return result;
	}

	@TestVisible
	private static Map<UUID, Product.Role> flattenRoles(final Map<String, Map<UUID, Product.Role>> accountRoles) {
		Map<UUID, Product.Role> result = new Map<UUID, Product.Role>();
		if (Collection.isNotEmpty(accountRoles)) {
			for (Map<UUID, Product.Role> prs : accountRoles.values()) {
				if (prs != null) result.putAll(prs);
			}
		}
		return result;
	}

	@TestVisible
	private static Map<UUID, Product.Role> flattenRoles(
		final Map<String, Map<UUID, Product.Role>> accountRoles,
		final Map<String, String> targetRoles) {

		Map<UUID, Product.Role> result = new Map<UUID, Product.Role>();
		if (Collection.isNotEmpty(accountRoles) && Collection.isNotEmpty(targetRoles)) {
			for (String p : targetRoles.keySet()) {
				if (!accountRoles.containsKey(p)) throw new DocuSignException(Label.UnsupportedProducts);

				// Filter roles needed. Ugh.
				String role = targetRoles.get(p);
				if (String.isNotBlank(role)) {
					Boolean foundRole = false;
					for (Product.Role pr : accountRoles.get(p).values()) {
						if (pr.role == role) {
							result.put(pr.id, pr);
							foundRole = true;
							break;
						}
					}
					if (!foundRole) throw new DocuSignException(Label.UnsupportedProductRoles);
				}
			}
		}
		return result;
	}

	@TestVisible
	private static Map<String, String> getAdminRoles(final Map<String, String> productRoles) {
		Map<String, String> result = new Map<String, String>();
		Map<String, String> roles = productRoles == null ? new Map<String, String>() : productRoles;
		for (String p : roles.keySet()) {
			String r = roles.get(p);
			if (p == Product.ESIGNATURE) {
				result.put(p, ESignatureProduct.ROLE_ADMINISTRATOR);
			} else if (p == Product.CLM) {
				result.put(p, ClmProduct.ROLE_ADMINISTRATOR);
			} else if (!String.isBlank(r)) {
				result.put(p, r);
			}
		}
		return result;
	}

	@TestVisible
	private static List<Account.User> mergeRoles(
		final List<Account.User> users,
		final Map<String, String> adminRoles,
		final Map<String, String> nonAdminRoles) {

		List<Account.User> result = new List<Account.User>();
		if (Collection.isNotEmpty(users)) {
			for (Account.User u : users) {
				if (u.canManageAccount) {
					// Ensure the user has DS Admin and CLM admin if applicable
					result.add(u.withRoles(adminRoles));
				} else {
					result.add(u.withRoles(nonAdminRoles));
				}
			}
		}
		return result;
	}

	/**
	 * Updates application roles for one or more users.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param userIds The IDs of the users for which to replace application roles.
	 * @param productRoles A map of products to roles which will be assigned to the users.
	 *
	 * @return Whether or not any user roles were updated.
	 */
	public static List<Account.User> updateUserRoles(
		final Set<Id> userIds,
		final Map<String, String> productRoles) {

		Permissions.verifyIsDocuSignAdministrator();

		if (Collection.isEmpty(userIds)) throw new DocuSignException(Label.UndefinedArgument);

		Set<Id> uIds = verifyBatchSize(userIds, Application.batchLimit);
		Map<UUID, Account.User> users = DB.queryUsers(uIds);
		if (Collection.isEmpty(users)) new List<Account.User>();

		try {
			// Update user groups in MAGNUM API.
			// Remove other roles first
			// First, get list of all configured products
			Set<String> allProducts = new Set<String>();
			for (Product p : AccountProducts.getProducts()) {
				allProducts.add(p.name);
			}

			// Next, get all roles for configured products.
			Map<String, Map<UUID, Product.Role>> accountRoles = AccountProducts.getRoles(allProducts);
			Map<UUID, Product.Role> allRoles = flattenRoles(accountRoles);

			// Then, get the roles we want to assign.
			Map<UUID, Product.Role> newRoles = flattenRoles(accountRoles, productRoles);

			// TODO: Return error details for users? Depends on whether we have a design and fallback mechanism.
			RoleAPI.getInstance().updateUserRoles(users, allRoles, newRoles);

			// Update permission sets
			Permissions.replaceRoles(uIds, productRoles);

			// Reset user access tokens and set CanManageAccount__c accordingly.
			Credentials.reset(
				uIds,
				productRoles != null
					&& productRoles.containsKey(Product.ESIGNATURE)
					&& productRoles.get(Product.ESIGNATURE).contains(ESignatureProduct.ROLE_ADMINISTRATOR));

			Map<String, String> adminRoles = getAdminRoles(productRoles);
			return mergeRoles(users.values(), adminRoles, productRoles);
		} finally {
			Credentials.save();
			AccountProducts.save();
		}
	}

	/**
	 * A DocuSign eSignature system sender, i.e. the sender to use when a Salesforce user is not a member of the
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
	 * Retrieves a list of users that may be used as the DocuSign eSignature system sender.
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
