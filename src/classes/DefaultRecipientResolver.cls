public with sharing class DefaultRecipientResolver implements RecipientResolver {

	private static final SObjectType TYPE_ACCOUNT = Schema.Account.getSObjectType();
	private static final SObjectType TYPE_CASE = Case.getSObjectType();
	private static final SObjectType TYPE_CONTACT = Contact.getSObjectType();
	private static final SObjectType TYPE_LEAD = Lead.getSObjectType();
	private static final SObjectType TYPE_OPPORTUNITY = Opportunity.getSObjectType();
	private static final SObjectType TYPE_OPPORTUNITY_CONTACT_ROLE = OpportunityContactRole.getSObjectType();
	private static final SObjectType TYPE_USER = User.getSObjectType();

	private static final Set<SObjectType> RESOLVABLE_TYPES = new Set<SObjectType> {
		TYPE_ACCOUNT, TYPE_CASE, TYPE_CONTACT, TYPE_LEAD, TYPE_OPPORTUNITY, TYPE_USER
	};

	private static final Set<SObjectType> SEARCHABLE_TYPES = new Set<SObjectType> {
		TYPE_CONTACT, TYPE_LEAD, TYPE_USER
	};

	public Boolean canResolveRecipients(final SObjectType type) {
		return type != null && RESOLVABLE_TYPES.contains(type);
	}

	public Boolean canSearchRecipients(final SObjectType type) {
		return type != null && SEARCHABLE_TYPES.contains(type);
	}

	private static List<Recipient> getAccountRecipients(final Set<Id> accountIds) {
		Permissions.verifyIsQueryable(TYPE_CONTACT, new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });
		Permissions.verifyIsQueryable(TYPE_ACCOUNT, new List<String> { 'Id', 'Name' });

		final List<Recipient> recipients = new List<Recipient>();
		for (Contact c : [
			SELECT Id, Name, Email, Phone, MobilePhone, Account.Id, Account.Name
			FROM Contact
			WHERE AccountId IN :accountIds
		]) {
			recipients.add(Recipient.fromSource(
				c.Name,
				c.Email,
				String.isBlank(c.Phone) ? c.MobilePhone : c.Phone,
				null,
				new Entity(
					c.Id,
					c.Name,
					new Entity(
						c.Account.Id,
						c.Account.Name,
						null))));
		}
		return recipients;
	}

	private static List<Recipient> getCaseRecipients(final Set<Id> caseIds) {
		Permissions.verifyIsQueryable(TYPE_CONTACT, new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });
		Permissions.verifyIsQueryable(TYPE_CASE, new List<String> { 'Id', 'CaseNumber' });

		List<Recipient> recipients = new List<Recipient>();
		for (Case c : [
			SELECT Id, CaseNumber, Contact.Id, Contact.Name, Contact.Email, Contact.Phone, Contact.MobilePhone
			FROM Case
			WHERE Id IN :caseIds
		]) {
			recipients.add(Recipient.fromSource(
				c.Contact.Name,
				c.Contact.Email,
				String.isBlank(c.Contact.Phone) ? c.Contact.MobilePhone : c.Contact.Phone,
				null,
				new Entity(
					c.Contact.Id,
					c.Contact.Name,
					new Entity(
						c.Id,
						c.CaseNumber,
						null))));
		}
		return recipients;
	}

	private static List<Recipient> getContactRecipients(final Set<Id> contactIds) {
		Permissions.verifyIsQueryable(TYPE_CONTACT, new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });
		Permissions.verifyIsQueryable(TYPE_ACCOUNT, new List<String> { 'Id', 'Name' });

		final List<Recipient> recipients = new List<Recipient>();
		for (Contact c : [
			SELECT Id, Name, Email, Phone, MobilePhone, Account.Id, Account.Name
			FROM Contact
			WHERE Id IN :contactIds
		]) {
			recipients.add(Recipient.fromSource(
				c.Name,
				c.Email,
				String.isBlank(c.Phone) ? c.MobilePhone : c.Phone,
				null,
				new Entity(
					c.Id,
					c.Name,
					c.Account == null ? null : new Entity(
						c.Account.Id,
						c.Account.Name,
						null))));
		}
		return recipients;
	}

	private static List<Recipient> getLeadRecipients(final Set<Id> leadIds) {
		Permissions.verifyIsQueryable(TYPE_LEAD, new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });

		final List<Recipient> recipients = new List<Recipient>();
		for (Lead c : [
			SELECT Id, Name, Email, Phone, MobilePhone
			FROM Lead
			WHERE Id IN :leadIds
		]) {
			recipients.add(Recipient.fromSource(
				c.Name,
				c.Email,
				String.isBlank(c.Phone) ? c.MobilePhone : c.Phone,
				null,
				new Entity(c.Id, c.Name, null)));
		}
		return recipients;
	}

	private static List<Recipient> getOpportunityRecipients(final Set<Id> opportunityIds) {
		Permissions.verifyIsQueryable(TYPE_CONTACT, new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });
		Permissions.verifyIsQueryable(TYPE_OPPORTUNITY_CONTACT_ROLE, new List<String> { 'Role' });
		Permissions.verifyIsQueryable(TYPE_ACCOUNT, new List<String> { 'Id', 'Name' });

		final List<Recipient> recipients = new List<Recipient>();
		for (OpportunityContactRole c : [
			SELECT
				Id,
				Contact.Id,
				Contact.Name,
				Contact.Email,
				Contact.Phone,
				Contact.MobilePhone,
				Opportunity.Account.Id,
				Opportunity.Account.Name,
				Role
			FROM OpportunityContactRole
			WHERE OpportunityId IN :opportunityIds
			ORDER BY CreatedDate
		]) {
			recipients.add(Recipient.fromSource(
				c.Contact.Name,
				c.Contact.Email,
				String.isBlank(c.Contact.Phone) ? c.Contact.MobilePhone : c.Contact.Phone,
				c.Role,
				new Entity(
					c.Contact.Id,
					c.Contact.Name,
					new Entity(
						c.Opportunity.Account.Id,
						c.Opportunity.Account.Name,
						null))));
		}
		return recipients;
	}

	private static List<Recipient> getUserRecipients(final Set<Id> userIds) {
		Permissions.verifyIsQueryable(TYPE_USER, new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });

		final List<Recipient> recipients = new List<Recipient>();
		for (User u : [
			SELECT Id, Name, Email, Phone, MobilePhone
			FROM User
			WHERE Id IN :userIds
		]) {
			recipients.add(Recipient.fromSource(
				u.Name,
				u.Email,
				String.isBlank(u.Phone) ? u.MobilePhone : u.Phone,
				null,
				new Entity(
					u.Id,
					u.Name,
					null)));
		}
		return recipients;
	}

	public List<Recipient> getRecipients(final SObjectType type, final Set<Id> sObjectIds) {
		if (type == null) throw new DocuSignException(Label.UndefinedType);

		List<Recipient> result = null;
		if (type == TYPE_ACCOUNT) {
			result = getAccountRecipients(sObjectIds);
		} else if (type == TYPE_CASE) {
			result = getCaseRecipients(sObjectIds);
		} else if (type == TYPE_CONTACT) {
			result = getContactRecipients(sObjectIds);
		} else if (type == TYPE_LEAD) {
			result = getLeadRecipients(sObjectIds);
		} else if (type == TYPE_OPPORTUNITY) {
			result = getOpportunityRecipients(sObjectIds);
		} else if (type == TYPE_USER) {
			result = getUserRecipients(sObjectIds);
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveRecipientSource_1,
				new List<String> { String.valueOf(type) }));
		}
		return result;
	}

	/***************************************************************************************************************
	 * READ BEFORE MODIFYING THE searchContacts, searchLeads, OR searchUsers METHODS:
	 * 1. Some Shield orgs encrypt names. Must use dynamic SOQL (Database.query) to avoid compilation issues.
	 * 2. Matching any part of string (%_%) is VERY inefficient and will be painfully slow or break on orgs with
	 * 	lots of records. Matching the first part (_%) is better.
	 **************************************************************************************************************/

	private static String buildQuery(final String selector, final String firstName, final String lastName,
		final Boolean isCompound, final Boolean isExact) {

		String result = selector;
		List<String> filters = new List<String>();
		if (String.isNotBlank(firstName)) {
			if (isCompound && isExact) {
				filters.add(' Name = :firstName');
			} else if (isExact) {
				filters.add(' FirstName = :firstName');
			} else if (isCompound) {
				filters.add(' Name LIKE :firstName');
			} else {
				filters.add(' FirstName LIKE :firstName');
			}
		}
		if (!isCompound && String.isNotBlank(lastName)) {
			if (isExact) {
				filters.add(' LastName = :lastName');
			} else {
				filters.add(' LastName LIKE :lastName');
			}
		}
		if (Collection.isNotEmpty(filters)) {
			result += ' WHERE' + Collection.mkString(filters, ' AND ');
		}
		result += ' LIMIT 100';
		return result;
	}

	private static List<Recipient> searchContacts(final String firstName, final String lastName,
		final Boolean isCompound, final Boolean isExact) {

		Permissions.verifyIsQueryable(TYPE_CONTACT, new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });
		Permissions.verifyIsQueryable(TYPE_ACCOUNT, new List<String> { 'Id', 'Name' });

		Boolean ic = isCompound && Permissions.isFilterable(TYPE_CONTACT, new List<String> { 'Name' }).isAuthorized;
		Boolean ie = isExact
			|| (ic && !Permissions.isUnencrypted(TYPE_CONTACT, new List<String> { 'Name' }).isAuthorized)
			|| (!ic && !Permissions.isUnencrypted(TYPE_CONTACT, new List<String> { 'FirstName', 'LastName' }).isAuthorized);
		List<Recipient> recipients = new List<Recipient>();
		String q = buildQuery('SELECT Id, Name, Email, Phone, MobilePhone, Account.Id, Account.Name FROM Contact',
			firstName, lastName, ic, ie);
		for (Contact c : System.Database.query(q)) {
			recipients.add(Recipient.fromSource(
				c.Name,
				c.Email,
				String.isBlank(c.Phone) ? c.MobilePhone : c.Phone,
				null,
				new Entity(
					c.Id,
					c.Name,
					new Entity(
						c.Account.Id,
						c.Account.Name,
						null))));
		}
		return recipients;
	}

	private static List<Recipient> searchLeads(final String firstName, final String lastName, final Boolean isCompound,
		final Boolean isExact) {

		Permissions.verifyIsQueryable(TYPE_LEAD, new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });

		Boolean ic = isCompound && Permissions.isFilterable(TYPE_LEAD, new List<String> { 'Name' }).isAuthorized;
		Boolean ie = isExact
			|| (ic && !Permissions.isUnencrypted(TYPE_LEAD, new List<String> { 'Name' }).isAuthorized)
			|| (!ic && !Permissions.isUnencrypted(TYPE_LEAD, new List<String> { 'FirstName', 'LastName' }).isAuthorized);
		List<Recipient> recipients = new List<Recipient>();
		String q = buildQuery('SELECT Id, Name, Email, Phone, MobilePhone FROM Lead',
			firstName, lastName, ic, ie);
		for (Lead l : System.Database.query(q)) {
			recipients.add(Recipient.fromSource(
				l.Name,
				l.Email,
				String.isBlank(l.Phone) ? l.MobilePhone : l.Phone,
				null,
				new Entity(l.Id, l.Name, null)));
		}
		return recipients;
	}

	private static List<Recipient> searchUsers(final String firstName, final String lastName, final Boolean isCompound,
		final Boolean isExact) {

		Permissions.verifyIsQueryable(TYPE_USER, new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });

		Boolean ic = isCompound && Permissions.isFilterable(TYPE_USER, new List<String> { 'Name' }).isAuthorized;
		Boolean ie = isExact
			|| (ic && !Permissions.isUnencrypted(TYPE_USER, new List<String> { 'Name' }).isAuthorized)
			|| (!ic && !Permissions.isUnencrypted(TYPE_USER, new List<String> { 'FirstName', 'LastName' }).isAuthorized);
		List<Recipient> recipients = new List<Recipient>();
		String q = buildQuery('SELECT Id, Name, Email, Phone, MobilePhone FROM User',
			firstName, lastName, ic, ie);
		for (User u : System.Database.query(q)) {
			recipients.add(Recipient.fromSource(
				u.Name,
				u.Email,
				String.isBlank(u.Phone) ? u.MobilePhone : u.Phone,
				null,
				new Entity(u.Id, u.Name, null)));
		}
		return recipients;
	}

	private static String buildSearchTerm(final String name, final Recipient.SearchBehavior behavior) {
		String result = name == null ? null : name.trim();
		if (result != null) {
			if (behavior == Recipient.SearchBehavior.CompoundMatchExact
				|| behavior == Recipient.SearchBehavior.DiscreteMatchExact) {

				result = result;
			} else if (behavior == Recipient.SearchBehavior.CompoundMatchAny
				|| behavior == Recipient.SearchBehavior.DiscreteMatchAny) {

				result = '%' + result + '%'; // This is super inefficient, so avoid if possible.
			} else { // MatchBeginning
				result += '%';
			}
		}
		return result;
	}

	public List<Recipient> searchRecipients(final SObjectType type, final String firstName, final String lastName,
		final Recipient.SearchBehavior behavior) {

		if (type == null) throw new DocuSignException(Label.UndefinedType);

		List<Recipient> result = null;
		Boolean isCompound = behavior == null || behavior.name().startsWith('Compound');
		Boolean isExact = behavior != null && behavior.name().endsWith('Exact');
		if (type == TYPE_CONTACT) {
			result = searchContacts(buildSearchTerm(firstName, behavior), buildSearchTerm(lastName, behavior),
				isCompound, isExact);
		} else if (type == TYPE_LEAD) {
			result = searchLeads(buildSearchTerm(firstName, behavior), buildSearchTerm(lastName, behavior),
				isCompound, isExact);
		} else if (type == TYPE_USER) {
			result = searchUsers(buildSearchTerm(firstName, behavior), buildSearchTerm(lastName, behavior),
				isCompound, isExact);
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveRecipientSource_1,
				new List<String> { String.valueOf(type) }));
		}
		return result;
	}
}
