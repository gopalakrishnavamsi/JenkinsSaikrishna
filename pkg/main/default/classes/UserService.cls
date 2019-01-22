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

		public Configuration queryConfiguration() {
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

		public List<User> queryCurrentUsers() {
			Permissions.verifyIsQueryable(User.getSObjectType(), new List<String> {
				'Id', 'FirstName', 'LastName', 'Email', Application.namespacePrefix + 'CanManageAccount__c',
				Application.namespacePrefix + 'InviteDate__c', Application.namespacePrefix + 'Status__c'
			});
			Permissions.verifyIsQueryable(Profile.getSObjectType(), new List<String> {
				'Name'
			});

			return [
				SELECT Id, FirstName, LastName, Email, Profile.Name, InviteDate__c, CanManageAccount__c, Status__c
				FROM User
				WHERE IsActive = TRUE
				AND (InviteId__c != NULL OR Username__c != NULL)
				LIMIT 1000
			];
		}

		public List<User> queryAvailableUsers(
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

			String query = 'SELECT Id, FirstName, LastName, Email, Profile.Name '
				+ 'FROM User '
				+ 'WHERE InviteId__c = NULL '
				+ 'AND Username__c = FALSE '
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

			return (List<User>)System.Database.query(query);
		}
	}

	/**
	 * Retrieves Salesforce user configuration: profiles and permission sets.
	 *
	 * @return Profiles and permission sets for the current Salesforce organization.
	 */
	public static Configuration getConfiguration() {
		Permissions.verifyIsDocuSignAdministrator();

		return DB.queryConfiguration();
	}

	/**
	 * Retrieve current Salesforce users that have been provisioned with DocuSign.
	 * <p>
	 * Callers must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return A list of current DocuSign users.
	 */
	public static List<User> getCurrentUsers() {
		Permissions.verifyIsDocuSignAdministrator();

		return DB.queryCurrentUsers();
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
	public static List<User> getAvailableUsers(
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
}
