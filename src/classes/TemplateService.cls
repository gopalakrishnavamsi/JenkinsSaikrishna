/**
 * Primary interface point for DocuSign for Salesforce template management.
 */
public with sharing class TemplateService {
	/**
	 * Retrieves all DocuSign templates.
	 *
	 * @return A list of DocuSign templates.
	 */
	public static List<Template> getTemplates() {
		Permissions.verifyIsDocuSignUser();

		return TemplateAPI.getInstance().getTemplates();
	}

	/**
	 * Retrieves a DocuSign template.
	 *
	 * @param templateId The DocuSign template ID.
	 *
	 * @return The DocuSign template.
	 */
	public static Template getTemplate(final UUID templateId) {
		Permissions.verifyIsDocuSignUser();

		return TemplateAPI.getInstance().getTemplate(templateId);
	}
}
