public class Tab {

	public static final String TYPE_APPROVE = 'Approve';
	public static final String TYPE_CHECKBOX = 'Checkbox';
	public static final String TYPE_COMPANY = 'Company';
	public static final String TYPE_DATE_SIGNED = 'DateSigned';
	public static final String TYPE_DATE = 'Date';
	public static final String TYPE_DECLINE = 'Decline';
	public static final String TYPE_EMAIL_ADDRESS = 'EmailAddress';
	public static final String TYPE_EMAIL = 'Email';
	public static final String TYPE_ENVELOPE_ID = 'EnvelopeId';
	public static final String TYPE_FIRST_NAME = 'FirstName';
	public static final String TYPE_FORMULA = 'Formula';
	public static final String TYPE_FULL_NAME = 'FullName';
	public static final String TYPE_INITIAL_HERE = 'InitialHere';
	public static final String TYPE_LAST_NAME = 'LastName';
	public static final String TYPE_LIST = 'List';
	public static final String TYPE_NOTARIZE = 'Notarize';
	public static final String TYPE_NOTE = 'Note';
	public static final String TYPE_NUMBER = 'Number';
	public static final String TYPE_RADIO_GROUP = 'RadioGroup';
	public static final String TYPE_SIGNER_ATTACHMENT = 'SignerAttachment';
	public static final String TYPE_SIGN_HERE = 'SignHere';
	public static final String TYPE_SMART_SECTION = 'SmartSection';
	public static final String TYPE_SSN = 'SSN';
	public static final String TYPE_TEXT = 'Text';
	public static final String TYPE_TITLE = 'Title';
	public static final String TYPE_VIEW = 'View';
	public static final String TYPE_ZIP = 'ZIP';

	@AuraEnabled
	public UUID id { get; private set; }
	@AuraEnabled
	public String type { get; private set; }
	@AuraEnabled
	public String name { get; private set; }
	@AuraEnabled
	public String path { get; private set; }
	@AuraEnabled
	public Boolean writeBack { get; private set; }
	@AuraEnabled
	public Boolean allowSenderToEdit { get; private set; }
	@AuraEnabled
	public String autoPlaceText { get; private set; }

	public Tab(
		final UUID id,
		final String type,
		final String name,
		final String path,
		final Boolean writeBack,
		final Boolean allowSenderToEdit,
		final String autoPlaceText) {

		this.id = id;
		this.type = type;
		this.name = name;
		this.path = path;
		this.writeBack = writeBack;
		this.allowSenderToEdit = allowSenderToEdit;
		this.autoPlaceText = autoPlaceText;
	}

	public static Tab newMergeField(
		final String type,
		final String path,
		final Boolean writeBack,
		final Boolean allowSenderToEdit) {

		// TODO: Validate path and set type automatically. Disable write-back if field is not updateable.
		return new Tab(
			null,
			type,
			null,
			path,
			writeBack,
			allowSenderToEdit,
			null);
	}

	public Tab withId(final UUID id) {
		this.id = id;
		return this;
	}

	public Tab withName(final String name) {
		this.name = name;
		return this;
	}

	public Tab withAutoPlaceText(final String autoPlaceText) {
		this.autoPlaceText = autoPlaceText;
		return this;
	}
}
