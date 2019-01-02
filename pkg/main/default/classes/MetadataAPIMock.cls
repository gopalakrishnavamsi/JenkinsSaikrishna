@IsTest
public class MetadataAPIMock implements WebServiceMock {

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
						record.customButtons = new List<String>();
						MetadataAPI.PlatformActionList pal = new MetadataAPI.PlatformActionList();
						pal.platformActionListItems = new List<MetadataAPI.PlatformActionListItem>();
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
	}
}
