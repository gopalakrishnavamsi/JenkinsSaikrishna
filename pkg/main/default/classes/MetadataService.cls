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
	public static final Integer METADATA_API_LAYOUT_LIMIT = 10;
	public static final Set<String> COMMON_OBJECT_API_NAMES = new Set<String> {
		'Account', 'Case', 'Contact', 'Lead', 'Opportunity'
	};

	private static final Map<SObjectType, MetadataAPI.WebLink> SEND_ACTIONS
		= new Map<SObjectType, MetadataAPI.WebLink>();
	private static final Map<SObjectType, MetadataAPI.WebLink> GEN_ACTIONS
		= new Map<SObjectType, MetadataAPI.WebLink>();
	private static final Map<SObjectType, MetadataAPI.WebLink> DEC_ACTIONS
		= new Map<SObjectType, MetadataAPI.WebLink>();
	private static final Map<SObjectType, MetadataAPI.WebLink> ONLINE_EDITOR_ACTIONS
		= new Map<SObjectType, MetadataAPI.WebLink>();
	private static final List<String> PARAMETERS_ADD_QUOTES = new List<String> {
		'templateId', 'title', 'onlineEditorTemplateId'
	};

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
	 * Returns a list of all Other Uncommon Salesforce object types.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The Salesforce objects.
	 */
	public static List<MergeObject> getAllOtherObjects() {
		Permissions.verifyIsDocuSignAdministrator();

		List<MergeObject> result = new List<MergeObject>();
		for (Schema.SObjectType type : Schema.getGlobalDescribe().values()) {
			if (MergeObject.isValid(type) && !COMMON_OBJECT_API_NAMES.contains(type.getDescribe().name)) {
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

	public static List<MergeField> getFields(
		final SObjectType type,
		final Integer depth) {

		Permissions.verifyIsDocuSignAdministrator();

		if (!MergeObject.isValid(type)) throw new DocuSignException(Label.InvalidType);
		if (depth > MergeField.MAX_DEPTH) throw new DocuSignException(Label.MaxObjectDepthExceeded);

		List<MergeField> result = new List<MergeField>();
		DescribeSObjectResult typeDesc = type.getDescribe();
		for (SObjectField f : typeDesc.fields.getMap().values()) {
			DescribeFieldResult field = f.getDescribe();
			if (MergeField.isValid(field)) {
				if (depth < MergeField.MAX_DEPTH) {
					result.add(MergeField.forField(field));
				} else if (Collection.isEmpty(field.getReferenceTo())) { // no relationships when at max depth
					result.add(MergeField.forField(field));
				}
			}
		}

		if (depth <= MergeField.MAX_CHILD_DEPTH) {
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
						result.add(MergeField.forField(field));
					}
				}
			}
		}
		return result;
	}

	public static List<Query.Relationship> getLookups(final SObjectType type) {
		Permissions.verifyIsDocuSignAdministrator();
		if (type == null) throw new DocuSignException(Label.InvalidType);
		List<Query.Relationship> result = new List<Query.Relationship>();
		DescribeSObjectResult typeDesc = type.getDescribe();
		for (SObjectField f : typeDesc.fields.getMap().values()) {
			DescribeFieldResult fieldDesc = f.getDescribe();
			SObjectType fieldSourceType = (SObjectType)Collection.head(fieldDesc.getReferenceTo());
			if (RecipientService.canResolveRecipientType(fieldSourceType)) {
				result.add(
					new Query.Relationship(
						true,
						fieldDesc.getRelationshipName(),
						fieldDesc.getLabel(),
						String.valueOf(fieldSourceType)
					)
				);
			}
		}

		return result;
	}

	public static List<Query.Relationship> getChildRelationships(final SObjectType type) {
		Permissions.verifyIsDocuSignAdministrator();
		if (type == null) throw new DocuSignException(Label.InvalidType);
		List<Query.Relationship> result = new List<Query.Relationship>();
		DescribeSObjectResult typeDesc = type.getDescribe();
		for (Schema.ChildRelationship cr : typeDesc.getChildRelationships()) {
			DescribeFieldResult sourceField = cr.getField().getDescribe();
			SObjectType childType = cr.getChildSObject();
			if (RecipientService.canResolveRelatedRecipients(childType) && String.isNotBlank(cr.getRelationshipName())) {
				result.add(
					new Query.Relationship(
						false,
						cr.getRelationshipName(),
						cr.getRelationshipName(),
						String.valueOf(childType)
					)
				);
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

	private static Map<String, List<MetadataAPI.RemoteSiteSetting>> filterSites(final List<RemoteSite> remoteSites) {
		if (Collection.isEmpty(remoteSites)) throw new DocuSignException(Label.UndefinedArgument);

		Map<String, List<MetadataAPI.RemoteSiteSetting>> resultsMap = new Map<String, List<MetadataAPI.RemoteSiteSetting>>();
		Map<String, MetadataAPI.RemoteSiteSetting> remoteSitesMapForCreate = new Map<String, MetadataAPI.RemoteSiteSetting>();
		Map<String, MetadataAPI.RemoteSiteSetting> remoteSitesMapForUpdate = new Map<String, MetadataAPI.RemoteSiteSetting>();
		List<String> names = new List<String>();

		//Add all the remote sites passed as input to the create and update maps
		for (RemoteSite rs : remoteSites) {
			remoteSitesMapForCreate.put(rs.fullName, convert(rs));
			remoteSitesMapForUpdate.put(rs.fullName, convert(rs));
			names.add(rs.fullName);
		}

		//Filter the create map by removing all existing remote sites
		//This will ensure that the create map contains remote site settings which are to be created new
		for (MetadataAPI.Metadata md : MetadataAPI.getInstance().readMetadata('RemoteSiteSetting', names)) {
			remoteSitesMapForCreate.remove(((MetadataAPI.RemoteSiteSetting)md).fullName);
		}

		//Filter the update map by removing all remote sites that are to be created
		//This will ensure that the update map contains remote site settings which are to be updated
		for (String keyName : remoteSitesMapForCreate.keySet()) {
			remoteSitesMapForUpdate.remove(keyName);
		}

		//Add the remote sites to be updated as well as created to the resultsMaps
		resultsMap.put('Create', remoteSitesMapForCreate.values());
		resultsMap.put('Update', remoteSitesMapForUpdate.values());

		return resultsMap;
	}

	/**
	 * Adds / updates one or more Remote Sites to this Salesforce organization.
	 *
	 * @param remoteSites The Remote Sites to created / updated.
	 *
	 * @return The API names of the newly-created / updated Remote Sites without namespaces.
	 */
	public static List<String> createRemoteSites(final List<RemoteSite> remoteSites) {
		if (Collection.isEmpty(remoteSites)) throw new DocuSignException(Label.UndefinedArgument);

		List<String> result = new List<String>();
		Map<String, List<MetadataAPI.RemoteSiteSetting>> rssMap = filterSites(remoteSites);
		if (Collection.isNotEmpty(rssMap.get('Create'))) {
			List<MetadataAPI.SaveResult> createResults = MetadataAPI.getInstance().createMetadata(rssMap.get('Create'));
			result.addAll(validateResults(createResults));
		}
		if (Collection.isNotEmpty(rssMap.get('Update'))) {
			List<MetadataAPI.SaveResult> updateResults = MetadataAPI.getInstance().updateMetadata(rssMap.get('Update'));
			result.addAll(validateResults(updateResults));
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

	private static Map<String, String> getApiFullNameToLabel(final List<String> apiFullNames) {
		Map<String, String> result = new Map<String, String> ();
		if (Collection.isNotEmpty(apiFullNames)) {
			for (List<String> apiFullNamesChunk : Collection.chunk(apiFullNames, METADATA_API_LAYOUT_LIMIT)) {
				List<MetadataAPI.Metadata> webLinksMetaData = MetadataAPI.getInstance().readMetadata('WebLink', apiFullNamesChunk);
				for (Integer i = 0; i < webLinksMetaData.size(); i++) {
					MetadataAPI.WebLink webLink = (MetadataAPI.WebLink)webLinksMetaData[i];
					if (webLink != null && String.isNotBlank(webLink.masterLabel)) {
						result.put(apiFullNamesChunk[i], webLink.masterLabel);
					}
				}
			}
		}
		return result;
	}

	private static String getActionType(final String apiName) {
		if (apiName == Layout.ACTION_NAME_SEND) {
			return Layout.ACTION_TYPE_SEND;
		} else if (apiName.contains(Layout.ACTION_NAME_GEN)) {
			return Layout.ACTION_TYPE_GEN;
		} else if (apiName.contains(Layout.ACTION_NAME_ONLINEEDITOR)) {
			return Layout.ACTION_TYPE_ONLINEEDITOR;
		} else if (apiName.contains(Layout.ACTION_NAME_DEC)) {
			return Layout.ACTION_TYPE_DEC;
		} else {
			return Layout.ACTION_TYPE_OTHER;
		}
	}

	private static Map<String, List<Layout.Action>> prepareLayoutNameToActions(final Map<String, MetadataAPI.FileProperties> layoutFullNames, final List<MetadataAPI.Layout> mdLayouts, final SObjectType type) {
		Map<String, List<Layout.Action>> layoutNameToLayoutActions = new Map<String, List<Layout.Action>>();
		Map<String, Map<String, String>> layoutNameToActionApiNameAndFullNameMap = new Map<String, Map<String, String>>();
		List<String> apiFullNames = new List<String>();
		Map<String, String> actionApiNameToFullName = new Map<String, String>();
		Map<String, String> actionApiFullNameToLabel = new Map<String, String>();
		if (Collection.isNotEmpty(mdLayouts)) {
			for (MetadataAPI.Layout mdLayout : mdLayouts) {
				actionApiNameToFullName = new Map<String, String>();
				if (mdLayout.fullName != null && layoutFullNames.containsKey(mdLayout.fullName)) {
					MetadataAPI.FileProperties fpName = layoutFullNames.get(mdLayout.fullName);
					if (fpName != null && fpName.fullName != null) {
						String layoutName = getLayoutName(fpName.fullName);
						if (layoutName != null && mdLayout.customButtons != null && Collection.isNotEmpty(mdLayout.customButtons)) {
							for (String apiName : mdLayout.customButtons) {
								actionApiNameToFullName.put(apiName, getActionFullName(type, apiName));
								apiFullNames.add(getActionFullName(type, apiName));
							}
							if (Collection.isNotEmpty(actionApiNameToFullName.keySet())) {
								layoutNameToActionApiNameAndFullNameMap.put(layoutName, actionApiNameToFullName);
							}
						}
					}
				}
			}

			if (Collection.isNotEmpty(apiFullNames)) {
				//Callout : get buttons label in chunk of 10
				actionApiFullNameToLabel = getApiFullNameToLabel(apiFullNames);
			}

			for (String layoutName : layoutNameToActionApiNameAndFullNameMap.keySet()) {
				List<Layout.Action> layoutActions = new List<Layout.Action>();
				Map<String, String> apiNameToFullName = layoutNameToActionApiNameAndFullNameMap.get(layoutName);
				for (String apiName : apiNameToFullName.keySet()) {
					String apiFullName = apiNameToFullName.get(apiName);
					if (apiFullName != null && actionApiFullNameToLabel.containsKey(apiFullName)) {
						layoutActions.add(new Layout.Action(
							getActionType(apiName),
							apiName,
							actionApiFullNameToLabel.get(apiFullName)
						));
					}
				}
				if (Collection.isNotEmpty(layoutActions)) {
					layoutNameToLayoutActions.put(layoutName, layoutActions);
				}
			}
		}
		return layoutNameToLayoutActions;
	}

	private static Layout convert(
		final SObjectType type,
		final MetadataAPI.FileProperties props,
		final MetadataAPI.Layout layout,
		final String layoutName,
		final List<Layout.Action> layoutActions) {

		if (type == null || props == null || layout == null || layoutName == null) return null;

		return new Layout(
			type,
			props.id,
			props.namespacePrefix,
			layoutName,
			layoutActions);
	}

	private static List<Layout> readLayouts(
		final SObjectType type,
		final MetadataAPI.Client client,
		final Map<String, MetadataAPI.FileProperties> fullNames) {

		List<Layout> result = new List<Layout>();
		if (type == null || client == null || Collection.isEmpty(fullNames)) return result;
		List<List<String>> layoutNamesChunk = Collection.chunk(new List<String>(fullNames.keySet()), METADATA_API_LAYOUT_LIMIT);
		List<MetadataAPI.Layout> layouts = new List<MetadataAPI.Layout>();
		Map<String, List<Layout.Action>> layoutNameToActions = new Map<String, List<Layout.Action>>();
		for (List<String> layoutNames : layoutNamesChunk) {
			layouts.addAll((List<MetadataAPI.Layout>)client.readMetadata(
				'Layout',
				layoutNames));
		}
		layoutNameToActions = prepareLayoutNameToActions(fullNames, layouts, type);
		for (MetadataAPI.Layout layout : (layouts == null ? new List<MetadataAPI.Layout>() : layouts)) {
			MetadataAPI.FileProperties fpFullNameName = fullNames.get(layout.fullName);
			String layoutName = getLayoutName(fpFullNameName.fullName);
			result.add(convert(
				type,
				fpFullNameName,
				layout,
				layoutName,
				layoutNameToActions.containsKey(layoutName) ? layoutNameToActions.get(layoutName) : null));
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
		webLink.url = String.format('\'{\'!URLFOR({0}\'\'{1}\'\', null, {2})\'}\'', new List<String> {
			'$Site.Prefix +' , new Url(Url.getOrgDomainUrl(), page.getUrl()).getPath(),
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

		Boolean hasDecAction = false;
		Boolean hasSendAction = false;
		Boolean hasGenAction = false;
		Boolean hasOnlineEditorAction = false;
		Boolean showAction;
		String actionName;
		Gen.LayoutParameters genLayoutParameters;
		EnvelopeConfigurationController.LayoutParameters decLayoutParameters;

		for (Layout.Action a : (newLayout.actions == null ? new List<Layout.Action>() : newLayout.actions)) {
			if (a.type == Layout.ACTION_TYPE_SEND) {
				hasSendAction = true;
				break;
			} else if (a.type == Layout.ACTION_TYPE_GEN) {
				hasGenAction = true;
				break;
			} else if (a.type == Layout.ACTION_TYPE_DEC) {
				hasDecAction = true;
				break;
			} else if (a.type == Layout.ACTION_TYPE_ONLINEEDITOR) {
				hasOnlineEditorAction = true;
				break;
			}
		}

		if (String.isNotBlank(parameters)) {
			if (parameters.contains('genButtonApiName')) {
				genLayoutParameters = (Gen.LayoutParameters)JSON.deserialize(parameters, Gen.LayoutParameters.class);
			} else if (parameters.contains('decButtonApiName')) {
				decLayoutParameters = (EnvelopeConfigurationController.LayoutParameters)JSON.deserialize(
					parameters,
					EnvelopeConfigurationController.LayoutParameters.class);
			}
		}

		if (genLayoutParameters != null) {
			showAction = hasGenAction || hasOnlineEditorAction;
			actionName = genLayoutParameters.genButtonApiName;
		} else if (decLayoutParameters != null) {
			showAction = hasDecAction;
			actionName = decLayoutParameters.decButtonApiName;
		} else {
			showAction = hasSendAction;
			actionName = Layout.ACTION_NAME_SEND;
		}

		currentLayout.customButtons = getCustomButtons(
			showAction,
			actionName,
			currentLayout.customButtons);
		if (currentLayout.platformActionList != null) {
			currentLayout.platformActionList.platformActionListItems = getPlatformActionListItems(
				type,
				showAction,
				actionName,
				currentLayout.platformActionList.platformActionListItems);
		}
		return currentLayout;
	}

	@TestVisible
	private static MetadataAPI.WebLink getWebLink(
		final SObjectType type,
		final String actionName,
		final String actionLabel,
		final Id templateId,
		final PageReference pageRef) {

		if (type == null || String.isBlank(actionName)) return null;

		MetadataAPI.WebLink webLink = (MetadataAPI.WebLink)Collection.head(MetadataAPI.getInstance().readMetadata(
			'WebLink', new List<String> { getActionFullName(type, actionName) }));
		if (webLink == null) {
			Map <String, String> parametersMap = new Map<String, String>();
			if (templateId != null) {
				parametersMap.put('templateId', templateId);
				parametersMap.put('recordId', type + '.Id');
				parametersMap.put('recordName', type + '.' + Salesforce.getNameField(type));
				parametersMap.put('title', actionLabel);
			}
			webLink = createWebLink(
				type,
				actionName,
				actionLabel,
				pageRef,
				parametersMap);
		} else if (webLink != null &&
			templateId != null &&
			String.isNotBlank(webLink.masterLabel) &&
			webLink.masterLabel != actionLabel) {
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
			result = getWebLink(type, Layout.ACTION_NAME_SEND, Label.SendWithDocuSign, null, Page.Sending);
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
			result = getWebLink(type,
				genLayoutParameters.genButtonApiName,
				genLayoutParameters.genButtonLabel,
				genLayoutParameters.genTemplateId,
				Page.GenDocumentGenerator);
			GEN_ACTIONS.put(type, result);
		}
		return result;
	}

	@TestVisible
	private static MetadataAPI.WebLink getDecAction(
		final SObjectType type,
		final String parameters) {

		if (type == null) return null;

		MetadataAPI.WebLink result = DEC_ACTIONS.get(type);
		if (result == null) {
			EnvelopeConfigurationController.LayoutParameters decLayoutParameters =
				(EnvelopeConfigurationController.LayoutParameters)JSON.deserialize(
					parameters,
					EnvelopeConfigurationController.LayoutParameters.class);
			result = getWebLink(type,
				decLayoutParameters.decButtonApiName,
				decLayoutParameters.decButtonLabel,
				decLayoutParameters.decTemplateId,
				Page.Sending);
			DEC_ACTIONS.put(type, result);
		}
		return result;
	}

	// FIXME: Consolidate Gen action logic. Pass in deserialized, validated types to this method.
	public static List<Layout> updateLayouts(
		final SObjectType type,
		final List<Layout> layouts,
		final String parameters,
		final UUID scmTemplateId) {

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
			} else if (l.hasDecAction()) {
				getDecAction(type, parameters);
			} else if (l.hasOnlineEditorAction()) {
				getOnlineEditorAction(type, parameters, scmTemplateId);
			}
		}
		if (ls != null && ls.keySet().size() > 0) {
			List<List<String>> layoutNamesChunk = Collection.chunk(new List<String>(ls.keySet()), METADATA_API_LAYOUT_LIMIT);
			for (List<String> layoutNames : layoutNamesChunk) {
				Map<String, MetadataAPI.Layout> mdLayouts = readLayouts(layoutNames);
				List<MetadataAPI.Layout> toUpdate = new List<MetadataAPI.Layout>();
				for (String fullName : layoutNames) {
					toUpdate.add(mergeLayout(type, ls.get(fullName), mdLayouts.get(fullName), parameters));
				}
				validateResults(MetadataAPI.getInstance().updateMetadata(toUpdate));
			}
		}
		return layouts;
	}

	// OnlineEditor logic start
	@TestVisible
	private static MetadataAPI.WebLink getOnlineEditorWebLink(
		final SObjectType type,
		final String actionName,
		final String actionLabel,
		final Id templateId,
		final UUID scmTemplateId) {

		if (type == null || String.isBlank(actionName)) return null;

		MetadataAPI.WebLink webLink = (MetadataAPI.WebLink)Collection.head(MetadataAPI.getInstance().readMetadata(
			'WebLink', new List<String> { getActionFullName(type, actionName) }));
		if (webLink == null) {

			Map <String, String> parametersMap = new Map<String, String>();
			parametersMap.put('templateId', templateId);
			parametersMap.put('recordId', type + '.Id');
			parametersMap.put('recordName', type + '.' + Salesforce.getNameField(type));
			parametersMap.put('title', actionLabel);
			parametersMap.put('onlineEditorTemplateId', String.valueOf(scmTemplateId));
			webLink = createWebLink(
				type,
				actionName,
				actionLabel,
				Page.OnlineEditorDocumentGenerator,
				parametersMap);
		} else if (webLink != null && String.isNotBlank(webLink.masterLabel) && webLink.masterLabel != actionLabel) {
			webLink.masterLabel = actionLabel;
			validateResults(MetadataAPI.getInstance().updateMetadata(new List<MetadataAPI.Metadata> { webLink }));
		}
		return webLink;
	}

	@TestVisible
	private static MetadataAPI.WebLink getOnlineEditorAction(
		final SObjectType type,
		final String parameters,
		final UUID scmTemplateId) {

		if (type == null) return null;

		MetadataAPI.WebLink result = ONLINE_EDITOR_ACTIONS.get(type);
		if (result == null) {
			Gen.LayoutParameters genLayoutParameters = (Gen.LayoutParameters)JSON.deserialize(parameters, Gen.LayoutParameters.class);
			result = getOnlineEditorWebLink(
				type,
				genLayoutParameters.genButtonApiName,
				genLayoutParameters.genButtonLabel,
				genLayoutParameters.genTemplateId,
				scmTemplateId);
			ONLINE_EDITOR_ACTIONS.put(type, result);
		}
		return result;
	}
	// OnlineEditor logic end
}
