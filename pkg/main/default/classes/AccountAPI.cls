public with sharing class AccountAPI extends ESignatureAPI {

	private static AccountAPI self = null;
	private static final String ACCOUNT_LACKS_PERMISSIONS = 'ACCOUNT_LACKS_PERMISSIONS';
	private static List<CustomField> accountCustomFields = null;
	private List<SigningGroup> sgs = null;

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
	private class APIViewResponse {
		public String url;
	}

	public Url getConsoleViewUrl() {
		return this.getConsoleViewUrl(RestAPI.defaultTimeout);
	}

	public Url getConsoleViewUrl(final Integer timeout) {
		RestAPI.Response response = this.post(
			new List<Object> { 'views', 'console' },
			'{"suppressNavigation":"true"}',
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get console view: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return new Url(((APIViewResponse)JSON.deserialize(response.body, APIViewResponse.class)).url);
	}

	// Serialization objects for custom fields
	@TestVisible
	private class APIListCustomField {
		public String name;
		public String required;
		public String show;
		public String value;
		public List<String> listItems;

		public CustomField toCustomField() {
			return CustomField.newListField(name, value, listItems, StringUtils.parseBoolean(required),
				StringUtils.parseBoolean(show));
		}
	}

	@TestVisible
	private class APITextCustomField {
		public String name;
		public String required;
		public String show;
		public String value;

		public CustomField toCustomField() {
			return CustomField.newTextField(name, value, StringUtils.parseBoolean(required),
				StringUtils.parseBoolean(show));
		}
	}

	@TestVisible
	private class APICustomFields {
		public List<APITextCustomField> textCustomFields;
		public List<APIListCustomField> listCustomFields;

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

	public List<CustomField> getCustomFields() {
		return this.getCustomFields(RestAPI.defaultTimeout);
	}

	public List<CustomField> getCustomFields(final Integer timeout) {
		if (accountCustomFields == null) {
			RestAPI.Response response = this.get(
				'custom_fields',
				timeout);
			if (response.hasError) {
				this.log.error('Failed to get get custom fields: ' + response.error.toString());
				throw new APIException(response.error);
			}

			accountCustomFields = ((APICustomFields)JSON.deserialize(response.body, APICustomFields.class))
				.toCustomFields();
		}
		return accountCustomFields;
	}

	@TestVisible
	private class APISigningGroupMember {
		public String userName;
		public String email;

		private SigningGroup.Member toMember() {
			return new SigningGroup.Member(userName, email);
		}
	}

	@TestVisible
	private class APISigningGroup {
		public String signingGroupId;
		public String groupName;
		public List<APISigningGroupMember> users;

		private SigningGroup toSigningGroup() {
			final List<SigningGroup.Member> members = new List<SigningGroup.Member>();
			if (users != null) {
				for (APISigningGroupMember u : users) {
					members.add(u.toMember());
				}
			}
			return new SigningGroup(Integer.valueOf(signingGroupId), groupName, members);
		}
	}

	@TestVisible
	private class APISigningGroups {
		public List<APISigningGroup> groups;

		private List<SigningGroup> toSigningGroups() {
			final List<SigningGroup> sgs = new List<SigningGroup>();
			if (groups != null) {
				for (APISigningGroup sg : groups) {
					sgs.add(sg.toSigningGroup());
				}
			}
			return sgs;
		}
	}

	public List<SigningGroup> getSigningGroups() {
		return getSigningGroups(RestAPI.defaultTimeout);
	}

	public List<SigningGroup> getSigningGroups(final Integer timeout) {
		if (this.sgs == null) {
			RestAPI.Response response = this.get(
				'signing_groups',
				new QueryString('include_users', 'true'),
				timeout);
			if (response.hasError) {
				final String body = response.body;
				if (response.statusCode == APIErrorCode.BAD_REQUEST
					&& body.containsIgnoreCase(ACCOUNT_LACKS_PERMISSIONS)) {

					this.sgs = new List<SigningGroup>();
					throw new APIException(new APIError(APIErrorCode.ACCOUNT_LACKS_PERMISSIONS,
						Label.SigningGroupsProhibited));
				} else {
					// TODO: Localize error description
					throw new APIException(response.error);
				}
			}

			this.sgs = ((APISigningGroups)JSON.deserialize(response.body, APISigningGroups.class)).toSigningGroups();
		}
		return this.sgs;
	}

	@TestVisible
	private class APIMergeField {
		public String configurationType;
		public String path;
		public String writeBack;
		public String allowSenderToEdit;

		public APIMergeField(final Tab tab) {
			if (tab != null) {
				this.configurationType = 'salesforce';
				this.path = tab.path;
				this.writeBack = String.valueOf(tab.writeBack);
				this.allowSenderToEdit = String.valueOf(tab.allowSenderToEdit);
			}
		}
	}

	@TestVisible
	private class APITab {
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
		public APIMergeField mergeField;

		public APITab(final Tab tab) {
			if (tab != null) {
				this.customTabId = String.valueOf(tab.id);
				this.type = tab.type;
				this.name = tab.name;
				this.tabLabel = tab.key;
				this.mergeField = new APIMergeField(tab);
				this.anchor = tab.autoPlaceText;
			}
		}

		public Tab toTab() {
			return new Tab(
				UUID.tryParse(this.customTabId),
				this.type,
				this.name,
				this.tabLabel,
				this.mergeField == null ? null : this.mergeField.path,
				this.mergeField == null ? null : StringUtils.parseBoolean(this.mergeField.writeBack),
				this.mergeField == null ? null : StringUtils.parseBoolean(this.mergeField.allowSenderToEdit),
				this.anchor);

		}
	}

	@TestVisible
	private class APITabs {
		public List<APITab> tabs;

		public List<Tab> toTabs() {
			List<Tab> result = new List<Tab>();
			if (this.tabs != null) {
				for (APITab t : this.tabs) {
					if (t != null) result.add(t.toTab());
				}
			}
			return result;
		}
	}

	public List<Tab> getTabs() {
		return this.getTabs(RestAPI.defaultTimeout);
	}

	public List<Tab> getTabs(final Integer timeout) {
		RestAPI.Response response = this.get(
			'tab_definitions',
			new QueryString('custom_tab_only', 'true'),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get custom fields: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return ((APITabs)JSON.deserialize(response.body, APITabs.class)).toTabs();
	}

	public Tab saveTab(final Tab tab) {
		return this.saveTab(tab, RestAPI.defaultTimeout);
	}

	public Tab saveTab(
		final Tab tab,
		final Integer timeout) {

		if (tab == null) throw new DocuSignException(Label.UndefinedArgument);

		RestAPI.Response response;
		if (UUID.isEmpty(tab.id)) {
			// Create new custom field
			response = this.post(
				'tab_definitions',
				JSON.serialize(new APITab(tab)),
				timeout);
		} else {
			// Update existing custom field
			response = this.put(
				new List<Object> { 'tab_definitions', tab.id },
				JSON.serialize(new APITab(tab)),
				timeout);
		}

		if (response.hasError) {
			this.log.error('Failed to save custom tab: ' + response.error.toString());
			throw new APIException(response.error);
		}

		return ((APITab)JSON.deserialize(response.body, APITab.class)).toTab();
	}

	public Boolean deleteTab(final UUID tabId) {
		return deleteTab(tabId, RestAPI.defaultTimeout);
	}

	public Boolean deleteTab(
		final UUID tabId,
		final Integer timeout) {

		if (tabId == null) throw new DocuSignException(Label.UndefinedArgument);

		RestAPI.Response response = this.del(
			new List<Object> { 'tab_definitions', tabId },
			timeout);
		if (response.hasError && response.error != APIError.notFound) {
			this.log.error('Failed to delete custom tab: ' + response.error);
			throw new APIException(response.error);
		}

		return response.error == APIError.none;
	}

	public Long getEveryoneGroupId() {
		return this.getEveryoneGroupId(RestAPI.defaultTimeout);
	}

	public Long getEveryoneGroupId(final Integer timeout) {
		RestAPI.Response response = this.get(
			'groups',
			new QueryString('group_type', 'everyoneGroup'),
			timeout);
		if (response.hasError && response.error != APIError.notFound) {
			this.log.error('Failed to retrieve Everyone group ID: ' + response.error);
			throw new APIException(response.error);
		}

		Long result = null;
		Map<String, Object> resp = (Map<String, Object>)JSON.deserializeUntyped(response.body);
		if (resp != null) {
			Map<String, Object> g = (Map<String, Object>)Collection.head((List<Object>)resp.get('groups'));
			if (g != null) result = Long.valueOf((String)g.get('groupId'));
		}
		return result;
	}
}
