/**
* Copyright (c) 2012, FinancialForce.com, inc
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
*   are permitted provided that the following conditions are met:
*
* - Redistributions of source code must retain the above copyright notice,
*      this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright notice,
*      this list of conditions and the following disclaimer in the documentation
*      and/or other materials provided with the distribution.
* - Neither the name of the FinancialForce.com, inc nor the names of its contributors
*      may be used to endorse or promote products derived from this software without
*      specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
*  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
*  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
*  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
*  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
*  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
*  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

/**
* This is a dummy test class to obtain 100% coverage for the generated WSDL2Apex code, it is not a funcitonal test class
*   You should follow the usual practices to cover your other code, as shown in the MetadataCreateJobTest.cls
**/
@isTest
private class MetadataServiceTest {

	/**
	* Dummy Metadata API web service mock class (see MetadataCreateJobTest.cls for a better example)
	**/
	private class WebServiceMockImpl implements WebServiceMock {
		public void doInvoke(
			final Object stub, final Object request, final Map<String, Object> response,
			final String endpoint, final String soapAction, final String requestName,
			final String responseNS, final String responseName, final String responseType) {
			if (request instanceof MetadataService.listMetadata_element) {
				response.put('response_x', new MetadataService.listMetadataResponse_element());
			} else if (request instanceof MetadataService.updateMetadata_element) {
				response.put('response_x', new MetadataService.updateMetadataResponse_element());
			} else if (request instanceof MetadataService.readMetadata_element) {
				response.put('response_x', new MetadataService.readLayoutResponse_element());
			} else if (request instanceof MetadataService.createMetadata_element) {
				response.put('response_x', new MetadataService.createMetadataResponse_element());
			} else if (request instanceof MetadataService.deleteMetadata_element) {
				response.put('response_x', new MetadataService.deleteMetadataResponse_element());
			}
		}
	}

	static testMethod void coverGeneratedCodeCRUDOperations() {
		// Null Web Service mock implementation
		System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
		// Only required to workaround a current code coverage bug in the platform
		MetadataService mdService = new MetadataService();
		// Invoke operations
		MetadataService.MetadataPort metaDataPort = MetadataService.getInstance();

		Test.startTest();
		metaDataPort.readMetadata('a', new String[] { 'a' });
		Test.stopTest();

		System.assert(true);
	}

	static testMethod void coverGeneratedCodeFileBasedOperations1() {
		// Null Web Service mock implementation
		System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
		// Only required to workaround a current code coverage bug in the platform
		MetadataService mdService = new MetadataService();
		// Invoke operations
		MetadataService.MetadataPort metaDataPort = MetadataService.getInstance();

		Test.startTest();
		metaDataPort.createMetadata(null);
		metaDataPort.listMetadata(null, null);
		metaDataPort.updateMetadata(null);
		metaDataPort.deleteMetadata(null, null);
		Test.stopTest();

		System.assert(true);
	}

	static testMethod void coverGeneratedCodeTypes() {
		// Reference types
		Test.startTest();
		new MetadataService();
		new MetadataService.listMetadataResponse_element();
		new MetadataService.PrimaryTabComponents();
		new MetadataService.LogInfo();
		new MetadataService.Layout();
		new MetadataService.CallOptions_element();
		new MetadataService.NetworkAccess();
		new MetadataService.SecuritySettings();
		new MetadataService.LayoutColumn();
		new MetadataService.FileProperties();
		new MetadataService.RelatedListItem();
		new MetadataService.ListMetadataQuery();
		new MetadataService.DebuggingHeader_element();
		new MetadataService.IpRange();
		new MetadataService.CustomConsoleComponents();
		new MetadataService.SubtabComponents();
		new MetadataService.SummaryLayoutItem();
		new MetadataService.LayoutSection();
		new MetadataService.listMetadata_element();
		new MetadataService.PasswordPolicies();
		new MetadataService.SessionHeader_element();
		new MetadataService.SummaryLayout();
		new MetadataService.MiniLayout();
		new MetadataService.DebuggingInfo_element();
		new MetadataService.SessionSettings();
		new MetadataService.LayoutItem();
		new MetadataService.QuickActionList();
		new MetadataService.QuickActionListItem();
		new MetadataService.FeedLayout();
		new MetadataService.ReportChartComponentLayoutItem();
		new MetadataService.Error();
		new MetadataService.RelatedContent();
		new MetadataService.SidebarComponent();
		new MetadataService.SaveResult();
		new MetadataService.FeedLayoutComponent();
		new MetadataService.RelatedContentItem();
		new MetadataService.readMetadata_element();
		new MetadataService.ReadLayoutResult().getRecords();
		new MetadataService.readLayoutResponse_element();
		new MetadataService.ReadSecuritySettingsResult().getRecords();
		new MetadataService.readSecuritySettingsResponse_element().getResult();
		new MetadataService.FeedLayoutFilter();
		new MetadataService.Container();
		new MetadataService.RelatedList();
		new MetadataService.PlatformActionListItem();
		new MetadataService.PlatformActionList();
		new MetadataService.createMetadata_element();
		new MetadataService.createMetadataResponse_element();
		new MetadataService.deleteMetadataResponse_element();
		new MetadataService.DeleteResult();
		new MetadataService.deleteMetadata_element();
		new MetadataService.ReadWebLinkResult();
		new MetadataService.WebLinkTranslation();
		new MetadataService.WebLink();
		new MetadataService.ReadWebLinkResult().getRecords();
		new MetadataService.readWebLinkResponse_element().getResult();
		Test.stopTest();

		System.assert(true);
	}
}
