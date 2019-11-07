/**
 * Salesforce metadata-related operations.
 */
public with sharing class MetadataService {

	public static final String REMOTE_SITE_ACCOUNT = 'Account';
	public static final String REMOTE_SITE_PROVISIONING = 'Provisioning';
	public static final String REMOTE_SITE_ESIGNATURE = 'eSignature';
	public static final String REMOTE_SITE_WEB = 'Web';
	public static final String REMOTE_SITE_API = 'API';
	public static final String REMOTE_SITE_MERGE = 'Merge';
	public static final String REMOTE_SITE_AUTH = 'Auth';

	private static final Map<SObjectType, MetadataAPI.WebLink> SEND_ACTIONS
		= new Map<SObjectType, MetadataAPI.WebLink>();
	private static final Map<SObjectType, MetadataAPI.WebLink> GEN_ACTIONS
		= new Map<SObjectType, MetadataAPI.WebLink>();
	private static final List<String> PARAMETERS_ADD_QUOTES = new List<String> { 'templateId', 'title' };
	private static Boolean isChildObj;

	/**
	 * Returns a list of common, supported Salesforce object types.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The Salesforce objects.
	 */
	public static List<MergeObject> getCommonObjects() {
		Permissions.verifyIsDocuSignAdministrator();

		return new List<MergeObject> {
			MergeObject.forType(Schema.Account.getSObjectType()),
			MergeObject.forType(Schema.Case.getSObjectType()),
			MergeObject.forType(Schema.Contact.getSObjectType()),
			MergeObject.forType(Schema.Lead.getSObjectType()),
			MergeObject.forType(Schema.Opportunity.getSObjectType())
		};
	}

	/**
	 * Returns a list of all Salesforce object types.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The Salesforce objects.
	 */
	public static List<MergeObject> getObjects() {
		Permissions.verifyIsDocuSignAdministrator();

		List<MergeObject> result = new List<MergeObject>();
		for (Schema.SObjectType type : Schema.getGlobalDescribe().values()) {
			if (MergeObject.isValid(type)) {
				result.add(MergeObject.forType(type));
			}
		}
		result.sort();
		return result;
	}

	/**
	 * Returns Salesforce object description.
	 *
	 * @param recordId Id of record.
	 *
	 * @return The Salesforce object.
	 */
	public static DescribeSObjectResult describeSObject(final Id recordId) {
		if (recordId == null || String.isEmpty(recordId)) throw new DocuSignException(Label.UndefinedArgument);
		return recordId.getSobjectType().getDescribe();
	}

	private static List<MergeField> getChildRelationships(final DescribeSObjectResult type) {
		List<MergeField> result = new List<MergeField>();
		for (Schema.ChildRelationship cr : type.getChildRelationships()) {
			if (MergeField.isValid(cr)) result.add(MergeField.forChildRelationship(cr));
		}
		return result;
	}

	private static List<MergeField> getFields(final DescribeSObjectResult type, final String relationShipName, final Boolean isChild) {
		List<MergeField> result = new List<MergeField>();
		if (MergeObject.isValid(type)) {
			for (SObjectField f : type.fields.getMap().values()) {
				DescribeFieldResult field = f.getDescribe();
				if (MergeField.isValid(field)) {
					if (field.getReferenceTo().isEmpty() || String.isNotBlank(relationShipName)) {
						result.add(MergeField.forField(field, relationShipName));
					} else if (!isChild && !field.getReferenceTo().isEmpty() && field.getRelationShipName() != null && String.isNotBlank(field.getRelationShipName())) {
						for (Schema.SObjectType parentObjectType : field.getReferenceTo()) {
							result.addAll(getParentFields(parentObjectType, field.getRelationShipName()));
						}
					}
				}
			}
		}
		return result;
	}

	public static List<MergeField> getFields(final SObjectType type, final Boolean isChild) {
		Permissions.verifyIsDocuSignAdministrator();

		if (type == null) throw new DocuSignException(Label.UndefinedArgument);
		isChildObj = isChild;
		DescribeSObjectResult typeDesc = type.getDescribe();
		List<MergeField> result = getFields(typeDesc, null, isChild);
		if (!isChildObj) {
			result.addAll(getChildRelationships(typeDesc));
		}
		result.sort();
		return result;
	}

	public static List<MergeField> getFields(final DescribeSObjectResult type) {
		List<MergeField> result = new List<MergeField>();
		if (MergeObject.isValid(type)) {
			for (SObjectField f : type.fields.getMap().values()) {
				DescribeFieldResult field = f.getDescribe();
				if (MergeField.isValid(field)) {
					if (!field.getReferenceTo().isEmpty()) {
						result.add(MergeField.forField(field, ''));
					}
				}
			}
		}
		return result;
	}

	private static List<MergeField> getParentFields(final SObjectType type, final String relationShipName) {
		List<MergeField> result = new List<MergeField>();
		for (SObjectField f : type.getDescribe().fields.getMap().values()) {
			DescribeFieldResult field = f.getDescribe();
			if (MergeField.isValid(field)) {
				if (field.getReferenceTo().isEmpty()) {
					result.add(MergeField.forField(field, relationShipName));
				}
			}
		}
		return result;
	}

	@TestVisible
	private static String getErrorMessage(final MetadataAPI.SaveResult saveResult) {
		if (saveResult == null || Collection.isEmpty(saveResult.errors)) {
			return Label.SalesforceApiErrorUnexpectedResponse;
		}

		List<String> messages = new List<String>();
		for (MetadataAPI.Error e : saveResult.errors) {
			if (String.isNotBlank(saveResult.fullName) && String.isNotBlank(e.statusCode)) {
				messages.add(String.format(
					Label.MetadataError_3,
					new List<String> { saveResult.fullName, e.statusCode, e.message }));
			} else {
				messages.add(e.message);
			}
		}
		return String.join(messages, '\n');
	}

	@TestVisible
	private static List<String> validateResults(final List<MetadataAPI.SaveResult> results) {
		List<String> fullNames = new List<String>();
		List<String> errors = new List<String>();
		for (MetadataAPI.SaveResult result : results) {
			if (!result.success) {
				String msg = getErrorMessage(result);
				LoggerService.getInstance().error('Error saving metadata: ' + msg);
				errors.add(msg);
			}
			fullNames.add(result.fullName);
		}

		if (Collection.isNotEmpty(errors)) {
			throw new DocuSignException(String.format(Label.UpdateMetadataFailure_1, new List<String> {
				'\n' + Collection.mkString(errors, '\n')
			}));
		}

		return fullNames;
	}

	/**
	 * A Salesforce remote site.
	 */
	public class RemoteSite {
		/**
		 * The unique name of the remote site.
 		 */
		public String name { get; private set; }
		/**
		 * The full name of the remote site.
		 */
		public String fullName { get; private set; }
		/**
		 * Optional description of the remote site.
		 */
		public String description { get; private set; }
		/**
		 * The remote site URL.
		 */
		public Url url { get; private set; }

		private RemoteSite(
			final String name,
			final String description,
			final Url url) {

			this.name = name;
			this.fullName = MetadataAPI.NAMESPACE_PREFIX + name;
			this.description = description;
			this.url = url;
		}
	}

	/**
	 * Constructs a Remote Site.
	 *
	 * @param environment The DocuSign environment.
	 * @param type The type of the Remote Site.
	 * @param description Optional description of the Remote Site.
	 * @param url The Remote Site URL.
	 */
	public static RemoteSite newRemoteSite(
		final DocuSign.Environment environment,
		final String type,
		final String description,
		final Url url) {

		if (environment == null || String.isBlank(type) || url == null) {
			throw new DocuSignException(Label.UndefinedArgument);
		}

		if (environment == DocuSign.Environment.Invalid || !DocuSign.isValidUrl(url)) {
			throw new DocuSignException(Label.InvalidEnvironment);
		}

		return new RemoteSite(
			String.format('{0}_{1}', new List<String> {
				environment == DocuSign.Environment.Other ? url.getHost().substringBefore('.') : environment.name(),
				type
			}),
			description,
			url);
	}

	private static MetadataAPI.RemoteSiteSetting convert(final RemoteSite rs) {
		if (rs == null || String.isBlank(rs.name) || rs.url == null) throw new DocuSignException(Label.UndefinedArgument);

		MetadataAPI.RemoteSiteSetting result = new MetadataAPI.RemoteSiteSetting();
		result.fullName = rs.name;
		result.description = rs.description;
		result.url = rs.url.toExternalForm();
		result.isActive = true;
		result.disableProtocolSecurity = false;
		return result;
	}

	private static List<MetadataAPI.RemoteSiteSetting> filterNewSites(final List<RemoteSite> remoteSites) {
		if (Collection.isEmpty(remoteSites)) throw new DocuSignException(Label.UndefinedArgument);

		Map<String, MetadataAPI.RemoteSiteSetting> result = new Map<String, MetadataAPI.RemoteSiteSetting>();
		List<String> names = new List<String>();
		for (RemoteSite rs : remoteSites) {
			result.put(rs.fullName, convert(rs));
			names.add(rs.fullName);
		}

		for (MetadataAPI.Metadata md : MetadataAPI.getInstance().readMetadata('RemoteSiteSetting', names)) {
			result.remove(((MetadataAPI.RemoteSiteSetting)md).fullName);
		}

		return result.values();
	}

	/**
	 * Adds one or more Remote Sites to this Salesforce organization. Existing sites are ignored.
	 *
	 * @param remoteSites The Remote Sites to create.
	 *
	 * @return The API names of the newly-created Remote Sites without namespaces.
	 */
	public static List<String> createRemoteSites(final List<RemoteSite> remoteSites) {
		if (Collection.isEmpty(remoteSites)) throw new DocuSignException(Label.UndefinedArgument);

		List<String> result = new List<String>();
		List<MetadataAPI.RemoteSiteSetting> rss = filterNewSites(remoteSites);
		if (Collection.isNotEmpty(rss)) {
			List<MetadataAPI.SaveResult> results = MetadataAPI.getInstance().createMetadata(rss);
			result = validateResults(results);
		}

		return result;
	}

	private static String getLayoutName(final String fullName) {
		// Metadata API returns incorrect fullName and no display name :-(
		return String.isBlank(fullName) ? null : fullName.substringAfter('-');
	}

	private static List<MetadataAPI.FileProperties> listLayouts(
		final SObjectType type,
		final MetadataAPI.Client client) {

		List<MetadataAPI.FileProperties> result = new List<MetadataAPI.FileProperties>();
		if (type == null || client == null) return result;

		MetadataAPI.ListMetadataQuery query = new MetadataAPI.ListMetadataQuery();
		query.type_x = 'Layout';
		List<MetadataAPI.FileProperties> fps = client.listMetadata(
			new List<MetadataAPI.ListMetadataQuery> { query },
			Salesforce.API_VERSION);

		if (Collection.isNotEmpty(fps)) {
			String t = type.getDescribe().getLocalName();
			for (MetadataAPI.FileProperties fp : fps) {
				if (fp.fullName.startsWith(t)) result.add(fp);
			}
		}
		return result;
	}

	private static Map<String, MetadataAPI.FileProperties> getLayoutFullNames(
		final SObjectType type,
		final List<MetadataAPI.FileProperties> props) {

		Map<String, MetadataAPI.FileProperties> result = new Map<String, MetadataAPI.FileProperties>();
		if (type == null || Collection.isEmpty(props)) return result;

		for (MetadataAPI.FileProperties fp : props) {
			result.put(Layout.getFullName(
				type,
				fp.namespacePrefix,
				getLayoutName(fp.fullName)),
				fp);
		}
		return result;
	}

	private static String getActionLabel(final SObjectType type, final String apiName) {
		if (type == null || String.isBlank(apiName)) return null;
		String result;
		MetadataAPI.WebLink webLink = (MetadataAPI.WebLink)Collection.head(MetadataAPI.getInstance().readMetadata(
			'WebLink', new List<String> { getActionFullName(type, apiName) }));
		if (webLink != null && String.isNotBlank(webLink.masterLabel)) {
			result = webLink.masterLabel;
		}
		return result;
	}

	private static String getActionType(final String apiName) {
		if (apiName == Layout.ACTION_NAME_SEND) {
			return Layout.ACTION_TYPE_SEND;
		} else if (apiName.contains(Layout.ACTION_NAME_GEN)) {
			return Layout.ACTION_TYPE_GEN;
		} else {
			return Layout.ACTION_TYPE_OTHER;
		}
	}

	private static List<Layout.Action> getActions(final MetadataAPI.Layout mdLayout, final SObjectType type) {
		List<Layout.Action> result = new List<Layout.Action>();
		if (mdLayout != null
			&& Collection.isNotEmpty(mdLayout.customButtons)) {

			for (String apiName : mdLayout.customButtons) {
				result.add(new Layout.Action(
					getActionType(apiName),
					apiName,
					getActionLabel(type, apiName)));
			}
		}
		return result;
	}

	private static Layout convert(
		final SObjectType type,
		final MetadataAPI.FileProperties props,
		final MetadataAPI.Layout layout) {

		if (type == null || props == null || layout == null) return null;

		return new Layout(
			type,
			props.id,
			props.namespacePrefix,
			getLayoutName(props.fullName),
			getActions(layout, type));
	}

	private static List<Layout> readLayouts(
		final SObjectType type,
		final MetadataAPI.Client client,
		final Map<String, MetadataAPI.FileProperties> fullNames) {

		List<Layout> result = new List<Layout>();
		if (type == null || client == null || Collection.isEmpty(fullNames)) return result;

		List<MetadataAPI.Layout> layouts = (List<MetadataAPI.Layout>)client.readMetadata(
			'Layout',
			new List<String>(fullNames.keySet()));
		for (MetadataAPI.Layout layout : (layouts == null ? new List<MetadataAPI.Layout>() : layouts)) {
			result.add(convert(
				type,
				fullNames.get(layout.fullName),
				layout));
		}
		result.sort();
		return result;
	}

	/**
	 * Retrieves layouts for a Salesforce object type.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param type The target Salesforce object type.
	 *
	 * @return Layouts associated with the target Salesforce object type.
	 */
	public static List<Layout> getLayouts(final SObjectType type) {
		Permissions.verifyIsDocuSignAdministrator();

		if (type == null) throw new DocuSignException(Label.UndefinedArgument);

		MetadataAPI.Client client = MetadataAPI.getInstance();
		List<MetadataAPI.FileProperties> props = listLayouts(type, client);
		Map<String, MetadataAPI.FileProperties> fullNames = getLayoutFullNames(type, props);
		return readLayouts(type, client, fullNames);
	}

	private static String getActionFullName(
		final SObjectType type,
		final String apiName) {

		if (type == null || String.isBlank(apiName)) throw new DocuSignException(Label.UndefinedArgument);

		return String.valueOf(type) + '.' + apiName;
	}

	@TestVisible
	private static String buildInputs(
		final SObjectType type,
		final Map<String, String> parameters) {

		Boolean prependComma = false;
		String result = '[';

		// Add 'sId' param if type is defined and not overridden
		if (type != null && !Collection.containsKey(parameters, 'sId')) {
			result += 'sId = ' + type + '.Id';
			prependComma = true;
		}

		for (String k : Collection.keys(parameters)) {
			if (prependComma) {
				if (PARAMETERS_ADD_QUOTES.contains(k)) {
					result += String.format(', {0} = \'\'{1}\'\'', new List<String> { k, parameters.get(k) });
				} else {
					result += String.format(', {0} = {1}', new List<String> { k, parameters.get(k) });
				}

			} else {
				if (PARAMETERS_ADD_QUOTES.contains(k)) {
					result += String.format('{0} = \'\'{1}\'\'', new List<String> { k, parameters.get(k) });
				} else {
					result += String.format('{0} = {1}', new List<String> { k, parameters.get(k) });
				}
				prependComma = true;
			}
		}

		result += ']';

		return result;
	}

	@TestVisible
	private static MetadataAPI.WebLink createWebLink(
		final SObjectType type,
		final String apiName,
		final String buttonLabel,
		final PageReference page,
		final Map<String, String> parameters) {

		if (type == null || String.isBlank(apiName) || String.isBlank(buttonLabel) || page == null) {
			throw new DocuSignException(Label.UndefinedArgument);
		}

		MetadataAPI.WebLink webLink = new MetadataAPI.WebLink();
		webLink.fullName = getActionFullName(type, apiName);
		webLink.availability = 'online';
		webLink.displayType = 'button';
		webLink.encodingKey = 'UTF-8';
		webLink.protected_x = false;
		webLink.url = String.format('\'{\'!URLFOR(\'\'{0}\'\', null, {1})\'}\'', new List<String> {
			new Url(Url.getOrgDomainUrl(), page.getUrl()).getPath(),
			buildInputs(type, parameters)
		});
		webLink.linkType = 'url';
		webLink.masterLabel = buttonLabel;
		webLink.openType = 'replace';

		validateResults(MetadataAPI.getInstance().createMetadata(new List<MetadataAPI.Metadata> { webLink }));

		return webLink;
	}

	@TestVisible
	private static Map<String, MetadataAPI.Layout> readLayouts(final List<String> layoutFullNames) {
		Map<String, MetadataAPI.Layout> result = new Map<String, MetadataAPI.Layout>();
		if (Collection.isEmpty(layoutFullNames)) return result;

		List<MetadataAPI.Layout> mdLayouts = (List<MetadataAPI.Layout>)MetadataAPI.getInstance().readMetadata(
			'Layout', layoutFullNames);
		if (Collection.isEmpty(mdLayouts) || mdLayouts.size() != layoutFullNames.size()) {
			throw new DocuSignException(Label.LayoutsNotFound);
		}

		for (MetadataAPI.Layout l : mdLayouts) {
			result.put(l.fullName, l);
		}

		return result;
	}

	@TestVisible
	private static List<String> getCustomButtons(
		final Boolean shouldHaveAction,
		final String actionName,
		final List<String> customButtons) {

		List<String> result = new List<String>();
		if (shouldHaveAction) {
			result.add(actionName);
		}

		if (customButtons != null) {
			for (String cb : customButtons) {
				if (cb != actionName) {
					result.add(cb);
				}
			}
		}

		return result;
	}

	// HACK: Salesforce MD API bug: readMetadata returns some QuickAction names with the type prepended. When calling
	// updateMetadata with no changes, this will fail as the QuickAction is not found. For custom objects, the prefix
	// may be garbled, e.g. SomeAction for MyObject__c becomes MyObject__SomeAction. Awesome.
	@TestVisible
	private static String fixActionName(
		final SObjectType type,
		final String actionName) {

		String result = actionName;
		if (type != null && actionName != null) {
			String t = String.valueOf(type);
			result = result.removeStart(t + '-');
			Integer index = t.indexOf('__c');
			if (index > 0) {
				result = result.removeStart(t.substring(0, index + 2));
			}
		}
		return result;
	}

	@TestVisible
	private static Set<String> getPossibleActionNames(
		final SObjectType type,
		final String actionName) {

		if (String.isBlank(actionName)) return new Set<String>();

		Set<String> result = new Set<String> { actionName };
		if (type != null) {
			String t = String.valueOf(type);
			result.add(t + '-' + actionName);
			Integer index = t.indexOf('__c');
			if (index > 0) {
				result.add(t.substring(0, index + 2) + actionName);
			}
		}
		return result;
	}

	@TestVisible
	private static List<MetadataAPI.PlatformActionListItem> getPlatformActionListItems(
		final SObjectType type,
		final Boolean shouldHaveAction,
		final String actionName,
		final List<MetadataAPI.PlatformActionListItem> platformActionListItems) {

		Integer sortOrder = 0;
		List<MetadataAPI.PlatformActionListItem> result = new List<MetadataAPI.PlatformActionListItem>();
		if (shouldHaveAction) {
			MetadataAPI.PlatformActionListItem pali = new MetadataAPI.PlatformActionListItem();
			pali.sortOrder = sortOrder++;
			pali.actionName = actionName;
			pali.actionType = 'CustomButton';
			result.add(pali);
		}

		if (platformActionListItems != null) {
			Set<String> actionNames = getPossibleActionNames(type, actionName);
			for (MetadataAPI.PlatformActionListItem pali : platformActionListItems) {
				if (pali != null && !actionNames.contains(pali.actionName)) {
					pali.sortOrder = sortOrder++;
					pali.actionName = fixActionName(type, pali.actionName);
					result.add(pali);
				}
			}
		}

		return result;
	}

	@TestVisible
	private static MetadataAPI.Layout mergeLayout(
		final SObjectType type,
		final Layout newLayout,
		final MetadataAPI.Layout currentLayout,
		final String parameters) {

		if (newLayout == null || currentLayout == null) throw new DocuSignException(Label.LayoutsNotFound);

		Boolean hasSendAction = false;
		Boolean hasGenAction = false;
		Gen.LayoutParameters genLayoutParameters;
		if (String.isNotBlank(parameters)) {
			genLayoutParameters = (Gen.LayoutParameters)JSON.deserialize(parameters, Gen.LayoutParameters.class);
		}
		for (Layout.Action a : (newLayout.actions == null ? new List<Layout.Action>() : newLayout.actions)) {
			if (a.type == Layout.ACTION_TYPE_SEND) {
				hasSendAction = true;
				break;
			} else if (a.type == Layout.ACTION_TYPE_GEN) {
				hasGenAction = true;
				break;
			}
		}

		currentLayout.customButtons = getCustomButtons(
			genLayoutParameters != null ? hasGenAction : hasSendAction,
			genLayoutParameters != null ? genLayoutParameters.genButtonApiName : Layout.ACTION_NAME_SEND,
			currentLayout.customButtons);
		if (currentLayout.platformActionList != null) {
			currentLayout.platformActionList.platformActionListItems = getPlatformActionListItems(
				type,
				genLayoutParameters != null ? hasGenAction : hasSendAction,
				genLayoutParameters != null ? genLayoutParameters.genButtonApiName : Layout.ACTION_NAME_SEND,
				currentLayout.platformActionList.platformActionListItems);
		}
		return currentLayout;
	}

	@TestVisible
	private static MetadataAPI.WebLink getWebLink(
		final SObjectType type,
		final String actionName) {

		if (type == null || String.isBlank(actionName)) return null;

		MetadataAPI.WebLink webLink = (MetadataAPI.WebLink)Collection.head(MetadataAPI.getInstance().readMetadata(
			'WebLink', new List<String> { getActionFullName(type, actionName) }));
		if (webLink == null) {
			webLink = createWebLink(
				type,
				actionName,
				Label.SendWithDocuSign,
				Page.Sending,
				null);
		}
		return webLink;
	}

	@TestVisible
	private static MetadataAPI.WebLink getGenWebLink(
		final SObjectType type,
		final String actionName,
		final String actionLabel,
		final Id genTemplateId) {

		if (type == null || String.isBlank(actionName)) return null;

		MetadataAPI.WebLink webLink = (MetadataAPI.WebLink)Collection.head(MetadataAPI.getInstance().readMetadata(
			'WebLink', new List<String> { getActionFullName(type, actionName) }));
		if (webLink == null) {
			Map <String, String> parametersMap = new Map<String, String>();
			parametersMap.put('templateId', genTemplateId);
			parametersMap.put('recordId', type + '.Id');
			parametersMap.put('recordName', type + '.' + Salesforce.getNameField(type));
			parametersMap.put('title', actionLabel);
			webLink = createWebLink(
				type,
				actionName,
				actionLabel,
				Page.GenDocumentGenerator,
				parametersMap);
		} else if (webLink != null && String.isNotBlank(webLink.masterLabel) && webLink.masterLabel != actionLabel) {
			webLink.masterLabel = actionLabel;
			validateResults(MetadataAPI.getInstance().updateMetadata(new List<MetadataAPI.Metadata> { webLink }));
		}
		return webLink;
	}

	@TestVisible
	private static MetadataAPI.WebLink getSendAction(final SObjectType type) {
		if (type == null) return null;

		MetadataAPI.WebLink result = SEND_ACTIONS.get(type);
		if (result == null) {
			result = getWebLink(type, Layout.ACTION_NAME_SEND);
			SEND_ACTIONS.put(type, result);
		}
		return result;
	}

	@TestVisible
	private static MetadataAPI.WebLink getGenAction(
		final SObjectType type,
		final String parameters) {

		if (type == null) return null;

		MetadataAPI.WebLink result = GEN_ACTIONS.get(type);
		if (result == null) {
			Gen.LayoutParameters genLayoutParameters = (Gen.LayoutParameters)JSON.deserialize(parameters, Gen.LayoutParameters.class);
			result = getGenWebLink(type, genLayoutParameters.genButtonApiName, genLayoutParameters.genButtonLabel, genLayoutParameters.genTemplateId);
			GEN_ACTIONS.put(type, result);
		}
		return result;
	}

	public static List<Layout> updateLayouts(
		final SObjectType type,
		final List<Layout> layouts,
		final String parameters) {

		Permissions.verifyIsDocuSignAdministrator();

		if (type == null || Collection.isEmpty(layouts)) throw new DocuSignException(Label.UndefinedArgument);

		Map<String, Layout> ls = new Map<String, Layout>();
		for (Layout l : layouts) {
			if (l == null) throw new DocuSignException(Label.InvalidLayout);
			ls.put(l.fullName, l);
			if (l.hasSendAction()) {
				getSendAction(type);
			} else if (l.hasGenAction()) {
				getGenAction(type, parameters);
			}
		}

		List<MetadataAPI.Layout> toUpdate = new List<MetadataAPI.Layout>();
		Map<String, MetadataAPI.Layout> mdLayouts = readLayouts(new List<String>(ls.keySet()));
		for (String fullName : mdLayouts.keySet()) {
			toUpdate.add(mergeLayout(type, ls.get(fullName), mdLayouts.get(fullName), parameters));
		}

		validateResults(MetadataAPI.getInstance().updateMetadata(toUpdate));

		return layouts;
	}
}
