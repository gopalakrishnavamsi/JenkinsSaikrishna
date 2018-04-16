public with sharing class DefaultRecipientResolver implements RecipientResolver {

	private static final Set<String> RESOLVABLE_TYPES = new Set<String> {
		'account', 'case', 'contact', 'lead', 'opportunity'
	};

	private static final Set<String> SEARCHABLE_TYPES = new Set<String> {
		'contact', 'lead', 'user'
	};

	public Boolean canResolveRecipients(final String sObjectType) {
		return String.isNotBlank(sObjectType) && RESOLVABLE_TYPES.contains(sObjectType.trim().toLowerCase());
	}

	public Boolean canSearchRecipients(final String sObjectType) {
		return String.isNotBlank(sObjectType) && SEARCHABLE_TYPES.contains(sObjectType.trim().toLowerCase());
	}

	private static List<Recipient> getAccountRecipients(final Set<Id> accountIds) {
		Permissions.verifyIsQueryable('Contact', new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });
		Permissions.verifyIsQueryable('Account', new List<String> { 'Id', 'Name' });

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
		Permissions.verifyIsQueryable('Contact', new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });
		Permissions.verifyIsQueryable('Case', new List<String> { 'Id', 'CaseNumber' });

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
		Permissions.verifyIsQueryable('Contact', new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });
		Permissions.verifyIsQueryable('Account', new List<String> { 'Id', 'Name' });

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
		Permissions.verifyIsQueryable('Lead', new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });

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
		Permissions.verifyIsQueryable('Contact', new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });
		Permissions.verifyIsQueryable('OpportunityContactRole', new List<String> { 'Role' });
		Permissions.verifyIsQueryable('Account', new List<String> { 'Id', 'Name' });

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

	public List<Recipient> getRecipients(final String sObjectType, final Set<Id> sObjectIds) {
		List<Recipient> result = null;
		String t = String.isBlank(sObjectType) ? null : sObjectType.trim();
		if (t == 'Account') {
			result = getAccountRecipients(sObjectIds);
		} else if (t == 'Case') {
			result = getCaseRecipients(sObjectIds);
		} else if (t == 'Contact') {
			result = getContactRecipients(sObjectIds);
		} else if (t == 'Lead') {
			result = getLeadRecipients(sObjectIds);
		} else if (t == 'Opportunity') {
			result = getOpportunityRecipients(sObjectIds);
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveRecipientSource_1,
				new List<String> { sObjectType }));
		}
		return result;
	}

	/***************************************************************************************************************
	 * READ BEFORE MODIFYING THE searchContacts, searchLeads, OR searchUsers METHODS:
	 * 1. Some Shield orgs encrypt names. Must use dynamic SOQL (Database.query) to avoid compilation issues.
	 * 2. Matching any part of string (%_%) is VERY inefficient and will be painfully slow or break on orgs with
	 * 	lots of records. Matching the first part (_%) is better.
	 **************************************************************************************************************/

	private static List<Recipient> searchContacts(final String name) {
		Permissions.verifyIsQueryable('Contact', new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });
		Permissions.verifyIsQueryable('Account', new List<String> { 'Id', 'Name' });

		List<Recipient> recipients = new List<Recipient>();
		String q = 'SELECT Id, Name, Email, Phone, MobilePhone, Account.Id, Account.Name FROM Contact WHERE Name LIKE :name';
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

	private static List<Recipient> searchLeads(final String name) {
		Permissions.verifyIsQueryable('Lead', new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });

		List<Recipient> recipients = new List<Recipient>();
		String q = 'SELECT Id, Name, Email, Phone, MobilePhone FROM Lead WHERE Name LIKE :name';
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

	private static List<Recipient> searchUsers(final String name) {
		Permissions.verifyIsQueryable('User', new List<String> { 'Id', 'Name', 'Email', 'Phone', 'MobilePhone' });

		List<Recipient> recipients = new List<Recipient>();
		String q = 'SELECT Id, Name, Email, Phone, MobilePhone FROM User WHERE Name LIKE :name';
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

	private static String getSearchTerm(final String name, final SearchBehavior behavior) {
		String result;
		if (behavior == SearchBehavior.MatchExact) {
			result = name;
		} else if (behavior == SearchBehavior.MatchAny) {
			result = '%' + name + '%'; // This is super inefficient, so avoid if possible.
		} else { // MatchBeginning
			result = name + '%';
		}
		return result;
	}

	public List<Recipient> searchRecipients(final String sObjectType, final String name,
		final SearchBehavior behavior) {

		if (String.isBlank(name)) throw new DocuSignException(Label.UndefinedArgument);

		List<Recipient> result = null;
		String t = String.isBlank(sObjectType) ? null : sObjectType.trim();
		if (t == 'Contact') {
			result = searchContacts(getSearchTerm(name, behavior));
		} else if (t == 'Lead') {
			result = searchLeads(getSearchTerm(name, behavior));
		} else if (t == 'User') {
			result = searchUsers(getSearchTerm(name, behavior));
		} else {
			throw new DocuSignException(String.format(Label.CannotResolveRecipientSource_1,
				new List<String> { sObjectType }));
		}
		return result;
	}
}
