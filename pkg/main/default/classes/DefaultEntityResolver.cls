/**
 * Default or fallback entity resolver. Handles Accounts, Cases, Contacts, Leads, Opportunities natively.
 * All other sObject types are handled in a generic fashion.
 */
public with sharing class DefaultEntityResolver implements EntityResolver {

	private static final SObjectType TYPE_ACCOUNT = Schema.Account.getSObjectType();
	private static final SObjectType TYPE_CASE = Case.getSObjectType();
	private static final SObjectType TYPE_CONTACT = Contact.getSObjectType();
	private static final SObjectType TYPE_OPPORTUNITY = Opportunity.getSObjectType();

	@TestVisible
	private static final DefaultEntityResolver.Database DB = new DefaultEntityResolver.Database();

	@TestVisible
	private with sharing class Database {

		public Entity queryEntity(final Id id) {
			if (id == null) return null;

			Entity result = new Entity(id);
			String name = Label.Unknown;
			Entity parent = null;
			SObjectType type = id.getSobjectType();
			if (type == TYPE_OPPORTUNITY) {
				Permissions.verifyIsQueryable(TYPE_OPPORTUNITY, new List<String> { 'Name' });
				Permissions.verifyIsQueryable(TYPE_ACCOUNT, new List<String> { 'Id', 'Name' });

				List<Opportunity> opportunities = [
					SELECT Name, Account.Id, Account.Name
					FROM Opportunity
					WHERE Id = :id
					LIMIT 1
				];
				if (Collection.isNotEmpty(opportunities)) {
					Opportunity o = opportunities[0];
					name = o.Name;
					parent = o.Account == null ? null : new Entity(o.Account.Id, o.Account.Name, null);
				}
			} else if (type == TYPE_CONTACT) {
				Permissions.verifyIsQueryable(TYPE_CONTACT, new List<String> { 'Name' });
				Permissions.verifyIsQueryable(TYPE_ACCOUNT, new List<String> { 'Id', 'Name' });

				List<Contact> contacts = [
					SELECT Name, Account.Id, Account.Name
					FROM Contact
					WHERE Id = :id
					LIMIT 1
				];
				if (Collection.isNotEmpty(contacts)) {
					Contact c = contacts[0];
					name = c.Name;
					parent = c.Account == null ? null : new Entity(c.Account.Id, c.Account.Name, null);
				}
			} else if (type == TYPE_CASE) {
				Permissions.verifyIsQueryable(TYPE_CASE, new List<String> { 'CaseNumber' });
				Permissions.verifyIsQueryable(TYPE_ACCOUNT, new List<String> { 'Id', 'Name' });

				List<Case> cases = [
					SELECT CaseNumber, Account.Id, Account.Name
					FROM Case
					WHERE Id = :id
					LIMIT 1
				];
				if (Collection.isNotEmpty(cases)) {
					Case c = cases[0];
					name = c.CaseNumber;
					parent = c.Account == null ? null : new Entity(c.Account.Id, c.Account.Name, null);
				}
			} else {
				String nameField = Salesforce.getNameField(type);
				Permissions.verifyIsQueryable(type, new List<String> { 'Id', nameField });

				List<SObject> objs = System.Database.query(String.format(
					'SELECT Id, {0} FROM {1} WHERE Id = :id LIMIT 1', new List<String> {
						nameField,
						String.valueOf(type)
					}));
				if (Collection.isNotEmpty(objs)) {
					name = (String)objs[0].get(nameField);
				}
			}

			return result
				.withName(name)
				.withParent(parent);
		}
	}

	public Boolean canResolve(final SObjectType type) {
		// The default entity resolver is the ultimate fallback for unknown types.
		return type != null;
	}

	public Entity resolve(final Id id) {
		if (id == null) throw new DocuSignException(Label.UndefinedId);

		return DB.queryEntity(id);
	}
}
