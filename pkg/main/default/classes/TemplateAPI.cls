/*
	Inner classes should ideally be protected so that derived classes can reuse the implementation without leaking
	API implementation details. Unfortunately Apex doesn't allow this so some of the classes must be public to reuse
	code or we have to structure our code less efficiently. In this case, we are redefining a number of serialization
	types used in common with EnvelopeAPI.
 */
public with sharing class TemplateAPI extends EnvelopeAPI {

	private static TemplateAPI self = null;
	private final Map<UUID, Template> templateMap;
	private static final Set<String> HTML_EXTENSIONS = new Set<String> { 'htm', 'html', 'adf' };

	private TemplateAPI(
		final Url baseUrl,
		final String apiVersion,
		final UUID accountId) {

		super(baseUrl, apiVersion, accountId);

		this.templateMap = new Map<UUID, Template>();
	}

	public static TemplateAPI getInstance() {
		if (self == null) {
			Credentials c = Credentials.getInstance();
			self = new TemplateAPI(
				c.environment.eSignatureBaseUrl,
				'v2.1',
				c.account.id);
		}
		return self;
	}

	@TestVisible
	private Boolean addGroupShare(
		final UUID templateId,
		final Long groupId,
		final Integer timeout) {

		if (templateId == null || groupId == null) throw new DocuSignException(Label.UndefinedArgument);

		RestAPI.Response response = this.put(
			new List<Object> { 'templates', templateId, 'groups' },
			QueryString.empty,
			JSON.serialize(new Map<String, Object> {
				'groups' => new List<Map<String, Object>> {
					new Map<String, Object> {
						'groupId' => String.valueOf(groupId)
					}
				}
			}),
			timeout);
		if (response.hasError && response.error != APIError.notFound) {
			this.log.error('Failed to add template group share: ' + response.error);
			throw new APIException(response.error);
		}

		return response.error == APIError.none;
	}

	@TestVisible
	private class APIHtmlDefinition {
		public String source;

		public APIHtmlDefinition(final String source) {
			this.source = source;
		}
	}

	//noinspection ApexUnusedDeclaration // IntelliJ IDEA gets confused about this
	@TestVisible
	private static Boolean isHtml(final Document doc) {
		return doc != null
			&& String.isNotBlank(doc.extension)
			&& HTML_EXTENSIONS.contains(doc.extension.toLowerCase());
	}

	@TestVisible
	private class APIDocument {
		public String documentId;
		public String name;
		public String fileExtension;
		public String documentBase64;
		public APIHtmlDefinition htmlDefinition;
		public String templateLocked;
		public String templateRequired;
		public String order;
		public String display;
		public ESignatureAPI.ErrorDetails errorDetails;

		public APIDocument(
			final Document doc,
			final Blob content) {

			if (doc != null && doc.type != Document.TYPE_TEMPLATE) {
				this.documentId = String.valueOf(doc.sequence);
				this.name = doc.name;
				this.fileExtension = doc.extension;
				if (content != null) {
					if (isHtml(doc)) {
						this.htmlDefinition = new APIHtmlDefinition(content.toString());
					} else {
						this.documentBase64 = EncodingUtil.base64Encode(content);
					}
				}
				this.templateLocked = String.valueOf(doc.readOnly);
				this.templateRequired = String.valueOf(doc.required);
				this.order = String.valueOf(doc.sequence);
			}
		}

		public Document toDocument(final Map<String, Document> ds) {
			Document result = ds == null ? null : ds.get(this.documentId);
			if (result == null) {
				result = new Document(
					null,
					Document.TYPE_FILE,
					String.isBlank(this.order) ? Integer.valueOf(this.documentId) : Integer.valueOf(this.order),
					this.name,
					nullIfBlank(this.fileExtension),
					null,
					StringUtils.parseBoolean(this.templateLocked),
					StringUtils.parseBoolean(this.templateRequired));
			}
			return result.withError(this.errorDetails == null ? APIError.none : this.errorDetails.toAPIError());
		}

		public APIDocument mergeWith(final APIDocument d) {
			if (d != null) {
				this.name = d.name;
				this.fileExtension = d.fileExtension;
				this.templateLocked = d.templateLocked;
				this.templateRequired = d.templateRequired;
				this.order = d.order;
				this.display = d.display;
			}
			return this;
		}
	}

	@TestVisible
	private class APISmsAuthentication {
		public List<String> senderProvidedNumbers;

		public APISmsAuthentication(final List<String> ns) {
			this.senderProvidedNumbers = ns;
		}
	}

	@TestVisible
	private class APIEmailSettings {
		public String supportedLanguage;
		public String emailSubject;
		public String emailBody;

		public APIEmailSettings(final Recipient.EmailSettings es) {
			if (es != null) {
				this.supportedLanguage = es.language;
				this.emailSubject = es.subject;
				this.emailBody = es.message;
			}
		}
	}

	//noinspection ApexUnusedDeclaration // IntelliJ IDEA gets confused about this
	private static String nullIfBlank(final String s) {
		return String.isBlank(s) ? null : s;
	}

	@TestVisible
	private class APIRecipient {
		public String recipientId;
		public String name;
		public String email;
		public String roleName;
		public String routingOrder;
		public String signingGroupId;
		public String signingGroupName;
		public String hostEmail;
		public String hostName;
		public String signerEmail;
		public String signerName;
		public List<String> customFields;
		public APIEmailSettings emailNotification;
		public String accessCode;
		public String requireIdLookup;
		public String idCheckConfigurationName;
		public APISmsAuthentication smsAuthentication;
		public String note;
		public APITabs tabs;
		public String status;
		public String deliveredDateTime;
		public String signedDateTime;
		public String declinedDateTime;
		public String declinedReason;
		public String clientUserId;
		public String templateLocked;
		public String templateRequired;
		public ESignatureAPI.ErrorDetails errorDetails;

		public APIRecipient(
			final Recipient r,
			final String documentId) {

			if (r != null) {
				this.recipientId = r.getEnvelopeRecipientId();
				if (r.type == Recipient.TYPE_IN_PERSON_SIGNER) {
					this.signerName = r.name;
					this.signerEmail = r.email == r.hostEmail ? null : r.email;
					this.hostName = r.hostName;
					this.hostEmail = r.hostEmail;
				} else {
					this.name = r.name;
					this.email = r.email;
				}
				// API requires a defined value for roleName when templates are used. Empty strings are OK.
				this.roleName = r.role == null || String.isBlank(r.role.name) ? '' : r.role.name;
				this.routingOrder = r.routingOrder == null ? '' : String.valueOf(r.routingOrder);
				this.signingGroupId = r.isSigningGroup ? String.valueOf(r.signingGroup.id) : null;
				if (Entity.isValid(r.source)) {
					String cf = CustomField.forRecipientSource(r.source.id);
					if (String.isNotBlank(cf)) this.customFields = new List<String> { cf };
				}
				this.emailNotification = r.emailSettings == null
					|| (String.isBlank(r.emailSettings.subject) && String.isBlank(r.emailSettings.message))
					? null : new APIEmailSettings(r.emailSettings);
				if (r.authentication != null) {
					this.accessCode = r.authentication.accessCode;
					this.requireIdLookup = String.valueOf(r.authentication.idCheckRequired);
					if (Collection.isNotEmpty(r.authentication.smsPhoneNumbers)) {
						this.requireIdLookup = 'true';
						this.idCheckConfigurationName = 'SMS Auth $';
						this.smsAuthentication = new APISmsAuthentication(r.authentication.smsPhoneNumbers);
					}
				}
				this.note = r.note;

				// Only add default anchor tags if role is defined and has a valid (> 0) value.
				this.tabs = new APITabs(
					documentId,
					this.recipientId,
					r.tabs);

				//setting the clientUserId property for embedded recipients
				//setting this to the Salesforce user id of the recipient
				//this will be set only for embedded recipients. If this property is set for other recipients the
				//envelope is not sent
				if (r.type == Recipient.TYPE_EMBEDDED_SIGNER) {
					this.clientUserId = Entity.isValid(r.source) ? r.source.id : null;
				}
				this.templateLocked = String.valueOf(r.readOnly);
				this.templateRequired = String.valueOf(r.required);
			}
		}

		public Recipient toRecipient(
			final String type,
			final Map<String, Recipient> recipientMap) {

			Recipient result = null;
			if (recipientMap != null && String.isNotBlank(this.recipientId)) {
				result = recipientMap.get(this.recipientId);
			}

			if (result == null) {
				result = new Recipient(
					null,
					nullIfBlank(this.recipientId),
					type,
					StringUtils.parseInteger(this.recipientId),
					StringUtils.parseInteger(this.routingOrder),
					String.isBlank(this.roleName) ? null : new Recipient.Role(this.roleName),
					type == Recipient.TYPE_IN_PERSON_SIGNER ? nullIfBlank(this.signerName) : nullIfBlank(this.name),
					type == Recipient.TYPE_IN_PERSON_SIGNER ? nullIfBlank(this.signerEmail) : nullIfBlank(this.email),
					String.isBlank(this.signingGroupId) ? null
						: new SigningGroup(
						Integer.valueOf(this.signingGroupId),
						nullIfBlank(this.signingGroupName)),
					null,
					String.isBlank(this.accessCode) && !StringUtils.parseBoolean(this.requireIdLookup) ? null
						: new Recipient.Authentication(
						nullIfBlank(this.accessCode),
						StringUtils.parseBoolean(this.requireIdLookup),
						this.smsAuthentication == null ? null : this.smsAuthentication.senderProvidedNumbers),
					nullIfBlank(this.note),
					this.emailNotification == null ? null : new Recipient.EmailSettings(
						nullIfBlank(this.emailNotification.supportedLanguage),
						Localization.getLabel(this.emailNotification.supportedLanguage),
						nullIfBlank(this.emailNotification.emailSubject),
						nullIfBlank(this.emailNotification.emailBody)),
					type == Recipient.TYPE_IN_PERSON_SIGNER ? nullIfBlank(this.hostName) : null,
					type == Recipient.TYPE_IN_PERSON_SIGNER ? nullIfBlank(this.hostEmail) : null,
					false,
					this.tabs == null ? null : this.tabs.toTabs(),
					null,
					StringUtils.parseBoolean(this.templateLocked),
					StringUtils.parseBoolean(this.templateRequired));
			}

			return result.withError(this.errorDetails == null ? APIError.none : this.errorDetails.toAPIError());
		}

		public APIRecipient mergeWith(final APIRecipient r) {
			if (r != null) {
				this.name = r.name;
				this.email = r.email;
				this.signerName = r.signerName;
				this.signerEmail = r.signerEmail;
				this.hostName = r.hostName;
				this.hostEmail = r.hostEmail;
				this.roleName = r.roleName;
				this.routingOrder = r.routingOrder;
				this.signingGroupId = r.signingGroupId;
				this.customFields = r.customFields;
				this.emailNotification = r.emailNotification;
				this.accessCode = r.accessCode;
				this.requireIdLookup = r.requireIdLookup;
				this.idCheckConfigurationName = r.idCheckConfigurationName;
				this.smsAuthentication = r.smsAuthentication;
				this.note = r.note;
				this.clientUserId = r.clientUserId;
				this.templateLocked = r.templateLocked;
				this.templateRequired = r.templateRequired;
			}
			return this;
		}
	}

	@TestVisible
	private class APIRecipientWrapper {
		public String type { get; private set; }
		public APIRecipient recipient { get; private set; }

		public APIRecipientWrapper(
			final String type,
			final APIRecipient recipient) {

			this.type = type;
			this.recipient = recipient;
		}

		public APIRecipientWrapper mergeWith(final APIRecipientWrapper r) {
			if (r != null && this.recipient != null) {
				this.type = r.type;
				if (r.recipient != null) this.recipient = this.recipient.mergeWith(r.recipient);
			}
			return this;
		}
	}

	@TestVisible
	private class APIRecipients {
		public List<APIRecipient> agents;
		public List<APIRecipient> carbonCopies;
		public List<APIRecipient> certifiedDeliveries;
		public List<APIRecipient> editors;
		public List<APIRecipient> inPersonSigners;
		public List<APIRecipient> intermediaries;
		public List<APIRecipient> signers;
		public List<APIRecipient> seals;
		public List<APIRecipient> witnesses;

		public APIRecipients(
			final List<Recipient> rs,
			final String documentId) {

			if (rs != null) {
				this.agents = new List<APIRecipient>();
				this.carbonCopies = new List<APIRecipient>();
				this.certifiedDeliveries = new List<APIRecipient>();
				this.editors = new List<APIRecipient>();
				this.inPersonSigners = new List<APIRecipient>();
				this.intermediaries = new List<APIRecipient>();
				this.seals = new List<APIRecipient>();
				this.signers = new List<APIRecipient>();
				this.witnesses = new List<APIRecipient>();
				for (Recipient r : rs) {
					if (r.type == Recipient.TYPE_AGENT) {
						this.agents.add(new APIRecipient(r, documentId));
					} else if (r.type == Recipient.TYPE_CARBON_COPY) {
						this.carbonCopies.add(new APIRecipient(r, documentId));
					} else if (r.type == Recipient.TYPE_CERTIFIED_DELIVERY) {
						this.certifiedDeliveries.add(new APIRecipient(r, documentId));
					} else if (r.type == Recipient.TYPE_EDITOR) {
						this.editors.add(new APIRecipient(r, documentId));
					} else if (r.type == Recipient.TYPE_INTERMEDIARY) {
						this.intermediaries.add(new APIRecipient(r, documentId));
					} else if (r.type == Recipient.TYPE_IN_PERSON_SIGNER) {
						this.inPersonSigners.add(new APIRecipient(r, documentId));
					} else if (r.type == Recipient.TYPE_SEAL) {
						this.seals.add(new APIRecipient(r, documentId));
					} else if (r.type == Recipient.TYPE_WITNESS) {
						this.witnesses.add(new APIRecipient(r, documentId));
					} else { // Recipient.TYPE_SIGNER and Recipient.TYPE_EMBEDDED_SIGNER
						this.signers.add(new APIRecipient(r, documentId));
					}
				}
			}
		}

		public APIRecipients(final List<APIRecipientWrapper> rs) {
			if (rs != null) {
				this.agents = new List<APIRecipient>();
				this.carbonCopies = new List<APIRecipient>();
				this.certifiedDeliveries = new List<APIRecipient>();
				this.editors = new List<APIRecipient>();
				this.inPersonSigners = new List<APIRecipient>();
				this.intermediaries = new List<APIRecipient>();
				this.seals = new List<APIRecipient>();
				this.signers = new List<APIRecipient>();
				this.witnesses = new List<APIRecipient>();
				for (APIRecipientWrapper r : rs) {
					if (r == null || String.isBlank(r.type) || r.recipient == null) continue;

					if (r.type == Recipient.TYPE_AGENT) {
						this.agents.add(r.recipient);
					} else if (r.type == Recipient.TYPE_CARBON_COPY) {
						this.carbonCopies.add(r.recipient);
					} else if (r.type == Recipient.TYPE_CERTIFIED_DELIVERY) {
						this.certifiedDeliveries.add(r.recipient);
					} else if (r.type == Recipient.TYPE_EDITOR) {
						this.editors.add(r.recipient);
					} else if (r.type == Recipient.TYPE_INTERMEDIARY) {
						this.intermediaries.add(r.recipient);
					} else if (r.type == Recipient.TYPE_IN_PERSON_SIGNER) {
						this.inPersonSigners.add(r.recipient);
					} else if (r.type == Recipient.TYPE_SEAL) {
						this.seals.add(r.recipient);
					} else if (r.type == Recipient.TYPE_WITNESS) {
						this.witnesses.add(r.recipient);
					} else { // Recipient.TYPE_SIGNER and Recipient.TYPE_EMBEDDED_SIGNER
						this.signers.add(r.recipient);
					}
				}
			}
		}

		public List<Recipient> toRecipients(final Map<String, Recipient> recipientMap) {
			List<Recipient> result = new List<Recipient>();
			if (this.agents != null) {
				for (APIRecipient r : this.agents) {
					result.add(r.toRecipient(Recipient.TYPE_AGENT, recipientMap));
				}
			}
			if (this.carbonCopies != null) {
				for (APIRecipient r : this.carbonCopies) {
					result.add(r.toRecipient(Recipient.TYPE_CARBON_COPY, recipientMap));
				}
			}
			if (this.certifiedDeliveries != null) {
				for (APIRecipient r : this.certifiedDeliveries) {
					result.add(r.toRecipient(Recipient.TYPE_CERTIFIED_DELIVERY, recipientMap));
				}
			}
			if (this.editors != null) {
				for (APIRecipient r : this.editors) {
					result.add(r.toRecipient(Recipient.TYPE_EDITOR, recipientMap));
				}
			}
			if (this.intermediaries != null) {
				for (APIRecipient r : this.intermediaries) {
					result.add(r.toRecipient(Recipient.TYPE_INTERMEDIARY, recipientMap));
				}
			}
			if (this.inPersonSigners != null) {
				for (APIRecipient r : this.inPersonSigners) {
					result.add(r.toRecipient(Recipient.TYPE_IN_PERSON_SIGNER, recipientMap));
				}
			}
			if (this.signers != null) {
				for (APIRecipient r : this.signers) {
					result.add(r.toRecipient(Recipient.TYPE_SIGNER, recipientMap));
				}
			}
			if (this.seals != null) {
				for (APIRecipient r : this.seals) {
					result.add(r.toRecipient(Recipient.TYPE_SEAL, recipientMap));
				}
			}
			if (this.witnesses != null) {
				for (APIRecipient r : this.witnesses) {
					result.add(r.toRecipient(Recipient.TYPE_WITNESS, recipientMap));
				}
			}
			result.sort();
			Integer sequence = 0;
			for (Recipient r : result) {
				r = r.withSequence(++sequence);
			}
			return result;
		}
	}

	@TestVisible
	private class APIMergeField {
		public String allowSenderToEdit;
		public String configurationType;
		public String path;
		//public String row; // TODO: Enable merge field rows.
		public String writeBack;

		public APIMergeField(final Tab tab) {
			if (tab != null) {
				this.allowSenderToEdit = String.valueOf(tab.allowSenderToEdit);
				this.configurationType = 'salesforce';
				this.path = tab.path;
				this.writeBack = String.valueOf(tab.writeBack);
			}
		}
	}

	@TestVisible
	private class APITab {
		public String customTabId;
		public String documentId;
		public String recipientId;
		public String name;
		public String tabLabel;
		public String anchorIgnoreIfNotPresent;
		public String anchorString;
		public APIMergeField mergeField;
		public String optional;
		public String value;
		public String selected; // checkbox value
		public String tabId;
		public String xPosition;
		public String yPosition;
		public String pageNumber;
		public String templateLocked;
		public String templateRequired;
		public Decimal scaleValue;
		public String anchorXOffset;
		public String anchorYOffset;
		public String anchorUnits;
		public String anchorCaseSensitive;
		public String anchorMatchWholeWord;
		public String anchorHorizontalAlignment;
		public String tabOrder;
		public String status;
		public String font;
		public String italic;
		public String bold;
		public String underline;
		public String fontColor;
		public String fontSize;
		public String conditionalParentLabel;
		public String conditionalParentValue;
		public String validationPattern;
		public String validationMessage;
		public String shared;
		public String requireInitialOnSharedChange;
		public String locked;
		public String senderRequired;
		public String requireAll;
		public List<Object> listItems;
		public Integer width;
		public Integer height;
		public Integer maxLength;
		public String groupName;
		public List<Object> radios;
		public String originalValue;
		public String concealValueOnDocument;
		public String disableAutoSize;
		public String useDash4;
		public String isPaymentAmount;
		public String formula;
		public String buttonText;
		public String requiredRead;
		public String declineReason;
		public String stampType;
		public Map<String, Object> stampTypeMetadata;
		public String hidden;
		public String roundDecimalPlaces;
		public Map<String, Object> paymentDetails;
		public ESignatureAPI.ErrorDetails errorDetails;

		public APITab(
			final String documentId,
			final String recipientId,
			final Tab t) {

			this.documentId = documentId;
			this.recipientId = recipientId;
			if (t != null) {
				if (UUID.isNotEmpty(t.id)) this.customTabId = String.valueOf(t.id);
				this.name = String.isBlank(documentId) ? t.name : (t.name + '_' + documentId);
				this.tabLabel = String.isBlank(t.key) ? '_DAL_ ' + this.name : t.key;
				if (String.isNotBlank(t.path)) {
					this.mergeField = new APIMergeField(t);
				}
				if (String.isNotBlank(t.autoPlaceText)) {
					this.anchorString = t.autoPlaceText;
					this.anchorIgnoreIfNotPresent = 'true';
				}
				if (t.value != null) {
					if (t.type == Tab.TYPE_CHECKBOX) {
						this.selected = String.valueOf(t.value);
					} else if (t.value instanceof Datetime) {
						this.value = StringUtils.formatDatetime((Datetime)t.value);
					} else {
						this.value = String.valueOf(t.value);
					}
				}
			}
		}

		@TestVisible
		private Object convertValue(final String type) {
			// Don't try to convert values of a type that makes no sense to Salesforce
			if (!Tab.isValidMergeFieldType(type)) return null;

			Object result = null;
			if (type == Tab.TYPE_NUMBER || type == Tab.TYPE_FORMULA) {
				result = StringUtils.parseDecimal(this.value);
			} else if (type == Tab.TYPE_CHECKBOX) {
				result = StringUtils.parseBoolean(this.selected);
			} else if (type == Tab.TYPE_DATE || type == Tab.TYPE_DATE_SIGNED) {
				result = StringUtils.parseDate(this.value);
			} else { // text type--just use string value
				result = this.value;
			}
			return result;
		}

		public Tab toTab(final String type) {
			return new Tab(
				UUID.tryParse(this.customTabId),
				type,
				nullIfBlank(this.name),
				this.tabLabel,
				this.mergeField == null ? null : nullIfBlank(this.mergeField.path),
				this.mergeField == null ? null : StringUtils.parseBoolean(this.mergeField.writeBack),
				this.mergeField == null ? null : StringUtils.parseBoolean(this.mergeField.allowSenderToEdit),
				this.anchorString)
				.withValue(convertValue(type));

		}
	}

	private static APITabs addTabs(
		final APITabs apiTabs,
		final String documentId,
		final String recipientId,
		final List<Tab> tabs) {

		for (Tab t : tabs) {
			if (t == null) continue;

			if (t.type == Tab.TYPE_APPROVE) {
				apiTabs.approveTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_CHECKBOX) {
				apiTabs.checkboxTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_COMPANY) {
				apiTabs.companyTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_DATE_SIGNED) {
				apiTabs.dateSignedTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_DATE) {
				apiTabs.dateTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_DECLINE) {
				apiTabs.declineTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_EMAIL_ADDRESS) {
				apiTabs.emailAddressTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_EMAIL) {
				apiTabs.emailTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_ENVELOPE_ID) {
				apiTabs.envelopeIdTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_FIRST_NAME) {
				apiTabs.firstNameTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_FORMULA) {
				apiTabs.formulaTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_FULL_NAME) {
				apiTabs.fullNameTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_INITIAL_HERE) {
				apiTabs.initialHereTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_LAST_NAME) {
				apiTabs.lastNameTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_LIST) {
				apiTabs.listTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_NOTARIZE) {
				apiTabs.notarizeTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_NOTE) {
				apiTabs.noteTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_NUMBER) {
				apiTabs.numberTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_RADIO_GROUP) {
				apiTabs.radioGroupTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_SIGNER_ATTACHMENT) {
				apiTabs.signerAttachmentTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_SIGN_HERE) {
				apiTabs.signHereTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_SMART_SECTION) {
				apiTabs.smartSectionTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_SSN) {
				apiTabs.ssnTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_TITLE) {
				apiTabs.titleTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_VIEW) {
				apiTabs.viewTabs.add(new APITab(documentId, recipientId, t));
			} else if (t.type == Tab.TYPE_ZIP) {
				apiTabs.zipTabs.add(new APITab(documentId, recipientId, t));
			} else { // Text
				apiTabs.textTabs.add(new APITab(documentId, recipientId, t));
			}
		}

		return apiTabs;
	}

	@TestVisible
	private class APITabs {
		public List<APITab> approveTabs;
		public List<APITab> checkboxTabs;
		public List<APITab> companyTabs;
		public List<APITab> dateSignedTabs;
		public List<APITab> dateTabs;
		public List<APITab> declineTabs;
		public List<APITab> emailAddressTabs;
		public List<APITab> emailTabs;
		public List<APITab> envelopeIdTabs;
		public List<APITab> firstNameTabs;
		public List<APITab> formulaTabs;
		public List<APITab> fullNameTabs;
		public List<APITab> initialHereTabs;
		public List<APITab> lastNameTabs;
		public List<APITab> listTabs;
		public List<APITab> notarizeTabs;
		public List<APITab> noteTabs;
		public List<APITab> numberTabs;
		public List<APITab> radioGroupTabs;
		public List<APITab> signerAttachmentTabs;
		public List<APITab> signHereTabs;
		public List<APITab> smartSectionTabs;
		public List<APITab> ssnTabs;
		public List<APITab> textTabs;
		public List<APITab> titleTabs;
		public List<APITab> viewTabs;
		public List<APITab> zipTabs;

		public APITabs() {
			this.approveTabs = new List<APITab>();
			this.checkboxTabs = new List<APITab>();
			this.companyTabs = new List<APITab>();
			this.dateSignedTabs = new List<APITab>();
			this.dateTabs = new List<APITab>();
			this.declineTabs = new List<APITab>();
			this.emailAddressTabs = new List<APITab>();
			this.emailTabs = new List<APITab>();
			this.envelopeIdTabs = new List<APITab>();
			this.firstNameTabs = new List<APITab>();
			this.formulaTabs = new List<APITab>();
			this.fullNameTabs = new List<APITab>();
			this.initialHereTabs = new List<APITab>();
			this.lastNameTabs = new List<APITab>();
			this.listTabs = new List<APITab>();
			this.notarizeTabs = new List<APITab>();
			this.noteTabs = new List<APITab>();
			this.numberTabs = new List<APITab>();
			this.radioGroupTabs = new List<APITab>();
			this.signerAttachmentTabs = new List<APITab>();
			this.signHereTabs = new List<APITab>();
			this.smartSectionTabs = new List<APITab>();
			this.ssnTabs = new List<APITab>();
			this.textTabs = new List<APITab>();
			this.titleTabs = new List<APITab>();
			this.viewTabs = new List<APITab>();
			this.zipTabs = new List<APITab>();
		}

		public APITabs(
			final String documentId,
			final String recipientId,
			final List<Tab> tabs) {

			this();

			if (tabs != null) addTabs(this, documentId, recipientId, tabs);
		}

		public List<Tab> toTabs() {
			List<Tab> result = new List<Tab>();
			if (this.approveTabs != null) {
				for (APITab t : this.approveTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_APPROVE));
				}
			}
			if (this.checkboxTabs != null) {
				for (APITab t : this.checkboxTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_CHECKBOX));
				}
			}
			if (this.companyTabs != null) {
				for (APITab t : this.companyTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_COMPANY));
				}
			}
			if (this.dateSignedTabs != null) {
				for (APITab t : this.dateSignedTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_DATE_SIGNED));
				}
			}
			if (this.dateTabs != null) {
				for (APITab t : this.dateTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_DATE));
				}
			}
			if (this.declineTabs != null) {
				for (APITab t : this.declineTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_DECLINE));
				}
			}
			if (this.emailAddressTabs != null) {
				for (APITab t : this.emailAddressTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_EMAIL_ADDRESS));
				}
			}
			if (this.emailTabs != null) {
				for (APITab t : this.emailTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_EMAIL));
				}
			}
			if (this.envelopeIdTabs != null) {
				for (APITab t : this.envelopeIdTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_ENVELOPE_ID));
				}
			}
			if (this.firstNameTabs != null) {
				for (APITab t : this.firstNameTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_FIRST_NAME));
				}
			}
			if (this.formulaTabs != null) {
				for (APITab t : this.formulaTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_FORMULA));
				}
			}
			if (this.fullNameTabs != null) {
				for (APITab t : this.fullNameTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_FULL_NAME));
				}
			}
			if (this.initialHereTabs != null) {
				for (APITab t : this.initialHereTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_INITIAL_HERE));
				}
			}
			if (this.lastNameTabs != null) {
				for (APITab t : this.lastNameTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_LAST_NAME));
				}
			}
			if (this.listTabs != null) {
				for (APITab t : this.listTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_LIST));
				}
			}
			if (this.notarizeTabs != null) {
				for (APITab t : this.notarizeTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_NOTARIZE));
				}
			}
			if (this.noteTabs != null) {
				for (APITab t : this.noteTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_NOTE));
				}
			}
			if (this.numberTabs != null) {
				for (APITab t : this.numberTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_NUMBER));
				}
			}
			if (this.radioGroupTabs != null) {
				for (APITab t : this.radioGroupTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_RADIO_GROUP));
				}
			}
			if (this.signerAttachmentTabs != null) {
				for (APITab t : this.signerAttachmentTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_SIGNER_ATTACHMENT));
				}
			}
			if (this.signHereTabs != null) {
				for (APITab t : this.signHereTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_SIGN_HERE));
				}
			}
			if (this.smartSectionTabs != null) {
				for (APITab t : this.smartSectionTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_SMART_SECTION));
				}
			}
			if (this.ssnTabs != null) {
				for (APITab t : this.ssnTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_SSN));
				}
			}
			if (this.textTabs != null) {
				for (APITab t : this.textTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_TEXT));
				}
			}
			if (this.titleTabs != null) {
				for (APITab t : this.titleTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_TITLE));
				}
			}
			if (this.viewTabs != null) {
				for (APITab t : this.viewTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_VIEW));
				}
			}
			if (this.zipTabs != null) {
				for (APITab t : this.zipTabs) {
					if (t != null) result.add(t.toTab(Tab.TYPE_ZIP));
				}
			}
			return result;
		}
	}

	@TestVisible
	private class APIListCustomField {
		public String name;
		public String required;
		public String show;
		public String value;
		public List<String> listItems;
		public String fieldId;
		public ESignatureAPI.ErrorDetails errorDetails;

		public APIListCustomField(final CustomField cf) {
			if (cf != null) {
				this.name = cf.name;
				this.required = String.valueOf(cf.required);
				this.show = String.valueOf(cf.show);
				this.value = cf.value;
				this.listItems = cf.items;
			}
		}

		public CustomField toCustomField() {
			return CustomField.newListField(
				this.name,
				String.isBlank(this.value) ? null : this.value,
				this.listItems,
				StringUtils.parseBoolean(this.required),
				StringUtils.parseBoolean(this.show));
		}
	}

	@TestVisible
	private class APITextCustomField {
		public String name;
		public String required;
		public String show;
		public String value;
		public String fieldId;
		public ESignatureAPI.ErrorDetails errorDetails;

		public APITextCustomField(
			final String name,
			final String value,
			final Boolean required,
			final Boolean show) {

			this.name = name;
			this.value = value;
			this.required = String.valueOf(required);
			this.show = String.valueOf(show);
		}

		public APITextCustomField(final CustomField cf) {
			if (cf != null) {
				this.name = cf.name;
				this.required = String.valueOf(cf.required);
				this.show = String.valueOf(cf.show);
				this.value = cf.value;
			}
		}

		public CustomField toCustomField() {
			return CustomField.newTextField(
				this.name,
				String.isBlank(this.value) ? null : this.value,
				StringUtils.parseBoolean(this.required),
				StringUtils.parseBoolean(this.show));
		}
	}

	@TestVisible
	private class APICustomFields {
		public List<APITextCustomField> textCustomFields;
		public List<APIListCustomField> listCustomFields;

		public APICustomFields(
			final List<APITextCustomField> textCustomFields,
			final List<APIListCustomField> listCustomFields) {

			this.textCustomFields = textCustomFields;
			this.listCustomFields = listCustomFields;
		}

		public List<CustomField> toCustomFields() {
			final List<CustomField> cfs = new List<CustomField>();

			if (this.textCustomFields != null) {
				for (APITextCustomField cf : this.textCustomFields) {
					cfs.add(cf.toCustomField());
				}
			}

			if (this.listCustomFields != null) {
				for (APIListCustomField cf : listCustomFields) {
					cfs.add(cf.toCustomField());
				}
			}

			return cfs;
		}
	}

	@TestVisible
	private class APIExpirations {
		public String expireEnabled;
		public String expireAfter;
		public String expireWarn;

		public APIExpirations(
			final Boolean expires,
			final Integer expireAfterDays,
			final Integer expireWarnDays) {

			this.expireEnabled = String.valueOf(expires);
			this.expireAfter = String.valueOf(expireAfterDays);
			this.expireWarn = String.valueOf(expireWarnDays);
		}
	}

	@TestVisible
	private class APIReminders {
		public String reminderEnabled;
		public String reminderDelay;
		public String reminderFrequency;

		public APIReminders(
			final Boolean remind,
			final Integer remindAfterDays,
			final Integer remindFrequencyDays) {

			this.reminderEnabled = String.valueOf(remind);
			this.reminderDelay = String.valueOf(remindAfterDays);
			this.reminderFrequency = String.valueOf(remindFrequencyDays);
		}
	}

	@TestVisible
	private class APINotifications {
		public APIReminders reminders;
		public APIExpirations expirations;
		public String useAccountDefaults;

		public APINotifications(final Notifications notifications) {
			if (notifications == null) {
				this.useAccountDefaults = 'true';
			} else {
				this.reminders = new APIReminders(
					notifications.remind,
					notifications.remindAfterDays,
					notifications.remindFrequencyDays);
				this.expirations = new APIExpirations(
					notifications.expires,
					notifications.expireAfterDays,
					notifications.expireWarnDays);
				this.useAccountDefaults = 'false';
			}
		}

		public Notifications toNotifications() {
			Boolean isRemindDefined = this.reminders != null;
			Boolean isExpireDefined = this.expirations != null;
			return new Notifications(
				isRemindDefined ? Boolean.valueOf(this.reminders.reminderEnabled) : false,
				isRemindDefined ? Integer.valueOf(this.reminders.reminderDelay) : null,
				isRemindDefined ? Integer.valueOf(this.reminders.reminderFrequency) : null,
				isExpireDefined ? Boolean.valueOf(this.expirations.expireEnabled) : false,
				isExpireDefined ? Integer.valueOf(this.expirations.expireAfter) : null,
				isExpireDefined ? Integer.valueOf(this.expirations.expireWarn) : null);
		}
	}

	@TestVisible
	private class APITemplate {
		public String templateId;
		public String name;
		public String lastModified;
		public APICustomFields customFields;
		public List<APIDocument> documents;
		public APIRecipients recipients;
		public String emailBlurb;
		public String emailSubject;
		public APINotifications notification;
		public APITabs tabs;

		public APITemplate(
			final Template template,
			final Map<String, Blob> documentContent,
			final Boolean forUpdate) {

			if (template != null) {
				this.templateId = String.valueOf(template.id);
				this.name = template.name;
				if (String.isNotBlank(template.emailSubject)) this.emailSubject = template.emailSubject;
				if (String.isNotBlank(template.emailMessage)) this.emailBlurb = template.emailMessage;
				this.notification = new APINotifications(template.notifications);
				if (!forUpdate && Collection.isNotEmpty(template.documents)) {
					this.documents = new List<APIDocument>();
					for (Document d : template.documents) {
						this.documents.add(new APIDocument(d,
							d.type != Document.TYPE_TEMPLATE && String.isNotBlank(d.sourceId)
								? documentContent.get(d.sourceId) : null));
					}
				}
				if (!forUpdate && Collection.isNotEmpty(template.recipients)) {
					this.recipients = new APIRecipients(template.recipients, null);
				}
				if (template.customFields != null) { // Add user-defined custom fields
					List<APITextCustomField> textCustomFields = new List<APITextCustomField>();
					List<APIListCustomField> listCustomFields = new List<APIListCustomField>();
					for (CustomField cf : template.customFields) {
						if (cf != null) {
							if (cf.type == 'text') {
								textCustomFields.add(new APITextCustomField(cf));
							} else {
								listCustomFields.add(new APIListCustomField(cf));
							}
						}
					}
					this.customFields = new APICustomFields(
						textCustomFields,
						listCustomFields);
				}
			}
		}

		public Template toTemplate() {
			List<Document> docs = new List<Document>();
			if (this.documents != null) {
				for (APIDocument d : this.documents) {
					docs.add(d.toDocument(null));
				}
			}

			return new Template(
				UUID.tryParse(this.templateId),
				this.name,
				this.customFields == null ? new List<CustomField>() : this.customFields.toCustomFields(),
				this.notification == null ? null : this.notification.toNotifications(),
				nullIfBlank(this.emailSubject),
				nullIfBlank(this.emailBlurb),
				docs,
				this.recipients == null ? new List<Recipient>() : this.recipients.toRecipients(null),
				StringUtils.parseDatetime(this.lastModified));
		}

		private Map<String, APITextCustomField> mapTextCustomFields() {
			Map<String, APITextCustomField> result = new Map<String, APITextCustomField>();
			if (this.customFields != null && this.customFields.textCustomFields != null) {
				for (APITextCustomField cf : this.customFields.textCustomFields) {
					if (cf == null || String.isBlank(cf.name)) continue;

					result.put(cf.name, cf);
				}
			}
			return result;
		}

		private Map<String, APIListCustomField> mapListCustomFields() {
			Map<String, APIListCustomField> result = new Map<String, APIListCustomField>();
			if (this.customFields != null && this.customFields.listCustomFields != null) {
				for (APIListCustomField cf : this.customFields.listCustomFields) {
					if (cf == null || String.isBlank(cf.name)) continue;

					result.put(cf.name, cf);
				}
			}
			return result;
		}

		public APITemplate mergeCustomFields(final APITemplate other) {
			if (other != null) {
				Map<String, APITextCustomField> thisTcfs = this.mapTextCustomFields();
				Map<String, APITextCustomField> otherTcfs = other.mapTextCustomFields();
				for (String name : Collection.intersection(thisTcfs.keySet(), otherTcfs.keySet())) {
					thisTcfs.get(name).fieldId = otherTcfs.get(name).fieldId;
				}

				Map<String, APIListCustomField> thisLcfs = this.mapListCustomFields();
				Map<String, APIListCustomField> otherLcfs = other.mapListCustomFields();
				for (String name : Collection.intersection(thisLcfs.keySet(), otherLcfs.keySet())) {
					thisLcfs.get(name).fieldId = otherLcfs.get(name).fieldId;
				}
			}
			return this;
		}
	}

	@TestVisible
	private APITemplate getTemplateInternal(
		final UUID templateId,
		final Integer timeout) {

		RestAPI.Response response = this.get(
			new List<Object> {
				'templates', templateId
			},
			new QueryString('include', 'custom_fields,notifications,recipients,documents'),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get template: ' + response.error);
			throw new APIException(response.error);
		}

		return (APITemplate)JSON.deserialize(response.body, APITemplate.class);
	}

	public Template createTemplate(
		final Template template,
		final Long shareGroupId) {

		return this.createTemplate(template, shareGroupId, RestAPI.defaultTimeout);
	}

	public Template createTemplate(
		final Template template,
		final Long shareGroupId,
		final Integer timeout) {

		if (template == null || shareGroupId == null) throw new DocuSignException(Label.UndefinedArgument);

		RestAPI.Response response = this.post(
			'templates',
			JSON.serialize(
				new APITemplate(
					template,
					this.getDocumentContent(
						template.documents,
						false), // TODO: Enable template document fetch. Requires Core change.
					false),
				true),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to create templates: ' + response.error);
			throw new APIException(response.error);
		}

		Map<String, Object> resp = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		Template result = template
			.withId(UUID.tryParse((String)resp.get('templateId')))
			.withLastModified(Datetime.now());

		if (result.id != null) addGroupShare(result.id, shareGroupId, timeout);

		return result;
	}

	@TestVisible
	private class APITemplateListResult {
		public String templateId;
		public String name;
		public APICustomFields customFields;
		public APINotifications notification;
		public String emailSubject;
		public String emailBlurb;
		public APIRecipients recipients;
		public String lastModified;

		public Template toTemplate() {
			return new Template(
				UUID.parse(this.templateId),
				nullIfBlank(this.name),
				this.customFields == null ? new List<CustomField>() : this.customFields.toCustomFields(),
				this.notification == null ? null : this.notification.toNotifications(),
				nullIfBlank(this.emailSubject),
				nullIfBlank(this.emailBlurb),
				this.recipients == null ? new List<Recipient>() : this.recipients.toRecipients(null),
				StringUtils.parseDatetime(this.lastModified));
		}
	}

	@TestVisible
	private class APITemplates {
		public String resultSetSize;
		public String startPosition;
		public String endPosition;
		public String totalSetSize;
		public List<APITemplateListResult> envelopeTemplates;

		public List<Template> toTemplates() {
			final List<Template> templates = new List<Template>();
			if (this.envelopeTemplates != null) {
				for (APITemplateListResult t : this.envelopeTemplates) {
					templates.add(t.toTemplate());
				}
			}
			return templates;
		}
	}

	public List<Template> getTemplates() {
		return this.getTemplates(RestAPI.defaultTimeout);
	}

	// TODO: Refactor to only search templates by partial name.
	// TODO: This API supports paging, but unclear what is default or max limit.
	public List<Template> getTemplates(final Integer timeout) {
		RestAPI.Response response = this.get(
			'templates',
			new QueryString(new Map<String, String> {
				'include' => 'custom_fields,shared_template_folders,notifications,recipients',
				'order_by' => 'name',
				'order' => 'asc'
			}),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get templates: ' + response.error.toString());
			throw new APIException(response.error);
		}

		List<Template> templates = ((APITemplates)JSON.deserialize(response.body, APITemplates.class)).toTemplates();
		for (Template t : templates) {
			templateMap.put(t.id, t);
		}
		return templates;
	}

	public Template getTemplate(final UUID templateId) {
		return this.getTemplate(templateId, RestAPI.defaultTimeout);
	}

	public Template getTemplate(
		final UUID templateId,
		final Integer timeout) {

		if (templateMap.containsKey(templateId)) return templateMap.get(templateId);

		APITemplate template = getTemplateInternal(templateId, timeout);
		Template result = template == null ? null : template.toTemplate();
		if (result != null) templateMap.put(result.id, result);

		return result;
	}

	@TestVisible
	private class APIViewRequest {
		public String returnUrl;
		public Boolean suppressNavigation;

		public APIViewRequest(final Url returnUrl) {
			this.returnUrl = returnUrl == null ? null : returnUrl.toExternalForm();
			this.suppressNavigation = true;
		}
	}

	@TestVisible
	private class APIViewResponse {
		public String url;

		public Url toUrl() {
			if (String.isBlank(this.url)) return null;

			// HACK: append send=1 to trigger tagger URL
			return this.url.containsIgnoreCase('send=1') ? new Url(this.url) : new Url(this.url + '&send=1');
		}
	}

	public Url getTemplateEditUrl(
		final UUID templateId,
		final Url returnUrl) {

		return this.getTemplateEditUrl(templateId, returnUrl, RestAPI.defaultTimeout);
	}

	public Url getTemplateEditUrl(
		final UUID templateId,
		final Url returnUrl,
		final Integer timeout) {

		if (UUID.isEmpty(templateId)) throw new DocuSignException(Label.UndefinedDocuSignTemplateId);

		RestAPI.Response response = this.post(
			new List<Object> { 'templates', templateId, 'views', 'edit' },
			JSON.serialize(new APIViewRequest(returnUrl), true),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get template edit view: ' + response.error.toString());
			throw new APIException(response.error);
		}
		return ((APIViewResponse)JSON.deserialize(response.body, APIViewResponse.class)).toUrl();
	}

	@TestVisible
	private class APITemplateUpdateDocuments {
		public List<APIDocument> documents;

		public APITemplateUpdateDocuments(final List<APIDocument> documents) {
			this.documents = Collection.isNotEmpty(documents) ? documents : new List<APIDocument>();
		}
	}

	@TestVisible
	private class APIDocumentsUpdate {
		public String templateId;
		public List<APIDocument> templateDocuments;

		public List<Document> toDocuments(final Map<String, Document> documentMap) {
			List<Document> result = new List<Document>();
			if (this.templateDocuments != null) {
				for (APIDocument td : this.templateDocuments) {
					if (td == null) continue;

					Document d = td.toDocument(documentMap);
					if (d != null) result.add(d);
				}
			}
			return result;
		}
	}

	// FIXME: Cannot update template document content without doing a multipart/form-data upload.
	@TestVisible
	private List<Document> addOrUpdateTemplateDocuments(
		final UUID templateId,
		final List<APIDocument> documents,
		final Map<String, Document> documentMap,
		final Integer timeout) {

		if (templateId == null) throw new DocuSignException(Label.UndefinedDocuSignTemplateId);

		RestAPI.Response response = this.put(
			new List<Object> {
				'templates', templateId, 'documents'
			},
			JSON.serialize(new APITemplateUpdateDocuments(documents), true),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to add template documents: ' + response.error);
			throw new APIException(response.error);
		}

		return ((APIDocumentsUpdate)JSON.deserialize(response.body, APIDocumentsUpdate.class))
			.toDocuments(documentMap);
	}

	@TestVisible
	private List<Document> removeTemplateDocuments(
		final UUID templateId,
		final List<APIDocument> documents,
		final Map<String, Document> documentMap,
		final Integer timeout) {

		if (templateId == null) throw new DocuSignException(Label.UndefinedDocuSignTemplateId);

		RestAPI.Response response = this.del(
			new List<Object> {
				'templates', templateId, 'documents'
			},
			JSON.serialize(new APITemplateUpdateDocuments(documents), true),
			timeout);
		if (response.hasError && response.error != APIError.notFound) {
			this.log.error('Failed to remove template documents: ' + response.error);
			throw new APIException(response.error);
		}

		return ((APIDocumentsUpdate)JSON.deserialize(response.body, APIDocumentsUpdate.class))
			.toDocuments(documentMap);
	}

	@TestVisible
	private static Map<String, APIDocument> mapTemplateDocuments(final List<APIDocument> documents) {
		Map<String, APIDocument> result = new Map<String, APIDocument>();
		if (documents == null) return result;

		for (APIDocument d : documents) {
			if (d == null || String.isBlank(d.documentId)) continue;

			result.put(d.documentId, d);
		}

		return result;
	}

	@TestVisible
	private List<Document> updateTemplateDocuments(
		final UUID templateId,
		final List<Document> newDocuments,
		final Map<String, Blob> documentContent,
		final Map<String, APIDocument> oldDocuments,
		final Integer timeout) {

		Set<String> oldIds = oldDocuments == null ? new Set<String>() : oldDocuments.keySet();
		Map<String, APIDocument> newDocuments2 = new Map<String, APIDocument>();
		Map<String, Document> documentMap = new Map<String, Document>();
		if (newDocuments != null) {
			for (Document d : newDocuments) {
				if (d == null) continue;

				// FIXME: Can only add content for new documents. Changes to existing documents requires multipart/form-data
				String documentId = String.valueOf(d.sequence);
				newDocuments2.put(
					documentId,
					new APIDocument(
						d,
						!oldIds.contains(documentId) && String.isNotBlank(d.sourceId)
							? documentContent.get(d.sourceId) : null));
				documentMap.put(documentId, d);
			}
		}

		Set<String> newIds = newDocuments2.keySet();
		List<APIDocument> toRemove = new List<APIDocument>();
		List<APIDocument> toAddOrUpdate = new List<APIDocument>();

		for (String documentId : Collection.difference(newIds, oldIds)) { // add
			APIDocument d = newDocuments2.get(documentId);
			if (d != null) toAddOrUpdate.add(d);
		}
		for (String documentId : Collection.difference(oldIds, newIds)) { // remove
			APIDocument d = oldDocuments.get(documentId);
			if (d != null) toRemove.add(d);
		}
		for (String documentId : Collection.intersection(newIds, oldIds)) { // update
			APIDocument d1 = oldDocuments.get(documentId);
			APIDocument d2 = newDocuments2.get(documentId);
			if (d1 != null && d2 != null) toAddOrUpdate.add(d1.mergeWith(d2));
		}

		List<Document> result = new List<Document>();
		if (Collection.isNotEmpty(toRemove)) {
			result.addAll(this.removeTemplateDocuments(
				templateId,
				toRemove,
				documentMap,
				timeout));
		}

		if (Collection.isNotEmpty(toAddOrUpdate)) {
			result.addAll(this.addOrUpdateTemplateDocuments(
				templateId,
				toAddOrUpdate,
				documentMap,
				timeout));
		}

		result.sort();

		List<String> errors = new List<String>();
		for (Document d : result) {
			if (d == null || d.error == null || d.error == APIError.none) continue;

			errors.add(d.error.toString());
		}
		if (Collection.isNotEmpty(errors)) {
			throw new DocuSignException(String.format('{0}\n{1}', new List<Object> {
				Label.TemplateDocumentError,
				String.join(errors, '\n')
			}));
		}

		return result;
	}

	@TestVisible
	private class APIRecipientUpdate {
		public String recipientId;
		public APITabs tabs;
		public ESignatureAPI.ErrorDetails errorDetails;

		public Recipient toRecipient(final Map<String, Recipient> rs) {
			if (rs == null || String.isBlank(this.recipientId)) return null;

			Recipient result = rs.get(this.recipientId);
			if (result != null) {
				result = result.withError(this.errorDetails == null ? APIError.none : this.errorDetails.toAPIError());
			} else {
				result = Recipient.fromSource(null, null, null, null, null)
					.withSequence(Integer.valueOf(this.recipientId))
					.withTabs(this.tabs == null ? null : this.tabs.toTabs())
					.withError(this.errorDetails == null ? APIError.none : this.errorDetails.toAPIError());
			}
			return result;
		}
	}

	@TestVisible
	private class APIRecipientUpdates {
		public List<APIRecipientUpdate> recipientUpdateResults;

		public List<Recipient> toRecipients(final Map<String, Recipient> rs) {
			List<Recipient> result = new List<Recipient>();
			if (this.recipientUpdateResults != null) {
				for (APIRecipientUpdate ru : this.recipientUpdateResults) {
					if (ru == null) continue;

					Recipient r = ru.toRecipient(rs);
					if (r != null) result.add(r);
				}
			}
			return result;
		}
	}

	@TestVisible
	private List<Recipient> addOrUpdateTemplateRecipients(
		final UUID templateId,
		final APIRecipients recipients,
		final Map<String, Recipient> recipientMap,
		final Integer timeout) {

		if (templateId == null) throw new DocuSignException(Label.UndefinedDocuSignTemplateId);

		RestAPI.Response response = this.put(
			new List<Object> {
				'templates', templateId, 'recipients'
			},
			JSON.serialize(recipients, true),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to add template recipients: ' + response.error);
			throw new APIException(response.error);
		}

		return ((APIRecipientUpdates)JSON.deserialize(response.body, APIRecipientUpdates.class))
			.toRecipients(recipientMap);
	}

	@TestVisible
	private List<Recipient> removeTemplateRecipients(
		final UUID templateId,
		final APIRecipients recipients,
		final Map<String, Recipient> recipientMap,
		final Integer timeout) {

		if (templateId == null) throw new DocuSignException(Label.UndefinedDocuSignTemplateId);

		RestAPI.Response response = this.del(
			new List<Object> {
				'templates', templateId, 'recipients'
			},
			JSON.serialize(recipients, true),
			timeout);
		if (response.hasError && response.error != APIError.notFound) {
			this.log.error('Failed to remove template recipients: ' + response.error);
			throw new APIException(response.error);
		}

		return ((APIRecipients)JSON.deserialize(response.body, APIRecipients.class))
			.toRecipients(recipientMap);
	}

	@TestVisible
	private static Map<String, APIRecipientWrapper> mapTemplateRecipients(final APIRecipients recipients) {
		Map<String, APIRecipientWrapper> result = new Map<String, APIRecipientWrapper>();
		if (recipients == null) return result;

		if (recipients.agents != null) {
			for (APIRecipient r : recipients.agents) {
				if (r == null || String.isBlank(r.recipientId)) continue;
				result.put(r.recipientId, new APIRecipientWrapper(Recipient.TYPE_AGENT, r));
			}
		}
		if (recipients.carbonCopies != null) {
			for (APIRecipient r : recipients.carbonCopies) {
				if (r == null || String.isBlank(r.recipientId)) continue;
				result.put(r.recipientId, new APIRecipientWrapper(Recipient.TYPE_CARBON_COPY, r));
			}
		}
		if (recipients.certifiedDeliveries != null) {
			for (APIRecipient r : recipients.certifiedDeliveries) {
				if (r == null || String.isBlank(r.recipientId)) continue;
				result.put(r.recipientId, new APIRecipientWrapper(Recipient.TYPE_CERTIFIED_DELIVERY, r));
			}
		}
		if (recipients.editors != null) {
			for (APIRecipient r : recipients.editors) {
				if (r == null || String.isBlank(r.recipientId)) continue;
				result.put(r.recipientId, new APIRecipientWrapper(Recipient.TYPE_EDITOR, r));
			}
		}
		if (recipients.intermediaries != null) {
			for (APIRecipient r : recipients.intermediaries) {
				if (r == null || String.isBlank(r.recipientId)) continue;
				result.put(r.recipientId, new APIRecipientWrapper(Recipient.TYPE_INTERMEDIARY, r));
			}
		}
		if (recipients.inPersonSigners != null) {
			for (APIRecipient r : recipients.inPersonSigners) {
				if (r == null || String.isBlank(r.recipientId)) continue;
				result.put(r.recipientId, new APIRecipientWrapper(Recipient.TYPE_IN_PERSON_SIGNER, r));
			}
		}
		if (recipients.signers != null) {
			for (APIRecipient r : recipients.signers) {
				if (r == null || String.isBlank(r.recipientId)) continue;
				result.put(r.recipientId, new APIRecipientWrapper(Recipient.TYPE_SIGNER, r));
			}
		}
		if (recipients.seals != null) {
			for (APIRecipient r : recipients.seals) {
				if (r == null || String.isBlank(r.recipientId)) continue;
				result.put(r.recipientId, new APIRecipientWrapper(Recipient.TYPE_SEAL, r));
			}
		}
		if (recipients.witnesses != null) {
			for (APIRecipient r : recipients.witnesses) {
				if (r == null || String.isBlank(r.recipientId)) continue;
				result.put(r.recipientId, new APIRecipientWrapper(Recipient.TYPE_WITNESS, r));
			}
		}

		return result;
	}

	@TestVisible
	private List<Recipient> updateTemplateRecipients(
		final UUID templateId,
		final List<Recipient> newRecipients,
		final Map<String, APIRecipientWrapper> oldRecipients,
		final Integer timeout) {

		Map<String, APIRecipientWrapper> newRecipients2 = new Map<String, APIRecipientWrapper>();
		Map<String, Recipient> recipientMap = new Map<String, Recipient>();
		if (newRecipients != null) {
			for (Recipient r : newRecipients) {
				if (r == null || String.isBlank(r.type)) continue;

				String recipientId = r.getEnvelopeRecipientId();
				newRecipients2.put(
					recipientId,
					new APIRecipientWrapper(
						r.type,
						new APIRecipient(
							r,
							null)));
				recipientMap.put(recipientId, r);
			}
		}

		Set<String> newIds = newRecipients2.keySet();
		Set<String> oldIds = oldRecipients == null ? new Set<String>() : oldRecipients.keySet();
		List<APIRecipientWrapper> toRemove = new List<APIRecipientWrapper>();
		List<APIRecipientWrapper> toAddOrUpdate = new List<APIRecipientWrapper>();

		for (String rId : Collection.difference(newIds, oldIds)) { // add
			APIRecipientWrapper r = newRecipients2.get(rId);
			if (r != null) toAddOrUpdate.add(r);
		}
		for (String rId : Collection.difference(oldIds, newIds)) { // remove
			APIRecipientWrapper r = oldRecipients.get(rId);
			if (r != null) toRemove.add(r);
		}
		for (String rId : Collection.intersection(newIds, oldIds)) { // update
			APIRecipientWrapper r1 = oldRecipients.get(rId);
			APIRecipientWrapper r2 = newRecipients2.get(rId);
			if (r1 != null && r2 != null) toAddOrUpdate.add(r1.mergeWith(r2));
		}

		List<Recipient> result = new List<Recipient>();
		if (Collection.isNotEmpty(toRemove)) {
			result.addAll(this.removeTemplateRecipients(
				templateId,
				new APIRecipients(toRemove),
				recipientMap,
				timeout));
		}

		if (Collection.isNotEmpty(toAddOrUpdate)) {
			result.addAll(this.addOrUpdateTemplateRecipients(
				templateId,
				new APIRecipients(toAddOrUpdate),
				recipientMap,
				timeout));
		}

		result.sort();

		List<String> errors = new List<String>();
		for (Recipient r : result) {
			if (r == null || r.error == null || r.error == APIError.none) continue;

			errors.add(String.format(Label.QueryError_2, new List<Object> {
				String.isBlank(r.email) ? r.getEnvelopeRecipientId() : r.email,
				r.error.toString()
			}));
		}
		if (Collection.isNotEmpty(errors)) {
			throw new DocuSignException(String.format('{0}\n{1}', new List<Object> {
				Label.TemplateRecipientError,
				String.join(errors, '\n')
			}));
		}

		return result;
	}

	public Template updateTemplate(final Template template) {
		return this.updateTemplate(template, RestAPI.defaultTimeout);
	}

	public Template updateTemplate(
		final Template template,
		final Integer timeout) {

		if (template == null) throw new DocuSignException(Label.UndefinedTemplate);
		if (template.id == null) throw new DocuSignException(Label.UndefinedDocuSignTemplateId);

		// Read existing template
		APITemplate oldTemplate = getTemplateInternal(template.id, timeout);

		// FIXME: Causes tags to disappear??
		updateTemplateDocuments(
			template.id,
			template.documents,
			getDocumentContent(template.documents, false),
			mapTemplateDocuments(oldTemplate.documents),
			timeout);

		updateTemplateRecipients(
			template.id,
			template.recipients,
			mapTemplateRecipients(oldTemplate.recipients),
			timeout);

		updateTemplate(
			template.id,
			new APITemplate(
				template,
				new Map<String, Blob>(),
				true)
				.mergeCustomFields(oldTemplate),
			timeout);

		return template.withLastModified(Datetime.now());
	}

	@TestVisible
	private class APITemplateUpdate {
		public ESignatureAPI.ErrorDetails errorDetails;
		public List<APIListCustomField> listCustomFieldUpdateResults;
		public List<APITextCustomField> textCustomFieldUpdateResults;
		// Not updating anything else for template: tabs, recipients, etc.

		private APIError getError(final ESignatureAPI.ErrorDetails error) {
			return error == null ? APIError.none : error.toAPIError();
		}

		public List<String> getErrors() {
			List<String> result = new List<String>();

			APIError e = getError(this.errorDetails);
			if (e != APIError.none) result.add(e.toString());

			if (this.listCustomFieldUpdateResults != null) {
				for (APIListCustomField cf : this.listCustomFieldUpdateResults) {
					if (cf == null || cf.errorDetails == null) continue;

					e = getError(cf.errorDetails);
					if (e != APIError.none) {
						result.add(String.format(Label.QueryError_2, new List<Object> {
							cf.name,
							e.toString()
						}));
					}
				}
			}

			if (this.textCustomFieldUpdateResults != null) {
				for (APITextCustomField cf : this.textCustomFieldUpdateResults) {
					if (cf == null || cf.errorDetails == null) continue;

					e = getError(cf.errorDetails);
					if (e != APIError.none) {
						result.add(String.format(Label.QueryError_2, new List<Object> {
							cf.name,
							e.toString()
						}));
					}
				}
			}

			return result;
		}
	}

	@TestVisible
	private Boolean updateTemplate(
		final UUID templateId,
		final APITemplate template,
		final Integer timeout) {

		if (templateId == null) throw new DocuSignException(Label.UndefinedDocuSignTemplateId);

		RestAPI.Response response = this.put(
			new List<Object> {
				'templates', templateId
			},
			JSON.serialize(template, true),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to update template: ' + response.error);
			throw new APIException(response.error);
		}

		APITemplateUpdate result = (APITemplateUpdate)JSON.deserialize(response.body, APITemplateUpdate.class);
		List<String> errors = result == null ? null : result.getErrors();
		if (Collection.isNotEmpty(errors)) {
			throw new DocuSignException(String.format('{0}\n{1}', new List<Object> {
				Label.TemplateError,
				String.join(errors, '\n')
			}));
		}

		return true;
	}

	public Boolean deleteTemplate(final UUID templateId) {
		return this.deleteTemplate(templateId, RestAPI.defaultTimeout);
	}

	public Boolean deleteTemplate(
		final UUID templateId,
		final Integer timeout) {

		if (templateId == null) throw new DocuSignException(Label.UndefinedDocuSignTemplateId);

		RestAPI.Response response = this.put(
			new List<Object> {
				'folders', 'recyclebin'
			},
			JSON.serialize(new Map<String, Object> {
				'envelopeIds' => new List<String> {
					String.valueOf(templateId)
				}
			}),
			timeout);
		if (response.hasError && response.error != APIError.notFound) {
			this.log.error('Failed to delete template: ' + response.error);
			throw new APIException(response.error);
		}

		return response.error == APIError.none;
	}
}
