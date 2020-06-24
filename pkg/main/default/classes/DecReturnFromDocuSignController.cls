public with sharing class DecReturnFromDocuSignController {

	public Id decTemplateId { get; private set; }
	@TestVisible
	private final String afterDecTaggerStep = '5';

	public DecReturnFromDocuSignController() {
		this(QueryString.fromCurrentPage());
	}

	public DecReturnFromDocuSignController(final QueryString parameters) {
		this(parameters.getId(QueryString.PARAM_SOURCE_ID));
	}

	public DecReturnFromDocuSignController(final Id decTemplateId) {
		this.decTemplateId = decTemplateId;
	}

	public PageReference onReturn() {
		PageReference redirectToDecFlow;
		if (this.decTemplateId != null) {
			redirectToDecFlow = Page.EnvelopeConfigurationNavigator;
			redirectToDecFlow.getParameters().put('id', this.decTemplateId);
			redirectToDecFlow.getParameters().put('step', this.afterDecTaggerStep);
			redirectToDecFlow.setRedirect(true);
		}
		return redirectToDecFlow;
	}
}