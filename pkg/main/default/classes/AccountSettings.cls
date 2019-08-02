/**
 * Account-level DocuSign for Salesforce settings.
 */
public with sharing class AccountSettings {

	private static AccountSettings self = null;
	private static final Integer DEFAULT_CALLOUT_TIMEOUT = 60000;
	/**
	 * Apex callout timeout. The default is 90 seconds.
	 */
	@AuraEnabled
	public Integer calloutTimeout { get; private set; }
	/**
	 * Salesforce entity resolvers. May be extended to resolve Salesforce objects unknown to DocuSign for Salesforce.
	 */
	@AuraEnabled
	public List<String> entityResolvers { get; private set; }
	/**
	 * DocuSign envelope document resolvers. May be extended to resolve Salesforce document types unknown to
	 * DocuSign for Salesforce.
	 */
	@AuraEnabled
	public List<String> documentResolvers { get; private set; }
	/**
	 * DocuSign envelope recipient resolvers. May be extended to resolve Salesforce recipient types unknown to
	 * DocuSign for Salesforce.
	 */
	@AuraEnabled
	public List<String> recipientResolvers { get; private set; }
	/**
	 * How to perform recipient searches. The ideal method is depended upon the subscriber org (number of contacts,
	 * platform encryption). The default search behavior is <code>DiscreteMatchBeginning</code> which allows partial
	 * matches on the beginning of first and last names. This is an efficient option for most subscriber orgs
	 * and can support deterministic platform encryption of these fields.
	 *
	 * @see Recipient.SearchBehavior for more details on search options.
	 */
	@AuraEnabled
	public String recipientSearchBehavior { get; private set; }
	/**
	 * The default sender when a user is not a member of the DocuSign account.
	 */
	@AuraEnabled
	public UUID systemSenderId { get; private set; }
	/**
	 * Whether eSignature functionality is enabled for this package. Set to <code>false</code> if using another
	 * eSignature product such as DocuSign for Salesforce.
	 */
	@AuraEnabled
	public Boolean isESignatureEnabled { get; private set; }

	public AccountSettings(
		final Integer calloutTimeout,
		final List<String> entityResolvers,
		final List<String> documentResolvers,
		final List<String> recipientResolvers,
		final String recipientSearchBehavior,
		final UUID systemSenderId,
		final Boolean isESignatureEnabled) {

		this.calloutTimeout = calloutTimeout;
		this.entityResolvers = entityResolvers;
		this.documentResolvers = documentResolvers;
		this.recipientResolvers = recipientResolvers;
		this.recipientSearchBehavior = recipientSearchBehavior;
		this.systemSenderId = systemSenderId;
		this.isESignatureEnabled = isESignatureEnabled;
	}

	public static AccountSettings getInstance() {
		if (self == null) {
			AccountSettings__c s = AccountSettings__c.getOrgDefaults();
			self = new AccountSettings(
				Integer.valueOf(s.CalloutTimeout__c),
				String.isBlank(s.EntityResolvers__c) ? new List<String>() : s.EntityResolvers__c.split(','),
				String.isBlank(s.DocumentResolvers__c) ? new List<String>() : s.DocumentResolvers__c.split(','),
				String.isBlank(s.RecipientResolvers__c) ? new List<String>() : s.RecipientResolvers__c.split(','),
				s.RecipientSearchBehavior__c,
				UUID.tryParse(s.SystemSenderId__c),
				s.IsESignatureEnabled__c == true);
		}
		return self;
	}

	public static AccountSettings save(final AccountSettings settings) {
		if (settings == null) throw new DocuSignException(Label.UndefinedArgument);

		AccountSettings__c s = AccountSettings__c.getOrgDefaults();
		s.CalloutTimeout__c = settings.calloutTimeout == null ? DEFAULT_CALLOUT_TIMEOUT : settings.calloutTimeout;
		s.EntityResolvers__c = Collection.mkString(settings.entityResolvers, ',');
		s.DocumentResolvers__c = Collection.mkString(settings.documentResolvers, ',');
		s.RecipientResolvers__c = Collection.mkString(settings.recipientResolvers, ',');
		s.RecipientSearchBehavior__c = settings.recipientSearchBehavior;
		s.SystemSenderId__c = String.valueOf(settings.systemSenderId);
		s.IsESignatureEnabled__c = settings.isESignatureEnabled == true;
		upsert s;

		self = null;
		return getInstance();
	}
}
