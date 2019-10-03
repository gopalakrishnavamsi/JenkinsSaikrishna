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

		public Set<UUID> getDocuSignUserIds(final Set<Id> userIds) {
			Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> {
				Application.namespacePrefix + 'Username__c'
			});

			Set<UUID> result = new Set<UUID>();
			for (User u : [SELECT Username__c FROM User WHERE Id IN :userIds LIMIT :Application.batchLimit]) {
				UUID dsUserId = UUID.tryParse(u.Username__c);
				if (UUID.isNotEmpty(dsUserId)) result.add(dsUserId);
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
		Map<Id, Map<String, List<String>>> userRoles = Permissions.getUserRoles(users.keySet());
		List<Account.User> result = users.values();
		for (Account.User user : result) {
			user.withRoles(userRoles.get(user.sourceId));
		}
		return result;
	}

	public static Map<String, List<String>> getRoles(final Set<String> products) {
		Permissions.verifyIsDocuSignAdministrator();

		if (Collection.isEmpty(products)) throw new DocuSignException(Label.UndefinedArgument);

		Map<String, List<String>> result = new Map<String, List<String>>();
		Map<String, Map<UUID, Product.Role>> prs = AccountProducts.getRoles(products);
		if (prs != null) {
			for (String p : prs.keySet()) {
				List<String> roles = new List<String>();
				for (Product.Role pr : prs.get(p).values()) {
					roles.add(pr.role);
				}
				result.put(p, roles);
			}
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
		final Map<String, List<String>> productRoles) {

		Permissions.verifyIsDocuSignAdministrator();

		try {
			if (Collection.isEmpty(users)) return users;

			verifyBatchSize(users, Application.batchLimit);

			// Update the username and password for the users
			List<Account.User> result = new List<Account.User>();
			Map<Id, Credentials.UserCredentials> creds = new Map<Id, Credentials.UserCredentials>();
			Set<UUID> userIds = new Set<UUID>();
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
					result.add(u.withError(null).withRoles(productRoles));
					if (UUID.isNotEmpty(u.id)) userIds.add(u.id);
				}
			}

			Boolean hasRoles = productRoles != null && !productRoles.isEmpty();
			if (hasRoles) {
				// Update user roles in MAGNUM API
				RoleAPI.getInstance().addRoleUsers(getRoleUsers(
					getRoleIds(
						AccountProducts.getRoles(productRoles.keySet()),
						productRoles),
					userIds));
			}

			Credentials.add(creds);
			if (hasRoles) Permissions.replaceRoles(creds.keySet(), productRoles);

			return result;
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
					if (u.hasError && String.isNotBlank(u.sourceId)){
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
	private static Set<UUID> getRoleIds(final Map<String, Map<UUID, Product.Role>> accountRoles) {
		Set<UUID> result = new Set<UUID>();
		if (Collection.isNotEmpty(accountRoles)) {
			for (String p : accountRoles.keySet()) {
				for (UUID rId : accountRoles.get(p).keySet()) {
					if (UUID.isNotEmpty(rId)) result.add(rId);
				}
			}
		}
		return result;
	}

	@TestVisible
	private static Map<UUID, Set<UUID>> getUserRoleDifference(
		final Set<UUID> userIds,
		final Set<UUID> allRoleIds,
		final Set<UUID> newRoleIds) {

		Map<UUID, Set<UUID>> result = new Map<UUID, Set<UUID>>();
		for (UUID roleId : Collection.difference(allRoleIds, newRoleIds)) {
			result.put(roleId, userIds);
		}
		return result;
	}

	@TestVisible
	private static Map<UUID, Set<UUID>> getRoleUsers(
		final Set<UUID> roleIds,
		final Set<UUID> userIds) {

		Map<UUID, Set<UUID>> result = new Map<UUID, Set<UUID>>();
		if (Collection.isNotEmpty(roleIds) && Collection.isNotEmpty(userIds)) {
			for (UUID rId : roleIds) {
				if (UUID.isNotEmpty(rId)) result.put(rId, userIds);
			}
		}
		return result;
	}

	@TestVisible
	private static Set<UUID> getRoleIds(
		final Map<String, Map<UUID, Product.Role>> accountRoles,
		final Map<String, List<String>> targetRoles) {

		Set<UUID> result = new Set<UUID>();
		if (Collection.isNotEmpty(accountRoles)
			&& Collection.isNotEmpty(targetRoles)) {

			for (String p : targetRoles.keySet()) {
				if (!accountRoles.containsKey(p)) throw new DocuSignException(Label.UnsupportedProducts);

				// Filter roles needed. Ugh.
				List<String> roles = targetRoles.get(p);
				if (Collection.isNotEmpty(roles)) {
					Integer count = 0;
					for (String role : roles) {
						for (Product.Role pr : accountRoles.get(p).values()) {
							if (pr.role == role) {
								result.add(pr.id);
								count++;
							}
						}
					}
					if (count != roles.size()) throw new DocuSignException(Label.UnsupportedProductRoles);
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
	public static Boolean updateUserRoles(
		final Set<Id> userIds,
		final Map<String, List<String>> productRoles) {

		Permissions.verifyIsDocuSignAdministrator();

		if (Collection.isEmpty(userIds)) throw new DocuSignException(Label.UndefinedArgument);

		Set<Id> uIds = verifyBatchSize(userIds, Application.batchLimit);
		Set<UUID> dsUserIds = DB.getDocuSignUserIds(uIds);

		try {
			// Update user groups in MAGNUM API.
			// Remove other roles first
			// First, get list of all configured products
			Set<String> allProducts = new Set<String>();
			for (Product p : AccountProducts.getProducts()) {
				allProducts.add(p.name);
			}

			// Next, get list of roles for configured products.
			Map<String, Map<UUID, Product.Role>> allRoles = AccountProducts.getRoles(allProducts);
			Set<UUID> allRoleIds = getRoleIds(allRoles);

			// Then, get the role IDs for the ones we want to assign.
			Set<UUID> newRoleIds = getRoleIds(allRoles, productRoles);

			// Determine which roles need to be removed, if present.
			RoleAPI client = RoleAPI.getInstance();
			Map<UUID, Set<UUID>> toRemove = getUserRoleDifference(
				dsUserIds,
				allRoleIds,
				newRoleIds);
			if (toRemove != null && !toRemove.isEmpty()) client.removeRoleUsers(toRemove);

			// Add new roles
			// TODO: Return error details for users? Depends on whether we have a design and fallback or retry mechanism.
			if (Collection.isNotEmpty(newRoleIds)) client.addRoleUsers(getRoleUsers(newRoleIds, dsUserIds));

			// Update permission sets
			Permissions.replaceRoles(uIds, productRoles);

			// Reset user access tokens and set CanManageAccount__c accordingly.
			return Credentials.reset(
				uIds,
				productRoles != null
					&& productRoles.containsKey(Product.ESIGNATURE)
					&& productRoles.get(Product.ESIGNATURE).contains(ESignatureProduct.ROLE_ADMINISTRATOR));
		} finally {
			AccountProducts.save();
		}
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
