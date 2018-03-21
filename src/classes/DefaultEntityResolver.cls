/**
 * Default or fallback entity resolver. Handles Accounts, Cases, Contacts, Leads, Opportunities natively.
 * All other sObject types are handled in a generic fashion.
 */
public with sharing class DefaultEntityResolver implements EntityResolver {

	@TestVisible
	private static final DefaultEntityResolver.Database DB = new DefaultEntityResolver.Database();

	@TestVisible
	private with sharing class Database {

		public Entity queryEntity(final String sObjectType, final Id sObjectId) {
			if (sObjectId == null || String.isBlank(sObjectType)) return null;

			Entity result = new Entity(sObjectId);
			String name = Label.Unknown;
			Entity parent = null;
			if (sObjectType == 'Opportunity') {
				Permissions.verifyIsQueryable('Opportunity', new List<String> { 'Name' });
				Permissions.verifyIsQueryable('Account', new List<String> { 'Id', 'Name' });

				List<Opportunity> opportunities = [
					SELECT Name, Account.Id, Account.Name
					FROM Opportunity
					WHERE Id = :sObjectId
					LIMIT 1
				];
				if (Collection.isNotEmpty(opportunities)) {
					Opportunity o = opportunities[0];
					name = o.Name;
					parent = o.Account == null ? null : new Entity(o.Account.Id, o.Account.Name, null);
				}
			} else if (sObjectType == 'Contact') {
				Permissions.verifyIsQueryable('Contact', new List<String> { 'Name' });
				Permissions.verifyIsQueryable('Account', new List<String> { 'Id', 'Name' });

				List<Contact> contacts = [
					SELECT Name, Account.Id, Account.Name
					FROM Contact
					WHERE Id = :sObjectId
					LIMIT 1
				];
				if (Collection.isNotEmpty(contacts)) {
					Contact c = contacts[0];
					name = c.Name;
					parent = c.Account == null ? null : new Entity(c.Account.Id, c.Account.Name, null);
				}
			} else if (sObjectType == 'Case') {
				Permissions.verifyIsQueryable('Case', new List<String> { 'CaseNumber' });
				Permissions.verifyIsQueryable('Account', new List<String> { 'Id', 'Name' });

				List<Case> cases = [
					SELECT CaseNumber, Account.Id, Account.Name
					FROM Case
					WHERE Id = :sObjectId
					LIMIT 1
				];
				if (Collection.isNotEmpty(cases)) {
					Case c = cases[0];
					name = c.CaseNumber;
					parent = c.Account == null ? null : new Entity(c.Account.Id, c.Account.Name, null);
				}
			} else {
				Permissions.verifyIsQueryable(sObjectType, new List<String> { 'Id', 'Name' });

				List<SObject> objs = System.Database.query('SELECT Id, Name FROM ' + String.escapeSingleQuotes(sObjectType)
					+ ' WHERE Id = :sObjectId LIMIT 1');
				if (Collection.isNotEmpty(objs)) {
					name = (String)objs[0].get('Name');
				}
			}

			return result
				.withName(name)
				.withParent(parent);
		}
	}

	public Boolean canResolve(final String sObjectType) {
		// The default entity resolver is the ultimate fallback for unknown types.
		return String.isNotBlank(sObjectType) && Salesforce.exists(Application.resolveType(sObjectType));
	}

	public Entity resolve(final String sObjectType, final Id sObjectId) {
		if (String.isBlank(sObjectType)) throw new DocuSignException(Label.UndefinedType);
		if (sObjectId == null) throw new DocuSignException(Label.UndefinedId);

		return DB.queryEntity(sObjectType, sObjectId);
	}
}
