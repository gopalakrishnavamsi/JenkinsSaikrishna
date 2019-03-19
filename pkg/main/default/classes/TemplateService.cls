/**
 * Primary interface point for DocuSign for Salesforce template management.
 */
global with sharing class TemplateService {
	/**
	 * Retrieves all DocuSign templates.
	 *
	 * @return A list of DocuSign templates.
	 */
	global static List<Template> getTemplates() {
		Permissions.verifyIsDocuSignUser();

		try {
			return TemplateAPI.getInstance().getTemplates();
		} finally {
			Credentials.save();
		}
	}

	/**
	 * Retrieves a DocuSign template.
	 *
	 * @param templateId The DocuSign template ID.
	 *
	 * @return The DocuSign template.
	 */
	global static Template getTemplate(final UUID templateId) {
		Permissions.verifyIsDocuSignUser();

		try {
			return TemplateAPI.getInstance().getTemplate(templateId);
		} finally {
			Credentials.save();
		}
	}
}