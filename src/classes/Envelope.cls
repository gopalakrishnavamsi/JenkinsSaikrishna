public class Envelope {

	public Id id { get; private set; }
	public String name { get; private set; }
	public UUID docuSignId { get; private set; }
	public Id envelopeConfigurationId { get; private set; }
	public List<Document> documents { get; private set; }
	public List<Recipient> recipients { get; private set; }
	public List<CustomField> customFields { get; private set; }
	public Notifications notifications { get; private set; }
	public String emailSubject { get; private set; }
	public String emailMessage { get; private set; }
	public Entity source { get; private set; }
	public DateTime sent { get; private set; }
	public Boolean isSent {
		get {
			return sent != null && sent <= DateTime.now();
		}
	}
	public Boolean hasTemplates {
		get {
			if (documents != null) {
				for (Document d : documents) {
					if (d.templateId != null) {
						return true;
					}
				}
			}
			return false;
		}
	}

	public Envelope(
		final Id id,
		final String name,
		final UUID docuSignId,
		final Id envelopeConfigurationId,
		final List<Document> documents,
		final List<Recipient> recipients,
		final List<CustomField> customFields,
		final Notifications notifications,
		final String emailSubject,
		final String emailMessage,
		final Entity source,
		final DateTime sent) {

		this.id = id;
		this.name = name;
		this.docuSignId = docuSignId;
		this.envelopeConfigurationId = envelopeConfigurationId;
		this.documents = documents;
		this.recipients = recipients;
		this.customFields = customFields;
		this.notifications = notifications;
		this.emailSubject = emailSubject;
		this.emailMessage = emailMessage;
		this.source = source;
		this.sent = sent;
	}

	public class Notifications {

		public Boolean remind { get; private set; }
		public Integer remindAfterDays { get; private set; }
		public Integer remindFrequencyDays { get; private set; }
		public Boolean expires { get; private set; }
		public Integer expireAfterDays { get; private set; }
		public Integer expireWarnDays { get; private set; }
		public Boolean updateChatter { get; private set; }

		public Notifications(final Boolean remind, final Integer remindAfterDays, final Integer remindFrequencyDays,
			final Boolean expires, final Integer expireAfterDays, final Integer expireWarnDays,
			final Boolean updateChatter) {

			this.remind = remind;
			this.remindAfterDays = remindAfterDays;
			this.remindFrequencyDays = remindFrequencyDays;
			this.expires = expires;
			this.expireAfterDays = expireAfterDays;
			this.expireWarnDays = expireWarnDays;
			this.updateChatter = updateChatter;
		}
	}

	public class Options {

		public Boolean sendNow { get; private set; }
		public Boolean includeDefaultAnchorTabs { get; private set; }
		public Boolean fetchDocuments { get; private set; }
		public Boolean useAccountNotificationDefaults { get; private set; }

		public Options(
			final Boolean sendNow,
			final Boolean includeDefaultAnchorTabs,
			final Boolean fetchDocuments,
			final Boolean useAccountNotificationDefaults) {

			this.sendNow = sendNow;
			this.includeDefaultAnchorTabs = includeDefaultAnchorTabs;
			this.fetchDocuments = fetchDocuments;
			this.useAccountNotificationDefaults = useAccountNotificationDefaults;
		}
	}

	public static Envelope convert(final Envelope__c e) {
		if (e == null) return null;

		return new Envelope(
			e.Id,
			e.Name,
			UUID.tryParse(e.DocuSignId__c),
			e.EnvelopeConfiguration__c,
			null,
			null,
			null,
			new Notifications(
				e.Remind__c,
				Integer.valueOf(e.RemindAfterDays__c),
				Integer.valueOf(e.RemindFrequencyDays__c),
				e.Expires__c,
				Integer.valueOf(e.ExpireAfterDays__c),
				Integer.valueOf(e.ExpireWarnDays__c),
				e.UpdateChatter__c),
			e.EmailSubject__c,
			e.EmailMessage__c,
			e.SourceId__c == null ? null : new Entity(e.SourceId__c),
			e.Sent__c);
	}
}
