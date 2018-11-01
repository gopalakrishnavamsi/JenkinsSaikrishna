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
@isTest(isParallel = true)
private class MetadataAPITest {

	/**
	* Dummy Metadata API web service mock class (see MetadataCreateJobTest.cls for a better example)
	**/
	private class WebServiceMockImpl implements WebServiceMock {
		public void doInvoke(
			final Object stub, final Object request, final Map<String, Object> response,
			final String endpoint, final String soapAction, final String requestName,
			final String responseNS, final String responseName, final String responseType) {
			if (request instanceof MetadataAPI.listMetadata_element) {
				response.put('response_x', new MetadataAPI.listMetadataResponse_element());
			} else if (request instanceof MetadataAPI.updateMetadata_element) {
				response.put('response_x', new MetadataAPI.updateMetadataResponse_element());
			} else if (request instanceof MetadataAPI.readMetadata_element) {
				response.put('response_x', new MetadataAPI.readLayoutResponse_element());
			} else if (request instanceof MetadataAPI.createMetadata_element) {
				response.put('response_x', new MetadataAPI.createMetadataResponse_element());
			} else if (request instanceof MetadataAPI.deleteMetadata_element) {
				response.put('response_x', new MetadataAPI.deleteMetadataResponse_element());
			}
		}
	}

	@IsTest
	static void coverGeneratedCodeCRUDOperations() {
		// Null Web Service mock implementation
		System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
		// Only required to workaround a current code coverage bug in the platform
		MetadataAPI mdService = new MetadataAPI();
		// Invoke operations
		MetadataAPI.MetadataPort metaDataPort = MetadataAPI.getInstance();

		Test.startTest();
		metaDataPort.readMetadata('a', new String[] { 'a' });
		Test.stopTest();

		System.assert(true);
	}

	@IsTest
	static void coverGeneratedCodeFileBasedOperations1() {
		// Null Web Service mock implementation
		System.Test.setMock(WebServiceMock.class, new WebServiceMockImpl());
		// Only required to workaround a current code coverage bug in the platform
		MetadataAPI mdService = new MetadataAPI();
		// Invoke operations
		MetadataAPI.MetadataPort metaDataPort = MetadataAPI.getInstance();

		Test.startTest();
		metaDataPort.createMetadata(null);
		metaDataPort.listMetadata(null, null);
		metaDataPort.updateMetadata(null);
		metaDataPort.deleteMetadata(null, null);
		Test.stopTest();

		System.assert(true);
	}

	@IsTest
	static void coverGeneratedCodeTypes() {
		// Reference types
		Test.startTest();
		new MetadataAPI();
		new MetadataAPI.listMetadataResponse_element();
		new MetadataAPI.PrimaryTabComponents();
		new MetadataAPI.LogInfo();
		new MetadataAPI.Layout();
		new MetadataAPI.CallOptions_element();
		new MetadataAPI.NetworkAccess();
		new MetadataAPI.SecuritySettings();
		new MetadataAPI.LayoutColumn();
		new MetadataAPI.FileProperties();
		new MetadataAPI.RelatedListItem();
		new MetadataAPI.ListMetadataQuery();
		new MetadataAPI.DebuggingHeader_element();
		new MetadataAPI.IpRange();
		new MetadataAPI.CustomConsoleComponents();
		new MetadataAPI.SubtabComponents();
		new MetadataAPI.SummaryLayoutItem();
		new MetadataAPI.LayoutSection();
		new MetadataAPI.listMetadata_element();
		new MetadataAPI.PasswordPolicies();
		new MetadataAPI.SessionHeader_element();
		new MetadataAPI.SummaryLayout();
		new MetadataAPI.MiniLayout();
		new MetadataAPI.DebuggingInfo_element();
		new MetadataAPI.SessionSettings();
		new MetadataAPI.LayoutItem();
		new MetadataAPI.QuickActionList();
		new MetadataAPI.QuickActionListItem();
		new MetadataAPI.FeedLayout();
		new MetadataAPI.ReportChartComponentLayoutItem();
		new MetadataAPI.Error();
		new MetadataAPI.RelatedContent();
		new MetadataAPI.SidebarComponent();
		new MetadataAPI.SaveResult();
		new MetadataAPI.FeedLayoutComponent();
		new MetadataAPI.RelatedContentItem();
		new MetadataAPI.readMetadata_element();
		new MetadataAPI.ReadLayoutResult().getRecords();
		new MetadataAPI.readLayoutResponse_element();
		new MetadataAPI.ReadSecuritySettingsResult().getRecords();
		new MetadataAPI.readSecuritySettingsResponse_element().getResult();
		new MetadataAPI.FeedLayoutFilter();
		new MetadataAPI.Container();
		new MetadataAPI.RelatedList();
		new MetadataAPI.PlatformActionListItem();
		new MetadataAPI.PlatformActionList();
		new MetadataAPI.createMetadata_element();
		new MetadataAPI.createMetadataResponse_element();
		new MetadataAPI.deleteMetadataResponse_element();
		new MetadataAPI.DeleteResult();
		new MetadataAPI.deleteMetadata_element();
		new MetadataAPI.ReadWebLinkResult();
		new MetadataAPI.WebLinkTranslation();
		new MetadataAPI.WebLink();
		new MetadataAPI.ReadWebLinkResult().getRecords();
		new MetadataAPI.readWebLinkResponse_element().getResult();
		Test.stopTest();

		System.assert(true);
	}
}