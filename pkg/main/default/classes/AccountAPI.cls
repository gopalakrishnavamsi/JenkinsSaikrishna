public with sharing class AccountAPI extends ESignatureAPI {

	private static AccountAPI self = null;
	private static final String SUCCESS = 'SUCCESS';
	private static final String USER_ALREADY_EXISTS_IN_ACCOUNT = 'USER_ALREADY_EXISTS_IN_ACCOUNT';
	private static final String USER_DOES_NOT_EXIST = 'USER_DOES_NOT_EXIST_IN_SYSTEM';
	private static final String INVALID_USERID = 'INVALID_USERID';
	private static List<CustomField> accountCustomFields = null;

	private Account account = null;

	private AccountAPI(
		final Url baseUrl,
		final UUID accountId) {

		super(baseUrl, 'v2', accountId);
	}

	public static AccountAPI getInstance() {
		if (self == null) {
			Credentials c = Credentials.getInstance();
			self = new AccountAPI(c.environment.eSignatureBaseUrl, c.account.id);
		}
		return self;
	}

	@TestVisible
	override protected APIError getError(final HttpResponse response) {
		APIError e = super.getError(response);
		if (e != APIError.none && e instanceof ESignatureAPI.Error) {
			ESignatureAPI.Error dse = (ESignatureAPI.Error)e;
			if (dse.docuSignCode == USER_ALREADY_EXISTS_IN_ACCOUNT) {
				e = new APIError(APIErrorCode.USER_ALREADY_EXISTS_IN_ACCOUNT, dse.description);
			} else if (dse.docuSignCode == USER_DOES_NOT_EXIST || dse.docuSignCode == INVALID_USERID) {
				e = new APIError(APIErrorCode.UNKNOWN_USER, dse.description);
			}
		}
		return e;
	}

	// Serialization objects for getAccount
	@TestVisible
	private class APIAccount {
		public String currentPlanId;
		public String planName;
		public String planStartDate;
		public String planEndDate;
		public String billingPeriodStartDate;
		public String billingPeriodEndDate;
		public String accountName;
		public String accountIdGuid;
		public String externalAccountId;
		public String connectPermission;
		public String suspensionStatus;
		public String suspensionDate;

		public Account toExternalForm() {
			Date psd = StringUtils.parseDate(this.planStartDate);
			Date sd = String.isBlank(this.suspensionDate) ? null : StringUtils.parseDate(this.suspensionDate);
			return new Account(
				UUID.parse(this.accountIdGuid),
				String.isBlank(this.externalAccountId) ? null : Long.valueOf(this.externalAccountId),
				this.accountName,
				new Account.Plan(
					UUID.parse(this.currentPlanId),
					this.planName,
					psd,
					StringUtils.parseDate(this.planEndDate)),
				new Account.Billing(
					sd == null ? StringUtils.parseDate(this.billingPeriodStartDate) : psd,
					sd == null ? StringUtils.parseDate(this.billingPeriodEndDate) : sd),
				stringToConnectPermission(this.connectPermission));
		}
	}

	public Account getAccount() {
		return this.getAccount(RestAPI.defaultTimeout);
	}

	public Account getAccount(final Integer timeout) {
		if (this.account == null) {
			final RestAPI.Response response = this.get(
				'',
				timeout);
			if (response.hasError) {
				this.log.error('Failed to read account: ' + response.error);
				throw new APIException(response.error);
			}

			this.account = ((AccountAPI.APIAccount)JSON.deserialize(response.body, AccountAPI.APIAccount.class))
				.toExternalForm();
			if (this.account != null) {
				this.account = this.addPlanId(account, timeout);
			}
		}
		return this.account;
	}

	// Serialization object for account billing plan
	@TestVisible
	private class PlanId {
		public String planId;
	}

	@TestVisible
	private class BillingPlans {
		public PlanId billingPlan;
	}

	@TestVisible
	// HACK: Workaround for API-900. Need to call another API to get the correct planId :(
	private Account addPlanId(final Account account, final Integer timeout) {
		final RestAPI.Response response = this.get(
			'billing_plan',
			timeout);
		if (response.hasError) {
			this.log.error('Failed to read account billing plan: ' + response.error);
			throw new APIException(response.error);
		}

		final BillingPlans billing = (BillingPlans)JSON.deserialize(response.body, BillingPlans.class);
		if (billing == null || billing.billingPlan == null || String.isBlank(billing.billingPlan.planId)) {
			this.log.error('API returned no plan ID.');
			return account;
		}

		return account.withPlanId(UUID.parse(billing.billingPlan.planId));
	}

	@TestVisible
	private class ViewResponse {
		public String url;
	}

	public Url getConsoleViewUrl() {
		return this.getConsoleViewUrl(RestAPI.defaultTimeout);
	}

	public Url getConsoleViewUrl(final Integer timeout) {
		final RestAPI.Response response = this.post(
			new List<Object> { 'views', 'console' },
			'{"suppressNavigation":"true"}',
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get console view: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return new Url(((ViewResponse)JSON.deserialize(response.body, ViewResponse.class)).url);
	}

	@TestVisible
	private class Setting {
		public String name;
		public String value;

		public Setting(final String name, final String value) {
			this.name = name;
			this.value = value;
		}
	}

	@TestVisible
	private static Account.ConnectPermission stringToConnectPermission(final String s) {
		if (s == 'full') {
			return Account.ConnectPermission.Full;
		} else if (s == 'sendOnly') {
			return Account.ConnectPermission.SendOnly;
		} else {
			return Account.ConnectPermission.None;
		}
	}

	@TestVisible
	private class APIUser {
		public String userId;
		public String email;
		public String firstName;
		public String lastName;
		public String userName;
		public List<Setting> userSettings;
		public String userStatus;
		public String apiPassword;
		public ErrorDetails errorDetails;
		public String enableConnectForUser;
		public String countryCode;
		public String subscribe;

		public APIUser(final Account.User user) {
			this.userId = String.valueOf(user.id);
			this.email = user.email;
			this.firstName = user.firstName;
			this.lastName = user.lastName;
			this.userName = user.firstName + ' ' + user.lastName;
			this.userSettings = new List<Setting> {
				new Setting('canManageAccount', String.valueOf(user.canManageAccount)),
				new Setting('canSendEnvelope', 'true')
			};
			this.userStatus = user.status;
		}

		private APIError errorExternalForm() {
			APIError e;
			if (errorDetails == null || String.isBlank(errorDetails.errorCode) || errorDetails.errorCode == SUCCESS) {
				e = APIError.none;
			} else if (errorDetails.errorCode == USER_ALREADY_EXISTS_IN_ACCOUNT) {
				e = new APIError(APIErrorCode.USER_ALREADY_EXISTS_IN_ACCOUNT, errorDetails.message);
			} else if (errorDetails.errorCode == USER_DOES_NOT_EXIST || errorDetails.errorCode == INVALID_USERID) {
				e = new APIError(APIErrorCode.UNKNOWN_USER, errorDetails.message);
			} else {
				e = new APIError(APIErrorCode.BAD_REQUEST, String.format('[{0}] {1}',
					new List<String> { errorDetails.errorCode, errorDetails.message }));
			}
			return e;
		}

		public Account.User toExternalForm(final Id sourceId, final Boolean canManageAccount) {
			Boolean isAdmin = canManageAccount;
			if (this.userSettings != null) {
				for (Setting s : this.userSettings) {
					if (s.name == 'canManageAccount') {
						isAdmin = StringUtils.parseBoolean(s.value);
						break;
					}
				}
			}
			return new Account.User(
				UUID.tryParse(this.userId),
				sourceId,
				this.email,
				this.firstName,
				this.lastName,
				this.userStatus,
				null,
				null,
				isAdmin,
				null,
				errorExternalForm());
		}
	}

	@TestVisible
	private class NewUsers {
		public List<AccountAPI.APIUser> newUsers;

		public NewUsers(final List<Account.User> users) {
			this.newUsers = new List<APIUser>();
			if (users != null) {
				for (Account.User u : users) {
					this.newUsers.add(new APIUser(u));
				}
			}
		}

		public List<Account.User> toExternalForm(final List<Account.User> users) {
			Map<String, Account.User> emailToUsers = new Map<String, Account.User>();
			for (Account.User u : users) {
				emailToUsers.put(u.email, u);
			}
			List<Account.User> result = new List<Account.User>();
			if (this.newUsers != null) {
				for (AccountAPI.APIUser u : this.newUsers) {
					Account.User original = emailToUsers.get(u.email);
					result.add(u.toExternalForm(original == null ? null : original == null ? null : original.sourceId,
						original == null ? false : original.canManageAccount));
				}
			}
			return result;
		}
	}

	public List<Account.User> addUsers(final List<Account.User> users) {
		return this.addUsers(users, RestAPI.defaultTimeout);
	}

	public List<Account.User> addUsers(final List<Account.User> users, final Integer timeout) {
		if (Collection.isEmpty(users)) throw new DocuSignException(Label.UndefinedUsers);

		final RestAPI.Response response = this.post(
			'users',
			JSON.serialize(new NewUsers(users)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to add users: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return ((NewUsers)JSON.deserialize(response.body, NewUsers.class)).toExternalForm(users);
	}

	// Serialization objects for removeUsers
	@TestVisible
	private class RemoveUsers {
		public List<AccountAPI.APIUser> users;

		public RemoveUsers(final List<Account.User> dsUsers) {
			this.users = new List<AccountAPI.APIUser>();
			if (dsUsers != null) {
				for (Account.User u : dsUsers) {
					this.users.add(new APIUser(u));
				}
			}
		}

		public List<Account.User> toExternalForm(final List<Account.User> users) {
			Map<String, Account.User> emailToUsers = new Map<String, Account.User>();
			for (Account.User u : users) {
				emailToUsers.put(u.email, u);
			}
			List<Account.User> result = new List<Account.User>();
			if (this.users != null) {
				for (AccountAPI.APIUser u : this.users) {
					Account.User original = emailToUsers.get(u.email);
					result.add(u.toExternalForm(original == null ? null : original == null ? null : original.sourceId,
						original == null ? false : original.canManageAccount));
				}
			}
			return result;
		}
	}

	public List<Account.User> removeUsers(final List<Account.User> users) {
		return this.removeUsers(users, RestAPI.defaultTimeout);
	}

	public List<Account.User> removeUsers(final List<Account.User> users, final Integer timeout) {
		if (Collection.isEmpty(users)) throw new DocuSignException(Label.UndefinedUsers);

		final RestAPI.Response response = this.del(
			'users',
			JSON.serialize(new RemoveUsers(users)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to remove users: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return ((RemoveUsers)JSON.deserialize(response.body, RemoveUsers.class)).toExternalForm(users);
	}

	// Serialization objects for custom fields
	@TestVisible
	private class ListCustomField {
		public String name;
		public String required;
		public String show;
		public String value;
		public List<String> listItems;

		public CustomField toExternalForm() {
			return CustomField.newListField(name, value, listItems, StringUtils.parseBoolean(required),
				StringUtils.parseBoolean(show));
		}
	}

	@TestVisible
	private class TextCustomField {
		public String name;
		public String required;
		public String show;
		public String value;

		public CustomField toExternalForm() {
			return CustomField.newTextField(name, value, StringUtils.parseBoolean(required),
				StringUtils.parseBoolean(show));
		}
	}

	@TestVisible
	private class CustomFields {
		public List<TextCustomField> textCustomFields;
		public List<ListCustomField> listCustomFields;

		public List<CustomField> toExternalForm() {
			final List<CustomField> cfs = new List<CustomField>();

			if (this.textCustomFields != null) {
				for (TextCustomField cf : this.textCustomFields) {
					cfs.add(cf.toExternalForm());
				}
			}

			if (this.listCustomFields != null) {
				for (ListCustomField cf : listCustomFields) {
					cfs.add(cf.toExternalForm());
				}
			}

			return cfs;
		}
	}

	public List<CustomField> getCustomFields() {
		return this.getCustomFields(RestAPI.defaultTimeout);
	}

	public List<CustomField> getCustomFields(final Integer timeout) {
		if (accountCustomFields == null) {
			final RestAPI.Response response = this.get(
				'custom_fields',
				timeout);
			if (response.hasError) {
				this.log.error('Failed to get get custom fields: ' + response.error.toString());
				throw new APIException(response.error);
			}

			accountCustomFields = ((CustomFields)JSON.deserialize(response.body, CustomFields.class)).toExternalForm();
		}
		return accountCustomFields;
	}

	@TestVisible
	private class MergeField {
		public String configurationType;
		public String path;
		public String writeBack;
		public String allowSenderToEdit;

		public MergeField(final DocumentCustomField.MergeField dsMF) {
			if (dsMF != null) {
				this.configurationType = 'salesforce';
				this.path = dsMF.path;
				this.writeBack = String.valueOf(dsMF.writeBack);
				this.allowSenderToEdit = String.valueOf(dsMF.editable);
			}
		}

		public DocumentCustomField.MergeField toExternalForm() {
			return new DocumentCustomField.MergeField(
				path,
				StringUtils.parseBoolean(writeBack),
				StringUtils.parseBoolean(allowSenderToEdit));
		}
	}

	@TestVisible
	private class CustomTab {
		public String customTabId;
		public String tabLabel;
		public String type;
		public String anchor;
		public String shared;
		public List<String> items;
		public String lastModified;
		public String initialValue;
		public String required;
		public String locked;
		public String editable;
		public String includedInEmail;
		public String font;
		public String fontColor;
		public String fontSize;
		public String concealValueOnDocument;
		public String disableAutoSize;
		public String name;
		public String bold;
		public String italic;
		public String underline;
		public String maximumLength;
		public String validationPattern;
		public String validationMessage;
		public MergeField mergeField;

		public CustomTab(final DocumentCustomField dsCT) {
			if (dsCT != null) {
				this.customTabId = String.valueOf(dsCT.id);
				this.tabLabel = StringUtils.fromString(dsCT.label);
				this.type = dsCT.type;
				this.anchor = StringUtils.fromString(dsCT.autoPlaceText);
				this.items = dsCT.items != null ? dsCT.items : new List<String>();
				this.initialValue = StringUtils.fromString(dsCT.initialValue);
				if (dsCT.options != null) {
					DocumentCustomField.Options dsOptions = dsCT.options;
					this.shared = String.valueOf(dsOptions.shared);
					this.required = String.valueOf(dsOptions.required);
					this.locked = String.valueOf(dsOptions.readOnly);
					this.editable = String.valueOf(dsOptions.editable);
					this.includedInEmail = String.valueOf(dsOptions.includeInEmail);
				}
				if (dsCT.formatting != null) {
					final DocumentCustomField.Formatting dsFormat = dsCT.formatting;
					if (dsFormat.font != null) {
						final DocumentCustomField.Font dsFont = dsFormat.font;
						this.font = dsFont.family;
						this.fontColor = dsFont.color;
						this.fontSize = dsFont.size;
						this.bold = String.valueOf(dsFont.bold);
						this.italic = String.valueOf(dsFont.italic);
						this.underline = String.valueOf(dsFont.underline);
					}
					this.concealValueOnDocument = String.valueOf(dsFormat.masked);
					this.disableAutoSize = String.valueOf(dsFormat.fixedSize);
				}
				this.name = dsCT.tooltip;
				if (dsCT.validation != null) {
					final DocumentCustomField.Validation dsV = dsCT.validation;
					this.maximumLength = String.valueOf(dsV.maximumCharacters);
					this.validationPattern = StringUtils.fromString(dsV.regularExpression);
					this.validationMessage = StringUtils.fromString(dsV.errorMessage);
				}
				if (dsCT.mergeField != null) {
					this.mergeField = new MergeField(dsCT.mergeField);
				}
			}
		}

		public DocumentCustomField toExternalForm() {
			return new DocumentCustomField(
				UUID.tryParse(customTabId),
				tabLabel,
				type,
				mergeField == null ? null : mergeField.toExternalForm(),
				items,
				initialValue,
				new DocumentCustomField.Options(
					StringUtils.parseBoolean(required),
					StringUtils.parseBoolean(locked),
					StringUtils.parseBoolean(shared),
					StringUtils.parseBoolean(editable),
					StringUtils.parseBoolean(includedInEmail)),
				new DocumentCustomField.Formatting(
					new DocumentCustomField.Font(
						font,
						fontColor,
						fontSize,
						StringUtils.parseBoolean(bold),
						StringUtils.parseBoolean(italic),
						StringUtils.parseBoolean(underline)
					),
					StringUtils.parseBoolean(concealValueOnDocument),
					StringUtils.parseBoolean(disableAutoSize)),
				new DocumentCustomField.Validation(
					StringUtils.parseInteger(maximumLength),
					validationPattern,
					validationMessage),
				name,
				anchor,
				StringUtils.parseDatetime(lastModified));
		}
	}

	@TestVisible
	private class CustomTabs {
		public List<CustomTab> tabs;

		public List<DocumentCustomField> toExternalForm() {
			final List<DocumentCustomField> cts = new List<DocumentCustomField>();
			if (tabs != null) {
				for (CustomTab ct : tabs) {
					cts.add(ct.toExternalForm());
				}
			}
			return cts;
		}
	}

	public List<DocumentCustomField> getDocumentCustomFields() {
		return this.getDocumentCustomFields(RestAPI.defaultTimeout);
	}

	public List<DocumentCustomField> getDocumentCustomFields(final Integer timeout) {
		final RestAPI.Response response = this.get(
			'tab_definitions',
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get custom fields: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return ((CustomTabs)JSON.deserialize(response.body, CustomTabs.class)).toExternalForm();
	}

	public UUID saveDocumentCustomField(final DocumentCustomField customTab) {
		return this.saveDocumentCustomField(customTab, RestAPI.defaultTimeout);
	}

	public UUID saveDocumentCustomField(final DocumentCustomField customTab, final Integer timeout) {
		if (customTab == null) throw new DocuSignException(Label.UndefinedArgument);

		final CustomTab apiCF = new CustomTab(customTab);

		RestAPI.Response response;
		if (UUID.isEmpty(customTab.id)) {
			// Create new custom field
			response = this.post(
				'tab_definitions',
				JSON.serialize(apiCF),
				timeout);
		} else {
			// Update existing custom field
			response = this.put(
				new List<Object> { 'tab_definitions', customTab.id },
				JSON.serialize(apiCF),
				timeout);
		}

		if (response.hasError) {
			this.log.error('Failed to save custom tab: ' + response.error.toString());
			throw new APIException(response.error);
		}

		final CustomTab result = (CustomTab)JSON.deserialize(response.body, CustomTab.class);
		return UUID.parse(result.customTabId);
	}

	public Boolean deleteDocumentCustomField(final UUID customTabId) {
		return deleteDocumentCustomField(customTabId, RestAPI.defaultTimeout);
	}

	public Boolean deleteDocumentCustomField(final UUID customTabId, final Integer timeout) {
		if (customTabId == null) throw new DocuSignException(Label.UndefinedArgument);

		final RestAPI.Response response = this.del(
			new List<Object> { 'tab_definitions', customTabId },
			timeout);
		if (response.hasError) {
			this.log.error('Failed to delete custom tab: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return true;
	}
}
