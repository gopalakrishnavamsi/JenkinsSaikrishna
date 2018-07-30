public with sharing class ReturnController {

	public Id sourceId { get; private set; }
	public String pathPrefix {
		get {
			return Site.getPathPrefix();
		}
	}
	@TestVisible
	private final Id envelopeId;
	public enum DocuSignAction {
		Unknown, Tag, Sign
	}
	@TestVisible
	private final DocuSignAction action;
	@TestVisible
	private final String event;

	public ReturnController() {
		this(QueryString.fromCurrentPage());
	}

	public ReturnController(final QueryString parameters) {
		this(parameters.getId(QueryString.PARAM_SOURCE_ID),
			parameters.getId(QueryString.PARAM_ENVELOPE_ID),
			parseDocuSignAction(parameters.get(QueryString.PARAM_DOCUSIGN_ACTION)),
			parameters.get('event'));
	}

	public ReturnController(final Id sourceId, final Id envelopeId, final DocuSignAction action, final String event) {
		this.sourceId = sourceId;
		this.envelopeId = envelopeId;
		this.action = action;
		this.event = event;
	}

	@TestVisible
	private static DocuSignAction parseDocuSignAction(final String s) {
		DocuSignAction result = DocuSignAction.Unknown;
		if (s == 'tag') {
			result = DocuSignAction.Tag;
		} else if (s == 'sign') {
			result = DocuSignAction.Sign;
		}
		return result;
	}

	public PageReference onReturn() {
		if (this.envelopeId != null) {
			if (this.event == 'cancel') {
				EnvelopeService.deleteEnvelope(this.envelopeId);
			} else if (this.event == 'send') {
				EnvelopeService.markEnvelopeSent(EnvelopeService.getEnvelope(this.envelopeId), true);
			}
		}
		// TODO: Handle other events, errors
		PageReference pg = new PageReference('/' + (this.sourceId == null ? '' : this.sourceId));
		pg.setRedirect(true);
		return pg;
	}
}
