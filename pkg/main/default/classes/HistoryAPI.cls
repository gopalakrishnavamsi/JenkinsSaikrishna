public with sharing class HistoryAPI extends ScmAPI {

	private static HistoryAPI self = null;
	@TestVisible
	private Set<String> userEmails = new Set<String>();
	@TestVisible
	private Set<String> contactEmails = new Set<String>();
	@TestVisible
	private Map<UUID, List<APIHistoryItems>> documentIdToAPIHistoryItems = new Map<UUID, List<APIHistoryItems>>();
	@TestVisible
	private Map<String, User> emailToUser = new Map<String, User>();
	@TestVisible
	private Map<String, Contact> emailToContact = new Map<String, Contact>();
	private static final Long SCM_OFFSET = 20L;
	private static final Integer BUFFER_SOQL_LIMIT = 5;

	private HistoryAPI(
		final Url baseUrl,
		final String apiVersion,
		final UUID accountId) {

		super(new Url(baseUrl, String.format('{0}/{1}/',
			new List<String> {
				apiVersion,
				String.valueOf(accountId)
			})));
	}

	public static HistoryAPI getInstance() {
		if (self == null) {
			Url baseUrl = AccountProducts.getInstance().getScmMergeBaseUrl();
			if (baseUrl == null) throw new DocuSignException(Label.NegotiateNotConfigured);
			self = new HistoryAPI(
				baseUrl,
				'v1',
				Credentials.getInstance().account.id);
		}
		return self;
	}

	@TestVisible
	private class APIActor {
		public String fullName;
		public String emailAddress;
	}

	@TestVisible
	private class APIUser {
		public String Email;
		public String FirstName;
		public String LastName;
		public String href;
	}

	@TestVisible
	private class APIData {
		public String documentName;
		public String documentOldName;
		public String versionNumber;
		public String documentUid;
		public String emailSubject;
		public String emailMessage;
		public APIActor actor;
		public APIActor reviewer;
		public List<APIActor> approvers;
		public APIUser user;
		public String comments;
	}

	@TestVisible
	private class APIHistoryItem {
		public APIData data;
		public String actionType;
		public Datetime createdDate;

		public AgreementHistoryItem convertAPIHistoryItem(final UUID documentId, Map<String, User> emailToUser, Map<String, Contact> emailToContact) {
			AgreementHistoryItem.Actor actor = new AgreementHistoryItem.Actor(
				'',
				'',
				'');
			List<AgreementHistoryItem.Actor> recipients = new List<AgreementHistoryItem.Actor>();
			String previewUrl = getAgreementPreviewLink(documentId.toString());

			if (this.data != null) {
				String baseURL = Salesforce.baseUrl.toExternalForm() + '/' ;

				if (this.data.actor != null && this.actionType != null) {

					//When Actor is User (Default)
					//Scenario 1 : When Action Type should map to salesforce  contact however contact is not in salesforce
					//Scenario 2 : For  All other action type
					User resolvedUser = emailToUser.containsKey(this.data.actor.emailAddress) ? emailToUser.get(this.data.actor.emailAddress) : null;
					actor = generateActorFromUser(this.data.actor, resolvedUser, baseURL);

					Boolean isActionTypeMapToSalesforceContact =
						(this.actionType.equals(AgreementHistoryItem.ExternalReviewCompletedDocumentAndComments)
							|| this.actionType.equals(AgreementHistoryItem.ExternalReviewCompletedCheckoutCancelled)
							|| this.actionType.equals(AgreementHistoryItem.ExternalReviewCompletedDocumentCheckin));

					//for action types where external review has been completed the actor should map to Salesforce contact
					//once DocumentCheckIn action item type provides the correct actor we will update the if condition to include DocumentCheckIn action Item check as well
					//actor = (isActionTypeMapToSalesforceContact) ? generateActorFromContact(this.data.actor, baseURL) : (Actor)generateActorFromUser(this.data.actor, baseURL);
					if (isActionTypeMapToSalesforceContact) {
						Contact resolvedContact = emailToContact.containsKey(this.data.actor.emailAddress) ? emailToContact.get(this.data.actor.emailAddress) : null;
						actor = generateActorFromContact(this.data.actor, resolvedContact, baseURL);
					}
				}

				if (this.data.reviewer != null) {
					Contact resolvedContact = emailToContact.get(this.data.reviewer.emailAddress);
					recipients.add(generateActorFromContact(this.data.reviewer, resolvedContact, baseURL));
				}

				if (this.data.approvers != null && !this.data.approvers.isEmpty()) {
					for (APIActor a : this.data.approvers) {
						User resolvedUser = emailToUser.containsKey(a.emailAddress) ? emailToUser.get(a.emailAddress) : null;
						recipients.add(generateActorFromUser(a, resolvedUser, baseURL));
					}
				}
			}
			return new AgreementHistoryItem(
				this.actionType,
				UserInfo.getUserEmail(),
				this.createdDate,
				this.data.emailSubject,
				this.data.emailMessage,
				this.data.documentName,
				this.data.versionNumber != null ? this.data.versionNumber : null,
				this.data.documentOldName != null ? this.data.documentOldName : null,
				this.data.documentName,
				actor,
				recipients,
				previewUrl,
				this.data.comments);
		}

		@TestVisible
		private String getAgreementPreviewLink(final String agreementId) {
			UUID agreementUId = UUID.parse(agreementId);
			PageReference agreementView = Page.AgreementPreview;
			agreementView.getParameters().put('sourceId', EncodingUtil.urlEncode(UserInfo.getUserId(), StringUtils.ENCODING));
			agreementView.getParameters().put('agreementId', EncodingUtil.urlEncode(agreementUId.value, StringUtils.ENCODING));
			return agreementView.getUrl();
		}

		@TestVisible
		private AgreementHistoryItem.Actor generateActorFromContact(HistoryAPI.APIActor actor, Contact resolvedContact, String baseURL) {
			return new AgreementHistoryItem.Actor(
				(resolvedContact != null && resolvedContact.Name != null) ? resolvedContact.Name : '',
				actor.emailAddress,
				(resolvedContact != null && resolvedContact.Id != null) ? baseURL + resolvedContact.Id : '');
		}

		@TestVisible
		private AgreementHistoryItem.Actor generateActorFromUser(HistoryAPI.APIActor actor, User resolvedUser, String baseURL) {

			return new AgreementHistoryItem.Actor(
				actor.fullName,
				actor.emailAddress,
				resolvedUser != null ? baseURL + resolvedUser.Id : '');
		}

		@TestVisible
		private Set<String> prepareUserEmails(APIData data, Set<String> userEmails) {
			if (data.actor != null && data.actor.emailAddress != null) {
				userEmails.add(data.actor.emailAddress);
			}
			if (data.approvers != null && !data.approvers.isEmpty()) {
				for (APIActor a : this.data.approvers) {
					if (a.emailAddress == null) {
						continue;
					}
					userEmails.add(a.emailAddress);
				}
			}
			return userEmails;
		}

		@TestVisible
		private Set<String> prepareContactEmails(APIData data, Set<String> contactEmails) {

			if (data.actor != null && data.actor.emailAddress != null) {
				contactEmails.add(data.actor.emailAddress);
			}
			if (data.reviewer != null && data.reviewer.emailAddress != null) {
				contactEmails.add(data.reviewer.emailAddress);
			}
			return contactEmails;
		}
	}

	@TestVisible
	private class APIHistoryItems {
		public List<APIHistoryItem> items;
		public String next;
	}

	// TODO: Avoid the void.
	public void prepareHistoryItems(final UUID documentId) {
		this.prepareHistoryItems(
			documentId,
			RestAPI.defaultTimeout);
	}

	public void prepareHistoryItems(
		final UUID documentId,
		final Integer timeout) {

		List<HistoryAPI.APIHistoryItems> resultAPIHistoryItems = new List<HistoryAPI.APIHistoryItems>();

		RestAPI.Response response = this.get(
			new List<Object> { 'historyitems', documentId },
			new QueryString('limit', String.valueOf(SCM_OFFSET)),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get history items for documentId - ' +
				documentId + response.error);
			throw new APIException(response.error);
		}
		APIHistoryItems result = (APIHistoryItems)JSON.deserialize(response.body, APIHistoryItems.class);
		for (APIHistoryItem a : result.items) {
			if (a != null && a.data != null) {
				userEmails = a.prepareUserEmails(a.data, userEmails);
				contactEmails = a.prepareContactEmails(a.data, contactEmails);
			}
		}
		resultAPIHistoryItems.add(result);
		documentIdToAPIHistoryItems.put(documentId, resultAPIHistoryItems);
	}

	@TestVisible
	private void populateEmailToUser(Set<String> userEmails) {
		try {
			Set<String> queryEmails = new Set<String>();
			for (String userEmail : userEmails) {
				if (emailToUser.containsKey(userEmail)) {
					continue;
				}
				queryEmails.add(userEmail);
			}
			if (queryEmails.size() > 0) {
				for (User u : [SELECT Id, Email FROM User WHERE Email IN :queryEmails AND IsActive = TRUE]) {
					emailToUser.put(u.Email, u);
				}
			}
		} catch (Exception ex) {
			this.log.error('Failed to resolve salesforce user in history items ' + ex.getMessage());
		}
	}

	@TestVisible
	private void populateEmailToContact(Set<String> contactEmails) {
		try {
			Set<String> queryEmails = new Set<String>();
			for (String contactEmail : contactEmails) {
				if (emailToContact.containsKey(contactEmail)) {
					continue;
				}
				queryEmails.add(contactEmail);
			}
			if (queryEmails.size() > 0) {
				for (Contact con : [SELECT Id, Name, Email FROM Contact WHERE Email IN :queryEmails]) {
					emailToContact.put(con.Email, con);
				}
			}
		} catch (Exception ex) {
			this.log.error('Failed to resolve salesforce contact in history items ' + ex.getMessage());
		}
	}

	// TODO: Why is this business logic in the API client?
	public Map<UUID, List<AgreementHistoryItem>> processHistoryItems() {
		Map<UUID, List<AgreementHistoryItem>> documentIdToAgreementHistoryItems
			= new Map<UUID, List<AgreementHistoryItem>>();
		Boolean isQueryEligible = Limits.getQueries() < (Limits.getLimitQueries() - BUFFER_SOQL_LIMIT);
		if (userEmails != null && userEmails.size() > 0 && isQueryEligible) {
			populateEmailToUser(userEmails);
		}
		if (contactEmails != null && contactEmails.size() > 0 && isQueryEligible) {
			populateEmailToContact(contactEmails);
		}
		for (UUID documentId : documentIdToAPIHistoryItems.keySet()) {
			documentIdToAgreementHistoryItems.put(documentId, getAgreementHistoryItems(documentId));
		}
		return documentIdToAgreementHistoryItems;
	}

	private List<AgreementHistoryItem> getAgreementHistoryItems(final UUID documentId) {
		List<AgreementHistoryItem> historyItems = new List<AgreementHistoryItem>();
		for (APIHistoryItems apiHistoryItems : documentIdToAPIHistoryItems.get(documentId)) {
			for (APIHistoryItem a : apiHistoryItems.items) {
				if (a != null && a.data != null) {
					historyItems.add(a.convertAPIHistoryItem(documentId, emailToUser, emailToContact));
				}
			}
		}
		return historyItems;
	}

	public List<AgreementHistoryItem> getHistoryItems(final UUID documentId) {
		return this.getHistoryItems(
			documentId,
			RestAPI.defaultTimeout);
	}

	public List<AgreementHistoryItem> getHistoryItems(
		final UUID documentId,
		final Integer timeout) {

		List<AgreementHistoryItem> historyItems = new List<AgreementHistoryItem>();
		Long offset = -SCM_OFFSET;
		String next = '';

		while (next != null) {
			offset += SCM_OFFSET;

			RestAPI.Response response = this.get(
				new List<Object> { 'historyitems', documentId },
				new QueryString('offset', String.valueOf(offset)),
				timeout);
			if (response.hasError) {
				this.log.error('Failed to get history items for documentId - ' +
					documentId + response.error);
				throw new APIException(response.error);
			}
			APIHistoryItems result = (APIHistoryItems)JSON.deserialize(response.body, APIHistoryItems.class);
			for (APIHistoryItem a : result.items) {
				if (a != null && a.data != null) {
					userEmails = a.prepareUserEmails(a.data, userEmails);
					contactEmails = a.prepareContactEmails(a.data, contactEmails);
				}
			}
			Boolean isQueryEligible = Limits.getQueries() < (Limits.getLimitQueries() - BUFFER_SOQL_LIMIT);
			if (userEmails != null && userEmails.size() > 0 && isQueryEligible) {
				populateEmailToUser(userEmails);
			}
			if (contactEmails != null && contactEmails.size() > 0 && isQueryEligible) {
				populateEmailToContact(contactEmails);
			}
			for (APIHistoryItem a : result.items) {
				if (a != null && a.data != null) {
					historyItems.add(a.convertAPIHistoryItem(documentId, emailToUser, emailToContact));
				}
			}
			next = result.next;
		}
		// catch some errors here
		return historyItems;
	}

	@TestVisible
	private class APIHref {
		public String href;

		public APIHref(final String href) {
			this.href = href;
		}
	}

	// FIXME: resendEmailType leaks API implementation details.
	public Boolean resendRequest(
		final String documentHref,
		final String resendEmailType) {

		return this.resendRequest(
			documentHref,
			resendEmailType,
			RestAPI.defaultTimeout);
	}

	public Boolean resendRequest(
		final String documentHref,
		final String resendEmailType,
		final Integer timeout) {

		RestAPI.Response response = this.post(
			new List<String> { 'emails' },
			JSON.serialize(new Map<String, Object> {
				'Document' => new APIHref(documentHref),
				'ResendEmailType' => resendEmailType
			}),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to resend request: ' + response.error);
			throw new APIException(response.error);
		}

		return response.statusCode == 200 ;
	}
}
