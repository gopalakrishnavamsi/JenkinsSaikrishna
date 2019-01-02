/**
 * Salesforce metadata-related operations.
 */
public with sharing class MetadataService {
	/**
	 * Returns a list of common, supported Salesforce object types.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The Salesforce objects.
	 */
	public static List<Salesforce.MergeObject> getCommonObjects() {
		Permissions.verifyIsDocuSignAdministrator();

		return new List<Salesforce.MergeObject> {
			new Salesforce.MergeObject('Account', Schema.Account.getSObjectType().getDescribe().getLabel(), false),
			new Salesforce.MergeObject('Case', Case.getSObjectType().getDescribe().getLabel(), false),
			new Salesforce.MergeObject('Contact', Contact.getSObjectType().getDescribe().getLabel(), false),
			new Salesforce.MergeObject('Lead', Lead.getSObjectType().getDescribe().getLabel(), false),
			new Salesforce.MergeObject('Opportunity', Opportunity.getSObjectType().getDescribe().getLabel(), false)
		};
	}

	/**
	 * Returns a list of all Salesforce object types.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @return The Salesforce objects.
	 */
	public static List<Salesforce.MergeObject> getAllObjects() {
		Permissions.verifyIsDocuSignAdministrator();

		List<Salesforce.MergeObject> result = SalesforceAPI.getInstance().getMergeObjects();
		if (result != null) result.sort();
		return result;
	}

	@TestVisible
	private static String getErrorMessage(final MetadataAPI.SaveResult saveResult) {
		if (saveResult == null || Collection.isEmpty(saveResult.errors)) {
			return Label.SalesforceApiErrorUnexpectedResponse;
		}

		List<String> messages = new List<String>();
		for (MetadataAPI.Error e : saveResult.errors) {
			if (e.statusCode == 'DUPLICATE_VALUE' || e.statusCode == 'DUPLICATE_DEVELOPER_NAME') {
				messages.add(Label.DuplicateButton);
			} else {
				messages.add(e.message);
			}
		}
		return String.join(messages, '\n');
	}

	@TestVisible
	private static void validateResults(final List<MetadataAPI.SaveResult> results) {
		List<String> errors = new List<String>();
		for (MetadataAPI.SaveResult result : results) {
			if (!result.success) {
				String msg = getErrorMessage(result);
				LoggerService.getInstance().error('Error saving metadata: ' + msg);
				errors.add(msg);
			}
		}

		if (Collection.isNotEmpty(errors)) {
			throw new DocuSignException(String.format(Label.UpdateMetadataFailure_1, new List<String> {
				Collection.mkString(errors, '\n')
			}));
		}
	}

	/**
	 * Adds a Remote Site to this Salesforce organization.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param name The unique name of the Remote Site.
	 * @param description Optional description of the Remote Site.
	 * @param url The Remote Site URL.
	 *
	 * @return The API name of the newly-created Remote Site.
	 */
	public static String createRemoteSite(final String name, final String description, final Url url) {
		Permissions.verifyIsDocuSignAdministrator();

		if (String.isBlank(name) || url == null) throw new DocuSignException(Label.UndefinedArgument);

		MetadataAPI.RemoteSiteSetting remoteSite = new MetadataAPI.RemoteSiteSetting();
		remoteSite.fullName = name;
		remoteSite.description = description;
		remoteSite.isActive = true;
		remoteSite.disableProtocolSecurity = false;
		remoteSite.url = url.toExternalForm();

		List<MetadataAPI.SaveResult> results = MetadataAPI.getInstance().createMetadata(
			new List<MetadataAPI.Metadata> { remoteSite });
		validateResults(results);

		MetadataAPI.SaveResult result = (MetadataAPI.SaveResult)Collection.head(results);
		if (result == null) throw new DocuSignException(Label.SalesforceApiErrorUnexpectedResponse);

		return result.fullName;
	}

	private static Layout convertLayout(
		final SObjectType type,
		final MetadataAPI.FileProperties props) {

		if (props == null) return null;

		return new Layout(
			type,
			props.id,
			props.namespacePrefix,
			props.fullName.substringAfter('-')); // Metadata API returns incorrect fullName and no display name :-(
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

		MetadataAPI.ListMetadataQuery query = new MetadataAPI.ListMetadataQuery();
		query.type_x = 'Layout';

		List<MetadataAPI.FileProperties> fps = MetadataAPI.getInstance().listMetadata(
			new List<MetadataAPI.ListMetadataQuery> { query },
			Salesforce.API_VERSION);
		List<Layout> result = new List<Layout>();
		if (Collection.isNotEmpty(fps)) {
			String t = String.valueOf(type);
			for (MetadataAPI.FileProperties fp : fps) {
				if (fp.fullName.startsWith(t)) result.add(convertLayout(type, fp));
			}
		}
		return result;
	}

	private static String getButtonFullName(
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
				result += String.format(', {0} = {1}', new List<String> { k, parameters.get(k) });
			} else {
				result += String.format('{0} = {1}', new List<String> { k, parameters.get(k) });
				prependComma = true;
			}
		}

		result += ']';

		return result;
	}

	@TestVisible
	private static MetadataAPI.WebLink createWebLink(
		final SObjectType type,
		final String fullName,
		final String buttonLabel,
		final PageReference page,
		final Map<String, String> parameters) {

		if (type == null || String.isBlank(fullName) || String.isBlank(buttonLabel) || page == null) {
			throw new DocuSignException(Label.UndefinedArgument);
		}

		MetadataAPI.WebLink webLink = new MetadataAPI.WebLink();
		webLink.fullName = fullName;
		webLink.availability = 'online';
		webLink.displayType = 'button';
		webLink.encodingKey = 'UTF-8';
		webLink.linkType = 'url';
		webLink.masterLabel = buttonLabel;
		webLink.openType = 'replace';
		webLink.protected_x = false;
		webLink.url = String.format('\'{\'!URLFOR(\'\'{0}\'\', null, {1})\'}\'', new List<String> {
			new Url(Url.getSalesforceBaseUrl(), page.getUrl()).getPath(),
			buildInputs(type, parameters)
		});

		validateResults(MetadataAPI.getInstance().createMetadata(new List<MetadataAPI.Metadata> { webLink }));

		return webLink;
	}

	@TestVisible
	private static MetadataAPI.QuickAction createQuickAction(
		final SObjectType type,
		final String fullName,
		final String buttonLabel,
		final String auraBundleFullName,
		final Integer height,
		final Integer width,
		final String icon) {

		if (type == null
			|| String.isBlank(fullName)
			|| String.isBlank(buttonLabel)
			|| String.isBlank(auraBundleFullName)) {

			throw new DocuSignException(Label.UndefinedArgument);
		}

		MetadataAPI.QuickAction quickAction = new MetadataAPI.QuickAction();
		quickAction.fullName = fullName;
		quickAction.height = height;
		quickAction.label = buttonLabel;
		quickAction.lightningComponent = auraBundleFullName;
		quickAction.isProtected = false;
		quickAction.optionsCreateFeedItem = false;
		quickAction.type_x = 'LightningComponent';
		quickAction.width = width;
		quickAction.icon = icon;

		validateResults(MetadataAPI.getInstance().createMetadata(new List<MetadataAPI.Metadata> { quickAction }));

		return quickAction;
	}

	@TestVisible
	private static List<MetadataAPI.Layout> readLayouts(
		final SObjectType type,
		final List<Layout> layouts) {

		List<String> layoutFullNames = new List<String>();
		for (Layout l : layouts) {
			if (l == null || l.type != type) throw new DocuSignException(Label.InvalidLayout);
			layoutFullNames.add(l.fullName);
		}

		List<MetadataAPI.Layout> result = (List<MetadataAPI.Layout>)MetadataAPI.getInstance().readMetadata(
			'Layout', layoutFullNames);
		if (Collection.isEmpty(result) || result.size() != layouts.size()) {
			throw new DocuSignException(Label.LayoutsNotFound);
		}

		return result;
	}

	@TestVisible
	private static Boolean addClassicButton(
		final String webLinkApiName,
		final List<MetadataAPI.Layout> layouts) {

		List<MetadataAPI.Metadata> modifiedLayouts = new List<MetadataAPI.Metadata>();
		for (MetadataAPI.Layout layout : layouts) {
			if (Collection.isEmpty(layout.customButtons)) {
				layout.customButtons = new List<String> { webLinkApiName };
				modifiedLayouts.add(layout);
			} else if (!layout.customButtons.contains(webLinkApiName)) {
				layout.customButtons.add(0, webLinkApiName);
				modifiedLayouts.add(layout);
			}
		}

		if (Collection.isNotEmpty(modifiedLayouts)) {
			validateResults(MetadataAPI.getInstance().updateMetadata(modifiedLayouts));
		}

		return true;
	}

	@TestVisible
	private static Boolean addLightningButton(
		final String webLinkApiName,
		final List<MetadataAPI.Layout> layouts) {

		List<MetadataAPI.Metadata> modifiedLayouts = new List<MetadataAPI.Metadata>();
		for (MetadataAPI.Layout layout : layouts) {
			if (layout.platformActionList == null) {
				layout.platformActionList = new MetadataAPI.PlatformActionList();
				layout.platformActionList.actionListContext = 'Record';
			}

			if (layout.platformActionList.platformActionListItems == null) {
				layout.platformActionList.platformActionListItems = new List<MetadataAPI.PlatformActionListItem>();
			}

			Boolean hasAction = false;
			for (MetadataAPI.PlatformActionListItem ai : layout.platformActionList.platformActionListItems) {
				if (ai.actionName == webLinkApiName) {
					hasAction = true;
					break;
				}
			}

			if (!hasAction) {
				MetadataAPI.PlatformActionListItem actionItem = new MetadataAPI.PlatformActionListItem();
				actionItem.actionName = webLinkApiName;
				actionItem.actionType = 'CustomButton';
				actionItem.sortOrder = 0;
				layout.platformActionList.platformActionListItems.add(actionItem);
				modifiedLayouts.add(layout);
			}
		}

		if (Collection.isNotEmpty(modifiedLayouts)) {
			validateResults(MetadataAPI.getInstance().updateMetadata(modifiedLayouts));
		}

		return true;
	}

	/**
	 * Adds the Send with DocuSign button to one or more layouts.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param type Salesforce object type.
	 * @param theme Salesforce UI theme.
	 * @param layouts One or more layouts to add the button.
	 *
	 * @return <code>True</code> if the add operation was successful.
	 */
	public static Boolean addSendButton(
		final SObjectType type,
		final UITheme.Theme theme,
		final List<Layout> layouts) {

		Permissions.verifyIsDocuSignAdministrator();

		if (type == null || theme == null || Collection.isEmpty(layouts)) {
			throw new DocuSignException(Label.UndefinedArgument);
		}

		List<MetadataAPI.Layout> mdLayouts = readLayouts(type, layouts);
		String apiName = Application.namespacePrefix + 'Send';
		String fullName = getButtonFullName(type, apiName);

		MetadataAPI.WebLink webLink = (MetadataAPI.WebLink)Collection.head(MetadataAPI.getInstance().readMetadata(
			'WebLink', new List<String> { fullName }));
		if (webLink == null) {
			webLink = createWebLink(
				type,
				fullName,
				Label.SendWithDocuSign,
				Page.Sending,
				null);
		}

		if (theme == UITheme.Theme.Classic) {
			addClassicButton(apiName, mdLayouts);
		} else { // Lightning
			addLightningButton(apiName, mdLayouts);
		}

		return true;
	}

	@TestVisible
	private static Boolean removeClassicButton(
		final String webLinkApiName,
		final List<MetadataAPI.Layout> layouts) {

		List<MetadataAPI.Metadata> modifiedLayouts = new List<MetadataAPI.Metadata>();
		for (MetadataAPI.Layout layout : layouts) {
			Integer index = Collection.indexOf(layout.customButtons, webLinkApiName);
			if (index >= 0) {
				layout.customButtons.remove(index);
				modifiedLayouts.add(layout);
			}
		}

		if (Collection.isNotEmpty(modifiedLayouts)) {
			validateResults(MetadataAPI.getInstance().updateMetadata(modifiedLayouts));
		}

		return true;
	}

	@TestVisible
	private static Boolean removeLightningButton(
		final String webLinkApiName,
		final List<MetadataAPI.Layout> layouts) {

		List<MetadataAPI.Metadata> modifiedLayouts = new List<MetadataAPI.Metadata>();
		for (MetadataAPI.Layout layout : layouts) {
			if (layout.platformActionList == null || layout.platformActionList.platformActionListItems == null) {
				continue;
			}

			Integer index = -1;
			for (Integer i = 0; i < Collection.size(layout.platformActionList.platformActionListItems); i++) {
				if (layout.platformActionList.platformActionListItems[i].actionName == webLinkApiName) {
					index = i;
					break;
				}
			}

			if (index >= 0) {
				layout.platformActionList.platformActionListItems.remove(index);
				modifiedLayouts.add(layout);
			}
		}

		if (Collection.isNotEmpty(modifiedLayouts)) {
			validateResults(MetadataAPI.getInstance().updateMetadata(modifiedLayouts));
		}

		return true;
	}

	/**
	 * Removes the Send with DocuSign button from one or more layouts.
	 * <p>
	 * The caller must be assigned the <code>DocuSign Administrator</code> permission set.
	 *
	 * @param type Salesforce object type.
	 * @param theme Salesforce UI theme.
	 * @param layouts One or more layouts from which to remove the button.
	 *
	 * @return <code>True</code> if the remove operation was successful.
	 */
	public static Boolean removeSendButton(
		final SObjectType type,
		final UITheme.Theme theme,
		final List<Layout> layouts) {

		Permissions.verifyIsDocuSignAdministrator();

		if (type == null || theme == null || Collection.isEmpty(layouts)) {
			throw new DocuSignException(Label.UndefinedArgument);
		}

		List<MetadataAPI.Layout> mdLayouts = readLayouts(type, layouts);
		String apiName = Application.namespacePrefix + 'Send';

		if (theme == UITheme.Theme.Classic) {
			removeClassicButton(apiName, mdLayouts);
		} else { // Lightning
			removeLightningButton(apiName, mdLayouts);
		}

		return true;
	}
}
