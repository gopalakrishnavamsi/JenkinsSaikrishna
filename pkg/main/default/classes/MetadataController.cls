public with sharing class MetadataController {

	public class MergeObjects {
		public List<MergeObject> common { get; private set; }
		public List<MergeObject> all { get; private set; }

		private MergeObjects(
			final List<MergeObject> common,
			final List<MergeObject> all) {

			this.common = common;
			this.all = all;
		}
	}

	@AuraEnabled(Cacheable = true)
	public static MergeObjects getSalesforceObjects() {
		try {
			return new MergeObjects(
				MetadataService.getCommonObjects(),
				MetadataService.getObjects());
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to retrieve Salesforce objects');
		}
	}

	@AuraEnabled(Cacheable = true)
	public static List<Layout> getLayouts(final String sObjectType) {
		try {
			return MetadataService.getLayouts(Salesforce.getSObjectType(sObjectType));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to retrieve layouts');
		}
	}

	// Fix layouts with proper SObjectType (not serializable)
	private static List<Layout> deserializeLayouts(
		final SObjectType type,
		final String layoutsJson) {

		List<Layout> result = new List<Layout>();
		if (String.isNotBlank(layoutsJson)) {
			List<Layout> layouts = (List<Layout>)JSON.deserialize(layoutsJson, List<Layout>.class);
			if (Collection.isNotEmpty(layouts)) {
				for (Layout l : layouts) {
					result.add(new Layout(type, l.id, l.namespace, l.name));
				}
			}
		}
		return result;
	}

	@AuraEnabled
	public static Boolean addSendButton(
		final String sObjectType,
		final Boolean isLightning,
		final String layoutsJson) {

		try {
			SObjectType type = Salesforce.getSObjectType(sObjectType);
			return MetadataService.addSendButton(
				type,
				isLightning ? UITheme.Theme.Lightning : UITheme.Theme.Classic,
				deserializeLayouts(type, layoutsJson));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to add send button');
		}
	}

	@AuraEnabled
	public static Boolean removeSendButton(
		final String sObjectType,
		final Boolean isLightning,
		final String layoutsJson) {

		try {
			SObjectType type = Salesforce.getSObjectType(sObjectType);
			return MetadataService.removeSendButton(
				type,
				isLightning ? UITheme.Theme.Lightning : UITheme.Theme.Classic,
				deserializeLayouts(type, layoutsJson));
		} catch (Exception ex) {
			throw Controller.wrapException(ex, 'Failed to remove send button');
		}
	}
}
