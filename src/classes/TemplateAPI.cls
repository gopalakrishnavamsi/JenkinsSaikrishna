public with sharing class TemplateAPI extends DocuSignAPI {

	private static TemplateAPI self = null;
	private final Map<UUID, Template> templateMap;

	@TestVisible
	private TemplateAPI(final Credentials apiCredentials) {
		super(apiCredentials);

		this.templateMap = new Map<UUID, Template>();
	}

	public static TemplateAPI getInstance() {
		if (self == null) {
			self = new TemplateAPI(Credentials.getInstance());
		}
		return self;
	}

	// Serialization objects for templates
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

	private class TemplateId {
		public String templateId;
		public String name;

		public Template toExternalForm() {
			return new Template(
				UUID.fromString(templateId),
				name,
				new List<CustomField>());
		}
	}

	private class APITemplate {
		public TemplateId envelopeTemplateDefinition;
		public CustomFields customFields;

		public Template toExternalForm() {
			return new Template(
				UUID.fromString(envelopeTemplateDefinition.templateId),
				envelopeTemplateDefinition.name,
				this.customFields == null ? new List<CustomField>() : this.customFields.toExternalForm());
		}
	}

	public Template getTemplate(final UUID templateId) {
		return getTemplate(templateId, RestAPI.defaultTimeout);
	}

	public Template getTemplate(final UUID templateId, final Integer timeout) {
		if (templateMap.containsKey(templateId)) return templateMap.get(templateId);

		final RestAPI.Response response = this.get(
			new List<Object> { 'templates', templateId },
			new QueryString('include', 'custom_fields'),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get template: ' + response.error.toString());
			throw new APIException(response.error);
		}

		Template template = ((TemplateAPI.APITemplate)JSON.deserialize(response.body,
			TemplateAPI.APITemplate.class)).toExternalForm();
		templateMap.put(template.id, template);
		return template;
	}

	private class Templates {
		public String resultSetSize;
		public String startPosition;
		public String endPosition;
		public String totalSetSize;
		public List<TemplateId> envelopeTemplates;

		public List<Template> toExternalForm() {
			final List<Template> templates = new List<Template>();
			if (envelopeTemplates != null) {
				for (TemplateId t : envelopeTemplates) {
					templates.add(t.toExternalForm());
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
		final RestAPI.Response response = this.get(
			'templates',
			new QueryString(new Map<String, String> {
				'include' => 'custom_fields,shared_template_folders',
				'order_by' => 'name',
				'order' => 'asc'
			}),
			timeout);
		if (response.hasError) {
			this.log.error('Failed to get templates: ' + response.error.toString());
			throw new APIException(response.error);
		}

		List<Template> templates = ((TemplateAPI.Templates)JSON.deserialize(response.body,
			TemplateAPI.Templates.class)).toExternalForm();
		for (Template t : templates) {
			templateMap.put(t.id, t);
		}
		return templates;
	}
}
