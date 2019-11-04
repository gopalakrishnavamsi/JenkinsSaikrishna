@IsTest
public class MetadataAPIMock implements WebServiceMock {

	private final Boolean success;

	public MetadataAPIMock(final Boolean success) {
		this.success = success;
	}

	private String getFullName(final MetadataAPI.Metadata md) {
		String result = null;
		if (md instanceof MetadataAPI.RemoteSiteSetting) {
			result = ((MetadataAPI.RemoteSiteSetting)md).fullName;
		} else if (md instanceof MetadataAPI.Layout) {
			result = ((MetadataAPI.Layout)md).fullName;
		} else if (md instanceof MetadataAPI.SecuritySettings) {
			result = ((MetadataAPI.SecuritySettings)md).fullName;
		} else if (md instanceof MetadataAPI.WebLink) {
			result = ((MetadataAPI.WebLink)md).fullName;
		} else {
			result = md.fullName;
		}
		return result;
	}

	public virtual void doInvoke(
		final Object stub,
		final Object request,
		final Map<String, Object> response,
		final String endpoint,
		final String soapAction,
		final String requestName,
		final String responseNS,
		final String responseName,
		final String responseType) {

		if (this.success) {
			if (request instanceof MetadataAPI.listMetadata_element) {
				List<MetadataAPI.FileProperties> result = new List<MetadataAPI.FileProperties>();
				MetadataAPI.listMetadata_element req = (MetadataAPI.listMetadata_element)request;
				if (req.queries != null) {
					for (MetadataAPI.ListMetadataQuery q : req.queries) {
						MetadataAPI.FileProperties fp = new MetadataAPI.FileProperties();
						fp.type_x = q.type_x;
						fp.namespacePrefix = Salesforce.namespace;
						fp.fullName = 'Contact-' + UUID.randomUUID().toString();
						result.add(fp);
					}
				}
				MetadataAPI.listMetadataResponse_element resp = new MetadataAPI.listMetadataResponse_element();
				resp.result = result;
				response.put('response_x', resp);
			} else if (request instanceof MetadataAPI.updateMetadata_element) {
				List<MetadataAPI.SaveResult> result = new List<MetadataAPI.SaveResult>();
				MetadataAPI.updateMetadata_element req = (MetadataAPI.updateMetadata_element)request;
				if (req.metadata != null) {
					for (MetadataAPI.Metadata md : req.metadata) {
						MetadataAPI.SaveResult r = new MetadataAPI.SaveResult();
						r.success = true;
						r.fullName = getFullName(md);
						result.add(r);
					}
				}
				MetadataAPI.updateMetadataResponse_element resp = new MetadataAPI.updateMetadataResponse_element();
				resp.result = result;
				response.put('response_x', resp);
			} else if (request instanceof MetadataAPI.readMetadata_element) {
				MetadataAPI.readMetadata_element req = (MetadataAPI.readMetadata_element)request;
				switch on req.type_x {
					when 'Layout' {
						List<MetadataAPI.Layout> records = new List<MetadataAPI.Layout>();
						for (String fn : req.fullNames) {
							MetadataAPI.Layout record = new MetadataAPI.Layout();
							record.fullName = fn;
							record.customButtons = new List<String> {
								MetadataAPI.NAMESPACE_PREFIX + 'Send',
								MetadataAPI.NAMESPACE_PREFIX + 'Gen'
							};
							MetadataAPI.PlatformActionList pal = new MetadataAPI.PlatformActionList();
							MetadataAPI.PlatformActionListItem pali1 = new MetadataAPI.PlatformActionListItem();
							pali1.actionName = MetadataAPI.NAMESPACE_PREFIX + 'Send';
							pali1.actionType = 'CustomButton';
							pali1.sortOrder = 0;
							MetadataAPI.PlatformActionListItem pali2 = new MetadataAPI.PlatformActionListItem();
							pali2.actionName = MetadataAPI.NAMESPACE_PREFIX + 'Gen';
							pali2.actionType = 'CustomButton';
							pali2.sortOrder = 1;
							pal.platformActionListItems = new List<MetadataAPI.PlatformActionListItem> { pali1, pali2 };
							record.platformActionList = pal;
							records.add(record);
						}
						MetadataAPI.ReadLayoutResult result = new MetadataAPI.ReadLayoutResult();
						result.records = records;
						MetadataAPI.readLayoutResponse_element resp = new MetadataAPI.readLayoutResponse_element();
						resp.result = result;
						response.put('response_x', resp);
					} when 'WebLink' {
						List<MetadataAPI.WebLink> records = new List<MetadataAPI.WebLink>();
						for (String fn : req.fullNames) {
							MetadataAPI.WebLink record = new MetadataAPI.WebLink();
							record.fullName = fn;
							record.masterLabel = 'test';
							records.add(record);
						}
						MetadataAPI.ReadWebLinkResult result = new MetadataAPI.ReadWebLinkResult();
						result.records = records;
						MetadataAPI.readWebLinkResponse_element resp = new MetadataAPI.readWebLinkResponse_element();
						resp.result = result;
						response.put('response_x', resp);
					} when 'QuickAction' {
						List<MetadataAPI.QuickAction> records = new List<MetadataAPI.QuickAction>();
						for (String fn : req.fullNames) {
							MetadataAPI.QuickAction record = new MetadataAPI.QuickAction();
							record.fullName = fn;
							records.add(record);
						}
						MetadataAPI.ReadQuickActionResult result = new MetadataAPI.ReadQuickActionResult();
						result.records = records;
						MetadataAPI.readQuickActionResponse_element resp = new MetadataAPI.readQuickActionResponse_element();
						resp.result = result;
						response.put('response_x', resp);
					} when 'RemoteSiteSetting' {
						List<MetadataAPI.RemoteSiteSetting> records = new List<MetadataAPI.RemoteSiteSetting>();
						for (String fn : req.fullNames) {
							MetadataAPI.RemoteSiteSetting record = new MetadataAPI.RemoteSiteSetting();
							record.fullName = fn;
							record.description = fn + ' description';
							record.url = 'https://unit.test';
							records.add(record);
						}
						MetadataAPI.ReadRemoteSiteSettingResult result = new MetadataAPI.ReadRemoteSiteSettingResult();
						result.records = records;
						MetadataAPI.readRemoteSiteSettingResponse_element resp = new MetadataAPI.readRemoteSiteSettingResponse_element();
						resp.result = result;
						response.put('response_x', resp);
					} when else { // SecuritySettings
						List<MetadataAPI.SecuritySettings> records = new List<MetadataAPI.SecuritySettings>();
						for (String fn : req.fullNames) {
							MetadataAPI.SecuritySettings record = new MetadataAPI.SecuritySettings();
							record.fullName = fn;
							records.add(record);
						}
						MetadataAPI.ReadSecuritySettingsResult result = new MetadataAPI.ReadSecuritySettingsResult();
						result.records = records;
						MetadataAPI.readSecuritySettingsResponse_element resp = new MetadataAPI.readSecuritySettingsResponse_element();
						resp.result = result;
						response.put('response_x', resp);
					}
				}
			} else if (request instanceof MetadataAPI.createMetadata_element) {
				List<MetadataAPI.SaveResult> result = new List<MetadataAPI.SaveResult>();
				MetadataAPI.createMetadata_element req = (MetadataAPI.createMetadata_element)request;
				if (req.metadata != null) {
					for (MetadataAPI.Metadata md : ((MetadataAPI.createMetadata_element)request).metadata) {
						MetadataAPI.SaveResult r = new MetadataAPI.SaveResult();
						r.success = true;
						r.fullName = getFullName(md);
						result.add(r);
					}
				}
				MetadataAPI.createMetadataResponse_element resp = new MetadataAPI.createMetadataResponse_element();
				resp.result = result;
				response.put('response_x', resp);
			} else if (request instanceof MetadataAPI.deleteMetadata_element) {
				response.put('response_x', new MetadataAPI.deleteMetadataResponse_element());
			}
		} else if (request instanceof MetadataAPI.readMetadata_element) {
			MetadataAPI.readMetadata_element req = (MetadataAPI.readMetadata_element)request;
			switch on req.type_x {
				when 'Layout' {
					MetadataAPI.ReadLayoutResult result = new MetadataAPI.ReadLayoutResult();
					result.records = new List<MetadataAPI.Layout>();
					MetadataAPI.readLayoutResponse_element resp = new MetadataAPI.readLayoutResponse_element();
					resp.result = result;
					response.put('response_x', resp);
				} when 'WebLink' {
					MetadataAPI.ReadWebLinkResult result = new MetadataAPI.ReadWebLinkResult();
					result.records = new List<MetadataAPI.WebLink>();
					MetadataAPI.readWebLinkResponse_element resp = new MetadataAPI.readWebLinkResponse_element();
					resp.result = result;
					response.put('response_x', resp);
				} when 'QuickAction' {
					MetadataAPI.ReadQuickActionResult result = new MetadataAPI.ReadQuickActionResult();
					result.records = new List<MetadataAPI.QuickAction>();
					MetadataAPI.readQuickActionResponse_element resp = new MetadataAPI.readQuickActionResponse_element();
					resp.result = result;
					response.put('response_x', resp);
				} when 'RemoteSiteSetting' {
					MetadataAPI.ReadRemoteSiteSettingResult result = new MetadataAPI.ReadRemoteSiteSettingResult();
					result.records = new List<MetadataAPI.RemoteSiteSetting>();
					MetadataAPI.readRemoteSiteSettingResponse_element resp = new MetadataAPI.readRemoteSiteSettingResponse_element();
					resp.result = result;
					response.put('response_x', resp);
				} when else { // SecuritySettings
					MetadataAPI.ReadSecuritySettingsResult result = new MetadataAPI.ReadSecuritySettingsResult();
					result.records = new List<MetadataAPI.SecuritySettings>();
					MetadataAPI.readSecuritySettingsResponse_element resp = new MetadataAPI.readSecuritySettingsResponse_element();
					resp.result = result;
					response.put('response_x', resp);
				}
			}
		} else if (request instanceof MetadataAPI.createMetadata_element
			|| request instanceof MetadataAPI.updateMetadata_element) {

			List<MetadataAPI.SaveResult> result = new List<MetadataAPI.SaveResult>();
			for (MetadataAPI.Metadata md : ((MetadataAPI.createMetadata_element)request).metadata) {
				MetadataAPI.SaveResult r = new MetadataAPI.SaveResult();
				r.success = false;
				MetadataAPI.Error e = new MetadataAPI.Error();
				e.statusCode = 'UNIT_TEST';
				e.message = 'Test failure';
				r.errors = new List<MetadataAPI.Error> { e };
				result.add(r);
			}
			MetadataAPI.createMetadataResponse_element resp = new MetadataAPI.createMetadataResponse_element();
			resp.result = result;
			response.put('response_x', resp);
		} else if (request instanceof MetadataAPI.deleteMetadata_element) {
			List<MetadataAPI.DeleteResult> result = new List<MetadataAPI.DeleteResult>();
			for (String fullName : ((MetadataAPI.deleteMetadata_element)request).fullNames) {
				MetadataAPI.DeleteResult r = new MetadataAPI.DeleteResult();
				r.fullName = fullName;
				r.success = false;
				MetadataAPI.Error e = new MetadataAPI.Error();
				e.statusCode = 'UNIT_TEST';
				e.message = 'Test failure';
				r.errors = new List<MetadataAPI.Error> { e };
				result.add(r);
			}
			MetadataAPI.deleteMetadataResponse_element resp = new MetadataAPI.deleteMetadataResponse_element();
			resp.result = result;
			response.put('response_x', resp);
		}
	}

	public static MetadataAPIMock success() {
		return (MetadataAPIMock)TestUtils.setMock(new MetadataAPIMock(true));
	}

	public static MetadataAPIMock failure() {
		return (MetadataAPIMock)TestUtils.setMock(new MetadataAPIMock(false));
	}
}
