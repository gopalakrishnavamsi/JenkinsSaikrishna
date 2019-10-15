// HACK: Use strings instead of enums to get around SFDC remoting deserialization limitation. Boo.
public class DocumentCustomField {

	private static final Map<String, String> TYPES = new Map<String, String> {
		'approve' => Label.Approve,
		'checkbox' => Label.CheckBox,
		'company' => Label.Company,
		'datesigned' => Label.DateSigned,
		'emailaddress' => Label.EmailAddress,
		'decline' => Label.Decline,
		'list' => Label.DropDown,
		'envelopeid' => Label.EnvelopeId,
		'firstname' => Label.FirstName,
		'formula' => Label.Formula,
		'fullname' => Label.FullName,
		'title' => Label.Title,
		'initialhere' => Label.InitialHere,
		'initialhereoptional' => Label.InitialHereOptional,
		'lastname' => Label.LastName,
		'note' => Label.Note,
		'signhere' => Label.SignHere,
		'signhereoptional' => Label.SignHereOptional,
		'radio' => Label.RadioButton,
		'signerattachment' => Label.SignerAttachment,
		'text' => Label.TextField
	};

	public UUID id { get; private set; }
	public String label { get; private set; }
	public String type { get; private set; }
	public String typeName { get; private set; }
	public MergeField mergeField { get; private set; }
	public List<String> items { get; private set; }
	public String initialValue { get; private set; }
	public Options options { get; private set; }
	public Formatting formatting { get; private set; }
	public Validation validation { get; private set; }
	public String tooltip { get; private set; }
	public String autoPlaceText { get; private set; }
	public Datetime lastModified { get; private set; }
	public String lastModifiedFormatted { get; private set; }

	public DocumentCustomField(final UUID id, final String label, final String type, final MergeField mergeField,
		final List<String> items, final String initialValue, final Options options,
		final Formatting formatting, final Validation validation, final String tooltip, final String autoPlaceText,
		final Datetime lastModified) {

		this.id = id;
		this.label = String.isNotBlank(label) ? label : '';
		this.type = type;
		this.typeName = String.isNotBlank(type) ? TYPES.get(type.toLowerCase()) : '';
		this.mergeField = mergeField;
		this.items = items == null ? new List<String>() : items;
		this.initialValue = initialValue;
		this.options = options == null ? new Options() : options;
		this.formatting = formatting == null ? new Formatting() : formatting;
		this.validation = validation == null ? new Validation() : validation;
		this.tooltip = tooltip;
		this.autoPlaceText = String.isNotBlank(autoPlaceText) ? autoPlaceText : '';
		this.lastModified = lastModified;
		this.lastModifiedFormatted = lastModified != null ? lastModified.formatLong() : '';
	}

	public class MergeField {
		public String path { get; private set; }
		public Boolean writeBack { get; private set; }
		public Boolean editable { get; private set; }

		public MergeField(final String path, final Boolean writeBack, final Boolean editable) {
			this.path = path;
			this.writeBack = writeBack;
			this.editable = editable;
		}
	}

	public class Options {
		public Boolean required { get; private set; }
		public Boolean readOnly { get; private set; }
		public Boolean shared { get; private set; }
		public Boolean editable { get; private set; }
		public Boolean includeInEmail { get; private set; }

		public Options() {
			this(false, false, false, false, false);
		}

		public Options(final Boolean required, final Boolean readOnly, final Boolean shared,
			final Boolean editable, final Boolean includeInEmail) {

			this.required = required;
			this.readOnly = readOnly;
			this.shared = shared;
			this.editable = editable;
			this.includeInEmail = includeInEmail;
		}
	}

	public class Font {

		public String family { get; private set; }
		public String color { get; private set; }
		public String size { get; private set; }
		public Boolean bold { get; private set; }
		public Boolean italic { get; private set; }
		public Boolean underline { get; private set; }

		public Font() {
			this('default', 'default', 'default', false, false, false);
		}

		public Font(final String family, final String color, final String size, final Boolean bold,
			final Boolean italic, final Boolean underline) {

			this.family = family;
			this.color = color;
			this.size = size;
			this.bold = bold;
			this.italic = italic;
			this.underline = underline;
		}
	}

	public class Formatting {

		public Font font { get; private set; }
		public Boolean masked { get; private set; }
		public Boolean fixedSize { get; private set; }

		public Formatting() {
			this(new Font(), false, false);
		}

		public Formatting(final Font font, final Boolean masked, final Boolean fixedSize) {
			this.font = font;
			this.masked = masked;
			this.fixedSize = fixedSize;
		}
	}

	public class Validation {

		public Integer maximumCharacters { get; private set; }
		public String regularExpression { get; private set; }
		public String errorMessage { get; private set; }

		public Validation() {
			this(null, null, null);
		}

		public Validation(final Integer maximumCharacters, final String regularExpression, final String errorMessage) {
			this.maximumCharacters = maximumCharacters;
			this.regularExpression = String.isNotBlank(regularExpression) ? regularExpression : '';
			this.errorMessage = errorMessage;
		}
	}
}