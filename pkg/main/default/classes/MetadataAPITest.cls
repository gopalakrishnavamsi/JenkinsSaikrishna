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

/*
 * This is a dummy test class to obtain 100% coverage for the generated WSDL2Apex code.
 */
@IsTest(IsParallel = true)
public class MetadataAPITest {

	@IsTest
	static void coverGeneratedCodeCRUDOperations() {
		// Null Web Service mock implementation
		System.Test.setMock(WebServiceMock.class, new MetadataAPIMock(true));
		// Only required to workaround a current code coverage bug in the platform
		new MetadataAPI();
		// Invoke operations
		MetadataAPI.Client metaDataPort = MetadataAPI.getInstance();

		Test.startTest();
		metaDataPort.readMetadata('Layout', new String[] { 'a' });
		metaDataPort.readMetadata('QuickAction', new String[] { 'b' });
		metaDataPort.readMetadata('WebLink', new String[] { 'c' });
		metaDataPort.readMetadata('SecuritySettings', new String[] { 'd' });
		metaDataPort.readMetadata('RemoteSiteSetting', new String[] { 'e' });
		Test.stopTest();

		System.assert(true);
	}

	@IsTest
	static void coverGeneratedCodeFileBasedOperations1() {
		// Null Web Service mock implementation
		System.Test.setMock(WebServiceMock.class, new MetadataAPIMock(true));
		// Only required to workaround a current code coverage bug in the platform
		new MetadataAPI();
		// Invoke operations
		MetadataAPI.Client metaDataPort = MetadataAPI.getInstance();

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
		new MetadataAPI.RemoteSiteSetting();
		new MetadataAPI.listMetadataResponse_element();
		new MetadataAPI.PrimaryTabComponents();
		new MetadataAPI.LogInfo();
		new MetadataAPI.Layout();
		new MetadataAPI.CallOptions_element();
		new MetadataAPI.LayoutColumn();
		new MetadataAPI.FileProperties();
		new MetadataAPI.RelatedListItem();
		new MetadataAPI.ListMetadataQuery();
		new MetadataAPI.DebuggingHeader_element();
		new MetadataAPI.CustomConsoleComponents();
		new MetadataAPI.SubtabComponents();
		new MetadataAPI.SummaryLayoutItem();
		new MetadataAPI.LayoutSection();
		new MetadataAPI.listMetadata_element();
		new MetadataAPI.SessionHeader_element();
		new MetadataAPI.SummaryLayout();
		new MetadataAPI.MiniLayout();
		new MetadataAPI.DebuggingInfo_element();
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
		new MetadataAPI.ReadRemoteSiteSettingResult().getRecords();
		new MetadataAPI.readRemoteSiteSettingResponse_element();
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
		new MetadataAPI.WebLink();
		new MetadataAPI.ReadWebLinkResult().getRecords();
		new MetadataAPI.readWebLinkResponse_element().getResult();
		Test.stopTest();

		System.assert(true);
	}

	@IsTest
	static void test_headers() {
		Test.startTest();
		MetadataAPI.Client client = MetadataAPI.getInstance();
		System.assertNotEquals(null, client);
		System.assertNotEquals(null, client.SessionHeader);
		System.assertNotEquals(null, client.SessionHeader.sessionId);
		System.assertNotEquals(null, client.AllOrNoneHeader);
		System.assert(client.AllOrNoneHeader.allOrNone);
		System.assertNotEquals(null, client.CallOptions);
		System.assertEquals('DocuSign/DocuSignforSalesforce Essentials/', client.CallOptions.client);
		Test.stopTest();
	}
}
