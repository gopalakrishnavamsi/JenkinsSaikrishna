public with sharing class EnvelopeResponse extends RemoteActionResponse {

	public Envelope envelope { get; private set; }
	public String url { get; private set; }

	private EnvelopeResponse(
		final Boolean success,
		final List<APIError> errors,
		final Envelope envelope,
		final String url) {

		super(success, errors);

		this.envelope = envelope;
		this.url = url;
	}

	public static EnvelopeResponse failure(final Exception ex) {
		return failure(new List<APIError> { APIError.fromException(ex) });
	}

	public static EnvelopeResponse failure(final List<APIError> errors) {
		return new EnvelopeResponse(false, errors, null, null);
	}

	public static EnvelopeResponse success(final Envelope envelope) {
		return new EnvelopeResponse(true, null, envelope, null);
	}

	public static EnvelopeResponse navigateTo(final String url) {
		return new EnvelopeResponse(true, null, null, url);
	}
}
