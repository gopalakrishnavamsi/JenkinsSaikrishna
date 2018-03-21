public with sharing class RecipientResponse extends RemoteActionResponse {

	public List<Recipient> recipients { get; private set; }
	public Set<Id> removedIds { get; private set; }

	private RecipientResponse(
		final Boolean success,
		final List<APIError> errors,
		final List<Recipient> recipients,
		final Set<Id> removedIds) {

		super(success, errors);

		this.recipients = recipients;
		this.removedIds = removedIds;
	}

	public static RecipientResponse failure(final Exception ex) {
		return failure(new List<APIError> { APIError.fromException(ex) });
	}

	public static RecipientResponse failure(final List<APIError> errors) {
		return new RecipientResponse(false, errors, null, null);
	}

	public static RecipientResponse success(final List<Recipient> recipients) {
		return new RecipientResponse(true, null, recipients, null);
	}

	public static RecipientResponse success(final Set<Id> removedIds) {
		return new RecipientResponse(true, null, null, removedIds == null ? new Set<Id>() : removedIds);
	}
}
