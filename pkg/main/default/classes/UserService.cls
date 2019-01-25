/**
 * Salesforce and DocuSign user management.
 */
public with sharing class UserService {

	@TestVisible
	private static final UserService.Database DB = new UserService.Database();

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
				UUID.tryParse(user.InviteId__c),
				user.InviteDate__c,
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
				Application.namespacePrefix + 'InviteId__c',
				Application.namespacePrefix + 'InviteDate__c',
				Application.namespacePrefix + 'Status__c',
				Application.namespacePrefix + 'Username__c'
			});
			Permissions.verifyIsQueryable(Profile.getSObjectType(), new List<String> {
				'Name'
			});

			return convert([
				SELECT Id, FirstName, LastName, Email, Profile.Name,
					CanManageAccount__c, InviteId__c, InviteDate__c, Status__c, Username__c
				FROM User
				WHERE IsActive = TRUE
				AND (InviteId__c != NULL OR Username__c != NULL)
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
				'Id', 'FirstName', 'LastName', 'Email'
			});
			Permissions.verifyIsQueryable(Profile.getSObjectType(), new List<String> {
				'Name'
			});

			String query = 'SELECT Id, FirstName, LastName, Email, Profile.Name, '
				+ Application.namespacePrefix + 'Username__c, '
				+ Application.namespacePrefix + 'CanManageAccount__c, '
				+ Application.namespacePrefix + 'Status__c, '
				+ Application.namespacePrefix + 'InviteId__c, '
				+ Application.namespacePrefix + 'InviteDate__c '
				+ 'FROM User '
				+ 'WHERE ' + Application.namespacePrefix + 'InviteId__c = NULL '
				+ 'AND ' + Application.namespacePrefix + 'Username__c = NULL '
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
				Application.namespacePrefix + 'InviteDate__c',
				Application.namespacePrefix + 'InviteId__c',
				Application.namespacePrefix + 'Status__c'
			});

			List<User> toUpdate = new List<User>();
			Set<Id> adminIds = new Set<Id>();
			Set<Id> senderIds = new Set<Id>();
			Set<Id> inactiveIds = new Set<Id>();
			for (Account.User user : (users == null ? new List<Account.User>() : users)) {
				if (user != null && !user.hasError && user.sourceId != null) {
					Boolean isInactive = UUID.isEmpty(user.id) && UUID.isEmpty(user.inviteId);
					toUpdate.add(new User(
						Id = user.sourceId,
						Username__c = isInactive ? null : String.valueOf(user.id),
						CanManageAccount__c = isInactive ? false : user.canManageAccount == true,
						InviteDate__c = isInactive ? null : user.inviteDate,
						InviteId__c = isInactive ? null : String.valueOf(user.inviteId),
						Status__c = isInactive ? Account.USER_STATUS_INACTIVE : user.status));
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
	 * Invite one or more Salesforce users to the DocuSign account. Each user will receive an individualized invite
	 * email to complete registration.
	 * <p>
	 * This operation may partially succeed or fail, so check the <code>error</code> property on each returned user.
	 * <p>
	 * Callers must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param users The users to invite.
	 *
	 * @return The invited users.
	 */
	public static List<Account.User> inviteUsers(final List<Account.User> users) {
		Permissions.verifyIsDocuSignAdministrator();

		if (Collection.isEmpty(users)) throw new DocuSignException(Label.UndefinedUsers);

		return DB.updateUsers(UserInviteAPI.getInstance().inviteUsers(users));
	}

	/**
	 * Resends DocuSign account invites to one or more Salesforce users.
	 * <p>
	 * This operation may partially succeed or fail, so check the <code>error</code> property on each returned user.
	 * <p>
	 * Callers must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param users The users for which to resend invites.
	 *
	 * @return The resent invite users.
	 */
	public static List<Account.User> resendInvites(final List<Account.User> users) {
		Permissions.verifyIsDocuSignAdministrator();

		if (Collection.isEmpty(users)) throw new DocuSignException(Label.UndefinedUsers);

		return DB.updateUsers(UserInviteAPI.getInstance().resendInvites(users));
	}

	/**
	 * Revokes DocuSign account invites for one or more Salesforce users.
	 * <p>
	 * This operation may partially succeed or fail, so check the <code>error</code> property on each returned user.
	 * <p>
	 * Callers must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param users The users for which to revoke invites.
	 *
	 * @return The revoked invite users.
	 */
	public static List<Account.User> revokeInvites(final List<Account.User> users) {
		Permissions.verifyIsDocuSignAdministrator();

		if (Collection.isEmpty(users)) throw new DocuSignException(Label.UndefinedUsers);

		return DB.updateUsers(UserInviteAPI.getInstance().resendInvites(users));
	}

	// FIXME: How to remove users? Legacy eSignature API method?
}
